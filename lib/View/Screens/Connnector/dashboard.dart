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
import 'package:fluttertoast/fluttertoast.dart';

/// This class defines the main DashboardPage in the application, displaying user-specific
/// data including scenarios, assignments, and test cases. The page provides search, view,
/// add, and delete functionalities for scenarios and assignments.
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ViewModel>(
      onInit: (store) {
        store.dispatch(FetchAssignmentsAction());
        store.dispatch(FetchScenariosAction());
        store.dispatch(FetchCommentsAction());
      },
      vm: () => Factory(this),
      builder: (context, vm) {
        String? selectedFilter;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              "Welcome, ${vm.designation ?? 'User'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            backgroundColor: vm.roleColor,
            actions: [
              IconButton(
                onPressed: vm.clearFilters,
                icon: Icon(Icons.clear_all),
              ),
              if (selectedFilter != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    selectedFilter = null;
                    vm.clearFilters();
                  },
                ),
            ],
          ),
          drawer: Drawer(
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
                      onPressed: () => signOut(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Dropdown for filtering
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return DropdownButtonFormField<String>(
                        value: selectedFilter,
                        decoration: const InputDecoration(
                          labelText: "Filter by Project Type",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'OBA', child: Text('OBA')),
                          DropdownMenuItem(
                              value: 'HR Portal', child: Text('HR Portal')),
                          DropdownMenuItem(value: 'All', child: Text('All')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value;
                            if (value == 'All') {
                              selectedFilter =
                                  null; // Clear the selected filter
                              vm.clearFilters(); // Show all scenarios
                            } else {
                              vm.filterScenarios(
                                  value!); // Apply specific filter
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              // Show "Not Found" message if no scenarios match the filter
              if (vm.filteredScenarios.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No scenarios found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              else
                // List of filtered scenarios
                Expanded(
                  child: ListView.builder(
                      itemCount: vm.filteredScenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = vm.filteredScenarios[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              scenario['projectName'] ?? 'Unnamed Scenario',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            onTap: () {
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
                            subtitle: Text(scenario['shortDescription'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      _addTestCaseDialog(
                                          context, scenario['docId'], vm);
                                    },
                                    child: Text("Add Test Case")),
                                IconButton(
                                    onPressed: () {
                                      _deleteScenarioDialog(
                                          context, scenario['docId']);
                                    },
                                    icon: Icon(Icons.delete))
                              ],
                            ),
                          ),
                        );
                      }),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onPressed: () => _addScenarioDialog(context, vm),
            child: const Icon(Icons.add),
            tooltip: 'Add Scenario',
          ),
        );
      },
    );
  }
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

void _addTestCaseDialog(BuildContext context, String scenarioId, ViewModel vm) {
  final nameController = TextEditingController();
  final bugIdController = TextEditingController();
  final commentsController = TextEditingController();
  final descriptionController = TextEditingController();
  final String createdBy =
      FirebaseAuth.instance.currentUser?.email ?? 'unknown_user';
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
          decoration: const InputDecoration(labelText: "Test  Case ID")),
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
          'scenarioId': scenarioId,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': createdBy,
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
        Fluttertoast.showToast(
          msg: "Please Fill all details!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0,
        );
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
                Fluttertoast.showToast(
                  msg: "Scenario added successfully!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
                StoreProvider.dispatch<AppState>(
                    context, FetchScenariosAction());
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Failed to delete Scenario!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  fontSize: 16.0,
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

  String? selectedEmail;
  String? selectedProjectName;

  Future<List<String>> fetchUserEmails() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return snapshot.docs.map((doc) => doc['email'] as String).toList();
    } catch (e) {
      print("Error fetching user emails: $e");
      return [];
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
                  return const Center(child: CircularProgressIndicator());
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
                      decoration:
                          const InputDecoration(labelText: "Short Description"),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedProjectName,
                      items: const [
                        DropdownMenuItem(
                            value: 'HR Portal', child: Text('HR Portal')),
                        DropdownMenuItem(value: 'OBA', child: Text('OBA')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedProjectName = value;
                        });
                      },
                      hint: const Text("Select Project Name"),
                    ),
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

              if (name.isNotEmpty &&
                  shortDescription.isNotEmpty &&
                  selectedProjectName != null &&
                  (vm.designation == 'Junior Tester' ||
                      selectedEmail != null)) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final createdByEmail = user?.email ?? 'Unknown';
                  final assignedEmail = vm.designation == 'Junior Tester'
                      ? createdByEmail
                      : selectedEmail;

                  await FirebaseFirestore.instance.collection('scenarios').add({
                    'name': name,
                    'shortDescription': shortDescription,
                    'projectName': selectedProjectName,
                    'createdAt': FieldValue.serverTimestamp(),
                    'createdByEmail': createdByEmail,
                    'assignedToEmail': assignedEmail,
                  });
                  Navigator.of(context).pop();
                  vm.fetchScenarios();
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: "Failed to Add Scenario",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
              } else {
                Fluttertoast.showToast(
                  msg: "Fill in all required fields",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      );
    },
  );
}
