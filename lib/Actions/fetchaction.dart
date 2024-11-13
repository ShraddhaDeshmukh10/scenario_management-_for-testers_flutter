import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class FetchAssignmentsAction extends ReduxAction<AppState> {
  @override
  Future<AppState?> reduce() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('assignments').get();

      final assignments = snapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'docId': doc.id, // Include document ID
        };
      }).toList();

      return state.copy(
          assignments: assignments); // Update assignments in state
    } catch (e) {
      print('Error fetching assignments: $e');
      return null;
    }
  }
}
