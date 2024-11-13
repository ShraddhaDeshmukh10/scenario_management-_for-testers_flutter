import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scenario_management_tool_for_testers/View/Screens/commentdetail.dart';

class CommentListPage extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final String designation;
  final Color roleColor;

  const CommentListPage({
    super.key,
    required this.designation,
    required this.comments,
    required this.roleColor,
  });

  @override
  _CommentListPageState createState() => _CommentListPageState();
}

class _CommentListPageState extends State<CommentListPage> {
  late List<Map<String, dynamic>> comments;
  late String designation;

  @override
  void initState() {
    super.initState();
    designation = widget.designation;
    comments = List.from(widget.comments); // Initialize the comments list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.roleColor,
        title: const Text("Comments List"),
      ),
      body: comments.isEmpty
          ? const Center(
              child: Text(
                'No comments available.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(comment['content'] ?? 'No content'),
                    subtitle: Text(comment['createdBy'] ?? 'Unknown'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button for all users
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editComment(context, comment, index);
                          },
                        ),
                        // Delete button only for "Tester Lead" role
                        if (designation == 'Tester Lead')
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteComment(context, comment, index);
                            },
                          ),
                        // View button
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          onPressed: () {
                            // Navigate to the comment detail page and pass roleColor
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentDetailPage(
                                  comment: comment,
                                  roleColor:
                                      widget.roleColor, // Pass roleColor here
                                ),
                              ),
                            );
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

  void _editComment(
      BuildContext context, Map<String, dynamic> comment, int index) {
    final TextEditingController _controller =
        TextEditingController(text: comment['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'Comment Content'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedContent = _controller.text;
              if (updatedContent.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('comments')
                      .doc(comment['docId'])
                      .update({'content': updatedContent});
                  setState(() {
                    comments[index]['content'] = updatedContent;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Comment updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update comment')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(
      BuildContext context, Map<String, dynamic> comment, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('comments')
                    .doc(comment['docId'])
                    .delete();
                setState(() {
                  comments.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete comment')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
