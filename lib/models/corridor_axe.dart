import 'stop.dart';

class PointControleAxe {
  const PointControleAxe({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    required this.ordre,
  });

  final String id;
  final String nom;
  final double latitude;
  final double longitude;
  final int ordre;

  factory PointControleAxe.fromJson(Map<String, dynamic> json) =>
      PointControleAxe(
        id: json['id'] as String,
        nom: json['nom'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        ordre: json['ordre'] as int,
      );
}

class CorridorAxe {
  CorridorAxe({
    required this.axeId,
    required this.nom,
    required Iterable<PointControleAxe> points,
    this.valideTerrain = false,
    this.source = '',
  }) : points = List.unmodifiable(
          points.toList()..sort((a, b) => a.ordre.compareTo(b.ordre)),
        );

  final String axeId;
  final String nom;
  final List<PointControleAxe> points;
  final bool valideTerrain;
  final String source;

  factory CorridorAxe.fromJson(Map<String, dynamic> json) => CorridorAxe(
        axeId: json['axeId'] as String,
        nom: json['nom'] as String,
        points: (json['points'] as List).map(
          (item) => PointControleAxe.fromJson(item as Map<String, dynamic>),
        ),
        valideTerrain: json['valideTerrain'] as bool? ?? false,
        source: json['source'] as String? ?? '',
      );

  List<PointControleAxe> pointsEntre(String depart, String arrivee) {
    final departNormalise = Stop.normaliserPourRecherche(depart);
    final arriveeNormalisee = Stop.normaliserPourRecherche(arrivee);
    final debut = points.indexWhere(
      (point) => Stop.normaliserPourRecherche(point.nom) == departNormalise,
    );
    final fin = points.indexWhere(
      (point) => Stop.normaliserPourRecherche(point.nom) == arriveeNormalisee,
    );
    if (debut < 0 || fin < 0) return const [];
    if (debut <= fin) return points.sublist(debut, fin + 1);
    return points.sublist(fin, debut + 1).reversed.toList(growable: false);
  }
}
