import 'package:firebase_auth/firebase_auth.dart';

class AppState {
  final User? user;
  final String? designation;
  final List<Map<String, dynamic>> scenarios;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> addtestcase;

  AppState({
    this.user,
    this.designation,
    this.scenarios = const [],
    this.assignments = const [],
    this.comments = const [],
    this.addtestcase = const [],
  });

  AppState copy(
          {User? user,
          String? designation,
          List<Map<String, dynamic>>? scenarios,
          List<Map<String, dynamic>>? assignments,
          List<Map<String, dynamic>>? addtestcase,
          List<Map<String, dynamic>>? comments}) =>
      AppState(
          user: user,
          designation: designation ?? this.designation,
          scenarios: scenarios ?? this.scenarios,
          assignments: assignments ?? this.assignments,
          comments: comments ?? this.comments,
          addtestcase: addtestcase ?? this.addtestcase);

  static AppState initialState() => AppState(
        user: null,
        designation: null,
        scenarios: [],
        assignments: [],
        comments: [],
        addtestcase: [],
      );
}
