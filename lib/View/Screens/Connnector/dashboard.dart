import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/Actions/addcomment.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchaction.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchsenario.dart';
import 'package:scenario_management_tool_for_testers/Resources/route.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';
import 'package:scenario_management_tool_for_testers/Services/sign_out.dart';
import 'package:scenario_management_tool_for_testers/viewmodel/dashviewmodel.dart';

/// This class defines the main DashboardPage in the application, displaying user-specific
/// data including scenarios, assignments, and test cases. The page provides search, view,
/// add, and delete functionalities for scenarios and assignments.
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// StoreConnector widget connects to the Redux store to access and update app state.
    return StoreConnector<AppState, ViewModel>(
      onInit: (store) {
        store.dispatch(FetchAssignmentsAction());
        store.dispatch(FetchScenariosAction());
        store.dispatch(FetchCommentsAction());
      },
      vm: () => Factory(this),
      builder: (context, vm) {
        final TextEditingController searchController = TextEditingController();

        return Scaffold(
          appBar: AppBar(
            title: Text("Welcome, ${vm.designation ?? 'User'}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            backgroundColor: vm.roleColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  /// Calls the search function with the current input in the search bar.
                  vm.searchScenarios(searchController.text);
                },
              ),
            ],
          ),
          drawer: Drawer(
            ///for logged in user information anf logout.
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text("User: ${vm.designation ?? 'User'}"),
                  accountEmail: Text(FirebaseAuth.instance.currentUser?.email ??
                      'Not logged in'),
                  currentAccountPicture:
                      const CircleAvatar(child: Icon(Icons.person)),
                  decoration: BoxDecoration(color: vm.roleColor),
                  otherAccountsPictures: [
                    IconButton(
                        icon: const Icon(Icons.exit_to_app),
                        onPressed: () {
                          signOut(context);
                        }),
                  ],
                ),
              ],
            ),
          ),
          body: vm.scenarios.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: "Search by Project Name",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (query) {
                          vm.searchScenarios(query);
                        },
                      ),
                    ),
                    // List of scenarios displayed in cards.
                    Expanded(
                        child: ListView.builder(
                      itemCount: vm.scenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = vm.scenarios[index];
                        final testCases = scenario['testCases'] ?? [];

                        return Card(
                          child: ExpansionTile(
                            title: Text(
                                scenario['projectName'] ?? 'Unnamed Scenario'),
                            subtitle: Text(scenario['shortDescription'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.scenariodetail,
                                      arguments: {
                                        'scenario': scenario,
                                        'roleColor': vm.roleColor,
                                        'designation': vm.designation ?? '',
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.remove_red_eye),
                                ),
                                Checkbox(
                                  value: scenario['checkboxState'] ?? false,
                                  onChanged: vm.isCheckboxEnabled
                                      ? (bool? value) {
                                          vm.updateScenario(scenario['docId'],
                                              {'checkboxState': value});
                                        }
                                      : null,
                                ),
                                if (vm.designation == 'Tester Lead')
                                  IconButton(
                                    onPressed: () {
                                      _deleteScenarioDialog(
                                          context, scenario['docId']);
                                    },
                                    icon: const Icon(Icons.delete),
                                  ),
                              ],
                            ),
                            // List of test cases for each scenario.
                            children: [
                              ...testCases.map<Widget>((testCase) {
                                return ListTile(
                                  title: Text(
                                      testCase['name'] ?? 'Unnamed Test Case'),
                                  subtitle: Text(testCase['tags'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_red_eye),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, Routes.testdetail,
                                          arguments: {
                                            'testCase': testCase,
                                            'roleColor': vm.roleColor,
                                          });
                                    },
                                  ),
                                );
                              }).toList(),
                              ListTile(
                                leading: const Icon(Icons.add),
                                title: const Text("Add Test Case"),
                                onTap: () {
                                  _addTestCaseDialog(
                                      context, scenario['docId'], vm);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    )),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addScenarioDialog(context, vm),
            child: const Icon(Icons.add),
            tooltip: 'Add Scenario',
          ),
        );
      },
    );
  }

  /// Displays a custom input dialog with a list of input fields, a title, and
  /// an action button to submit the input.
  Future<void> showInputDialog({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required Function() onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: onSubmit,
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  /// Opens a dialog to add a new test case, allowing the user to specify
  /// details like name, description, and tags.
  void _addTestCaseDialog(
      BuildContext context, String scenarioId, ViewModel vm) {
    final nameController = TextEditingController();
    final bugIdController = TextEditingController();
    final commentsController = TextEditingController();
    final descriptionController = TextEditingController();
    final attachmentController = TextEditingController();
    String? selectedTag;

    final tagsOptions = vm.designation == 'Junior Tester'
        ? ["Passed", "Failed", "In Review"]
        : ["Passed", "Failed", "In Review", "Completed"];

    showInputDialog(
      context: context,
      title: "Add Test Case",
      children: [
        TextFormField(
            controller: bugIdController,
            decoration: const InputDecoration(labelText: "Bug ID")),
        TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Test Case Name")),
        DropdownButtonFormField<String>(
          value: selectedTag,
          decoration: const InputDecoration(labelText: "Tags"),
          items: tagsOptions
              .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
              .toList(),
          onChanged: (value) => selectedTag = value,
        ),
        TextFormField(
            controller: commentsController,
            decoration: const InputDecoration(labelText: "Comments")),
        TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: "Description")),
        TextFormField(
            controller: attachmentController,
            decoration: const InputDecoration(labelText: "Attachment")),
      ],
      onSubmit: () {
        if (bugIdController.text.isNotEmpty &&
            nameController.text.isNotEmpty &&
            selectedTag != null) {
          final testCase = {
            'name': nameController.text,
            'bugId': bugIdController.text,
            'tags': selectedTag,
            'comments': commentsController.text,
            'description': descriptionController.text,
            'attachment': attachmentController.text,
            'scenarioId': scenarioId,
            'createdAt': FieldValue.serverTimestamp(),
          };
          FirebaseFirestore.instance
              .collection('scenarios')
              .doc(scenarioId)
              .collection('testCases')
              .add(testCase)
              .then((_) {
            Navigator.of(context).pop();
            vm.fetchScenarios();
          }).catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to add test case: $e")));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill in all fields")));
        }
      },
    );
  }

  ///opens a dialog to delete a scenario only by lead tester
  void _deleteScenarioDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Scenario'),
          content: const Text('Are you sure you want to delete this scenario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('scenarios')
                      .doc(docId)
                      .delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Scenario deleted successfully')),
                  );
                  StoreProvider.dispatch<AppState>(
                      context, FetchScenariosAction());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to delete the scenario')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  ///opena a dialog to add scenario . here lead tester and developer has acces to assign user through drop down.
  ///junior tester can add scenario and view it.
  void _addScenarioDialog(BuildContext context, ViewModel vm) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController shortDescriptionController =
        TextEditingController();
    final TextEditingController projectNameController = TextEditingController();
    final TextEditingController projectIdController = TextEditingController();

    String? selectedEmail; // Variable to store selected email

    // Fetching user emails from Firestore
    Future<List<String>> fetchUserEmails() async {
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').get();
        return snapshot.docs.map((doc) => doc['email'] as String).toList();
      } catch (e) {
        print("Error fetching user emails: $e");
        return []; // Return empty list in case of error
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Scenario"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<List<String>>(
                future: fetchUserEmails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return const Text("Error loading emails.");
                  }

                  final List<String> userEmails = snapshot.data ?? [];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "Scenario Name"),
                      ),
                      TextField(
                        controller: shortDescriptionController,
                        decoration: const InputDecoration(
                            labelText: "Short Description"),
                      ),
                      TextField(
                        controller: projectNameController,
                        decoration:
                            const InputDecoration(labelText: "Project Name"),
                      ),
                      TextField(
                        controller: projectIdController,
                        decoration:
                            const InputDecoration(labelText: "Project ID"),
                      ),
                      if (vm.designation == 'Junior Tester')
                        Text("Dropdown is accessible only for Lead Tester"),
                      // Only show the dropdown for Lead Tester
                      if (vm.designation != 'Junior Tester')
                        DropdownButton<String>(
                          hint: const Text("Select User Email"),
                          value: selectedEmail,
                          isExpanded: true,
                          onChanged: (newValue) {
                            setState(() {
                              selectedEmail = newValue;
                            });
                          },
                          items: userEmails.map((email) {
                            return DropdownMenuItem<String>(
                              value: email,
                              child: Text(email),
                            );
                          }).toList(),
                        ),
                      // If not Lead Tester, show a simple Text widget
                    ],
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final String name = nameController.text;
                final String shortDescription = shortDescriptionController.text;
                final String projectName = projectNameController.text;
                final String projectId = projectIdController.text;

                // Ensure an email is selected
                if (name.isNotEmpty &&
                    shortDescription.isNotEmpty &&
                    projectName.isNotEmpty &&
                    projectId.isNotEmpty &&
                    selectedEmail != null) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    final createdByEmail = user?.email ?? 'Unknown';

                    await FirebaseFirestore.instance
                        .collection('scenarios')
                        .add({
                      'name': name,
                      'shortDescription': shortDescription,
                      'projectName': projectName,
                      'projectId': projectId,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdByEmail':
                          createdByEmail, // Storing creator's email
                      'assignedToEmail':
                          selectedEmail, // Storing selected email
                    });

                    Navigator.of(context).pop();
                    vm.fetchScenarios(); // Dispatch fetch scenarios action
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to add scenario")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: const Text("Add Scenario"),
            ),
          ],
        );
      },
    );
  }
}
