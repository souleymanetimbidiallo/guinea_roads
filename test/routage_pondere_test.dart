import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/correspondance.dart';
import 'package:guinea_roads/models/segment_transport.dart';
import 'package:guinea_roads/models/stop.dart';
import 'package:guinea_roads/services/routage_pondere_service.dart';

void main() {
  test('Dijkstra emprunte uniquement une correspondance validée', () {
    final resultat = const RoutagePondereService().calculer(
      segments: [
        _segment('a', 'axe-a', 'Départ', 'Hub'),
        _segment('b', 'axe-b', 'Hub', 'Arrivée'),
      ],
      correspondances: const [
        Correspondance(
          id: 'hub-a-b',
          axeDepartId: 'axe-a',
          pointDepartId: 'hub',
          axeArriveeId: 'axe-b',
          pointArriveeId: 'hub',
          type: TypeCorrespondance.marche,
          dureeMinMinutes: 2,
          dureeMaxMinutes: 4,
          cout: 0,
          valideeTerrain: true,
          sourceValidation: 'test terrain',
        ),
      ],
      depart: 'Départ',
      arrivee: 'Arrivée',
    );

    expect(resultat, isNotNull);
    expect(resultat!.segments.map((item) => item.segmentId), ['a', 'b']);
    expect(resultat.correspondances.single.id, 'hub-a-b');
  });

  test('Dijkstra utilise une correspondance à confirmer faute de mieux', () {
    final resultat = const RoutagePondereService().calculer(
      segments: [
        _segment('a', 'axe-a', 'Départ', 'Hub'),
        _segment('b', 'axe-b', 'Hub', 'Arrivée'),
      ],
      correspondances: const [
        Correspondance(
          id: 'hub-a-b',
          axeDepartId: 'axe-a',
          pointDepartId: 'hub',
          axeArriveeId: 'axe-b',
          pointArriveeId: 'hub',
          type: TypeCorrespondance.marche,
          dureeMinMinutes: 2,
          dureeMaxMinutes: 4,
          cout: 0,
        ),
      ],
      depart: 'Départ',
      arrivee: 'Arrivée',
    );
    expect(resultat, isNotNull);
    expect(resultat!.correspondances.single.aConfirmer, isTrue);
  });

  test('Dijkstra préfère une correspondance validée à une à confirmer', () {
    final resultat = const RoutagePondereService().calculer(
      segments: [
        _segment('a', 'axe-a', 'Départ', 'Hub validé'),
        _segment('b', 'axe-b', 'Hub validé', 'Arrivée'),
        _segment('c', 'axe-a', 'Départ', 'Hub pilote'),
        _segment('d', 'axe-b', 'Hub pilote', 'Arrivée'),
      ],
      correspondances: const [
        Correspondance(
          id: 'pilote',
          axeDepartId: 'axe-a',
          pointDepartId: 'hub-pilote',
          axeArriveeId: 'axe-b',
          pointArriveeId: 'hub-pilote',
          type: TypeCorrespondance.marche,
          dureeMinMinutes: 1,
          dureeMaxMinutes: 2,
          cout: 0,
        ),
        Correspondance(
          id: 'validee',
          axeDepartId: 'axe-a',
          pointDepartId: 'hub-valide',
          axeArriveeId: 'axe-b',
          pointArriveeId: 'hub-valide',
          type: TypeCorrespondance.marche,
          dureeMinMinutes: 3,
          dureeMaxMinutes: 5,
          cout: 0,
          valideeTerrain: true,
          sourceValidation: 'Test terrain',
        ),
      ],
      depart: 'Départ',
      arrivee: 'Arrivée',
    );
    expect(resultat!.correspondances.single.id, 'validee');
  });

  test('Dijkstra refuse un changement d’axe sans aucune correspondance', () {
    final resultat = const RoutagePondereService().calculer(
      segments: [
        _segment('a', 'axe-a', 'Départ', 'Hub'),
        _segment('b', 'axe-b', 'Hub', 'Arrivée'),
      ],
      correspondances: const [],
      depart: 'Départ',
      arrivee: 'Arrivée',
    );
    expect(resultat, isNull);
  });
}

SegmentTransport _segment(
  String id,
  String axe,
  String depart,
  String arrivee,
) =>
    SegmentTransport(
      id: id,
      axeId: axe,
      depart: _stop(depart),
      arrivee: _stop(arrivee),
      transportsDisponibles: const ['taxi'],
    );

Stop _stop(String nom) => Stop(
      id: nom.toLowerCase(),
      name: nom,
      latitude: 0,
      longitude: 0,
      order: 0,
      axe: 'test',
    );
