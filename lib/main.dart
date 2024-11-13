import 'package:async_redux/async_redux.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scenario_management_tool_for_testers/Resources/route.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/Connnector/dashboard.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/assignedlist.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/commentlist.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/login.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/registerscreen.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/scenariodetail.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/splash.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/testcaselist.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

final store = Store<AppState>(initialState: AppState.initialState());
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Hive.openBox('userBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: Routes.splash,
          onGenerateRoute: (settings) {
            final args = (settings.arguments ?? <String, dynamic>{})
                as Map<String, dynamic>;
            switch (settings.name) {
              case Routes.splash:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case Routes.login:
                return MaterialPageRoute(builder: (_) => const LoginPage());
              case Routes.register:
                return MaterialPageRoute(builder: (_) => const RegisterPage());
              case Routes.dashboard:
                return MaterialPageRoute(builder: (_) => const DashboardPage());
              case Routes.assignedlist:
                return MaterialPageRoute(
                  builder: (_) => AssignedUsersPage(
                    assignments: args['assignments'] ?? [],
                    designation: args['designation'] ?? '',
                    roleColor: args['roleColor'] ?? Colors.grey,
                  ),
                );
              case Routes.commentlist:
                return MaterialPageRoute(
                  builder: (_) => CommentListPage(
                    comments: args['comments'] ?? [],
                    designation: args['designation'] ?? '',
                    roleColor: args['roleColor'] ?? Colors.grey,
                  ),
                );
              case Routes.testcaselist:
                return MaterialPageRoute(
                  builder: (_) => TestCaseListPage(
                    designation: args['designation'] ?? '',
                    roleColor: args['roleColor'] ?? Colors.grey,
                  ),
                );
              case Routes.scenariodetail:
                return MaterialPageRoute(
                  builder: (_) => ScenarioDetailPage(
                    scenario: args['scenario'],
                    roleColor: args['roleColor'],
                  ),
                );
              default:
                return MaterialPageRoute(builder: (_) => const LoginPage());
            }
          }),
    );
  }
}
