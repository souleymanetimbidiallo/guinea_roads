import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/correspondance.dart';
import 'package:guinea_roads/models/tarification.dart';
import 'package:guinea_roads/services/calcul_correspondance_service.dart';

void main() {
  final axeA = _axe('axe-a', 'hub-a');
  final axeB = _axe('axe-b', 'hub-b');

  test('expose uniquement les correspondances validées sur le terrain', () {
    final validee = _correspondance(
      id: 'validee',
      valideeTerrain: true,
    );
    final proposition = _correspondance(
      id: 'proposition',
      valideeTerrain: false,
    );
    final reseau = ReseauMobilite(
      axes: [axeA, axeB],
      correspondances: [validee, proposition],
    );

    expect(
      reseau.correspondancesValideesDepuis('axe-a', 'hub-a'),
      [validee],
    );
    expect(
      reseau.correspondancesValideesDepuis('axe-b', 'hub-b'),
      [validee],
    );
  });

  test('respecte le sens d’une correspondance non bidirectionnelle', () {
    final allerSimple = _correspondance(
      id: 'aller-simple',
      valideeTerrain: true,
      bidirectionnelle: false,
    );
    final reseau = ReseauMobilite(
      axes: [axeA, axeB],
      correspondances: [allerSimple],
    );

    expect(
      reseau.correspondancesValideesDepuis('axe-a', 'hub-a'),
      [allerSimple],
    );
    expect(
      reseau.correspondancesValideesDepuis('axe-b', 'hub-b'),
      isEmpty,
    );
  });

  test('refuse une correspondance vers un point inconnu', () {
    expect(
      () => ReseauMobilite(
        axes: [axeA, axeB],
        correspondances: [
          const Correspondance(
            id: 'invalide',
            axeDepartId: 'axe-a',
            pointDepartId: 'inconnu',
            axeArriveeId: 'axe-b',
            pointArriveeId: 'hub-b',
            type: TypeCorrespondance.marche,
            dureeMinMinutes: 5,
            dureeMaxMinutes: 5,
            cout: 0,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('additionne le coût et la durée des changements validés', () {
    final correspondances = [
      _correspondance(id: 'marche', valideeTerrain: true),
      const Correspondance(
        id: 'tricycle',
        axeDepartId: 'axe-a',
        pointDepartId: 'hub-a',
        axeArriveeId: 'axe-b',
        pointArriveeId: 'hub-b',
        type: TypeCorrespondance.tricycle,
        dureeMinMinutes: 8,
        dureeMaxMinutes: 10,
        cout: 1500,
        valideeTerrain: true,
        sourceValidation: 'Test terrain',
      ),
    ];

    final resultat =
        const CalculCorrespondanceService().calculer(correspondances);

    expect(resultat.coutTotal, 1500);
    expect(resultat.dureeTotaleMinMinutes, 13);
    expect(resultat.dureeTotaleMaxMinutes, 15);
    expect(resultat.nombreChangements, 2);
  });

  test('refuse de calculer une correspondance non validée', () {
    expect(
      () => const CalculCorrespondanceService().calculer([
        _correspondance(id: 'proposition', valideeTerrain: false),
      ]),
      throwsA(isA<CorrespondanceNonValideeException>()),
    );
  });
}

AxeTarifaire _axe(String id, String pointId) {
  return AxeTarifaire(
    id: id,
    nom: id,
    limites: [
      LimiteTarifaire(
        id: pointId,
        nom: pointId,
        latitude: 0,
        longitude: 0,
        position: 0,
      ),
      LimiteTarifaire(
        id: '$pointId-fin',
        nom: '$pointId-fin',
        latitude: 1,
        longitude: 1,
        position: 1,
      ),
    ],
    tranches: [
      TrancheTarifaire(
        id: 'tranche-$id',
        nom: 'Tranche $id',
        positionDebut: 0,
        positionFin: 1,
        tarifsParTransport: const {'taxi': 2000},
      ),
    ],
  );
}

Correspondance _correspondance({
  required String id,
  required bool valideeTerrain,
  bool bidirectionnelle = true,
}) {
  return Correspondance(
    id: id,
    axeDepartId: 'axe-a',
    pointDepartId: 'hub-a',
    axeArriveeId: 'axe-b',
    pointArriveeId: 'hub-b',
    type: TypeCorrespondance.marche,
    dureeMinMinutes: 5,
    dureeMaxMinutes: 5,
    cout: 0,
    bidirectionnelle: bidirectionnelle,
    valideeTerrain: valideeTerrain,
    sourceValidation: valideeTerrain ? 'Test terrain' : '',
  );
}
