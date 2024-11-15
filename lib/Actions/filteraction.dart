import 'package:async_redux/async_redux.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class FilterScenariosAction extends ReduxAction<AppState> {
  final String filter;

  FilterScenariosAction(this.filter);

  @override
  AppState reduce() {
    print("Filter applied: $filter");
    final filtered = state.scenarios.where((scenario) {
      return scenario['projectName']?.toLowerCase() == filter.toLowerCase();
    }).toList();
    print("Filtered scenarios: $filtered");
    return state.copy(filteredScenarios: filtered);
  }
}

class ClearFiltersAction extends ReduxAction<AppState> {
  @override
  AppState reduce() {
    return state.copy(filteredScenarios: state.scenarios);
  }
}
