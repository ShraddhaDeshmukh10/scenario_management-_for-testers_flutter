import 'package:async_redux/async_redux.dart';
import 'package:scenario_management_tool_for_testers/Services/firebasesevices.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class FetchScenariosAction extends ReduxAction<AppState> {
  final String? projectName;

  FetchScenariosAction({this.projectName});

  @override
  Future<AppState> reduce() async {
    final firebaseService = FirebaseService();
    final scenarios = await firebaseService.fetchScenariosFromFirebase();

    // Filter scenarios if a project name is provided
    final filteredScenarios = projectName != null
        ? scenarios
            .where((scenario) => (scenario['project'] ?? '')
                .toLowerCase()
                .contains(projectName!.toLowerCase()))
            .toList()
        : scenarios;

    return state.copy(scenarios: filteredScenarios);
  }
}
