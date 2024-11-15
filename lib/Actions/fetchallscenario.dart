import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

Future<void> fetchTestCases(Store<AppState> store, String scenarioId) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('scenarios')
        .doc(scenarioId)
        .collection('testCases')
        .get();

    List<Map<String, dynamic>> testCases = snapshot.docs.map((doc) {
      return {'docId': doc.id, ...?doc.data() as Map<String, dynamic>};
    }).toList();
  } catch (e) {
    print("Error fetching test cases: $e");
  }
}

Future<void> fetchComments(Store<AppState> store, String scenarioId) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('scenarios')
        .doc(scenarioId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> comments = snapshot.docs.map((doc) {
      return {'docId': doc.id, ...?doc.data() as Map<String, dynamic>};
    }).toList();
  } catch (e) {
    print("Error fetching comments: $e");
  }
}

Future<void> fetchChangeHistory(
    Store<AppState> store, String scenarioId) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('scenarios')
        .doc(scenarioId)
        .collection('changes')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    List<Map<String, dynamic>> changeHistory = snapshot.docs.map((doc) {
      return {'docId': doc.id, ...?doc.data() as Map<String, dynamic>};
    }).toList();
  } catch (e) {
    print("Error fetching change history: $e");
    ;
  }
}
