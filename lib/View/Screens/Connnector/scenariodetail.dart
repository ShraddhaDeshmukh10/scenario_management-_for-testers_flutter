import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/Actions/load_actions.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';
import 'package:scenario_management_tool_for_testers/main.dart';

///This class takes scenario, roleColor, and designation as inputs, with scenario details rendered across various sections (Scenario Details, Test Cases, Comments, etc.).
///Conditional rendering using if allows certain actions only for lead tester and developer, such as viewing change history or deleting test cases.
class ScenarioDetailPage extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final Color roleColor;
  final String designation;

  const ScenarioDetailPage({
    super.key,
    required this.scenario,
    required this.roleColor,
    required this.designation,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, List<Map<String, dynamic>>>(
      converter: (store) => store.state.testCases,
      onInit: (store) =>
          store.dispatch(FetchTestCasesAction(scenario['docId'])),
      builder: (context, testCases) {
        return Scaffold(
          appBar: AppBar(
            title: Text(scenario['projectName'] ?? 'Scenario Detail'),
            backgroundColor: roleColor,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// this option is only available to developer and lead tester to track the changes in scenario tastcases.
                if (designation != 'Junior Tester') ...[
                  // Change history button code
                  TextButton(
                    child: const Text("Click to see change history"),
                    onPressed: () async {
                      final changes =
                          await _fetchChangeHistory(scenario['docId']);
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
                                              CrossAxisAlignment.start,
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
                                onPressed: () => Navigator.of(context).pop(),
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
                TextButton(
                  onPressed: () {
                    _addComment(context, scenario['docId']);
                  },
                  child: const Text("Add Comment"),
                ),
                const Divider(),
                const Text(
                  "Comment List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Divider(),
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
                            Text(
                                "Created By: ${comment['createdBy'] ?? 'N/A'}"),
                            Text(
                                "Timestamp: ${(comment['timestamp'] as Timestamp).toDate()}"),
                            const Divider(),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),
                const Text(
                  'Scenario Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Divider(),
                SizedBox(height: 8),
                Text("Scenario ID: ${scenario['projectId'] ?? 'N/A'}"),
                Text("Scenario Name: ${scenario['name'] ?? 'N/A'}"),
                Text("Description: ${scenario['shortDescription'] ?? 'N/A'}"),
                Text("Assigned User: ${scenario['assignedToEmail'] ?? 'N/A'}"),
                Text(
                    "Created At: ${scenario['createdAt'] != null ? (scenario['createdAt'] as Timestamp).toDate().toString() : 'N/A'}"),
                Text("Created By: ${scenario['createdByEmail'] ?? 'N/A'}"),
                const Divider(),
                //  Test Cases...............
                const Text(
                  'Test Cases',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Divider(),
                if (testCases.isEmpty)
                  const Text("No test cases found")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: testCases.length,
                    itemBuilder: (context, index) {
                      final testCase = testCases[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Test Case Name: ${testCase['name'] ?? 'N/A'}"),
                          Text("Bug ID: ${testCase['bugId'] ?? 'N/A'}"),
                          Text(
                              "Scenario ID: ${testCase['scenarioId'] ?? 'N/A'}"),
                          Text(
                              "Short Description: ${testCase['description'] ?? 'N/A'}"),
                          Text("Created At: ${testCase['createdAt'] ?? 'N/A'}"),
                          Text("Comments: ${testCase['comments'] ?? 'N/A'}"),
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
                                  onPressed: () => _deleteTestCase(
                                      testCase['docId'], testCase),
                                ),
                            ],
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  )
              ],
            ),
          ),
        );
      },
    );
  }

//// used to fetch testcases from firestore
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

  ///Firestore Query retrieves up to 10 recent changes for the scenario, sorted by timestamp.
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

  ///allows delete option to lead tester
  Future<void> _deleteTestCase(
      String testCaseId, Map<String, dynamic> testCase) async {
    try {
      await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenario['docId'])
          .collection('testCases')
          .doc(testCaseId)
          .delete();
      store.dispatch(FetchTestCasesAction(scenario['docId']));
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
                    store.dispatch(FetchTestCasesAction(scenario['docId']));
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
    final TextEditingController shortDescriptionController =
        TextEditingController(text: testCase['shortDescription'] ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: testCase['description'] ?? '');
    final TextEditingController commentsController =
        TextEditingController(text: testCase['comments'] ?? '');
    String? selectedTag;

    final tagsOptions = designation == 'Junior Tester'
        ? ["Passed", "Failed", "In Review"]
        : ["Passed", "Failed", "In Review", "Completed"];

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
                DropdownButtonFormField<String>(
                  value: selectedTag,
                  decoration: const InputDecoration(labelText: "Tags"),
                  items: tagsOptions
                      .map((tag) =>
                          DropdownMenuItem(value: tag, child: Text(tag)))
                      .toList(),
                  onChanged: (value) => selectedTag = value,
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
                final newShortDescription = shortDescriptionController.text;
                final newDescription = descriptionController.text;
                final newComments = commentsController.text;
                final newTags = selectedTag;

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
                      'shortDescription': newShortDescription,
                      'description': newDescription,
                      'comments': newComments,
                      'tags': selectedTag,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    await _saveChangeHistory(scenario['docId'],
                        "Updated test case ${testCase['docId']}");
                    store.dispatch(FetchTestCasesAction(scenario['docId']));
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
}
