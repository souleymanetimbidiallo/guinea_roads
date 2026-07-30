class ProfilTransport {
  const ProfilTransport({
    required this.transport,
    required this.facteurDureeMin,
    required this.facteurDureeMax,
    required this.attenteMinMinutes,
    required this.attenteMaxMinutes,
    required this.tempsParArretMinutes,
    required this.facteurCongestionMax,
    this.valideTerrain = false,
    this.source = '',
  });

  final String transport;
  final double facteurDureeMin;
  final double facteurDureeMax;
  final double attenteMinMinutes;
  final double attenteMaxMinutes;
  final double tempsParArretMinutes;
  final double facteurCongestionMax;
  final bool valideTerrain;
  final String source;

  factory ProfilTransport.fromJson(Map<String, dynamic> json) =>
      ProfilTransport(
        transport: json['transport'] as String,
        facteurDureeMin: (json['facteurDureeMin'] as num).toDouble(),
        facteurDureeMax: (json['facteurDureeMax'] as num).toDouble(),
        attenteMinMinutes: (json['attenteMinMinutes'] as num).toDouble(),
        attenteMaxMinutes: (json['attenteMaxMinutes'] as num).toDouble(),
        tempsParArretMinutes: (json['tempsParArretMinutes'] as num).toDouble(),
        facteurCongestionMax: (json['facteurCongestionMax'] as num).toDouble(),
        valideTerrain: json['valideTerrain'] as bool? ?? false,
        source: json['source'] as String? ?? '',
      );
}

class EstimationDureeTransport {
  const EstimationDureeTransport({
    required this.minMinutes,
    required this.maxMinutes,
    required this.profilValideTerrain,
  });

  final double minMinutes;
  final double maxMinutes;
  final bool profilValideTerrain;
}
