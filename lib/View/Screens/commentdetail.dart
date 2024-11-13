import 'package:flutter/material.dart';

class CommentDetailPage extends StatelessWidget {
  final Map<String, dynamic> comment;
  final Color roleColor;

  const CommentDetailPage(
      {super.key, required this.comment, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: roleColor, // Use the passed role color
        title: const Text("Comment Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Content:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(comment['content'] ?? 'No content available'),
            const SizedBox(height: 20),
            Text(
              "Attachment:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(comment['attachment'] ?? 'No attachment available'),
            const SizedBox(height: 20),
            Text(
              "Created By:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(comment['createdBy'] ?? 'Unknown'),
            const SizedBox(height: 20),
            Text(
              "Created At:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(comment['createdAt']?.toDate().toString() ?? 'Unknown date'),
          ],
        ),
      ),
    );
  }
}
