import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/correspondance.dart';
import 'package:guinea_roads/services/calcul_correspondance_service.dart';
import 'package:guinea_roads/services/correspondance_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge la correspondance terrain de Hamdallaye', () async {
    final correspondances = await CorrespondanceDataService().charger();
    final hamdallaye = correspondances.single;

    expect(hamdallaye.id, 'hamdallaye-le-prince-corniche-nord');
    expect(hamdallaye.type, TypeCorrespondance.marche);
    expect(hamdallaye.dureeMinMinutes, 2);
    expect(hamdallaye.dureeMaxMinutes, 4);
    expect(hamdallaye.cout, 0);
    expect(hamdallaye.bidirectionnelle, isTrue);
    expect(hamdallaye.valideeTerrain, isTrue);
    expect(
      hamdallaye.instructions,
      'Contourner le rond-point selon le point d’arrivée.',
    );
  });

  test('conserve la fourchette dans le calcul des pénalités', () async {
    final correspondances = await CorrespondanceDataService().charger();

    final resultat =
        const CalculCorrespondanceService().calculer(correspondances);

    expect(resultat.coutTotal, 0);
    expect(resultat.dureeTotaleMinMinutes, 2);
    expect(resultat.dureeTotaleMaxMinutes, 4);
    expect(resultat.nombreChangements, 1);
  });
}
