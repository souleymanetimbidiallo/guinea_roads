import '../models/tarification.dart';

class TransportIndisponibleException implements Exception {
  final String transport;
  final String tranche;

  const TransportIndisponibleException(this.transport, this.tranche);

  @override
  String toString() =>
      'TransportIndisponibleException: $transport est indisponible sur '
      '$tranche.';
}

class CalculTarifaireService {
  const CalculTarifaireService();

  TarifTrajet calculer({
    required AxeTarifaire axe,
    required double positionDepart,
    required double positionArrivee,
    required String transport,
  }) {
    if (positionDepart == positionArrivee) {
      return TarifTrajet(
        axeId: axe.id,
        transport: transport,
        prixTotal: 0,
        tranchesFacturees: const [],
      );
    }

    final tranches = axe.tranches
        .where(
          (tranche) => tranche.estTraversee(positionDepart, positionArrivee),
        )
        .toList()
      ..sort((a, b) => a.positionDebut.compareTo(b.positionDebut));

    if (tranches.isEmpty) {
      throw ArgumentError(
        'Les positions du trajet ne traversent aucune tranche de ${axe.nom}.',
      );
    }

    var prixTotal = 0;
    for (final tranche in tranches) {
      final tarif = tranche.tarifPour(transport);
      if (tarif == null) {
        throw TransportIndisponibleException(transport, tranche.nom);
      }
      prixTotal += tarif;
    }

    return TarifTrajet(
      axeId: axe.id,
      transport: transport,
      prixTotal: prixTotal,
      tranchesFacturees: List.unmodifiable(tranches),
    );
  }
}
