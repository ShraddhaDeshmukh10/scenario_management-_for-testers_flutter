import 'package:async_redux/async_redux.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scenario_management_tool_for_testers/appstate.dart';

class AddCommentAction extends ReduxAction<AppState> {
  final String content;
  final String attachment;

  AddCommentAction(this.content, this.attachment);

  @override
  Future<AppState?> reduce() async {
    try {
      // Add the comment to Firestore
      await FirebaseFirestore.instance.collection('comments').add({
        'content': content,
        'attachment': attachment,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.email,
      });

      // Fetch the updated comments list after adding the comment
      await dispatch(FetchCommentsAction()); // Update the comments state
      return null; // No need to modify state directly, as FetchCommentsAction will handle it
    } catch (e) {
      print("Error adding comment: $e");
      return state.copy(); // Return the current state if there's an error
    }
  }
}

class FetchCommentsAction extends ReduxAction<AppState> {
  @override
  Future<AppState> reduce() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('comments').get();

      final comments = snapshot.docs.map((doc) {
        return {
          'docId': doc.id,
          'content': doc['content'] ?? 'No Content',
          'createdBy': doc['createdBy'] ?? 'Unknown',
          'attachment': doc['attachment'] ?? '',
          'createdAt': (doc['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      return state.copy(comments: comments);
    } catch (e) {
      print("Error fetching comments: $e");
      return state;
    }
  }
}
