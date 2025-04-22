// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/troncon.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Troncon>> getAllTroncons() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Troncons').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Troncon.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Erreur lors du chargement des tronçons : $e');
      return [];
    }
  }
}
