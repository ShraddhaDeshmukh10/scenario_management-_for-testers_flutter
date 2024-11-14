import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class DeleteScenarioAction extends ReduxAction<AppState> {
  final String docId;

  DeleteScenarioAction(this.docId);

  @override
  Future<AppState> reduce() async {
    try {
      await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(docId)
          .delete();

      // Update state after deletion
      final updatedScenarios =
          state.scenarios.where((s) => s['docId'] != docId).toList();
      return state.copy(scenarios: updatedScenarios);
    } catch (e) {
      print("Error deleting scenario: $e");
      throw Exception("Failed to delete scenario.");
    }
  }
}
