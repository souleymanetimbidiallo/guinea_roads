import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/services/congestion_data_service.dart';
import 'package:guinea_roads/services/congestion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge des créneaux pilotes non validés', () async {
    final creneaux = await CongestionDataService().charger();

    expect(creneaux, hasLength(4));
    expect(creneaux.every((creneau) => !creneau.valideTerrain), isTrue);
  });

  test('applique la pointe de semaine uniquement pendant son créneau',
      () async {
    final creneaux = await CongestionDataService().charger();
    const service = CongestionService();

    final pointe = service.evaluer(
      date: DateTime(2026, 7, 30, 8),
      axe: 'Corniche Nord',
      creneaux: creneaux,
    );
    final horsPointe = service.evaluer(
      date: DateTime(2026, 7, 30, 12),
      axe: 'Corniche Nord',
      creneaux: creneaux,
    );

    expect(pointe.niveau, 0.7);
    expect(pointe.appliquee, isTrue);
    expect(pointe.valideeTerrain, isFalse);
    expect(horsPointe.niveau, 0);
    expect(horsPointe.appliquee, isFalse);
  });

  test('préfère le créneau spécifique à l’axe', () async {
    final creneaux = await CongestionDataService().charger();

    final resultat = const CongestionService().evaluer(
      date: DateTime(2026, 7, 30, 18),
      axe: 'Le Prince',
      creneaux: creneaux,
    );

    expect(resultat.niveau, 0.95);
    expect(resultat.appliquee, isTrue);
  });
}
