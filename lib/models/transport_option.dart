import 'trajet.dart';

class TransportOption {
  TransportOption({
    required this.trajet,
    required List<String> modesParTroncon,
  }) : modesParTroncon = List.unmodifiable(modesParTroncon) {
    if (trajet.troncons.length != modesParTroncon.length) {
      throw ArgumentError(
        'Un mode doit être défini pour chaque tronçon du trajet.',
      );
    }

    for (var index = 0; index < trajet.troncons.length; index++) {
      final prix = trajet.troncons[index].prixParType[modesParTroncon[index]];
      if (prix == null || prix <= 0) {
        throw ArgumentError(
          'Le mode ${modesParTroncon[index]} est indisponible '
          'sur le tronçon $index.',
        );
      }
    }
  }

  final Trajet trajet;
  final List<String> modesParTroncon;

  int get coutTotal {
    var total = 0;
    for (var index = 0; index < trajet.troncons.length; index++) {
      total += trajet.troncons[index].prixParType[modesParTroncon[index]] ?? 0;
    }
    return total;
  }

  List<String> get modesUtilises {
    final modes = <String>[];
    for (final mode in modesParTroncon) {
      if (!modes.contains(mode)) {
        modes.add(mode);
      }
    }
    return List.unmodifiable(modes);
  }

  int get nombreChangements {
    var changements = 0;
    for (var index = 1; index < modesParTroncon.length; index++) {
      if (modesParTroncon[index] != modesParTroncon[index - 1]) {
        changements++;
      }
    }
    return changements;
  }

  String get signature => modesParTroncon.join('|');
}
