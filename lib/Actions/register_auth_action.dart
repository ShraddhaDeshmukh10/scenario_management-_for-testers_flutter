import 'package:async_redux/async_redux.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class RegisterAction extends ReduxAction<AppState> {
  final String email;
  final String password;
  final String designation;

  RegisterAction(
      {required this.email, required this.password, required this.designation});

  @override
  Future<AppState?> reduce() async {
    try {
      // Step 1: Create user in Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Step 2: Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'role': designation, // Save the correct designation to Firestore
      });

      // Step 3: Save user data to Hive
      var userBox = await Hive.openBox('userBox');
      userBox.put('email', userCredential.user?.email);
      userBox.put('designation', designation); // Save designation to Hive

      // Step 4: Update state with correct user data (including designation)
      return state.copy(
        user: userCredential.user,
        designation:
            designation, // Make sure the correct designation is stored in state
      );
    } catch (e) {
      throw UserException("Failed to register: ${e.toString()}");
    }
  }
}
