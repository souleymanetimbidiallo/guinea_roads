class LimiteTarifaire {
  final String id;
  final String nom;
  final double latitude;
  final double longitude;
  final double position;
  final List<String> aliases;

  const LimiteTarifaire({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    required this.position,
    this.aliases = const [],
  });

  factory LimiteTarifaire.fromJson(Map<String, dynamic> json) {
    return LimiteTarifaire(
      id: json['id'] as String,
      nom: json['nom'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      position: (json['position'] as num).toDouble(),
      aliases: List<String>.from(json['aliases'] as List? ?? const []),
    );
  }
}

class RepereTarifaire {
  final String id;
  final String nom;
  final double latitude;
  final double longitude;
  final double position;
  final List<String> aliases;

  const RepereTarifaire({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    required this.position,
    this.aliases = const [],
  });

  factory RepereTarifaire.fromJson(Map<String, dynamic> json) {
    return RepereTarifaire(
      id: json['id'] as String,
      nom: json['nom'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      position: (json['position'] as num).toDouble(),
      aliases: List<String>.from(json['aliases'] as List? ?? const []),
    );
  }
}

class TrancheTarifaire {
  final String id;
  final String nom;
  final double positionDebut;
  final double positionFin;
  final Map<String, int> tarifsParTransport;

  TrancheTarifaire({
    required this.id,
    required this.nom,
    required this.positionDebut,
    required this.positionFin,
    required Map<String, int> tarifsParTransport,
  })  : assert(positionFin > positionDebut),
        tarifsParTransport = Map.unmodifiable(tarifsParTransport);

  factory TrancheTarifaire.fromJson(Map<String, dynamic> json) {
    return TrancheTarifaire(
      id: json['id'] as String,
      nom: json['nom'] as String,
      positionDebut: (json['positionDebut'] as num).toDouble(),
      positionFin: (json['positionFin'] as num).toDouble(),
      tarifsParTransport: Map<String, int>.from(
        json['tarifsParTransport'] as Map,
      ),
    );
  }

  bool estTraversee(double positionDepart, double positionArrivee) {
    final debut =
        positionDepart < positionArrivee ? positionDepart : positionArrivee;
    final fin =
        positionDepart < positionArrivee ? positionArrivee : positionDepart;

    return debut < positionFin && fin > positionDebut;
  }

  int? tarifPour(String transport) {
    final tarif = tarifsParTransport[transport];
    return tarif != null && tarif > 0 ? tarif : null;
  }
}

class AxeTarifaire {
  final String id;
  final String nom;
  final List<LimiteTarifaire> limites;
  final List<RepereTarifaire> reperes;
  final List<TrancheTarifaire> tranches;
  final String sourceTarifs;
  final bool tarifsValidesTerrain;

  AxeTarifaire({
    required this.id,
    required this.nom,
    required List<LimiteTarifaire> limites,
    required List<TrancheTarifaire> tranches,
    List<RepereTarifaire> reperes = const [],
    this.sourceTarifs = '',
    this.tarifsValidesTerrain = false,
  })  : limites = List.unmodifiable(limites),
        reperes = List.unmodifiable(reperes),
        tranches = List.unmodifiable(tranches) {
    _valider();
  }

  factory AxeTarifaire.fromJson(Map<String, dynamic> json) {
    return AxeTarifaire(
      id: json['id'] as String,
      nom: json['nom'] as String,
      limites: (json['limites'] as List)
          .map(
            (item) => LimiteTarifaire.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      reperes: (json['reperes'] as List? ?? const [])
          .map(
            (item) => RepereTarifaire.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      tranches: (json['tranches'] as List)
          .map(
            (item) => TrancheTarifaire.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      sourceTarifs: json['sourceTarifs'] as String? ?? '',
      tarifsValidesTerrain: json['tarifsValidesTerrain'] as bool? ?? false,
    );
  }

  double? positionPourNom(String nomPoint) {
    final nomNormalise = _normaliserNom(nomPoint);
    for (final limite in limites) {
      if (_correspondAuNom(limite.nom, limite.aliases, nomNormalise)) {
        return limite.position;
      }
    }
    for (final repere in reperes) {
      if (_correspondAuNom(repere.nom, repere.aliases, nomNormalise)) {
        return repere.position;
      }
    }
    return null;
  }

  void _valider() {
    if (tranches.isEmpty) {
      throw ArgumentError.value(tranches, 'tranches', 'ne peut pas être vide');
    }

    for (var index = 1; index < limites.length; index++) {
      if (limites[index - 1].position >= limites[index].position) {
        throw ArgumentError(
          'Les limites tarifaires doivent être ordonnées sans doublon.',
        );
      }
    }

    final tranchesOrdonnees = [...tranches]
      ..sort((a, b) => a.positionDebut.compareTo(b.positionDebut));
    for (var index = 1; index < tranchesOrdonnees.length; index++) {
      if (tranchesOrdonnees[index - 1].positionFin >
          tranchesOrdonnees[index].positionDebut) {
        throw ArgumentError(
          'Les tranches tarifaires d’un axe ne doivent pas se chevaucher.',
        );
      }
    }

    final positionMinimum = tranchesOrdonnees.first.positionDebut;
    final positionMaximum = tranchesOrdonnees.last.positionFin;
    for (final limite in limites) {
      if (limite.position < positionMinimum ||
          limite.position > positionMaximum) {
        throw ArgumentError(
          'Le point ${limite.nom} se trouve hors des tranches de l’axe.',
        );
      }
    }
    for (final repere in reperes) {
      if (repere.position < positionMinimum ||
          repere.position > positionMaximum) {
        throw ArgumentError(
          'Le point ${repere.nom} se trouve hors des tranches de l’axe.',
        );
      }
    }
  }
}

bool _correspondAuNom(
  String nom,
  List<String> aliases,
  String nomRecherche,
) {
  return _normaliserNom(nom) == nomRecherche ||
      aliases.any((alias) => _normaliserNom(alias) == nomRecherche);
}

String _normaliserNom(String valeur) => valeur.toLowerCase().trim();

class TarifTrajet {
  final String axeId;
  final String transport;
  final int prixTotal;
  final List<TrancheTarifaire> tranchesFacturees;

  const TarifTrajet({
    required this.axeId,
    required this.transport,
    required this.prixTotal,
    required this.tranchesFacturees,
  });

  int get nombreTranches => tranchesFacturees.length;
}
