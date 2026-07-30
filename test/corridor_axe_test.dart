import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/services/corridor_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge trois corridors pilotes non validés', () async {
    final corridors = await CorridorDataService().charger();
    expect(corridors, hasLength(3));
    expect(corridors.every((corridor) => !corridor.valideTerrain), isTrue);
  });

  test('extrait les points de contrôle dans les deux sens', () async {
    final corridor = (await CorridorDataService().charger())
        .singleWhere((item) => item.axeId == 'le-prince');
    final aller = corridor.pointsEntre('Dixinn', 'Bambeto');
    final retour = corridor.pointsEntre('Bambeto', 'Dixinn');
    expect(
        aller.map((point) => point.nom), ['Dixinn', 'Hamdallaye', 'Bambeto']);
    expect(
        retour.map((point) => point.nom), ['Bambeto', 'Hamdallaye', 'Dixinn']);
  });
}
