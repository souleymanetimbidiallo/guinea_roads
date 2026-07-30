import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/services/calcul_duree_transport_service.dart';
import 'package:guinea_roads/services/profil_transport_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge les trois profils pilotes non validés', () async {
    final profils = await ProfilTransportDataService().charger();
    expect(profils.map((profil) => profil.transport),
        containsAll(['taxi', 'minibus', 'tricycle']));
    expect(profils.every((profil) => !profil.valideTerrain), isTrue);
  });

  test('différencie la durée selon le profil de transport', () async {
    final profils = await ProfilTransportDataService().charger();
    const service = CalculDureeTransportService();
    final taxi = service.calculer(
      dureeRoutiereMinutes: 30,
      nombreArrets: 3,
      profil: profils.singleWhere((profil) => profil.transport == 'taxi'),
    );
    final minibus = service.calculer(
      dureeRoutiereMinutes: 30,
      nombreArrets: 3,
      profil: profils.singleWhere((profil) => profil.transport == 'minibus'),
    );
    expect(minibus.minMinutes, greaterThan(taxi.minMinutes));
    expect(minibus.maxMinutes, greaterThan(taxi.maxMinutes));
    expect(taxi.profilValideTerrain, isFalse);
  });
}
