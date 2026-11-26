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

  test('applique les tarifs de référence aux nouveaux tronçons', () {
    final nouveaux = controller.allTroncons.where(
      (t) => t.axe == 'Transversale 5' || t.axe == 'Madina – Kénien',
    );
    for (final troncon in nouveaux) {
      expect(troncon.prixParType,
          {'taxi': 2000, 'minibus': 1500, 'tricycle': 2500});
    }
  });

  test('retrouve un arrêt par son nom de la grille officielle', () {
    expect(arret('Sonfonia T7').correspondARecherche('Sonfonia Gare'), isTrue);
    expect(arret('Concasseur').correspondARecherche('Concasseur Hamdallaye'),
        isTrue);
  });
}
