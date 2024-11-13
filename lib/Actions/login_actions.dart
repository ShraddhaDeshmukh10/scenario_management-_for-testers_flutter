import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class LoginAction extends ReduxAction<AppState> {
  final String email;
  final String password;

  LoginAction({required this.email, required this.password});

  @override
  Future<AppState> reduce() async {
    User? user = await authenticateUser(email, password);

    // Fetch the designation from Firestore after user login
    String? designation;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      designation = userDoc['role'] ??
          'Junior Tester'; // Default to 'Junior Tester' if not found
    }

    // Save the user's email and designation to Hive
    var userBox = await Hive.openBox('userBox');
    if (user != null) {
      userBox.put('email', user.email);
      userBox.put('designation', designation ?? 'Junior Tester');
    }

    // Return the updated state with the user and designation
    return state.copy(user: user, designation: designation ?? 'Junior Tester');
  }

  Future<User?> authenticateUser(String email, String password) async {
    try {
      // Firebase authentication process
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Return the authenticated user
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }
}
