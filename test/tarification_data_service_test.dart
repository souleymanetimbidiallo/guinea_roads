import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/services/calcul_tarifaire_service.dart';
import 'package:guinea_roads/services/tarification_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge l’axe pilote depuis les assets', () async {
    final axes = await TarificationDataService().chargerAxes();

    expect(axes, hasLength(1));
    expect(axes.single.id, 'sonfonia-t7-lambanyi-ciment');
    expect(axes.single.limites, hasLength(3));
    expect(axes.single.reperes.single.position, 1.5);
    expect(axes.single.tranches, hasLength(2));
    expect(axes.single.tarifsValidesTerrain, isFalse);
    expect(
      axes.single.positionPourNom('Lambangni'),
      axes.single.positionPourNom('Lambanyi (Ciment-Guinée)'),
    );
  });

  test('le moteur calcule un tarif à partir des données chargées', () async {
    final axe = (await TarificationDataService().chargerAxes()).single;

    final resultat = const CalculTarifaireService().calculer(
      axe: axe,
      positionDepart: 0,
      positionArrivee: 1.5,
      transport: 'taxi',
    );

    expect(resultat.prixTotal, 4000);
    expect(resultat.nombreTranches, 2);
  });

  test('refuse un document JSON qui ne contient pas une liste', () {
    final service = TarificationDataService();

    expect(
      () => service.decoderAxes('{"id": "axe"}'),
      throwsFormatException,
    );
  });
}
