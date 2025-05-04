import 'troncon.dart';

class Trajet {
  final List<Troncon> troncons;

  Trajet({required this.troncons});

  int getTotalCost(String type) {
    return troncons.fold(0, (total, t) => total + (t.prixParType[type] ?? 0));
  }
}
extension TrajetCostExtension on Trajet {
  Map<String, int> getTotalCosts() {
    int taxi = 0;
    int minibus = 0;
    int tricycle = 0;

    for (final troncon in troncons) {
      taxi += troncon.prixParType["taxi"] ?? 0;
      minibus += troncon.prixParType["minibus"] ?? 0;
      tricycle += troncon.prixParType["tricycle"] ?? 0;
    }

    return {
      "taxi": taxi,
      "minibus": minibus,
      "tricycle": tricycle,
    };
  }

  List<String> getActiveModes() {
    final couts = getTotalCosts();
    return couts.entries.where((e) => e.value > 0).map((e) => e.key).toList();
  }

  Map<Troncon, String> assignModes(List<String> modes) {
    Map<Troncon, String> mapping = {};
    int modeIndex = 0;
    for (int i = 0; i < troncons.length; i++) {
      mapping[troncons[i]] = modes[modeIndex];
      // changer de mode si c’est un nouveau segment (optionnel selon logique)
      if (i < troncons.length - 1 &&
          modes.length > modeIndex + 1 &&
          troncons[i + 1].prixParType[modes[modeIndex]] == 0) {
        modeIndex++;
      }
    }
    return mapping;
  }
}

