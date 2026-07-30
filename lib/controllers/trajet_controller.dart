import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import '../models/stop.dart';
import '../models/troncon.dart';
import '../models/trajet.dart';
import '../models/transport_option.dart';
import '../models/tarification.dart';
import '../models/correspondance.dart';
import '../models/profil_transport.dart';
import '../services/calcul_tarifaire_service.dart';
import '../services/calcul_duree_transport_service.dart';
import '../services/correspondance_data_service.dart';
import '../services/firestore_service.dart';
import '../services/google_directions_service.dart';
import '../services/profil_transport_data_service.dart';
import '../services/tarification_data_service.dart';

enum EchecRechercheTrajet {
  aucun,
  arretInconnu,
  aucunChemin,
  correspondanceNonValidee,
}

class TrajetController {
  TrajetController({
    Future<List<Troncon>> Function()? firestoreLoader,
    Future<List<AxeTarifaire>> Function()? tarificationLoader,
    Future<List<Correspondance>> Function()? correspondanceLoader,
    Future<List<ProfilTransport>> Function()? profilTransportLoader,
    GoogleRoutesService? directionsService,
  })  : _firestoreLoader = firestoreLoader,
        _tarificationLoader = tarificationLoader,
        _correspondanceLoader = correspondanceLoader,
        _profilTransportLoader = profilTransportLoader,
        _directionsService = directionsService ?? GoogleRoutesService();

  List<Troncon> allTroncons = [];
  List<AxeTarifaire> axesTarifaires = [];
  List<Correspondance> correspondances = [];
  List<ProfilTransport> profilsTransport = [];
  EchecRechercheTrajet dernierEchec = EchecRechercheTrajet.aucun;
  bool loadedFromLocalData = false;
  final Future<List<Troncon>> Function()? _firestoreLoader;
  final Future<List<AxeTarifaire>> Function()? _tarificationLoader;
  final Future<List<Correspondance>> Function()? _correspondanceLoader;
  final Future<List<ProfilTransport>> Function()? _profilTransportLoader;
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
    await _loadTarificationPilote();
    await _loadCorrespondances();
    await _loadProfilsTransport();
  }

  Future<void> _loadProfilsTransport() async {
    try {
      final loader = _profilTransportLoader ??
          () => ProfilTransportDataService().charger();
      profilsTransport = await loader();
    } catch (error) {
      profilsTransport = [];
      debugPrint('Profils transport indisponibles : durée routière utilisée.');
    }
  }

  Future<void> _loadCorrespondances() async {
    try {
      final loader =
          _correspondanceLoader ?? () => CorrespondanceDataService().charger();
      correspondances = (await loader())
          .where((correspondance) => correspondance.valideeTerrain)
          .toList(growable: false);
    } catch (error) {
      correspondances = [];
      debugPrint('Correspondances indisponibles : changements d’axe refusés.');
    }
  }

  Future<void> _loadTarificationPilote() async {
    try {
      final loader =
          _tarificationLoader ?? () => TarificationDataService().chargerAxes();
      axesTarifaires = await loader();
    } catch (error) {
      axesTarifaires = [];
      debugPrint('Tarification V2 indisponible, maintien des tarifs V1.');
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
    final trajets = getAlternativeTrajets(depart, arrivee, maxTrajets: 1);
    return trajets.isEmpty ? null : trajets.first;
  }

  List<Trajet> getAlternativeTrajets(
    Stop depart,
    Stop arrivee, {
    int maxTrajets = 3,
    int maxDetourTroncons = 3,
  }) {
    dernierEchec = EchecRechercheTrajet.aucun;
    if (maxTrajets <= 0) return [];

    final trajetTarifaire = _construireTrajetTarifaire(depart, arrivee);
    if (trajetTarifaire != null) return [trajetTarifaire];

    final graph = _buildGraph();
    final start = depart.name.toLowerCase().trim();
    final goal = arrivee.name.toLowerCase().trim();
    if (start == goal ||
        !graph.containsKey(start) ||
        !graph.containsKey(goal)) {
      dernierEchec = EchecRechercheTrajet.arretInconnu;
      return [];
    }

    final paths = _findSimplePaths(
      graph,
      start,
      goal,
      // Des raccourcis topologiques peuvent être invalides parce qu’ils
      // changent d’axe sans correspondance. On explore donc davantage de
      // candidats avant de retenir uniquement les trajets autorisés.
      maxPaths: maxTrajets * 20,
      maxDetourEdges: maxDetourTroncons,
    );
    if (paths.isEmpty) {
      dernierEchec = EchecRechercheTrajet.aucunChemin;
      debugPrint('Aucun trajet multi-axe trouvé.');
      return [];
    }

    final trajets = <Trajet>[];
    for (final path in paths) {
      final construit = _rebuildTronconsFromPath(path);
      if (construit != null) {
        trajets.add(
          Trajet(
            troncons: construit.troncons,
            correspondances: construit.correspondances,
          ),
        );
        if (trajets.length >= maxTrajets) break;
      }
    }
    if (trajets.isEmpty) {
      dernierEchec = EchecRechercheTrajet.correspondanceNonValidee;
    }
    return trajets;
  }

  Trajet? _construireTrajetTarifaire(Stop depart, Stop arrivee) {
    for (final axe in axesTarifaires) {
      final pointDepart = axe.pointPourNom(depart.name);
      final pointArrivee = axe.pointPourNom(arrivee.name);
      if (pointDepart == null || pointArrivee == null) continue;
      if (pointDepart.position == pointArrivee.position) return null;

      final points = axe.pointsPourTrajet(pointDepart, pointArrivee);
      final troncons = <Troncon>[];
      for (var index = 0; index < points.length - 1; index++) {
        final pointActuel = points[index];
        final pointSuivant = points[index + 1];
        final tranche = axe.tranchePourSegment(
          pointActuel.position,
          pointSuivant.position,
        );
        if (tranche == null) return null;

        troncons.add(
          Troncon(
            depart: _stopDepuisPoint(pointActuel, axe),
            arrivee: _stopDepuisPoint(pointSuivant, axe),
            axe: axe.nom,
            prixParType: tranche.tarifsParTransport,
          ),
        );
      }
      return troncons.isEmpty ? null : Trajet(troncons: troncons);
    }
    return null;
  }

  Stop _stopDepuisPoint(PointTarifaire point, AxeTarifaire axe) {
    return Stop(
      id: 'tarif-${axe.id}-${point.id}',
      name: point.nom,
      latitude: point.latitude,
      longitude: point.longitude,
      order: point.position.round(),
      axe: axe.nom,
    );
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
      final tarifV2 = _calculerTarifV2(trajet, candidat.modes);
      final option = TransportOption(
        trajet: trajet,
        modesParTroncon: candidat.modes,
        tarifV2: tarifV2,
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

  TarifTrajet? _calculerTarifV2(Trajet trajet, List<String> modes) {
    final modesUniques = modes.toSet();
    if (trajet.troncons.isEmpty || modesUniques.length != 1) return null;

    final depart = trajet.troncons.first.depart.name;
    final arrivee = trajet.troncons.last.arrivee.name;
    for (final axe in axesTarifaires) {
      final positionDepart = axe.positionPourNom(depart);
      final positionArrivee = axe.positionPourNom(arrivee);
      if (positionDepart == null || positionArrivee == null) continue;

      try {
        return const CalculTarifaireService().calculer(
          axe: axe,
          positionDepart: positionDepart,
          positionArrivee: positionArrivee,
          transport: modesUniques.single,
        );
      } on TransportIndisponibleException {
        return null;
      } on ArgumentError {
        return null;
      }
    }
    return null;
  }

  _TrajetConstruit? _rebuildTronconsFromPath(List<String> path) {
    var possibilites = <_TrajetConstruit>[
      const _TrajetConstruit(troncons: [], correspondances: []),
    ];
    for (int i = 0; i < path.length - 1; i++) {
      final from = path[i];
      final to = path[i + 1];
      final candidats = allTroncons
          .where(
            (troncon) =>
                (_nomNormalise(troncon.depart.name) == from &&
                    _nomNormalise(troncon.arrivee.name) == to) ||
                (_nomNormalise(troncon.depart.name) == to &&
                    _nomNormalise(troncon.arrivee.name) == from),
          )
          .map(
            (original) => _nomNormalise(original.depart.name) == from
                ? original
                : Troncon(
                    depart: original.arrivee,
                    arrivee: original.depart,
                    axe: original.axe,
                    prixParType: original.prixParType,
                  ),
          )
          .toList();

      final suivantes = <_TrajetConstruit>[];
      for (final possibilite in possibilites) {
        for (final candidat in candidats) {
          Correspondance? correspondance;
          if (possibilite.troncons.isNotEmpty) {
            final precedent = possibilite.troncons.last;
            if (_slug(precedent.axe) != _slug(candidat.axe)) {
              correspondance = _trouverCorrespondance(
                precedent.axe,
                candidat.axe,
                candidat.depart.name,
              );
              if (correspondance == null) continue;
            }
          }
          suivantes.add(
            _TrajetConstruit(
              troncons: [...possibilite.troncons, candidat],
              correspondances: [
                ...possibilite.correspondances,
                if (correspondance != null) correspondance,
              ],
            ),
          );
        }
      }
      possibilites = suivantes;
      if (possibilites.isEmpty) return null;
    }
    return possibilites.first;
  }

  Correspondance? _trouverCorrespondance(
    String axeDepuis,
    String axeVers,
    String point,
  ) {
    final depuis = _slug(axeDepuis);
    final vers = _slug(axeVers);
    final pointId = _slug(point);
    for (final correspondance in correspondances) {
      final sensDirect = correspondance.axeDepartId == depuis &&
          correspondance.axeArriveeId == vers &&
          correspondance.pointDepartId == pointId &&
          correspondance.pointArriveeId == pointId;
      final sensInverse = correspondance.bidirectionnelle &&
          correspondance.axeDepartId == vers &&
          correspondance.axeArriveeId == depuis &&
          correspondance.pointDepartId == pointId &&
          correspondance.pointArriveeId == pointId;
      if (sensDirect || sensInverse) return correspondance;
    }
    return null;
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

  List<List<String>> _findSimplePaths(
    Map<String, List<String>> graph,
    String start,
    String goal, {
    required int maxPaths,
    required int maxDetourEdges,
  }) {
    final shortestPath = _bfsPath(graph, start, goal);
    if (shortestPath.isEmpty) return [];

    final maxEdges = shortestPath.length - 1 + maxDetourEdges;
    final queue = <List<String>>[
      [start],
    ];
    final results = <List<String>>[];

    while (queue.isNotEmpty && results.length < maxPaths) {
      final path = queue.removeAt(0);
      final current = path.last;
      final edgeCount = path.length - 1;

      if (current == goal) {
        results.add(path);
        continue;
      }
      if (edgeCount >= maxEdges) continue;

      final neighbors = [...graph[current] ?? const <String>[]]..sort();
      for (final next in neighbors) {
        if (!path.contains(next)) {
          queue.add([...path, next]);
        }
      }
    }

    return results;
  }

  List<Stop> extractAllStops() {
    final stopsSet = <String, Stop>{};
    for (var troncon in allTroncons) {
      stopsSet[troncon.depart.name.toLowerCase().trim()] = troncon.depart;
      stopsSet[troncon.arrivee.name.toLowerCase().trim()] = troncon.arrivee;
    }
    for (final axe in axesTarifaires) {
      for (final point in <PointTarifaire>[...axe.limites, ...axe.reperes]) {
        final stop = _stopDepuisPoint(point, axe);
        stopsSet[stop.name.toLowerCase().trim()] = stop;
      }
    }
    return stopsSet.values.toList();
  }

  Future<Map<String, double>> getDistanceAndDuration(Trajet trajet) async {
    final metrics = await Future.wait(
      trajet.troncons.map(
        (troncon) => _fetchDistanceAndDuration(troncon.depart, troncon.arrivee),
      ),
    );
    final totalDistance = metrics.fold<double>(
      0,
      (total, metric) => total + (metric['distance'] ?? 0),
    );
    final drivingDuration = metrics.fold<double>(
      0,
      (total, metric) => total + (metric['duration'] ?? 0),
    );
    final durationMin =
        drivingDuration + trajet.dureeCorrespondancesMin.toDouble();
    final durationMax =
        drivingDuration + trajet.dureeCorrespondancesMax.toDouble();

    return {
      'distance': totalDistance,
      'duration': (durationMin + durationMax) / 2,
      'durationMin': durationMin,
      'durationMax': durationMax,
    };
  }

  Future<Map<String, double>> getDistanceAndDurationForOption(
    TransportOption option,
  ) async {
    final metrics = await Future.wait(
      option.trajet.troncons.map(
        (troncon) => _fetchDistanceAndDuration(troncon.depart, troncon.arrivee),
      ),
    );
    var distance = 0.0;
    var min = 0.0;
    var max = 0.0;
    var profilsValides = true;
    for (var index = 0; index < metrics.length; index++) {
      final metric = metrics[index];
      distance += metric['distance'] ?? 0;
      final base = metric['duration'] ?? 0;
      final mode = option.modesParTroncon[index];
      ProfilTransport? profil;
      for (final item in profilsTransport) {
        if (item.transport == mode) {
          profil = item;
          break;
        }
      }
      if (profil == null || base <= 0) {
        min += base;
        max += base;
        profilsValides = false;
        continue;
      }
      final estimation = const CalculDureeTransportService().calculer(
        dureeRoutiereMinutes: base,
        nombreArrets: 1,
        profil: profil,
      );
      min += estimation.minMinutes;
      max += estimation.maxMinutes;
      profilsValides &= estimation.profilValideTerrain;
    }
    min += option.trajet.dureeCorrespondancesMin;
    max += option.trajet.dureeCorrespondancesMax;
    return {
      'distance': distance,
      'duration': (min + max) / 2,
      'durationMin': min,
      'durationMax': max,
      'profilsValidesTerrain': profilsValides ? 1 : 0,
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
    } catch (error) {
      // Les métriques ne doivent pas empêcher l'affichage du trajet local.
      debugPrint('Google Directions indisponible : $error');
      return {'distance': 0, 'duration': 0};
    }
  }
}

String _nomNormalise(String valeur) => valeur.toLowerCase().trim();

String _slug(String valeur) {
  return _nomNormalise(valeur)
      .replaceAll(RegExp(r'[àáâä]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
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

class _TrajetConstruit {
  const _TrajetConstruit({
    required this.troncons,
    required this.correspondances,
  });

  final List<Troncon> troncons;
  final List<Correspondance> correspondances;
}
