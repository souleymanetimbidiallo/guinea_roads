// lib/models/troncon.dart
import 'stop.dart';

class Troncon {
  final Stop depart;
  final Stop arrivee;
  final String axe;
  final Map<String, int> prixParType;

  Troncon({
    required this.depart,
    required this.arrivee,
    required this.axe,
    required this.prixParType,
  });

  factory Troncon.fromFirestore(Map<String, dynamic> data) {
    final departData = data['depart'] as Map<String, dynamic>;
    final arriveeData = data['arrivee'] as Map<String, dynamic>;

    return Troncon(
      depart: Stop(
        id: departData['id'],
        name: departData['name'],
        latitude: departData['latitude'],
        longitude: departData['longitude'],
        order: departData['order'],
        axe: departData['axe'],
      ),
      arrivee: Stop(
        id: arriveeData['id'],
        name: arriveeData['name'],
        latitude: arriveeData['latitude'],
        longitude: arriveeData['longitude'],
        order: arriveeData['order'],
        axe: arriveeData['axe'],
      ),
      axe: data['axe'],
      prixParType: Map<String, int>.from(data['prixParType']),
    );
  }
}
