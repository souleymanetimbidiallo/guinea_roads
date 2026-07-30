class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final String axe;

  Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    required this.axe,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      name: normaliserNomAffiche(json['name'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      order: json['order'],
      axe: json['axe'],
    );
  }

  static String normaliserNomAffiche(String nom) {
    final nomNormalise = nom.toLowerCase().trim();
    if (nomNormalise == 'lambangni' ||
        nomNormalise == 'lambanyi ciment' ||
        nomNormalise == 'lambanyi ciment-guinée') {
      return 'Lambanyi (Ciment-Guinée)';
    }
    return nom;
  }

  bool correspondARecherche(String recherche) {
    final termes = <String>[
      name,
      if (name == 'Lambanyi (Ciment-Guinée)') ...[
        'Lambangni',
        'Lambanyi ciment',
        'Ciment Guinée',
      ],
    ];
    final requete = normaliserPourRecherche(recherche);
    return requete.isEmpty ||
        termes.any(
          (terme) => normaliserPourRecherche(terme).contains(requete),
        );
  }

  static String normaliserPourRecherche(String valeur) {
    return valeur
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[àáâä]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  }
}
