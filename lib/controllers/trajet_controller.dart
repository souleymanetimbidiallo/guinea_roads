import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/stop.dart';
import '../models/troncon.dart';
import '../models/trajet.dart';
import '../services/firestore_service.dart';

class TrajetController {
  List<Troncon> allTroncons = [];
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> loadTronconsFromFirestore() async {
    try {
      allTroncons = await _firestoreService.getAllTroncons();
    } catch (e) {
      print('🚫 Firestore inaccessible, chargement local JSON.');
      await loadTronconsFromLocalJson();
    }
  }

  Future<void> loadTronconsFromLocalJson() async {
    final String response = await rootBundle.loadString('assets/data/troncons_backup.json');
    final data = await json.decode(response) as List;
    allTroncons = data.map((json) => Troncon.fromJson(json)).toList();
  }

  Trajet? getMultiAxeTrajet(Stop depart, Stop arrivee) {
    final graph = _buildGraph();
    final path = _bfsPath(graph, depart.name.toLowerCase().trim(), arrivee.name.toLowerCase().trim());

    if (path.isEmpty) {
      print('❌ Aucun trajet multi-axe trouvé.');
      return null;
    }

    List<Troncon> tronconsPath = _rebuildTronconsFromPath(path);
    return Trajet(troncons: tronconsPath);
  }

  int calculerCoutTrajetParModes(Trajet trajet, List<String> modes) {
    int total = 0;
    int index = 0;
    for (final troncon in trajet.troncons) {
      final mode = index < modes.length ? modes[index] : modes.last;
      total += troncon.prixParType[mode] ?? 0;
      index++;
    }
    return total;
  }

  List<Map<String, dynamic>> getSmartMultimodalOptions(Trajet trajet) {
    List<Map<String, dynamic>> options = [];

    List<String> allModes = ['taxi', 'minibus', 'tricycle'];

    void backtrack(int index, List<Troncon> current, List<String> currentModes) {
      if (index >= trajet.troncons.length) {
        options.add({
          "trajet": Trajet(troncons: [...current]),
          "modes": [...currentModes]
        });
        return;
      }

      final troncon = trajet.troncons[index];

      for (var mode in allModes) {
        if ((troncon.prixParType[mode] ?? 0) > 0) {
          bool canMerge = currentModes.isNotEmpty && currentModes.last == mode;

          if (canMerge) {
            current.add(troncon);
            backtrack(index + 1, current, currentModes);
            current.removeLast();
          } else {
            current.add(troncon);
            currentModes.add(mode);
            backtrack(index + 1, current, currentModes);
            current.removeLast();
            currentModes.removeLast();
          }
        }
      }
    }

    backtrack(0, [], []);

    return options;
  }

  List<Map<String, dynamic>> getTransportOptionsForTrajet(Trajet trajet) {
    List<Map<String, dynamic>> options = [];
    final modes = ['taxi', 'minibus', 'tricycle'];

    for (final mode in modes) {
      final isAvailable = trajet.troncons.every((t) => (t.prixParType[mode] ?? 0) > 0);
      if (isAvailable) {
        options.add({
          "trajet": trajet,
          "mode": mode
        });
      }
    }

    return options;
  }

  List<Map<String, dynamic>> getCombinedTransportOptionsForTrajet(Trajet trajet) {
    Set<String> allModes = {'taxi', 'minibus', 'tricycle'};
    Set<String> usedModes = {};

    for (var troncon in trajet.troncons) {
      for (var mode in allModes) {
        if ((troncon.prixParType[mode] ?? 0) > 0) {
          usedModes.add(mode);
        }
      }
    }

    List<Map<String, dynamic>> result = [];

    if (usedModes.length > 1) {
      result.add({
        "trajet": trajet,
        "modes": usedModes.toList()
      });
    }

    return result;
  }

  List<Troncon> _rebuildTronconsFromPath(List<String> path) {
    List<Troncon> tronconsPath = [];
    for (int i = 0; i < path.length - 1; i++) {
      final from = path[i];
      final to = path[i + 1];

      final original = allTroncons.firstWhere(
            (t) =>
        (t.depart.name.toLowerCase().trim() == from && t.arrivee.name.toLowerCase().trim() == to) ||
            (t.depart.name.toLowerCase().trim() == to && t.arrivee.name.toLowerCase().trim() == from),
        orElse: () => throw Exception('Tronçon manquant entre $from et $to'),
      );

      final troncon = original.depart.name.toLowerCase().trim() == from
          ? original
          : Troncon(
        depart: original.arrivee,
        arrivee: original.depart,
        axe: original.axe,
        prixParType: original.prixParType,
      );

      tronconsPath.add(troncon);
    }
    return tronconsPath;
  }

  Map<String, List<String>> _buildGraph() {
    Map<String, List<String>> graph = {};
    for (var t in allTroncons) {
      final from = t.depart.name.toLowerCase().trim();
      final to = t.arrivee.name.toLowerCase().trim();
      graph.putIfAbsent(from, () => []).add(to);
      graph.putIfAbsent(to, () => []).add(from);
    }
    return graph;
  }

  List<String> _bfsPath(Map<String, List<String>> graph, String start, String goal) {
    Set<String> visited = {};
    Map<String, String?> cameFrom = {};
    List<String> queue = [start];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == goal) break;
      visited.add(current);

      for (final next in graph[current] ?? []) {
        if (!visited.contains(next) && !queue.contains(next)) {
          queue.add(next);
          cameFrom[next] = current;
        }
      }
    }

    if (!cameFrom.containsKey(goal)) return [];

    List<String> path = [goal];
    String? current = goal;
    while (current != start) {
      current = cameFrom[current];
      if (current == null) return [];
      path.insert(0, current);
    }
    return path;
  }

  List<Stop> extractAllStops() {
    final stopsSet = <String, Stop>{};
    for (var troncon in allTroncons) {
      stopsSet[troncon.depart.name.toLowerCase().trim()] = troncon.depart;
      stopsSet[troncon.arrivee.name.toLowerCase().trim()] = troncon.arrivee;
    }
    return stopsSet.values.toList();
  }
}
