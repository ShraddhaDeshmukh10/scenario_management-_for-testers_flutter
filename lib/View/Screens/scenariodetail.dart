import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/viewmodel/dashviewmodel.dart';

class ScenarioDetailPage extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final Color roleColor;
  final String designation;

  ScenarioDetailPage({
    required this.scenario,
    required this.roleColor,
    required this.designation,
  });

  Future<List<Map<String, dynamic>>> _fetchTestCases(String scenarioId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenarioId)
          .collection('testCases')
          .get();

      return snapshot.docs.map((doc) {
        return {'docId': doc.id, ...?doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print("Error fetching test cases: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchChangeHistory(
      String scenarioId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenarioId)
          .collection('changes')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        return {'docId': doc.id, ...?doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print("Error fetching change history: $e");
      return [];
    }
  }

  Future<void> _deleteTestCase(String testCaseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenario['docId'])
          .collection('testCases')
          .doc(testCaseId)
          .delete();
    } catch (e) {
      print("Failed to delete test case: $e");
    }
  }

  Future<void> _saveChangeHistory(String scenarioId, String description) async {
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'unknown_user';
    try {
      await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenarioId)
          .collection('changes')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'EditedBy': userEmail,
        'description': description,
      });
    } catch (e) {
      print("Error saving change history: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchComments(String scenarioId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenarioId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {'docId': doc.id, ...?doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      print("Error fetching comments: $e");
      return [];
    }
  }

  void _addComment(BuildContext context, String scenarioId) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Comment"),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(labelText: "Enter your comment"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final userEmail =
                    FirebaseAuth.instance.currentUser?.email ?? 'unknown_user';
                final commentText = commentController.text;

                if (commentText.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('scenarios')
                        .doc(scenarioId)
                        .collection('comments')
                        .add({
                      'text': commentText,
                      'createdBy': userEmail,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print("Error adding comment: $e");
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _editTestCase(BuildContext context, Map<String, dynamic> testCase) {
    final TextEditingController nameController =
        TextEditingController(text: testCase['name'] ?? '');
    final TextEditingController bugIdController =
        TextEditingController(text: testCase['bugId'] ?? '');
    final TextEditingController projectNameController =
        TextEditingController(text: testCase['projectName'] ?? '');
    final TextEditingController shortDescriptionController =
        TextEditingController(text: testCase['shortDescription'] ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: testCase['description'] ?? '');
    final TextEditingController commentsController =
        TextEditingController(text: testCase['comments'] ?? '');
    final TextEditingController tagsController =
        TextEditingController(text: testCase['tags'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Test Case"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: "Test Case Name"),
                ),
                TextField(
                  controller: bugIdController,
                  decoration: const InputDecoration(labelText: "Bug ID"),
                ),
                TextField(
                  controller: projectNameController,
                  decoration: const InputDecoration(labelText: "Project Name"),
                ),
                TextField(
                  controller: shortDescriptionController,
                  decoration:
                      const InputDecoration(labelText: "Short Description"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(labelText: "Comments"),
                ),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(labelText: "Tags"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text;
                final newBugId = bugIdController.text;
                final newProjectName = projectNameController.text;
                final newShortDescription = shortDescriptionController.text;
                final newDescription = descriptionController.text;
                final newComments = commentsController.text;
                final newTags = tagsController.text;

                if (newName.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('scenarios')
                        .doc(scenario['docId'])
                        .collection('testCases')
                        .doc(testCase['docId'])
                        .update({
                      'name': newName,
                      'bugId': newBugId,
                      'projectName': newProjectName,
                      'shortDescription': newShortDescription,
                      'description': newDescription,
                      'comments': newComments,
                      'tags': newTags,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    await _saveChangeHistory(scenario['docId'],
                        "Updated test case ${testCase['docId']}");
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to update")));
                  }
                }
              },
              child: const Text("Save"),
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
        title: Text(scenario['name'] ?? 'Scenario Detail'),
        backgroundColor: roleColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => _addComment(context, scenario['docId']),
                child: const Text("Add Comment"),
              ),
              Divider(),
              Text(
                "Comment List",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Divider(),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchComments(scenario['docId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No comments found"));
                  }

                  final comments = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comments.map((comment) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Comment: ${comment['text'] ?? 'N/A'}"),
                          Text("Created By: ${comment['createdBy'] ?? 'N/A'}"),
                          Text(
                              "Timestamp: ${(comment['timestamp'] as Timestamp).toDate()}"),
                          Divider(),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
              Divider(),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchTestCases(scenario['docId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No test cases found"));
                  }

                  final testCases = snapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scenario Details',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Divider(),
                          SizedBox(height: 8),
                          Text(
                              "Scenario ID: ${scenario['projectId'] ?? 'N/A'}"),
                          Text("Scenario Name: ${scenario['name'] ?? 'N/A'}"),
                          Text(
                              "Description: ${scenario['shortDescription'] ?? 'N/A'}"),
                          Text(
                              "Assigned User: ${scenario['assignedToEmail'] ?? 'N/A'}"),
                          Text(
                              "Created At: ${scenario['createdAt'] != null ? (scenario['createdAt'] as Timestamp).toDate().toString() : 'N/A'}"),
                          Text(
                              "Created By: ${scenario['createdByEmail'] ?? 'N/A'}"),
                          Divider(),
                          if (designation != 'Junior Tester') ...[
                            TextButton(
                              child: const Text("Click to see change history"),
                              onPressed: () async {
                                final changes = await _fetchChangeHistory(
                                    scenario['docId']);
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Change History"),
                                      content: changes.isEmpty
                                          ? const Text("No changes found.")
                                          : SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: changes.map((change) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          "Scenario ID: ${scenario['projectId']}"),
                                                      Text(
                                                          "Project Name: ${scenario['projectName'] ?? 'N/A'}"),
                                                      Text(
                                                          "Edited By: ${change['EditedBy'] ?? 'Unknown'}"),
                                                      Text(
                                                          "Timestamp: ${(change['timestamp'] as Timestamp).toDate()}"),
                                                      Divider(),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                          Divider(),
                          Text(
                            'Test Cases',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Divider(),
                          SizedBox(height: 8),
                          if (testCases.isEmpty)
                            const Text("No test cases found")
                          else
                            Column(
                              children: testCases.map((testCase) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8),
                                    Text(
                                        "Test Case Name: ${testCase['name'] ?? 'N/A'}"),
                                    Text(
                                        "Bug ID: ${testCase['bugId'] ?? 'N/A'}"),
                                    Text(
                                        "Project Name: ${testCase['projectName'] ?? 'N/A'}"),
                                    Text(
                                        "Scenario ID: ${testCase['projectId'] ?? 'N/A'}"),
                                    Text(
                                        "Short Description: ${testCase['shortDescription'] ?? 'N/A'}"),
                                    Text(
                                        "Description: ${testCase['description'] ?? 'N/A'}"),
                                    Text(
                                        "Comments: ${testCase['comments'] ?? 'N/A'}"),
                                    Text("Tags: ${testCase['tags'] ?? 'N/A'}"),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _editTestCase(context, testCase),
                                        ),
                                        if (designation != 'Junior Tester')
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              bool confirmDelete =
                                                  await showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: const Text(
                                                                'Delete Test Case'),
                                                            content: const Text(
                                                                'Are you sure you want to delete this test case?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false),
                                                                child: const Text(
                                                                    'Cancel'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            true),
                                                                child: const Text(
                                                                    'Delete'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ) ??
                                                      false;

                                              if (confirmDelete) {
                                                await _deleteTestCase(
                                                    testCase['docId']);
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                    Divider(),
                                  ],
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
