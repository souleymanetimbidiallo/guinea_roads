// lib/controllers/trajet_controller.dart corrigé pour trajet bidirectionnel avec gestion des pivots = départ ou arrivée

import '../models/stop.dart';
import '../models/troncon.dart';
import '../models/trajet.dart';
import '../services/firestore_service.dart';

class TrajetController {
  List<Troncon> allTroncons = [];
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> loadTronconsFromFirestore() async {
    allTroncons = await _firestoreService.getAllTroncons();
    print('✅ Tronçons chargés : \${allTroncons.length}');
  }

  List<Troncon> findPath(String axe, String departName, String arriveeName) {
    final tronconsAxe = allTroncons.where((t) => t.axe == axe).toList();

    Map<String, List<Troncon>> graph = {};
    for (var t in tronconsAxe) {
      final from = t.depart.name.toLowerCase().trim();
      final to = t.arrivee.name.toLowerCase().trim();
      graph.putIfAbsent(from, () => []).add(t);

      final reverse = Troncon(
        depart: t.arrivee,
        arrivee: t.depart,
        axe: t.axe,
        prixParType: t.prixParType,
      );
      graph.putIfAbsent(to, () => []).add(reverse);
    }

    String start = departName.toLowerCase().trim();
    String goal = arriveeName.toLowerCase().trim();

    Set<String> visited = {};
    Map<String, Troncon?> cameFrom = {};
    List<String> queue = [start];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == goal) break;
      visited.add(current);

      for (final t in graph[current] ?? []) {
        final next = t.arrivee.name.toLowerCase().trim();
        if (!visited.contains(next) && !queue.contains(next)) {
          queue.add(next);
          cameFrom[next] = t;
        }
      }
    }

    if (!cameFrom.containsKey(goal)) {
      print('❌ Aucun chemin trouvé entre \$departName et \$arriveeName');
      return [];
    }

    List<Troncon> path = [];
    String current = goal;
    while (current != start) {
      final t = cameFrom[current]!;
      path.insert(0, t);
      current = t.depart.name.toLowerCase().trim();
    }

    print('✅ Trajet trouvé entre \$departName et \$arriveeName : \${path.length} tronçons');
    return path;
  }

  Trajet getTrajet(Stop depart, Stop arrivee) {
    final troncons = findPath(depart.axe, depart.name, arrivee.name);
    return Trajet(troncons: troncons);
  }

  List<Stop> extractAllStops() {
    final stopsSet = <String, Stop>{};
    for (var troncon in allTroncons) {
      stopsSet[troncon.depart.name.toLowerCase().trim()] = troncon.depart;
      stopsSet[troncon.arrivee.name.toLowerCase().trim()] = troncon.arrivee;
    }
    return stopsSet.values.toList();
  }

  List<Stop> findStopsPresentInMultipleAxes() {
    final Map<String, Set<String>> stopAxesMap = {};
    for (final troncon in allTroncons) {
      for (final stop in [troncon.depart, troncon.arrivee]) {
        final key = stop.name.toLowerCase().trim();
        stopAxesMap.putIfAbsent(key, () => {}).add(stop.axe);
      }
    }
    final pivots = stopAxesMap.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => allTroncons
        .expand((t) => [t.depart, t.arrivee])
        .firstWhere((s) => s.name.toLowerCase().trim() == entry.key))
        .toList();
    print('🚏 Pivots multi-axes trouvés : \${pivots.map((e) => e.name).join(", ")}');
    return pivots;
  }

  Stop? findPivotStopByNameAndAxe(String name, String axe) {
    try {
      return allTroncons
          .expand((t) => [t.depart, t.arrivee])
          .firstWhere((s) =>
      s.name.toLowerCase().trim() == name.toLowerCase().trim() &&
          s.axe == axe);
    } catch (_) {
      return null;
    }
  }

  Trajet? getMultiAxeTrajet(Stop depart, Stop arrivee) {
    if (depart.axe == arrivee.axe) {
      return getTrajet(depart, arrivee);
    }

    final multiAxeStops = findStopsPresentInMultipleAxes();
    Trajet? bestTrajet;
    int bestLength = 9999;

    for (final pivot in multiAxeStops) {
      final isPivotDepart = pivot.name.toLowerCase().trim() == depart.name.toLowerCase().trim();
      final isPivotArrivee = pivot.name.toLowerCase().trim() == arrivee.name.toLowerCase().trim();

      if (isPivotDepart) {
        final altPath = findPath(arrivee.axe, pivot.name, arrivee.name);
        if (altPath.isNotEmpty && altPath.length < bestLength) {
          bestTrajet = Trajet(troncons: altPath);
          bestLength = altPath.length;
        }
        continue;
      }

      if (isPivotArrivee) {
        final altPath = findPath(depart.axe, depart.name, pivot.name);
        if (altPath.isNotEmpty && altPath.length < bestLength) {
          bestTrajet = Trajet(troncons: altPath);
          bestLength = altPath.length;
        }
        continue;
      }

      final pivotInDepartAxe = findPivotStopByNameAndAxe(pivot.name, depart.axe);
      final pivotInArriveeAxe = findPivotStopByNameAndAxe(pivot.name, arrivee.axe);

      if (pivotInDepartAxe != null && pivotInArriveeAxe != null) {
        final troncons1 = findPath(depart.axe, depart.name, pivot.name);
        final troncons2 = findPath(arrivee.axe, pivot.name, arrivee.name);

        if (troncons1.isNotEmpty && troncons2.isNotEmpty) {
          final total = [...troncons1, ...troncons2];
          if (total.length < bestLength) {
            bestLength = total.length;
            bestTrajet = Trajet(troncons: total);
          }
        }
      }
    }

    return bestTrajet;
  }
}
