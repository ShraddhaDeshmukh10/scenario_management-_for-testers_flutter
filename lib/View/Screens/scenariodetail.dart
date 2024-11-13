import 'package:flutter/material.dart';

class ScenarioDetailPage extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final Color roleColor; // Change this to a Color

  const ScenarioDetailPage({
    Key? key,
    required this.scenario,
    required this.roleColor, // Accept Color directly
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scenario Details"),
        backgroundColor: roleColor, // Directly use the Color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${scenario['name'] ?? 'N/A'}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("ID:",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(scenario['id'] ?? 'N/A'),
            const SizedBox(height: 10),
            Text("Project:",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(scenario['project'] ?? 'N/A'),
            const SizedBox(height: 10),
            Text("Short Description:",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(scenario['shortDescription'] ?? 'N/A'),
            const SizedBox(height: 10),
            Text("Created At:",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(scenario['createdAt']?.toDate().toString() ?? 'N/A'),
            const SizedBox(height: 10),
            Text("Created By:",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(scenario['createdBy'] ?? 'N/A')
          ],
        ),
      ),
    );
  }
}
