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

  test('Dijkstra refuse une correspondance non validée', () {
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
