import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/segment_transport.dart';
import 'package:guinea_roads/models/stop.dart';
import 'package:guinea_roads/models/troncon.dart';
import 'package:guinea_roads/services/hub_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('convertit un tronçon V1 en segment sans y déplacer les tarifs', () {
    final segment = SegmentTransport.depuisTroncon(
      Troncon(
        depart: _stop('Hamdallaye'),
        arrivee: _stop('Bambeto'),
        axe: 'Le Prince',
        prixParType: const {'taxi': 2000, 'minibus': 1500, 'tricycle': 0},
      ),
    );
    expect(segment.axeId, 'le-prince');
    expect(segment.transportsDisponibles, {'taxi', 'minibus'});
  });

  test('charge Hamdallaye comme hub terrain entre deux axes', () async {
    final hubs = await HubDataService().charger();
    final hub = hubs.single;
    expect(hub.id, 'hamdallaye');
    expect(hub.points.map((point) => point.axeId),
        containsAll(['le-prince', 'corniche-nord']));
    expect(hub.valideTerrain, isTrue);
  });
}

Stop _stop(String nom) => Stop(
      id: nom.toLowerCase(),
      name: nom,
      latitude: 0,
      longitude: 0,
      order: 0,
      axe: 'test',
    );
