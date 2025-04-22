// lib/controllers/trajet_controller.dart
import '../models/stop.dart';
import '../models/troncon.dart';
import '../models/trajet.dart';
import '../services/firestore_service.dart';

class TrajetController {
  List<Troncon> allTroncons = [];
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> loadTronconsFromFirestore() async {
    allTroncons = await _firestoreService.getAllTroncons();
  }

  List<Troncon> getTronconsBetween(Stop depart, Stop arrivee) {
    List<Troncon> troncons = [];

    if (depart.axe != arrivee.axe) return [];

    int start = depart.order;
    int end = arrivee.order;

    if (start > end) {
      // Inversion
      int temp = start;
      start = end;
      end = temp;
    }

    troncons = allTroncons.where((t) =>
    t.axe == depart.axe &&
        (t.depart.order >= start && t.depart.order <= end) &&
        (t.arrivee.order >= start && t.arrivee.order <= end)
    ).toList();

    troncons.sort((a, b) => a.depart.order.compareTo(b.depart.order));

    return troncons;
  }


  Trajet getTrajet(Stop depart, Stop arrivee) {
    final troncons = getTronconsBetween(depart, arrivee);
    return Trajet(troncons: troncons);
  }

  List<Stop> extractAllStops() {
    final stopsSet = <String, Stop>{};

    for (var troncon in allTroncons) {
      stopsSet[troncon.depart.name] = troncon.depart;
      stopsSet[troncon.arrivee.name] = troncon.arrivee;
    }

    return stopsSet.values.toList();
  }

}
