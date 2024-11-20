import 'package:get_it/get_it.dart';
import 'package:scenario_management_tool_for_testers/Services/data_services.dart';
import 'package:scenario_management_tool_for_testers/Services/image_services.dart';

GetIt locator = GetIt.instance;

void setupServiceLocator() {
  try {
    locator.registerLazySingleton<DataService>(() => Services());
  } catch (e) {
    print("Error registering service locator: $e");
  }
}
