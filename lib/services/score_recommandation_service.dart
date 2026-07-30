class CandidatRecommandation {
  const CandidatRecommandation({
    required this.cout,
    required this.dureeMinutes,
    required this.changements,
  });

  final int cout;
  final double dureeMinutes;
  final int changements;
}

class ScoreRecommandation {
  const ScoreRecommandation({
    required this.valeur,
    required this.raison,
  });

  final double valeur;
  final String raison;
}

class ScoreRecommandationService {
  const ScoreRecommandationService();

  List<ScoreRecommandation> calculer(List<CandidatRecommandation> candidats) {
    if (candidats.isEmpty) return const [];
    final couts = candidats.map((item) => item.cout.toDouble());
    final durees = candidats.map((item) => item.dureeMinutes);
    final changements = candidats.map((item) => item.changements.toDouble());

    final minCout = couts.reduce((a, b) => a < b ? a : b);
    final maxCout = couts.reduce((a, b) => a > b ? a : b);
    final minDuree = durees.reduce((a, b) => a < b ? a : b);
    final maxDuree = durees.reduce((a, b) => a > b ? a : b);
    final minChangements = changements.reduce((a, b) => a < b ? a : b);
    final maxChangements = changements.reduce((a, b) => a > b ? a : b);

    double normaliser(double valeur, double min, double max) =>
        max == min ? 0 : (valeur - min) / (max - min);

    return candidats.map((candidat) {
      final cout = normaliser(candidat.cout.toDouble(), minCout, maxCout);
      final duree = normaliser(candidat.dureeMinutes, minDuree, maxDuree);
      final changementsNormalises = normaliser(
        candidat.changements.toDouble(),
        minChangements,
        maxChangements,
      );
      final penalite =
          duree * 0.40 + cout * 0.35 + changementsNormalises * 0.25;
      final raison = duree == 0 && cout == 0
          ? 'Rapide et économique'
          : changementsNormalises == 0 && duree <= 0.5
              ? 'Peu de changements et durée maîtrisée'
              : cout == 0
                  ? 'Option la plus économique'
                  : duree == 0
                      ? 'Option la plus rapide'
                      : 'Meilleur équilibre global';
      return ScoreRecommandation(
        valeur: (100 * (1 - penalite)).clamp(0, 100),
        raison: raison,
      );
    }).toList(growable: false);
  }
}
