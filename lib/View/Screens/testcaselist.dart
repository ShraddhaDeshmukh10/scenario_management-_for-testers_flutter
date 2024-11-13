import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/View/testcasedetail.dart';

class TestCaseListPage extends StatefulWidget {
  final String designation; // Use designation
  final Color roleColor;

  const TestCaseListPage({
    super.key,
    required this.designation,
    required this.roleColor,
  });

  @override
  State<TestCaseListPage> createState() => _TestCaseListPageState();
}

class _TestCaseListPageState extends State<TestCaseListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchTestCases() async {
    var testCaseSnapshot = await _firestore.collection('testcases').get();
    return testCaseSnapshot.docs
        .map((doc) => {
              ...doc.data() as Map<String, dynamic>,
              'docId': doc.id,
            })
        .toList();
  }

  void _editTestCase(String docId, Map<String, dynamic> currentData) {
    final TextEditingController nameController =
        TextEditingController(text: currentData['testcasename']);
    final TextEditingController projectController =
        TextEditingController(text: currentData['project']);
    final TextEditingController bugIdController =
        TextEditingController(text: currentData['id']);
    final TextEditingController shortDescriptionController =
        TextEditingController(text: currentData['shortDescription']);
    final TextEditingController scenarioController =
        TextEditingController(text: currentData['scenario']);
    final TextEditingController commentsController =
        TextEditingController(text: currentData['comments']);
    final TextEditingController descriptionController =
        TextEditingController(text: currentData['description']);
    final TextEditingController attachmentController =
        TextEditingController(text: currentData['attachments']);
    String? _selectedTag = currentData['tags'];

    final List<String> tagsOptions = [
      "Passed",
      "Failed",
      "In Review",
      "Completed"
    ];

    final List<String> filteredTagsOptions =
        widget.designation == 'Junior Tester'
            ? tagsOptions.where((tag) => tag != "Completed").toList()
            : tagsOptions;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Test Case"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: "Test Case Name"),
                ),
                TextField(
                  controller: projectController,
                  decoration: const InputDecoration(labelText: "Project Name"),
                ),
                TextField(
                  controller: bugIdController,
                  decoration: const InputDecoration(labelText: "Bug ID"),
                ),
                TextField(
                  controller: shortDescriptionController,
                  decoration:
                      const InputDecoration(labelText: "Short Description"),
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
                DropdownButtonFormField<String>(
                  value: _selectedTag ??
                      tagsOptions
                          .first, // Ensure there is a valid initial value
                  decoration: const InputDecoration(labelText: "Tags"),
                  items: filteredTagsOptions.map((String tag) {
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
                try {
                  await _firestore.collection('testcases').doc(docId).update({
                    'testcasename': nameController.text,
                    'project': projectController.text,
                    'id': bugIdController.text,
                    'shortDescription': shortDescriptionController.text,
                    'scenario': scenarioController.text,
                    'comments': commentsController.text,
                    'description': descriptionController.text,
                    'attachments': attachmentController.text,
                    'tags': _selectedTag,
                  });

                  Navigator.of(context).pop();
                  setState(() {
                    _fetchTestCases();
                  });
                } catch (e) {
                  print("Failed to update test case: $e");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Failed to update test case")));
                }
              },
              child: const Text("Save"),
            ),
            if (widget.designation == 'Tester Lead')
              TextButton(
                onPressed: () async {
                  try {
                    await _firestore
                        .collection('testcases')
                        .doc(docId)
                        .delete();
                    Navigator.of(context).pop();
                    setState(() {
                      _fetchTestCases();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Test case deleted successfully")));
                  } catch (e) {
                    print("Failed to delete test case: $e");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Failed to delete test case")));
                  }
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Cases"),
        backgroundColor: widget.roleColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTestCases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No test cases found"));
          }

          final testCases = snapshot.data!;
          return ListView.builder(
            itemCount: testCases.length,
            itemBuilder: (context, index) {
              final testCase = testCases[index];
              return Card(
                child: ListTile(
                  title: Text(testCase['project'] ?? 'Unnamed Test Case'),
                  subtitle: Text("tags: ${testCase['tags'] ?? 'N/A'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: () {
                          // Navigate to the new TestCaseDetailPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestCaseDetailPage(
                                testCase: testCase,
                                roleColor: widget.roleColor,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _editTestCase(testCase['docId'], testCase),
                      ),
                      if (widget.designation == 'Tester Lead')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await _firestore
                                  .collection('testcases')
                                  .doc(testCase['docId'])
                                  .delete();
                              setState(() {
                                _fetchTestCases();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Test case deleted successfully")),
                              );
                            } catch (e) {
                              print("Failed to delete test case: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Failed to delete test case")),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
