import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/Actions/login_actions.dart';
import 'package:scenario_management_tool_for_testers/Resources/route.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';
import 'package:scenario_management_tool_for_testers/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Class used for login.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool passwordVisible = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLoginInfo();
  }

  // Save login info to SharedPreferences
  Future<void> _saveLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _emailController.text);
    await prefs.setString('password', _passwordController.text);
  }

  // Load login info from SharedPreferences
  Future<void> _loadLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    // If credentials are found, automatically redirect to the dashboard
    if (username != null && password != null) {
      setState(() {
        _emailController.text = username;
        _passwordController.text = password;
      });

      // Assuming you have a way to validate the login (e.g., check credentials with a backend)
      _autoLogin(username, password);
    }
  }

  // Automatically log in the user if valid credentials are found
  Future<void> _autoLogin(String email, String password) async {
    // Simulate a login validation (In reality, you'd validate with an API or backend)
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1)); // Simulate network call

    // Dispatch login action and navigate to dashboard
    store.dispatch(
      LoginAction(
        email: email,
        password: password,
      ),
    );

    setState(() {
      isLoading = false;
    });
    Navigator.pushNamedAndRemoveUntil(
        context, Routes.dashboard, (route) => false);
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simulate a network call
    await Future.delayed(const Duration(seconds: 2));

    // Save login information
    await _saveLoginInfo();

    // Dispatch login action and navigate after loading ends
    store.dispatch(
      LoginAction(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );

    setState(() {
      isLoading = false;
    });
    Navigator.pushReplacementNamed(context, Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        // Redirect to dashboard if user is already logged in
        if (state.user != null) {
          Future.delayed(Duration.zero, () {
            // Navigator.pushReplacementNamed(context, Routes.dashboard);
            Navigator.pushNamedAndRemoveUntil(
                context, Routes.dashboard, (route) => false);
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome, log in to your account",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : _login, // Disable button when loading
                      child: const Text('Login'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.register),
                      child: const Text(
                        "Don't have an account? Register here",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
