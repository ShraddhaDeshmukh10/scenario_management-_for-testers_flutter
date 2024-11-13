import 'package:async_redux/async_redux.dart';
import 'package:scenario_management_tool_for_testers/Services/firebasesevices.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class UpdateScenarioAction extends ReduxAction<AppState> {
  final String docId;
  final Map<String, dynamic> updatedData;

  UpdateScenarioAction({required this.docId, required this.updatedData});

  @override
  Future<AppState> reduce() async {
    final firebaseService = FirebaseService();
    await firebaseService.updateScenarioInFirebase(docId, updatedData);

    // Optionally, update the local state after updating Firebase
    final updatedScenarios = state.scenarios.map((scenario) {
      if (scenario['docId'] == docId) {
        return {...scenario, ...updatedData}; // Update the scenario locally
      }
      return scenario;
    }).toList();

    return state.copy(scenarios: updatedScenarios);
  }
}
