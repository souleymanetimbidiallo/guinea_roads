import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';
import 'package:guinea_roads/services/partage_trajet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rédige un itinéraire lisible à partager', () async {
    final controller = TrajetController(firestoreLoader: () async => []);
    await controller.loadTronconsFromFirestore();
    final stops = controller.extractAllStops();
    final trajet = controller.getMultiAxeTrajet(
      stops.firstWhere((s) => s.name == 'Km 36'),
      stops.firstWhere((s) => s.name == 'Kagbelen'),
    )!;

    final texte = texteDePartage(
      trajet: trajet,
      modes: List.filled(trajet.troncons.length, 'taxi'),
      prixTotal: 6000,
      duree: '35–52 min',
      distanceKm: 12.4,
    );

    expect(
      texte,
      'Trajet Km 36 → Kagbelen\n'
      '6 000 GNF · 35–52 min · 12.4 km\n'
      '\n'
      '1. Taxi (Autoroute Fidel Castro) : Km 36 → Lansanayah · 1 tronçon · 2 000 GNF\n'
      '   Changement à Lansanayah : à pied, 1–3 min\n'
      '2. Taxi (Transversale 9) : Lansanayah → Cimenterie · 1 tronçon · 2 000 GNF\n'
      '   Changement à Cimenterie : à pied, 1–3 min\n'
      '3. Taxi (Le Prince) : Cimenterie → Kagbelen · 1 tronçon · 2 000 GNF\n'
      '\n'
      'Estimations à confirmer sur le terrain. Calculé avec Guinea Roads.',
    );
  });
}
