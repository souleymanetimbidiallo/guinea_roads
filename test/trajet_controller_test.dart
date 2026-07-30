import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';
import 'package:guinea_roads/models/correspondance.dart';
import 'package:guinea_roads/models/stop.dart';
import 'package:guinea_roads/models/tarification.dart';
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

  test('applique le tarif V2 aux points connus d’un axe pilote', () {
    final sonfonia = _stop('Sonfonia T7');
    final uglc = _stop('Université Lansana Conté');
    final controller = TrajetController()
      ..allTroncons = [_troncon(sonfonia, uglc)]
      ..axesTarifaires = [
        AxeTarifaire(
          id: 'axe-pilote',
          nom: 'Axe pilote',
          limites: const [
            LimiteTarifaire(
              id: 'sonfonia',
              nom: 'Sonfonia T7',
              latitude: 0,
              longitude: 0,
              position: 0,
            ),
            LimiteTarifaire(
              id: 'uglc',
              nom: 'UGLC',
              latitude: 0,
              longitude: 0,
              position: 1,
              aliases: ['Université Lansana Conté'],
            ),
          ],
          tranches: [
            TrancheTarifaire(
              id: 'sonfonia-uglc',
              nom: 'Sonfonia – UGLC',
              positionDebut: 0,
              positionFin: 1,
              tarifsParTransport: const {
                'taxi': 3000,
                'minibus': 2000,
                'tricycle': 1000,
              },
            ),
          ],
        ),
      ];

    final trajet = controller.getMultiAxeTrajet(sonfonia, uglc)!;
    final options = controller.getTransportOptions(trajet);

    expect(options, isNotEmpty);
    expect(options.every((option) => option.tarifV2 != null), isTrue);
    expect(options.first.coutTotal, 1000);
    expect(options.first.tarifV2!.nombreTranches, 1);
  });

  test('conserve le tarif V1 lorsque le trajet est hors axe pilote', () {
    final a = _stop('A');
    final b = _stop('B');
    final controller = TrajetController()..allTroncons = [_troncon(a, b)];

    final trajet = controller.getMultiAxeTrajet(a, b)!;
    final options = controller.getTransportOptions(trajet);

    expect(options.every((option) => option.tarifV2 == null), isTrue);
    expect(options.first.coutTotal, 500);
  });

  test('normalise l’ancien nom Lambangni sans changer ses coordonnées', () {
    final stop = Stop.fromJson({
      'id': 'lambangni',
      'name': 'Lambangni',
      'latitude': 9.64364,
      'longitude': -13.610821,
      'order': 2,
      'axe': 'Corniche Nord',
    });

    expect(stop.name, 'Lambanyi (Ciment-Guinée)');
    expect(stop.latitude, 9.64364);
    expect(stop.longitude, -13.610821);
  });

  test('recherche un arrêt sans dépendre des accents ou de l’ancien nom', () {
    final kipe = _stop('Kipé');
    final lambanyi = _stop('Lambanyi (Ciment-Guinée)');

    expect(kipe.correspondARecherche('kipe'), isTrue);
    expect(lambanyi.correspondARecherche('lambangni'), isTrue);
    expect(lambanyi.correspondARecherche('ciment guinee'), isTrue);
    expect(kipe.correspondARecherche('bambeto'), isFalse);
  });

  test('applique deux tranches sur le trajet pilote complet', () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );
    await controller.loadTronconsFromFirestore();
    final stops = controller.extractAllStops();
    final sonfonia = stops.singleWhere((stop) => stop.name == 'Sonfonia T7');
    final lambanyi = stops.singleWhere(
      (stop) => stop.name == 'Lambanyi (Ciment-Guinée)',
    );

    final trajet = controller.getMultiAxeTrajet(sonfonia, lambanyi)!;
    final options = controller.getTransportOptions(trajet);
    final taxi = options.singleWhere(
      (option) =>
          option.modesUtilises.length == 1 &&
          option.modesUtilises.single == 'taxi',
    );

    expect(taxi.tarifV2, isNotNull);
    expect(taxi.tarifV2!.nombreTranches, 2);
    expect(taxi.coutTotal, 4000);
  });

  test('expose un repère pilote sans modifier les tronçons V1', () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );
    await controller.loadTronconsFromFirestore();

    expect(controller.allTroncons, hasLength(18));
    expect(
      controller.extractAllStops().map((stop) => stop.name),
      contains('Kobayah Pharmacie Dara'),
    );
  });

  test('construit un trajet V2 jusqu’au repère Kobayah', () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );
    await controller.loadTronconsFromFirestore();
    final stops = controller.extractAllStops();
    final sonfonia = stops.singleWhere((stop) => stop.name == 'Sonfonia T7');
    final kobayah = stops.singleWhere(
      (stop) => stop.name == 'Kobayah Pharmacie Dara',
    );

    final trajet = controller.getMultiAxeTrajet(sonfonia, kobayah)!;
    final taxi = controller.getTransportOptions(trajet).singleWhere(
          (option) =>
              option.modesUtilises.length == 1 &&
              option.modesUtilises.single == 'taxi',
        );

    expect(trajet.troncons, hasLength(2));
    expect(
        trajet.troncons.first.arrivee.name, 'Université Général Lansana Conté');
    expect(taxi.tarifV2!.nombreTranches, 2);
    expect(taxi.coutTotal, 4000);
  });

  test('facture une tranche entre Kobayah et Lambanyi', () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );
    await controller.loadTronconsFromFirestore();
    final stops = controller.extractAllStops();
    final kobayah = stops.singleWhere(
      (stop) => stop.name == 'Kobayah Pharmacie Dara',
    );
    final lambanyi = stops.singleWhere(
      (stop) => stop.name == 'Lambanyi (Ciment-Guinée)',
    );

    final trajet = controller.getMultiAxeTrajet(kobayah, lambanyi)!;
    final taxi = controller.getTransportOptions(trajet).singleWhere(
          (option) =>
              option.modesUtilises.length == 1 &&
              option.modesUtilises.single == 'taxi',
        );

    expect(trajet.troncons, hasLength(1));
    expect(taxi.tarifV2!.nombreTranches, 1);
    expect(taxi.coutTotal, 2000);
  });

  test('utilise la correspondance piétonne validée à Hamdallaye', () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );
    await controller.loadTronconsFromFirestore();
    final stops = controller.extractAllStops();
    final kipe = stops.singleWhere((stop) => stop.name == 'Kipé');
    final bambeto = stops.singleWhere((stop) => stop.name == 'Bambeto');

    final trajet = controller.getMultiAxeTrajet(kipe, bambeto)!;

    expect(trajet.correspondances, hasLength(1));
    expect(trajet.correspondances.single.lieu, 'Hamdallaye');
    expect(trajet.correspondances.single.type, TypeCorrespondance.marche);
    expect(trajet.dureeCorrespondancesMin, 2);
    expect(trajet.dureeCorrespondancesMax, 4);
  });

  test('refuse un changement d’axe sans correspondance validée', () {
    final depart = _stopSurAxe('Départ', 'axe-a');
    final jonctionA = _stopSurAxe('Jonction', 'axe-a');
    final jonctionB = _stopSurAxe('Jonction', 'axe-b');
    final arrivee = _stopSurAxe('Arrivée', 'axe-b');
    final controller = TrajetController()
      ..allTroncons = [
        _tronconSurAxe(depart, jonctionA, 'Axe A'),
        _tronconSurAxe(jonctionB, arrivee, 'Axe B'),
      ];

    final trajets = controller.getAlternativeTrajets(depart, arrivee);

    expect(trajets, isEmpty);
    expect(
      controller.dernierEchec,
      EchecRechercheTrajet.correspondanceNonValidee,
    );
  });

  test('ignore les raccourcis invalides et trouve une alternative validée', () {
    final depart = _stopSurAxe('Départ', 'axe-a');
    final arrivee = _stopSurAxe('Arrivée', 'axe-b');
    final jonctionA = _stopSurAxe('Jonction', 'axe-a');
    final jonctionB = _stopSurAxe('Jonction', 'axe-b');
    final milieu = _stopSurAxe('Milieu', 'axe-b');
    final controller = TrajetController()
      ..allTroncons = [
        for (final nom in ['Court A', 'Court B', 'Court C']) ...[
          _tronconSurAxe(
            depart,
            _stopSurAxe(nom, 'axe-a'),
            'Axe A',
          ),
          _tronconSurAxe(
            _stopSurAxe(nom, 'axe-b'),
            arrivee,
            'Axe B',
          ),
        ],
        _tronconSurAxe(depart, jonctionA, 'Axe A'),
        _tronconSurAxe(jonctionB, milieu, 'Axe B'),
        _tronconSurAxe(milieu, arrivee, 'Axe B'),
      ]
      ..correspondances = [
        _correspondance(
          id: 'jonction-a-b',
          axeDepartId: 'axe-a',
          pointDepartId: 'jonction',
          axeArriveeId: 'axe-b',
          pointArriveeId: 'jonction',
        ),
      ];

    final trajets = controller.getAlternativeTrajets(
      depart,
      arrivee,
      maxTrajets: 1,
    );

    expect(trajets, hasLength(1));
    expect(trajets.single.troncons, hasLength(3));
    expect(trajets.single.correspondances.single.id, 'jonction-a-b');
    expect(controller.dernierEchec, EchecRechercheTrajet.aucun);
  });

  test('additionne plusieurs correspondances dans un même trajet', () {
    final depart = _stopSurAxe('Départ', 'axe-a');
    final jonction1A = _stopSurAxe('Jonction 1', 'axe-a');
    final jonction1B = _stopSurAxe('Jonction 1', 'axe-b');
    final jonction2B = _stopSurAxe('Jonction 2', 'axe-b');
    final jonction2C = _stopSurAxe('Jonction 2', 'axe-c');
    final arrivee = _stopSurAxe('Arrivée', 'axe-c');
    final controller = TrajetController()
      ..allTroncons = [
        _tronconSurAxe(depart, jonction1A, 'Axe A'),
        _tronconSurAxe(jonction1B, jonction2B, 'Axe B'),
        _tronconSurAxe(jonction2C, arrivee, 'Axe C'),
      ]
      ..correspondances = [
        _correspondance(
          id: 'jonction-1',
          axeDepartId: 'axe-a',
          pointDepartId: 'jonction-1',
          axeArriveeId: 'axe-b',
          pointArriveeId: 'jonction-1',
          dureeMin: 2,
          dureeMax: 4,
        ),
        _correspondance(
          id: 'jonction-2',
          axeDepartId: 'axe-b',
          pointDepartId: 'jonction-2',
          axeArriveeId: 'axe-c',
          pointArriveeId: 'jonction-2',
          dureeMin: 3,
          dureeMax: 6,
          cout: 500,
        ),
      ];

    final trajet = controller.getMultiAxeTrajet(depart, arrivee)!;
    final option = controller.getTransportOptions(trajet).first;

    expect(trajet.correspondances, hasLength(2));
    expect(trajet.dureeCorrespondancesMin, 5);
    expect(trajet.dureeCorrespondancesMax, 10);
    expect(trajet.coutCorrespondances, 500);
    expect(option.coutTotal, 2000);
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

Stop _stopSurAxe(String name, String axe) => Stop(
      id: '${name.toLowerCase()}-$axe',
      name: name,
      latitude: 0,
      longitude: 0,
      order: 0,
      axe: axe,
    );

Troncon _tronconSurAxe(Stop depart, Stop arrivee, String axe) => Troncon(
      depart: depart,
      arrivee: arrivee,
      axe: axe,
      prixParType: const {
        'taxi': 2000,
        'minibus': 1000,
        'tricycle': 500,
      },
    );

Correspondance _correspondance({
  required String id,
  required String axeDepartId,
  required String pointDepartId,
  required String axeArriveeId,
  required String pointArriveeId,
  int dureeMin = 1,
  int dureeMax = 1,
  int cout = 0,
}) =>
    Correspondance(
      id: id,
      axeDepartId: axeDepartId,
      pointDepartId: pointDepartId,
      axeArriveeId: axeArriveeId,
      pointArriveeId: pointArriveeId,
      type: TypeCorrespondance.marche,
      dureeMinMinutes: dureeMin,
      dureeMaxMinutes: dureeMax,
      cout: cout,
      valideeTerrain: true,
      sourceValidation: 'test terrain',
    );
