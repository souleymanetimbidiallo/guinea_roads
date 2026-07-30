class PointHub {
  const PointHub({required this.axeId, required this.pointId});

  final String axeId;
  final String pointId;

  factory PointHub.fromJson(Map<String, dynamic> json) => PointHub(
        axeId: json['axeId'] as String,
        pointId: json['pointId'] as String,
      );
}

class HubMobilite {
  HubMobilite({
    required this.id,
    required this.nom,
    required Iterable<PointHub> points,
    required Iterable<String> correspondanceIds,
    this.valideTerrain = false,
    this.sourceValidation = '',
  })  : points = List.unmodifiable(points),
        correspondanceIds = List.unmodifiable(correspondanceIds) {
    if (this.points.length < 2) {
      throw ArgumentError('Un hub doit relier au moins deux points.');
    }
    if (valideTerrain && sourceValidation.trim().isEmpty) {
      throw ArgumentError('Un hub validé doit indiquer sa source terrain.');
    }
  }

  final String id;
  final String nom;
  final List<PointHub> points;
  final List<String> correspondanceIds;
  final bool valideTerrain;
  final String sourceValidation;

  factory HubMobilite.fromJson(Map<String, dynamic> json) => HubMobilite(
        id: json['id'] as String,
        nom: json['nom'] as String,
        points: (json['points'] as List)
            .map((item) => PointHub.fromJson(item as Map<String, dynamic>)),
        correspondanceIds: List<String>.from(json['correspondanceIds'] as List),
        valideTerrain: json['valideTerrain'] as bool? ?? false,
        sourceValidation: json['sourceValidation'] as String? ?? '',
      );
}
