import 'package:firebase_auth/firebase_auth.dart';
import 'package:scenario_management_tool_for_testers/Actions/load_actions.dart';

class AppState {
  final User? user;
  final String? designation;
  final List<Map<String, dynamic>> scenarios;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> addtestcase;
  final List<Map<String, dynamic>> testCases;
  final List<Map<String, dynamic>> changeHistory;

  AppState({
    this.user,
    this.designation,
    this.scenarios = const [],
    this.assignments = const [],
    this.comments = const [],
    this.addtestcase = const [],
    required this.testCases,
    required this.changeHistory,
  });

  AppState copy({
    User? user,
    String? designation,
    List<Map<String, dynamic>>? scenarios,
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? addtestcase,
    List<Map<String, dynamic>>? testCases,
    List<Map<String, dynamic>>? changeHistory,
    List<Map<String, dynamic>>? comments,
  }) =>
      AppState(
        user: user,
        designation: designation ?? this.designation,
        scenarios: scenarios ?? this.scenarios,
        assignments: assignments ?? this.assignments,
        comments: comments ?? this.comments,
        testCases: testCases ?? this.testCases,
        changeHistory: changeHistory ?? this.changeHistory,
        addtestcase: addtestcase ?? this.addtestcase,
      );

  static AppState initialState() => AppState(
        user: null,
        designation: null,
        scenarios: [],
        assignments: [],
        changeHistory: [],
        comments: [],
        testCases: [],
        addtestcase: [],
      );
}
