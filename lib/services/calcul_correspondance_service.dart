import '../models/correspondance.dart';

class PenalitesCorrespondance {
  final int coutTotal;
  final int dureeTotaleMinMinutes;
  final int dureeTotaleMaxMinutes;
  final int nombreChangements;

  const PenalitesCorrespondance({
    required this.coutTotal,
    required this.dureeTotaleMinMinutes,
    required this.dureeTotaleMaxMinutes,
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
    var dureeTotaleMinMinutes = 0;
    var dureeTotaleMaxMinutes = 0;
    var nombreChangements = 0;

    for (final correspondance in correspondances) {
      if (!correspondance.valideeTerrain) {
        throw CorrespondanceNonValideeException(correspondance.id);
      }
      coutTotal += correspondance.cout;
      dureeTotaleMinMinutes += correspondance.dureeMinMinutes;
      dureeTotaleMaxMinutes += correspondance.dureeMaxMinutes;
      nombreChangements++;
    }

    return PenalitesCorrespondance(
      coutTotal: coutTotal,
      dureeTotaleMinMinutes: dureeTotaleMinMinutes,
      dureeTotaleMaxMinutes: dureeTotaleMaxMinutes,
      nombreChangements: nombreChangements,
    );
  }
}
