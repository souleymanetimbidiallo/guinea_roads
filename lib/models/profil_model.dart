import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  String id;
  String name;
  String email;
  String? photoUrl;
  List<String> history;

  UserProfile({required this.id, required this.name, required this.email, required this.history, this.photoUrl});

  // Factory method to create a UserProfile from Firestore document
  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    print('Creating UserProfile from document...');
    return UserProfile(
      id: doc.id,
      name: doc['name'],
      email: doc['email'],
      history: List<String>.from(doc['history']),
      photoUrl: doc['photoUrl'],
    );
  }

  // Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    print('Updating user data for userId: $userId...');
    await FirebaseFirestore.instance.collection('users').doc(userId).update(data);
  }

  // Fetch user data
  static Future<UserProfile> getUser(String userId) async {
    print('Fetching user data for userId: $userId...');
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      print('User document found.');
      return UserProfile.fromDocument(doc);
    } else {
      throw Exception('User not found in Firestore.');
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }
}
