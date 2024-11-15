import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/Actions/add_test_action.dart';
import 'package:scenario_management_tool_for_testers/Actions/addcomment.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchaction.dart';
import 'package:scenario_management_tool_for_testers/Actions/filteraction.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/Connnector/dashboard.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchsenario.dart';
import 'package:scenario_management_tool_for_testers/Actions/updatesenario.dart';
import 'package:scenario_management_tool_for_testers/Actions/deletesenario.dart';
import 'package:scenario_management_tool_for_testers/main.dart';

class ViewModel extends Vm {
  final String? designation;
  final List<Map<String, dynamic>> scenarios;
  List<Map<String, dynamic>> filteredScenarios; // Filtered scenarios
  final void Function(String filter) filterScenarios;
  final void Function() clearFilters;
  final Color roleColor;
  final bool isCheckboxEnabled;
  final List<Map<String, dynamic>> assignments;
  final void Function(String content, String attachment) addComment;
  final List<Map<String, dynamic>> comments;
  final VoidCallback fetchAssignments;
  final VoidCallback fetchComments;
  final VoidCallback fetchScenarios;
  final void Function(String, Map<String, dynamic>) updateScenario;
  final Function(String?) searchScenarios;
  final void Function(String docId) deleteScenario;
  final List<Map<String, dynamic>> testCases;
  final List<Map<String, dynamic>> changeHistory;

  final void Function(
      String project,
      String bugId,
      String shortDescription,
      String testCaseName,
      String scenario,
      String comments,
      String description,
      String attachment,
      String? tag) addtestcase;

  ViewModel({
    required this.addtestcase,
    required this.testCases,
    required this.changeHistory,
    required this.deleteScenario,
    required this.scenarios,
    required this.filteredScenarios,
    required this.filterScenarios,
    required this.clearFilters,
    required this.addComment,
    required this.designation,
    required this.assignments,
    required this.roleColor,
    required this.fetchAssignments,
    required this.fetchComments,
    required this.comments,
    required this.isCheckboxEnabled,
    required this.fetchScenarios,
    required this.updateScenario,
    required this.searchScenarios,
  }) : super(equals: [scenarios, comments, filteredScenarios]);

  static ViewModel fromStore(Store<AppState> store) {
    String designation = store.state.designation ?? '';
    Color getRoleColor() {
      switch (designation) {
        case 'Junior Tester':
          return Colors.red;
        case 'Tester Lead':
          return Colors.green;
        case 'Developer':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return ViewModel(
      testCases: store.state.testCases,
      changeHistory: store.state.changeHistory,
      scenarios: store.state.scenarios,
      filteredScenarios: store.state.filteredScenarios ?? store.state.scenarios,
      filterScenarios: (String filter) {
        store.dispatch(FilterScenariosAction(filter));
      },
      clearFilters: () {
        store.dispatch(ClearFiltersAction());
      },
      assignments: store.state.assignments,
      designation: store.state.designation,
      addComment: (content, attachment) =>
          store.dispatch(AddCommentAction(content, attachment)),
      comments: store.state.comments,
      roleColor: getRoleColor(),
      isCheckboxEnabled: designation == 'Tester Lead',
      deleteScenario: (docId) => store.dispatch(DeleteScenarioAction(docId)),
      fetchAssignments: () => store.dispatch(FetchAssignmentsAction()),
      fetchComments: () => store.dispatch(FetchCommentsAction()),
      fetchScenarios: () => store.dispatch(FetchScenariosAction()),
      searchScenarios: (projectName) =>
          store.dispatch(FetchScenariosAction(projectName: projectName)),
      updateScenario: (docId, data) =>
          store.dispatch(UpdateScenarioAction(docId: docId, updatedData: data)),
      addtestcase: (project, bugId, shortDescription, testCaseName, scenario,
              comments, description, attachment, tag) =>
          store.dispatch(AddTestCaseAction(
        project: project,
        bugId: bugId,
        shortDescription: shortDescription,
        testCaseName: testCaseName,
        scenarioId: scenario,
        comments: comments,
        description: description,
        attachment: attachment,
        tag: tag,
      )),
    );
  }
}

class Factory extends VmFactory<AppState, DashboardPage, ViewModel> {
  Factory(DashboardPage connector) : super(connector);

  @override
  ViewModel fromStore() => ViewModel.fromStore(store);
}
