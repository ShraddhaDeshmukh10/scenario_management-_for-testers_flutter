// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:scenario_management_tool_for_testers/Actions/login_actions.dart';
// import 'package:scenario_management_tool_for_testers/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// Future<void> validateStoredCredentials() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? email = prefs.getString('username');
//     String? password = prefs.getString('password');

//     if (email != null && password != null) {
//         User? user = await authenticateUser(email, password);
//         if (user == null) {
//             await prefs.clear(); // Clear invalid credentials
//         } else {
//             // Automatically log the user in
//             store.dispatch(LoginAction(email: email, password: password));
//         }
//     }
// }
