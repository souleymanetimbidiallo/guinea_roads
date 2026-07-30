import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/tarification.dart';
import 'package:guinea_roads/services/calcul_tarifaire_service.dart';

void main() {
  const service = CalculTarifaireService();
  late AxeTarifaire axePilote;

  setUp(() {
    axePilote = AxeTarifaire(
      id: 'sonfonia-lambanyi',
      nom: 'Sonfonia T7 – Lambanyi Ciment',
      limites: const [
        LimiteTarifaire(
          id: 'sonfonia-t7',
          nom: 'Sonfonia T7',
          latitude: 9.669334,
          longitude: -13.558108,
          position: 0,
        ),
        LimiteTarifaire(
          id: 'uglc',
          nom: 'UGLC',
          latitude: 9.6805,
          longitude: -13.579675,
          position: 1,
        ),
        LimiteTarifaire(
          id: 'lambanyi-ciment',
          nom: 'Lambanyi Ciment',
          latitude: 9.64364,
          longitude: -13.610821,
          position: 2,
        ),
      ],
      reperes: const [
        RepereTarifaire(
          id: 'kobayah-pharmacie-dara',
          nom: 'Kobayah Pharmacie Dara',
          latitude: 9.66,
          longitude: -13.59,
          position: 1.5,
        ),
      ],
      tranches: [
        TrancheTarifaire(
          id: 'sonfonia-uglc',
          nom: 'Sonfonia T7 – UGLC',
          positionDebut: 0,
          positionFin: 1,
          tarifsParTransport: const {
            'taxi': 2000,
            'minibus': 1500,
            'tricycle': 2500,
          },
        ),
        TrancheTarifaire(
          id: 'uglc-lambanyi',
          nom: 'UGLC – Lambanyi Ciment',
          positionDebut: 1,
          positionFin: 2,
          tarifsParTransport: const {
            'taxi': 2000,
            'minibus': 1500,
            'tricycle': 0,
          },
        ),
      ],
    );
  });

  test('facture une seule tranche entre deux limites voisines', () {
    final resultat = service.calculer(
      axe: axePilote,
      positionDepart: 0,
      positionArrivee: 1,
      transport: 'taxi',
    );

    expect(resultat.prixTotal, 2000);
    expect(resultat.nombreTranches, 1);
    expect(resultat.tranchesFacturees.single.id, 'sonfonia-uglc');
  });

  test('facture toutes les tranches traversées vers un repère', () {
    final resultat = service.calculer(
      axe: axePilote,
      positionDepart: 0,
      positionArrivee: 1.5,
      transport: 'minibus',
    );

    expect(resultat.prixTotal, 3000);
    expect(
      resultat.tranchesFacturees.map((tranche) => tranche.id),
      ['sonfonia-uglc', 'uglc-lambanyi'],
    );
  });

  test('calcule le même tarif dans le sens inverse', () {
    final aller = service.calculer(
      axe: axePilote,
      positionDepart: 0,
      positionArrivee: 1.5,
      transport: 'taxi',
    );
    final retour = service.calculer(
      axe: axePilote,
      positionDepart: 1.5,
      positionArrivee: 0,
      transport: 'taxi',
    );

    expect(retour.prixTotal, aller.prixTotal);
    expect(retour.nombreTranches, aller.nombreTranches);
  });

  test('ne facture rien lorsque le départ et l’arrivée sont identiques', () {
    final resultat = service.calculer(
      axe: axePilote,
      positionDepart: 1,
      positionArrivee: 1,
      transport: 'taxi',
    );

    expect(resultat.prixTotal, 0);
    expect(resultat.tranchesFacturees, isEmpty);
  });

  test('refuse un transport indisponible sur une tranche', () {
    expect(
      () => service.calculer(
        axe: axePilote,
        positionDepart: 0,
        positionArrivee: 1.5,
        transport: 'tricycle',
      ),
      throwsA(isA<TransportIndisponibleException>()),
    );
  });

  test('refuse des tranches qui se chevauchent', () {
    expect(
      () => AxeTarifaire(
        id: 'invalide',
        nom: 'Axe invalide',
        limites: const [],
        tranches: [
          TrancheTarifaire(
            id: 'a',
            nom: 'A',
            positionDebut: 0,
            positionFin: 2,
            tarifsParTransport: const {'taxi': 1000},
          ),
          TrancheTarifaire(
            id: 'b',
            nom: 'B',
            positionDebut: 1,
            positionFin: 3,
            tarifsParTransport: const {'taxi': 1000},
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
