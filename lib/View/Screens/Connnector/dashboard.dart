import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/Actions/addcomment.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchaction.dart';
import 'package:scenario_management_tool_for_testers/Actions/fetchsenario.dart';
import 'package:scenario_management_tool_for_testers/Resources/route.dart';
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
                ListTile(
                  leading: IconButton(
                      onPressed: () {
                        _addTestCase(context, vm);
                      },
                      icon: Icon(Icons.add)),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.testcaselist,
                          arguments: {
                            'designation': vm.designation,
                            'roleColor': vm.roleColor,
                          });
                    },
                    icon: Icon(Icons.remove_red_eye),
                  ),
                  title: const Text("Test Case Form"),
                ),
                Divider()
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
                          return Card(
                            child: ListTile(
                              title:
                                  Text(scenario['name'] ?? 'Unnamed Scenario'),
                              subtitle:
                                  Text(scenario['shortDescription'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        Routes.scenariodetail,
                                        arguments: {
                                          'scenario': scenario,
                                          'roleColor': vm.roleColor,
                                        },
                                      );

                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder:
                                      //         (context) => ///////////////////
                                      //             ScenarioDetailPage(
                                      //       scenario: scenario,
                                      //       roleColor: vm.roleColor,
                                      //     ),
                                      //   ),
                                      // );
                                    },
                                    icon:
                                        const Icon(Icons.remove_red_eye_sharp),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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

  void _addTestCase(BuildContext context, ViewModel vm) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController bugIdController = TextEditingController();
    final TextEditingController scenarioController = TextEditingController();
    final TextEditingController commentsController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController attachmentController = TextEditingController();
    final TextEditingController projectController = TextEditingController();
    final TextEditingController shortDescriptionController =
        TextEditingController();

    String? _selectedTag; // Store the selected tag

    // List of options for tags, filter out "Completed" for Junior Testers
    final List<String> tagsOptions = vm.designation == 'Junior Tester'
        ? ["Passed", "Failed", "In Review"]
        : ["Passed", "Failed", "In Review", "Completed"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Test Case Form"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: projectController,
                    decoration:
                        const InputDecoration(labelText: "Project Name")),
                TextField(
                    controller: bugIdController,
                    decoration: const InputDecoration(labelText: "Bug ID")),
                TextField(
                    controller: shortDescriptionController,
                    decoration:
                        const InputDecoration(labelText: "Short Description")),
                TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Test Case Name")),
                DropdownButtonFormField<String>(
                  value: _selectedTag ??
                      tagsOptions
                          .first, // Ensure there is a valid initial value
                  decoration: const InputDecoration(labelText: "Tags"),
                  items: tagsOptions.map((String tag) {
                    return DropdownMenuItem<String>(
                      value: tag,
                      child: Text(tag),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    // Update the selected tag when the user selects a new option
                    _selectedTag = newValue;
                  },
                ),
                TextField(
                    controller: scenarioController,
                    decoration: const InputDecoration(labelText: "Scenario")),
                TextField(
                    controller: commentsController,
                    decoration: const InputDecoration(labelText: "Comments")),
                TextField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: "Description")),
                TextField(
                    controller: attachmentController,
                    decoration: const InputDecoration(labelText: "Attachment")),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String project = projectController.text;
                String id = bugIdController.text;
                String shortDescription = shortDescriptionController.text;
                String name = nameController.text;
                String scenario = scenarioController.text;
                String comments = commentsController.text;
                String description = descriptionController.text;
                String attachment = attachmentController.text;

                if (project.isNotEmpty &&
                    id.isNotEmpty &&
                    shortDescription.isNotEmpty &&
                    name.isNotEmpty &&
                    scenario.isNotEmpty &&
                    comments.isNotEmpty &&
                    description.isNotEmpty &&
                    attachment.isNotEmpty &&
                    _selectedTag != null) {
                  try {
                    // Pass the selected tag here
                    vm.addtestcase(
                      project,
                      id,
                      shortDescription,
                      name,
                      scenario,
                      comments,
                      description,
                      attachment,
                      _selectedTag,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Test case added successfully")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add test case: $e")));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill in all fields")));
                }
              },
              child: const Text("Add Test Case"),
            )
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

  void _addScenarioDialog(BuildContext context, ViewModel vm) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController shortDescriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Scenario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Scenario Name"),
              ),
              TextField(
                controller: shortDescriptionController,
                decoration:
                    const InputDecoration(labelText: "Short Description"),
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
                final String name = nameController.text;
                final String shortDescription = shortDescriptionController.text;

                if (name.isNotEmpty && shortDescription.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('scenarios')
                        .add({
                      'name': name,
                      'shortDescription': shortDescription,
                      'createdAt': FieldValue.serverTimestamp(),
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
