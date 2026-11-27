import '../models/correspondance.dart';

class PenalitesCorrespondance {
  final int coutTotal;
  final int dureeTotaleMinMinutes;
  final int dureeTotaleMaxMinutes;
  final int nombreChangements;

  /// Nombre de correspondances qui restent à confirmer sur le terrain.
  final int nombreAConfirmer;

  const PenalitesCorrespondance({
    required this.coutTotal,
    required this.dureeTotaleMinMinutes,
    required this.dureeTotaleMaxMinutes,
    required this.nombreChangements,
    this.nombreAConfirmer = 0,
  });
}

class CalculCorrespondanceService {
  const CalculCorrespondanceService();

  PenalitesCorrespondance calculer(Iterable<Correspondance> correspondances) {
    var coutTotal = 0;
    var dureeTotaleMinMinutes = 0;
    var dureeTotaleMaxMinutes = 0;
    var nombreChangements = 0;
    var nombreAConfirmer = 0;

    for (final correspondance in correspondances) {
      if (correspondance.aConfirmer) nombreAConfirmer++;
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
      nombreAConfirmer: nombreAConfirmer,
    );
  }
}
