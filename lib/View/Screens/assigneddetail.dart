import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final Color roleColor;

  const AssignmentDetailPage({
    super.key,
    required this.assignment,
    required this.roleColor,
  });

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final timestamp =
        assignment['createdAt']; // assuming createdAt is a Firestore Timestamp

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assignment Details"),
        backgroundColor: roleColor, // Use roleColor from constructor
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bug ID:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(assignment['bugId']),
            const SizedBox(height: 10),
            Text(
              'Assigned User:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(assignment['assignedUser']),
            const SizedBox(height: 10),
            Text(
              'Assigned By:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              assignment['assignedBy'],
            ),
            const SizedBox(height: 10),
            Text(
              'Created At:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(timestamp != null ? formatTimestamp(timestamp) : 'N/A')
          ],
        ),
      ),
    );
  }
}
