import '../models/creneau_congestion.dart';

class EvaluationCongestion {
  const EvaluationCongestion({
    required this.niveau,
    required this.appliquee,
    required this.valideeTerrain,
  });

  final double niveau;
  final bool appliquee;
  final bool valideeTerrain;
}

class CongestionService {
  const CongestionService();

  EvaluationCongestion evaluer({
    required DateTime date,
    required String axe,
    required List<CreneauCongestion> creneaux,
  }) {
    final correspondants = creneaux
        .where((creneau) => creneau.correspond(date, axe))
        .toList(growable: false);
    if (correspondants.isEmpty) {
      return const EvaluationCongestion(
        niveau: 0,
        appliquee: false,
        valideeTerrain: true,
      );
    }

    final specifiques =
        correspondants.where((creneau) => creneau.axeId != null).toList();
    final retenus = specifiques.isNotEmpty ? specifiques : correspondants;
    final niveau = retenus
        .map((creneau) => creneau.niveau)
        .reduce((a, b) => a > b ? a : b);
    return EvaluationCongestion(
      niveau: niveau,
      appliquee: true,
      valideeTerrain: retenus.every((creneau) => creneau.valideTerrain),
    );
  }
}
