import '../models/correspondance.dart';

class PenalitesCorrespondance {
  final int coutTotal;
  final int dureeTotaleMinutes;
  final int nombreChangements;

  const PenalitesCorrespondance({
    required this.coutTotal,
    required this.dureeTotaleMinutes,
    required this.nombreChangements,
  });
}

class CorrespondanceNonValideeException implements Exception {
  final String correspondanceId;

  const CorrespondanceNonValideeException(this.correspondanceId);

  @override
  String toString() =>
      'CorrespondanceNonValideeException: $correspondanceId doit être '
      'validée sur le terrain.';
}

class CalculCorrespondanceService {
  const CalculCorrespondanceService();

  PenalitesCorrespondance calculer(Iterable<Correspondance> correspondances) {
    var coutTotal = 0;
    var dureeTotaleMinutes = 0;
    var nombreChangements = 0;

    for (final correspondance in correspondances) {
      if (!correspondance.valideeTerrain) {
        throw CorrespondanceNonValideeException(correspondance.id);
      }
      coutTotal += correspondance.cout;
      dureeTotaleMinutes += correspondance.dureeMinutes;
      nombreChangements++;
    }

    return PenalitesCorrespondance(
      coutTotal: coutTotal,
      dureeTotaleMinutes: dureeTotaleMinutes,
      nombreChangements: nombreChangements,
    );
  }
}
