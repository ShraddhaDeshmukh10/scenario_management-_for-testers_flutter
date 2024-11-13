import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch scenarios from Firebase
  Future<List<Map<String, dynamic>>> fetchScenariosFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('scenarios').get();
      return snapshot.docs
          .map(
              (doc) => {'docId': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print("Error fetching scenarios: $e");
      return [];
    }
  }

  Future<void> updateScenarioInFirebase(
      String docId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('scenarios').doc(docId).update(updatedData);
    } catch (e) {
      print("Error updating scenario: $e");
      throw Exception("Failed to update scenario");
    }
  }
}
