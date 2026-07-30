import 'trajet.dart';
import 'tarification.dart';

class TransportOption {
  TransportOption({
    required this.trajet,
    required List<String> modesParTroncon,
    this.tarifV2,
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

    if (tarifV2 != null &&
        (modesUtilises.length != 1 ||
            modesUtilises.single != tarifV2!.transport)) {
      throw ArgumentError(
        'Le tarif V2 doit correspondre au transport unique de l’option.',
      );
    }
  }

  final Trajet trajet;
  final List<String> modesParTroncon;
  final TarifTrajet? tarifV2;

  int get coutTotal {
    if (tarifV2 != null) return tarifV2!.prixTotal;

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
