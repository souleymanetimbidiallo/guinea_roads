import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import '../models/stop.dart';
import '../models/troncon.dart';
import '../models/trajet.dart';
import '../models/transport_option.dart';
import '../services/firestore_service.dart';
import '../services/google_directions_service.dart';

class TrajetController {
  TrajetController({
    Future<List<Troncon>> Function()? firestoreLoader,
    GoogleRoutesService? directionsService,
  })  : _firestoreLoader = firestoreLoader,
        _directionsService = directionsService ?? GoogleRoutesService();

  List<Troncon> allTroncons = [];
  bool loadedFromLocalData = false;
  final Future<List<Troncon>> Function()? _firestoreLoader;
  final GoogleRoutesService _directionsService;

  Future<void> loadTronconsFromFirestore() async {
    try {
      final loader =
          _firestoreLoader ?? () => FirestoreService().getAllTroncons();
      allTroncons = await loader();
      if (allTroncons.isEmpty) {
        await loadTronconsFromLocalJson();
      } else {
        loadedFromLocalData = false;
      }
    } catch (e) {
      debugPrint('Firestore inaccessible, chargement local JSON.');
      await loadTronconsFromLocalJson();
    }
  }

  Future<void> loadTronconsFromLocalJson() async {
    final String response =
        await rootBundle.loadString('assets/data/troncons_backup.json');
    final data = await json.decode(response) as List;
    allTroncons = data.map((json) => Troncon.fromJson(json)).toList();
    loadedFromLocalData = true;
  }

  Trajet? getMultiAxeTrajet(Stop depart, Stop arrivee) {
    final graph = _buildGraph();
    final path = _bfsPath(graph, depart.name.toLowerCase().trim(),
        arrivee.name.toLowerCase().trim());

    if (path.isEmpty) {
      debugPrint('Aucun trajet multi-axe trouvé.');
      return null;
    }

    List<Troncon> tronconsPath = _rebuildTronconsFromPath(path);
    return Trajet(troncons: tronconsPath);
  }

  List<TransportOption> getTransportOptions(Trajet trajet) {
    if (trajet.troncons.isEmpty) return [];

    const modesDisponibles = ['taxi', 'minibus', 'tricycle'];
    var candidats = <_TransportCandidate>[
      const _TransportCandidate(modes: [], cout: 0),
    ];

    for (final troncon in trajet.troncons) {
      final prochains = <String, _TransportCandidate>{};

      for (final candidat in candidats) {
        for (final mode in modesDisponibles) {
          final prix = troncon.prixParType[mode] ?? 0;
          if (prix <= 0) continue;

          final modes = [...candidat.modes, mode];
          final changements = _countModeChanges(modes);
          final cle = '$mode|$changements';
          final prochain = _TransportCandidate(
            modes: modes,
            cout: candidat.cout + prix,
          );
          final existant = prochains[cle];

          if (existant == null || prochain.cout < existant.cout) {
            prochains[cle] = prochain;
          }
        }
      }

      candidats = prochains.values.toList();
    }

    candidats.sort((a, b) {
      final cout = a.cout.compareTo(b.cout);
      if (cout != 0) return cout;
      return _countModeChanges(a.modes).compareTo(_countModeChanges(b.modes));
    });

    final allOptions = <TransportOption>[];
    final signatures = <String>{};
    for (final candidat in candidats) {
      final option = TransportOption(
        trajet: trajet,
        modesParTroncon: candidat.modes,
      );
      if (signatures.add(option.signature)) {
        allOptions.add(option);
      }
    }

    final options =
        allOptions.where((option) => option.nombreChangements == 0).toList();
    for (final option in allOptions) {
      if (options.length >= 6) break;
      if (!options.any((selected) => selected.signature == option.signature)) {
        options.add(option);
      }
    }
    options.sort((a, b) => a.coutTotal.compareTo(b.coutTotal));
    return options;
  }

  List<Troncon> _rebuildTronconsFromPath(List<String> path) {
    List<Troncon> tronconsPath = [];
    for (int i = 0; i < path.length - 1; i++) {
      final from = path[i];
      final to = path[i + 1];

      final original = allTroncons.firstWhere(
        (t) =>
            (t.depart.name.toLowerCase().trim() == from &&
                t.arrivee.name.toLowerCase().trim() == to) ||
            (t.depart.name.toLowerCase().trim() == to &&
                t.arrivee.name.toLowerCase().trim() == from),
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

  List<String> _bfsPath(
      Map<String, List<String>> graph, String start, String goal) {
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

  Future<Map<String, double>> getDistanceAndDuration(Trajet trajet) async {
    double totalDistance = 0;
    double totalDuration = 0;

    for (final troncon in trajet.troncons) {
      final d =
          await _fetchDistanceAndDuration(troncon.depart, troncon.arrivee);
      totalDistance += d['distance']!;
      totalDuration += d['duration']!;
    }

    return {
      'distance': totalDistance,
      'duration': totalDuration,
    };
  }

  Future<Map<String, double>> _fetchDistanceAndDuration(
      Stop from, Stop to) async {
    try {
      final route = await _directionsService.getDrivingRoute(from, to);
      return {
        'distance': route.distanceKm,
        'duration': route.durationMinutes,
      };
    } on DirectionsException catch (error) {
      // Les métriques ne doivent pas empêcher l'affichage du trajet local.
      debugPrint('Google Directions indisponible : $error');
      return {'distance': 0, 'duration': 0};
    }
  }
}

int _countModeChanges(List<String> modes) {
  var changements = 0;
  for (var index = 1; index < modes.length; index++) {
    if (modes[index] != modes[index - 1]) changements++;
  }
  return changements;
}

class _TransportCandidate {
  const _TransportCandidate({
    required this.modes,
    required this.cout,
  });

  final List<String> modes;
  final int cout;
}
