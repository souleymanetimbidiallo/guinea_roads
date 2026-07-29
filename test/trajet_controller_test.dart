import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';
import 'package:guinea_roads/models/stop.dart';
import 'package:guinea_roads/models/troncon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge les données locales lorsque Firestore retourne une liste vide',
      () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );

    await controller.loadTronconsFromFirestore();

    expect(controller.allTroncons, isNotEmpty);
    expect(controller.loadedFromLocalData, isTrue);
  });

  test('charge les données locales lorsque Firestore échoue', () async {
    final controller = TrajetController(
      firestoreLoader: () async => throw Exception('hors connexion'),
    );

    await controller.loadTronconsFromFirestore();

    expect(controller.allTroncons, isNotEmpty);
    expect(controller.loadedFromLocalData, isTrue);
  });

  test('retourne plusieurs chemins simples classés par nombre de tronçons', () {
    final a = _stop('A');
    final b = _stop('B');
    final c = _stop('C');
    final d = _stop('D');
    final controller = TrajetController()
      ..allTroncons = [
        _troncon(a, b),
        _troncon(b, d),
        _troncon(a, c),
        _troncon(c, d),
        _troncon(b, c),
      ];

    final trajets = controller.getAlternativeTrajets(a, d);

    expect(trajets, hasLength(3));
    expect(
      trajets.map((trajet) => trajet.troncons.length),
      orderedEquals([2, 2, 3]),
    );
    expect(
      trajets
          .map(
            (trajet) => [
              trajet.troncons.first.depart.name,
              ...trajet.troncons.map((troncon) => troncon.arrivee.name),
            ].join('>'),
          )
          .toSet()
          .length,
      3,
    );
  });

  test('limite le nombre de chemins alternatifs demandé', () {
    final a = _stop('A');
    final b = _stop('B');
    final c = _stop('C');
    final d = _stop('D');
    final controller = TrajetController()
      ..allTroncons = [
        _troncon(a, b),
        _troncon(b, d),
        _troncon(a, c),
        _troncon(c, d),
      ];

    final trajets = controller.getAlternativeTrajets(a, d, maxTrajets: 1);

    expect(trajets, hasLength(1));
    expect(controller.getMultiAxeTrajet(a, d), isNotNull);
  });

  test('ne boucle pas lorsque le graphe contient un cycle', () {
    final a = _stop('A');
    final b = _stop('B');
    final c = _stop('C');
    final controller = TrajetController()
      ..allTroncons = [
        _troncon(a, b),
        _troncon(b, c),
        _troncon(c, a),
      ];

    final trajets = controller.getAlternativeTrajets(a, c);

    expect(trajets, hasLength(2));
    expect(
      trajets.every((trajet) => trajet.troncons.length <= 2),
      isTrue,
    );
  });
}

Stop _stop(String name) => Stop(
      id: name.toLowerCase(),
      name: name,
      latitude: 0,
      longitude: 0,
      order: 0,
      axe: 'test',
    );

Troncon _troncon(Stop depart, Stop arrivee) => Troncon(
      depart: depart,
      arrivee: arrivee,
      axe: 'test',
      prixParType: const {
        'taxi': 2000,
        'minibus': 1000,
        'tricycle': 500,
      },
    );
