import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/services/score_recommandation_service.dart';

void main() {
  test('préfère le meilleur compromis entre durée prix et changements', () {
    final scores = const ScoreRecommandationService().calculer(const [
      CandidatRecommandation(cout: 5000, dureeMinutes: 30, changements: 0),
      CandidatRecommandation(cout: 3000, dureeMinutes: 45, changements: 1),
      CandidatRecommandation(cout: 4000, dureeMinutes: 35, changements: 0),
    ]);

    expect(scores[2].valeur, greaterThan(scores[0].valeur));
    expect(scores[2].valeur, greaterThan(scores[1].valeur));
  });

  test('attribue le même score à des options identiques', () {
    final scores = const ScoreRecommandationService().calculer(const [
      CandidatRecommandation(cout: 3000, dureeMinutes: 30, changements: 0),
      CandidatRecommandation(cout: 3000, dureeMinutes: 30, changements: 0),
    ]);
    expect(scores[0].valeur, scores[1].valeur);
  });
}
