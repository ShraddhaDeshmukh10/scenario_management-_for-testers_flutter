import 'package:flutter/material.dart';

class TestCaseDetailPage extends StatelessWidget {
  final Map<String, dynamic> testCase;
  final Color roleColor;

  const TestCaseDetailPage({
    super.key,
    required this.testCase,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    // Format the timestamp for "createdAt" if available
    String createdAt = testCase['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
                testCase['createdAt'].seconds * 1000)
            .toLocal()
            .toString()
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Case Details"),
        backgroundColor: roleColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Test Case Name:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['testcasename'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Project: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['project'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Bug ID:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['id'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Short Description:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['shortDescription'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Scenario: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['scenario'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Comments: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['comments'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Description:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['description'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Attachment:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['attachments'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Tags: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['tags'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Created By:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(testCase['createdBy'] ?? 'N/A'),
            SizedBox(
              height: 10,
            ),
            Text("Created At: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(createdAt)
          ],
        ),
      ),
    );
  }
}
