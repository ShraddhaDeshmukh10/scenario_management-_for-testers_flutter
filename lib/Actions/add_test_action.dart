import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class AddTestCaseAction extends ReduxAction<AppState> {
  final String project;
  final String bugId;
  final String shortDescription;
  final String testCaseName;
  final String scenario;
  final String comments;
  final String description;
  final String attachment;
  final String? tag;

  AddTestCaseAction({
    required this.project,
    required this.bugId,
    required this.shortDescription,
    required this.testCaseName,
    required this.scenario,
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
      DocumentReference docRef =
          await FirebaseFirestore.instance.collection('testcases').add({
        'project': project,
        'bugId': bugId,
        'shortDescription': shortDescription,
        'testCaseName': testCaseName,
        'scenario': scenario,
        'comments': comments,
        'description': description,
        'attachments': attachment,
        'tags': tag ?? 'Unspecified',
        'assignedUsers': [userEmail],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userEmail,
      });

      String docId = docRef.id;

      Map<String, dynamic> newTestCase = {
        'project': project,
        'bugId': bugId,
        'shortDescription': shortDescription,
        'testCaseName': testCaseName,
        'scenario': scenario,
        'comments': comments,
        'description': description,
        'attachments': attachment,
        'tags': tag ?? 'Unspecified',
        'assignedUsers': [userEmail],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userEmail,
        'docId': docId, // Store the document ID
      };

      List<Map<String, dynamic>> updatedTestCases = List.from(state.addtestcase)
        ..add(newTestCase);

      return state.copy(addtestcase: updatedTestCases);
    } catch (e) {
      // Handle the error by showing a message or logging it
      print("Error adding test case: $e");
      throw Exception('Failed to add test case');
    }
  }
}
