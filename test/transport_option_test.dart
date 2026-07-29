import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';
import 'package:guinea_roads/models/stop.dart';
import 'package:guinea_roads/models/trajet.dart';
import 'package:guinea_roads/models/transport_option.dart';
import 'package:guinea_roads/models/troncon.dart';

void main() {
  final a = _stop('a');
  final b = _stop('b');
  final c = _stop('c');
  final trajet = Trajet(
    troncons: [
      _troncon(a, b, taxi: 2000, minibus: 1500),
      _troncon(b, c, taxi: 2000, tricycle: 1000),
    ],
  );

  test('calcule le prix avec exactement un mode par tronçon', () {
    final option = TransportOption(
      trajet: trajet,
      modesParTroncon: const ['minibus', 'tricycle'],
    );

    expect(option.coutTotal, 2500);
    expect(option.modesUtilises, ['minibus', 'tricycle']);
    expect(option.nombreChangements, 1);
  });

  test('refuse un mode absent sur un tronçon', () {
    expect(
      () => TransportOption(
        trajet: trajet,
        modesParTroncon: const ['tricycle', 'taxi'],
      ),
      throwsArgumentError,
    );
  });

  test('génère des variantes valides triées par prix', () {
    final options = TrajetController().getTransportOptions(trajet);

    expect(options, isNotEmpty);
    expect(options.first.modesParTroncon, ['minibus', 'tricycle']);
    expect(options.first.coutTotal, 2500);
    expect(
      options.every(
        (option) =>
            option.modesParTroncon.length == trajet.troncons.length &&
            option.coutTotal > 0,
      ),
      isTrue,
    );
    expect(
      options.map((option) => option.signature).toSet().length,
      options.length,
    );
  });
}

Stop _stop(String name) {
  return Stop(
    id: name,
    name: name,
    latitude: 0,
    longitude: 0,
    order: 0,
    axe: 'test',
  );
}

Troncon _troncon(
  Stop depart,
  Stop arrivee, {
  int taxi = 0,
  int minibus = 0,
  int tricycle = 0,
}) {
  return Troncon(
    depart: depart,
    arrivee: arrivee,
    axe: 'test',
    prixParType: {
      'taxi': taxi,
      'minibus': minibus,
      'tricycle': tricycle,
    },
  );
}
