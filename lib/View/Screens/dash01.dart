import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/Resources/route.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/assignedlist.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/commentlist.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/scenariodetail.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _designation;
  String? _userEmail;
  List<Map<String, dynamic>> _scenarios = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _allScenarios = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchScenarios();
    _fetchAssignments();
  }

  Future<void> _fetchUserData() async {
    var userBox = await Hive.openBox('userBox');
    String? savedRole = userBox.get('role');
    String? savedEmail = userBox.get('email');

    if (savedRole == null && _auth.currentUser != null) {
      var userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        savedRole = userDoc['role'] ?? 'Junior Tester';
        userBox.put('role', savedRole);
      } else {
        savedRole = 'unknown';
      }
    }

    if (mounted) {
      setState(() {
        _designation = savedRole;
        _userEmail = savedEmail ?? _auth.currentUser?.email;
      });
    }
  }

  Future<void> _fetchScenarios() async {
    var scenariosSnapshot = await _firestore.collection('scenarios').get();

    if (mounted) {
      setState(() {
        _allScenarios = scenariosSnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'docId': doc.id, // To use for updating checkbox state
                })
            .toList();
        _scenarios = List.from(_allScenarios);
      });
    }
  }

  Future<void> _fetchAssignments() async {
    var assignmentsSnapshot = await _firestore.collection('assignments').get();

    if (mounted) {
      setState(() {
        _assignments = assignmentsSnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'docId': doc.id, // To use for updating assignments
                })
            .toList();
      });
    }
  }

  // Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    await _auth.signOut();
    Hive.box('userBox').clear();
    SystemNavigator.pop();
  }

  void _addAssignmentDialog() {
    final TextEditingController bugIdController = TextEditingController();
    final TextEditingController assignedUserController =
        TextEditingController();
    final TextEditingController assignedByController =
        TextEditingController(text: _userEmail ?? '');

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
                controller: assignedByController,
                decoration: const InputDecoration(labelText: "Assigned By"),
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
                String bugId = bugIdController.text;
                String assignedUser = assignedUserController.text;
                String assignedBy = assignedByController.text;

                if (bugId.isNotEmpty && assignedUser.isNotEmpty) {
                  try {
                    await _firestore.collection('assignments').add({
                      'bugId': bugId,
                      'assignedUser': assignedUser,
                      'assignedBy': assignedBy,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    _fetchAssignments(); // Refresh assignments
                  } catch (e) {
                    print("Failed to add assignment: $e");
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

  void _addTestCase() {
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
    final List<String> tagsOptions = _designation == 'Junior Tester'
        ? [
            "Passed",
            "Failed",
            "In Review",
          ]
        : [
            "Passed",
            "Failed",
            "In Review",
            "Completed",
          ];

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
                  decoration: const InputDecoration(
                      labelText: "Project Name"), // Added project field
                ),
                TextField(
                  controller: bugIdController,
                  decoration: const InputDecoration(labelText: "Bug ID"),
                ),
                TextField(
                  controller: shortDescriptionController,
                  decoration: const InputDecoration(
                      labelText:
                          "Short Description"), // Added short description field
                ),
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: "Test Case Name"),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedTag,
                  decoration: const InputDecoration(labelText: "Tags"),
                  items: tagsOptions.map((String tag) {
                    return DropdownMenuItem<String>(
                      value: tag,
                      child: Text(tag),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTag = newValue;
                    });
                  },
                ),
                TextField(
                  controller: scenarioController,
                  decoration: const InputDecoration(labelText: "Scenario"),
                ),
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(labelText: "Comments"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: attachmentController,
                  decoration: const InputDecoration(labelText: "Attachment"),
                ),
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
                    await _firestore.collection('testcases').add({
                      'project': project,
                      'id': id,
                      'shortDescription': shortDescription,
                      'testcasename': name,
                      'scenario': scenario,
                      'comments': comments,
                      'description': description,
                      'attachments': attachment, // Save the attachment
                      'tags': _selectedTag, // Save the selected tag
                      'assignedUsers': [_userEmail],
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': _userEmail,
                    });
                    Navigator.of(context).pop();
                    _fetchScenarios(); // Refresh scenarios
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add test case: $e")));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please fill in all fields")));
                }
              },
              child: const Text("Add Test Case"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchComments() async {
    var commentsSnapshot = await _firestore.collection('comments').get();

    if (mounted) {
      setState(() {
        _comments = commentsSnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'docId': doc.id, // To use for editing or deleting comments
                })
            .toList();
      });
    }
  }

  void _addCommentDialog() {
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
                  try {
                    // Add the comment to Firestore
                    await _firestore.collection('comments').add({
                      'content': content,
                      'attachment': attachment,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy':
                          _userEmail, // Optional: add the creator's email
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Comment added successfully")),
                    );
                  } catch (e) {
                    print("Failed to add comment: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to add comment")),
                    );
                  }
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

  // Add a new scenario dialog
  void _addScenarioDialog() {
    final TextEditingController scenarioNameController =
        TextEditingController();
    final TextEditingController idController = TextEditingController();
    final TextEditingController projectController = TextEditingController();
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
                  controller: scenarioNameController,
                  decoration:
                      const InputDecoration(labelText: "Scenario Name")),
              TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: "ID")),
              TextField(
                  controller: projectController,
                  decoration: const InputDecoration(labelText: "Project")),
              TextField(
                  controller: shortDescriptionController,
                  decoration:
                      const InputDecoration(labelText: "Short Description")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String name = scenarioNameController.text;
                String project = projectController.text;
                String id = idController.text;
                String shortDescription = shortDescriptionController.text;

                if (name.isNotEmpty &&
                    project.isNotEmpty &&
                    id.isNotEmpty &&
                    shortDescription.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('scenarios')
                        .add({
                      'name': name,
                      'project': project,
                      'id': id,
                      'shortDescription': shortDescription,
                      'assignedUsers': [_userEmail],
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': _userEmail,
                    });
                    Navigator.of(context).pop();
                    _fetchScenarios(); // Refresh scenarios
                  } catch (e) {
                    print("Failed to add scenario: $e");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Failed to add scenario due to permission error")));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please fill in all fields")));
                }
              },
              child: const Text("Add Scenario"),
            ),
          ],
        );
      },
    );
  }

  // Edit scenario dialog
  void _editScenarioDialog(Map<String, dynamic> scenario) {
    final TextEditingController scenarioNameController =
        TextEditingController(text: scenario['name']);
    final TextEditingController idController =
        TextEditingController(text: scenario['id']);
    final TextEditingController projectController =
        TextEditingController(text: scenario['project']);
    final TextEditingController shortDescriptionController =
        TextEditingController(text: scenario['shortDescription']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Scenario"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: scenarioNameController,
                  decoration:
                      const InputDecoration(labelText: "Scenario Name")),
              TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: "ID")),
              TextField(
                  controller: projectController,
                  decoration: const InputDecoration(labelText: "Project")),
              TextField(
                  controller: shortDescriptionController,
                  decoration:
                      const InputDecoration(labelText: "Short Description")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String name = scenarioNameController.text;
                String project = projectController.text;
                String id = idController.text;
                String shortDescription = shortDescriptionController.text;

                if (name.isNotEmpty &&
                    project.isNotEmpty &&
                    id.isNotEmpty &&
                    shortDescription.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('scenarios')
                        .doc(scenario['id'])
                        .update({
                      'name': name,
                      'project': project,
                      'id': id,
                      'shortDescription': shortDescription,
                      'assignedUsers': [
                        scenario['assignedUsers'] ?? _userEmail
                      ],
                    });
                    Navigator.of(context).pop();
                    _fetchScenarios(); // Refresh scenarios
                  } catch (e) {
                    print("Failed to update scenario: $e");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Failed to update scenario due to permission error")));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please fill in all fields")));
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  // Get color based on role
  Color getRoleColor() {
    print("Getting color for designation: $_designation");

    if (_designation == 'Junior Tester') {
      return Colors.red;
    } else if (_designation == 'Tester Lead') {
      return Colors.green;
    } else if (_designation == 'Developer') {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  // Update checkbox state in Firestore
  Future<void> _updateCheckboxState(String docId, bool value) async {
    try {
      await _firestore.collection('scenarios').doc(docId).update({
        'checkboxState': value,
      });
    } catch (e) {
      print("Failed to update checkbox state: $e");
    }
  }

  // Enable checkbox for specific roles
  bool _isCheckboxEnabled() => _designation == 'Tester Lead';

  // Filter scenarios by project name
  void _searchScenarios(String projectName) {
    setState(() {
      _scenarios = _allScenarios
          .where((scenario) => (scenario['project'] ?? '')
              .toLowerCase()
              .contains(projectName.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Color roleColor = getRoleColor();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: roleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _searchScenarios(searchController.text);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("User: ${_designation ?? 'User'}"),
              accountEmail: Text(_auth.currentUser?.email ?? 'Not logged in'),
              currentAccountPicture:
                  const CircleAvatar(child: Icon(Icons.person)),
              decoration: BoxDecoration(color: roleColor),
              otherAccountsPictures: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: _logout,
                ),
              ],
            ),
            ListTile(
              leading: IconButton(
                  onPressed: _addAssignmentDialog, icon: Icon(Icons.add)),
              trailing: IconButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => AssignedUsersPage(
                  //       assignments: _assignments,
                  //       userRole: _designation ?? '',
                  //     ),
                  //   ),
                  // );
                },
                icon: Icon(Icons.remove_red_eye),
              ),
              title: const Text("Assignment Management"),
              onTap: _addAssignmentDialog, // Call assignment form dialog
            ),
            Divider(),
            ListTile(
              leading:
                  IconButton(onPressed: _addTestCase, icon: Icon(Icons.add)),
              trailing: IconButton(
                onPressed: () {
                  // Navigator.pushNamed(context, Routes.testCaselist);
                },
                icon: Icon(Icons.remove_red_eye),
              ),
              title: const Text("Add Test Case"),
              onTap: _addTestCase, // Call assignment form dialog
            ),
            Divider(),
            ListTile(
              leading: IconButton(
                  onPressed: () {
                    _addCommentDialog();
                  },
                  icon: Icon(Icons.add)),
              trailing: IconButton(
                onPressed: () async {
                  // Fetch comments before navigating
                  await _fetchComments();
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => CommentListPage(
                  //       userRole: _designation ?? '',
                  //       initialComments: _comments,
                  //       getRoleColor:
                  //           getRoleColor, // Pass the function, not the result
                  //     ),
                  //   ),
                  // );
                },
                icon: Icon(Icons.remove_red_eye),
              ),
              title: const Text("Comment Form"),
              onTap: () {
                _addCommentDialog();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, ${_designation ?? 'User'}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              decoration:
                  const InputDecoration(labelText: "Search by Project Name"),
              onSubmitted: _searchScenarios,
            ),
            Expanded(
              child: _scenarios.isEmpty
                  ? const Center(child: Text("No scenarios available"))
                  : ListView.builder(
                      itemCount: _scenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = _scenarios[index];
                        final bool checkboxState =
                            scenario['checkboxState'] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(scenario['name'] ?? 'Unnamed Scenario'),
                            subtitle: Text(scenario['shortDescription'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: checkboxState,
                                  onChanged: _isCheckboxEnabled()
                                      ? (bool? value) {
                                          setState(() {
                                            scenario['checkboxState'] = value!;
                                          });
                                          _updateCheckboxState(
                                              scenario['docId'], value!);
                                        }
                                      : null, // Disable for other roles
                                ),
                                IconButton(
                                    onPressed: () {
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) =>
                                      //         ScenarioDetailPage(
                                      //             scenario: scenario, roleColor: (){},),
                                      //   ),
                                      // );
                                    },
                                    icon: Icon(Icons.remove_red_eye_sharp))
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addScenarioDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Scenario',
      ),
    );
  }
}
