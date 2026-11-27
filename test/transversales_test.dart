import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';
import 'package:guinea_roads/models/correspondance.dart';
import 'package:guinea_roads/models/stop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TrajetController controller;
  late List<Stop> stops;

  setUp(() async {
    controller = TrajetController(firestoreLoader: () async => []);
    await controller.loadTronconsFromFirestore();
    stops = controller.extractAllStops();
  });

  Stop arret(String nom) => stops.firstWhere((stop) => stop.name == nom);

  test('relie l’Aéroport à Kipé par la Transversale 2, sans changement', () {
    final trajet =
        controller.getMultiAxeTrajet(arret('Aéroport'), arret('Kipé'))!;

    expect(trajet.troncons.map((t) => t.axe).toSet(), {'Transversale 2'});
    expect(trajet.correspondances, isEmpty);
  });

  test('passe de l’autoroute à Le Prince par la Transversale 9', () {
    final trajet =
        controller.getMultiAxeTrajet(arret('Km 36'), arret('Kagbelen'))!;

    expect(
      trajet.troncons.map((t) => t.axe),
      containsAll(['Autoroute Fidel Castro', 'Transversale 9', 'Le Prince']),
    );
    expect(trajet.correspondances.map((c) => c.lieu),
        containsAll(['Lansanayah', 'Cimenterie']));
    expect(trajet.correspondancesAConfirmer, isTrue);
  });

  test('rejoint une transversale par un taxi local payant', () {
    final trajet =
        controller.getMultiAxeTrajet(arret('Kobaya'), arret('Matoto'))!;

    final taxiLocal = trajet.correspondances.where(
      (c) => c.type == TypeCorrespondance.taxiLocal,
    );
    expect(taxiLocal, isNotEmpty);
    expect(trajet.coutCorrespondances, greaterThanOrEqualTo(2000));
    expect(trajet.correspondancesAConfirmer, isTrue);
  });

  test('marche de Concasseur au rond-point de Hamdallaye', () {
    final trajet =
        controller.getMultiAxeTrajet(arret('Concasseur'), arret('Bambeto'))!;

    expect(trajet.correspondances.map((c) => c.lieu), contains('Concasseur'));
    expect(trajet.troncons.last.arrivee.name, 'Bambeto');
  });

  test('chaque arrêt des tronçons est joignable depuis le Port', () {
    final port = arret('Port');
    final nomsTroncons = {
      for (final t in controller.allTroncons) ...[
        t.depart.name,
        t.arrivee.name,
      ],
    };
    final injoignables = stops
        .where((stop) => nomsTroncons.contains(stop.name))
        .where((stop) => stop.name != 'Port')
        .where((stop) => controller.getMultiAxeTrajet(port, stop) == null)
        .map((stop) => stop.name)
        .toSet();

    expect(injoignables, isEmpty);
  });

  test('respecte les modes de transport autorisés par axe', () {
    const axesPrincipaux = {
      'Autoroute Fidel Castro',
      'Le Prince',
      'Corniche Nord'
    };
    const tronconsTricycle = {
      'Le Prince|Dixinn|Hamdallaye',
      'Le Prince|Sonfonia T7|Cimenterie',
      'Le Prince|Cimenterie|Kagbelen',
    };
    for (final troncon in controller.allTroncons) {
      final cle =
          '${troncon.axe}|${troncon.depart.name}|${troncon.arrivee.name}';
      final prix = troncon.prixParType;
      expect(prix['taxi'], 2000, reason: cle);

      final tricycleAutorise =
          troncon.axe == 'Corniche Nord' || tronconsTricycle.contains(cle);
      expect(prix['tricycle'], tricycleAutorise ? 2500 : 0, reason: cle);

      if (!axesPrincipaux.contains(troncon.axe)) {
        expect(prix['minibus'], 0, reason: cle);
      }
    }
  });

  test('retrouve un arrêt par son nom de la grille officielle', () {
    expect(arret('Sonfonia T7').correspondARecherche('Sonfonia Gare'), isTrue);
    expect(arret('Concasseur').correspondARecherche('Concasseur Hamdallaye'),
        isTrue);
  });
}
