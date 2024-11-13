import 'package:flutter/material.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/assigneddetail.dart';

class AssignedUsersPage extends StatefulWidget {
  final List<Map<String, dynamic>> assignments;
  final String designation; // Use designation
  final Color roleColor;

  const AssignedUsersPage({
    super.key,
    required this.assignments,
    required this.designation,
    required this.roleColor,
  });

  @override
  _AssignedUsersPageState createState() => _AssignedUsersPageState();
}

class _AssignedUsersPageState extends State<AssignedUsersPage> {
  late List<Map<String, dynamic>> assignments;
  late String designation;

  @override
  void initState() {
    super.initState();
    assignments = widget.assignments;
    designation = widget.designation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Users"),
        backgroundColor: widget.roleColor, // Use widget.roleColor
      ),
      body: assignments.isEmpty
          ? const Center(child: Text("No users assigned"))
          : ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title:
                        Text(assignment['assignedUser'] ?? 'No User Assigned'),
                    subtitle: Text('Bug ID: ${assignment['bugId']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignmentDetailPage(
                            assignment: assignment,
                            roleColor: widget.roleColor, // Use widget.roleColor
                          ),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editAssignment(context, assignment);
                          },
                        ),
                        if (designation == 'Tester Lead') // Use designation
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteAssignment(context, assignment);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Edit Assignment functionality
  void _editAssignment(BuildContext context, Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController userController =
            TextEditingController(text: assignment['assignedUser']);
        final TextEditingController bugIdController =
            TextEditingController(text: assignment['bugId']);

        return AlertDialog(
          title: const Text("Edit Assignment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: "Assigned User"),
              ),
              TextField(
                controller: bugIdController,
                decoration: const InputDecoration(labelText: "Bug ID"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  assignment['assignedUser'] = userController.text;
                  assignment['bugId'] = bugIdController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Delete Assignment functionality
  void _deleteAssignment(
      BuildContext context, Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Assignment"),
          content:
              const Text("Are you sure you want to delete this assignment?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  assignments.remove(assignment); // Remove from the list
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Assignment deleted")),
                );
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
