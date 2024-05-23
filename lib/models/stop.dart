import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final String id;
  final String name;
  final LatLng location;

  Stop({required this.id, required this.name, required this.location});

  factory Stop.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    GeoPoint geo = data['location'];
    return Stop(
      id: doc.id,
      name: data['name'],
      location: LatLng(geo.latitude, geo.longitude),
    );
  }

  static Future<List<Stop>> fetchStops(String query) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Arrets')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snapshot.docs.map((doc) => Stop.fromFirestore(doc)).toList();
  }
}