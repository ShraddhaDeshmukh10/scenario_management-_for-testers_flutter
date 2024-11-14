import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class AddTestCaseAction extends ReduxAction<AppState> {
  final String project;
  final String bugId;
  final String shortDescription;
  final String testCaseName;
  final String scenarioId;
  final String comments;
  final String description;
  final String attachment;
  final String? tag;

  AddTestCaseAction({
    required this.project,
    required this.bugId,
    required this.shortDescription,
    required this.testCaseName,
    required this.scenarioId,
    required this.comments,
    required this.description,
    required this.attachment,
    this.tag,
  });

  @override
  Future<AppState> reduce() async {
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'unknown_user';

    try {
      // Add the test case to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenarioId)
          .collection('testCases')
          .add({
        'project': project,
        'bugId': bugId,
        'shortDescription': shortDescription,
        'testCaseName': testCaseName,
        'comments': comments,
        'description': description,
        'attachment': attachment,
        'tags': tag ?? 'Unspecified',
        'createdBy': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add the test case to the state
      final newTestCase = {
        'project': project,
        'bugId': bugId,
        'shortDescription': shortDescription,
        'testCaseName': testCaseName,
        'comments': comments,
        'description': description,
        'attachment': attachment,
        'tags': tag ?? 'Unspecified',
        'createdBy': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'docId': docRef.id,
      };

      final updatedScenarios = state.scenarios.map((scenario) {
        if (scenario['docId'] == scenarioId) {
          final testCases = List.from(scenario['testCases'] ?? []);
          testCases.add(newTestCase);
          return {...scenario, 'testCases': testCases};
        }
        return scenario;
      }).toList();

      return state.copy(scenarios: updatedScenarios);
    } catch (e) {
      print("Error adding test case: $e");
      throw Exception("Failed to add test case.");
    }
  }
}
