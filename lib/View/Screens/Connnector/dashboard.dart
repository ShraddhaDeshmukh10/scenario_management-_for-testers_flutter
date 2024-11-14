import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/Actions/addcomment.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchaction.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchsenario.dart';
import 'package:scenario_management_tool_for_testers/Resources/route.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/scenariodetail.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';
import 'package:scenario_management_tool_for_testers/screens/sign_out.dart';
import 'package:scenario_management_tool_for_testers/viewmodel/dashviewmodel.dart';

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
                  vm.searchScenarios(searchController.text);
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
                        onPressed: () {
                          signOut(context);
                        }),
                  ],
                ),
                ListTile(
                  leading: IconButton(
                      onPressed: () => _addAssignmentDialog(context, vm),
                      icon: const Icon(Icons.add)),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.assignedlist,
                          arguments: {
                            'assignments': vm.assignments,
                            'designation': vm.designation,
                            'roleColor': vm.roleColor,
                          });
                    },
                    icon: const Icon(Icons.remove_red_eye),
                  ),
                  title: const Text("Assignment Management"),
                  onTap: () => _addAssignmentDialog(context, vm),
                ),
                const Divider(),
                ListTile(
                  leading: IconButton(
                      onPressed: () {
                        _addCommentDialog(context, vm);
                      },
                      icon: Icon(Icons.add)),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.commentlist,
                          arguments: {
                            'comments': vm.comments,
                            'designation': vm.designation,
                            'roleColor': vm.roleColor,
                          });
                    },
                    icon: Icon(Icons.remove_red_eye),
                  ),
                  title: const Text("Comment Form"),
                ),
                const Divider(),
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
                    Expanded(
                        child: ListView.builder(
                      itemCount: vm.scenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = vm.scenarios[index];
                        final testCases = scenario['testCases'] ?? [];

                        return Card(
                          child: ExpansionTile(
                            title: Text(scenario['name'] ?? 'Unnamed Scenario'),
                            subtitle: Text(scenario['shortDescription'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ScenarioDetailPage(
                                          scenario: scenario,
                                          roleColor: vm.roleColor,
                                          designation: vm.designation ?? '',
                                        ),
                                      ),
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

  void _addTestCaseDialog(
      BuildContext context, String scenarioId, ViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final bugIdController = TextEditingController();
    final commentsController = TextEditingController();
    final descriptionController = TextEditingController();
    final attachmentController = TextEditingController();
    final projectController = TextEditingController();
    final shortDescriptionController = TextEditingController();
    String? selectedTag;

    final tagsOptions = vm.designation == 'Junior Tester'
        ? ["Passed", "Failed", "In Review"]
        : ["Passed", "Failed", "In Review", "Completed"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Test Case"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: projectController,
                    decoration:
                        const InputDecoration(labelText: "Project Name"),
                  ),
                  TextFormField(
                    controller: bugIdController,
                    decoration: const InputDecoration(labelText: "Bug ID"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a Bug ID";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: shortDescriptionController,
                    decoration:
                        const InputDecoration(labelText: "Short Description"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a short description";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Test Case Name"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a test case name";
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedTag,
                    decoration: const InputDecoration(labelText: "Tags"),
                    items: tagsOptions.map((tag) {
                      return DropdownMenuItem(value: tag, child: Text(tag));
                    }).toList(),
                    onChanged: (value) => selectedTag = value,
                    validator: (value) {
                      if (value == null) {
                        return "Please select a tag";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: commentsController,
                    decoration: const InputDecoration(labelText: "Comments"),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  TextFormField(
                    controller: attachmentController,
                    decoration: const InputDecoration(labelText: "Attachment"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  final testCase = {
                    'name': nameController.text,
                    'bugId': bugIdController.text,
                    'tags': selectedTag,
                    'comments': commentsController.text,
                    'description': descriptionController.text,
                    'attachment': attachmentController.text,
                    'projectName': projectController.text,
                    'shortDescription': shortDescriptionController.text,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Test case added successfully")),
                    );
                    vm.fetchScenarios();
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add test case: $e")),
                    );
                  });
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addCommentDialog(BuildContext context, ViewModel vm) {
    final TextEditingController contentController = TextEditingController();
    final TextEditingController attachmentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Comment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Content"),
              ),
              TextField(
                controller: attachmentController,
                decoration:
                    const InputDecoration(labelText: "Attachment (Optional)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String content = contentController.text;
                String attachment = attachmentController.text;

                if (content.isNotEmpty) {
                  vm.addComment(
                      content, attachment); // This now calls the correct action
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Comment added successfully")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Content cannot be empty")),
                  );
                }
              },
              child: const Text("Add Comment"),
            ),
          ],
        );
      },
    );
  }

  void _addAssignmentDialog(BuildContext context, ViewModel vm) {
    final TextEditingController bugIdController = TextEditingController();
    final TextEditingController assignedUserController =
        TextEditingController();
    final String assignedBy =
        FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Assignment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bugIdController,
                decoration: const InputDecoration(labelText: "Bug ID"),
              ),
              TextField(
                controller: assignedUserController,
                decoration: const InputDecoration(labelText: "Assigned User"),
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Assigned By"),
                controller: TextEditingController(text: assignedBy),
                enabled: false, // Make Assigned By read-only
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final String bugId = bugIdController.text;
                final String assignedUser = assignedUserController.text;

                if (bugId.isNotEmpty && assignedUser.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('assignments')
                        .add({
                      'bugId': bugId,
                      'assignedUser': assignedUser,
                      'assignedBy': assignedBy,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    vm.fetchAssignments(); // Dispatch fetch action
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Failed to add assignment")));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please fill in all fields")));
                }
              },
              child: const Text("Add Assignment"),
            ),
          ],
        );
      },
    );
  }

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
}
