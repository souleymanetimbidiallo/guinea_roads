import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/trajet_enregistre.dart';
import 'package:guinea_roads/services/favoris_service.dart';
import 'package:guinea_roads/services/historique_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sérialise et restaure un trajet', () {
    final trajet = TrajetEnregistre(
      depart: 'Port',
      arrivee: 'Kipé',
      modes: const ['minibus', 'taxi'],
      enregistreLe: DateTime.utc(2026, 7, 29, 10, 30),
    );

    final restored = TrajetEnregistre.fromStorage(trajet.toStorage());

    expect(restored, isNotNull);
    expect(restored!.depart, 'Port');
    expect(restored.arrivee, 'Kipé');
    expect(restored.modes, ['minibus', 'taxi']);
    expect(restored.enregistreLe, DateTime.utc(2026, 7, 29, 10, 30));
  });

  test('migre une ancienne entrée texte de l’historique', () {
    final restored = TrajetEnregistre.fromStorage('Port → Dixinn');

    expect(restored, isNotNull);
    expect(restored!.depart, 'Port');
    expect(restored.arrivee, 'Dixinn');
    expect(restored.modes, isEmpty);
  });

  test('déduplique et replace un trajet récent en tête', () async {
    final premier = _trajet('Port', 'Dixinn');
    final second = _trajet('Dixinn', 'Hamdallaye');

    await HistoriqueService.ajouterTrajet(premier);
    await HistoriqueService.ajouterTrajet(second);
    await HistoriqueService.ajouterTrajet(premier);
    final historique = await HistoriqueService.lireHistorique();

    expect(historique, hasLength(2));
    expect(historique.first.identifiant, premier.identifiant);
  });

  test('limite l’historique à vingt trajets', () async {
    for (var index = 0; index < 25; index++) {
      await HistoriqueService.ajouterTrajet(
        _trajet('Départ $index', 'Arrivée $index'),
      );
    }

    final historique = await HistoriqueService.lireHistorique();

    expect(historique, hasLength(HistoriqueService.nombreMaximum));
    expect(historique.first.depart, 'Départ 24');
  });

  test('ajoute puis retire un favori', () async {
    final trajet = _trajet('Port', 'Kipé');

    expect(await FavorisService.basculer(trajet), isTrue);
    expect(await FavorisService.contient('Port', 'Kipé'), isTrue);
    expect(await FavorisService.basculer(trajet), isFalse);
    expect(await FavorisService.lireFavoris(), isEmpty);
  });
}

TrajetEnregistre _trajet(String depart, String arrivee) {
  return TrajetEnregistre(
    depart: depart,
    arrivee: arrivee,
    modes: const ['taxi'],
  );
}
