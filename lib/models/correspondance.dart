import 'tarification.dart';

enum TypeCorrespondance {
  marche,
  taxiLocal,
  tricycle,
  minibus;

  factory TypeCorrespondance.fromJson(String valeur) {
    return switch (valeur) {
      'marche' => TypeCorrespondance.marche,
      'taxiLocal' => TypeCorrespondance.taxiLocal,
      'tricycle' => TypeCorrespondance.tricycle,
      'minibus' => TypeCorrespondance.minibus,
      _ => throw FormatException(
          'Type de correspondance inconnu : $valeur',
        ),
    };
  }
}

class Correspondance {
  final String id;
  final String axeDepartId;
  final String pointDepartId;
  final String axeArriveeId;
  final String pointArriveeId;
  final TypeCorrespondance type;
  final int dureeMinMinutes;
  final int dureeMaxMinutes;
  final int cout;
  final bool bidirectionnelle;
  final bool valideeTerrain;
  final String sourceValidation;
  final String instructions;

  const Correspondance({
    required this.id,
    required this.axeDepartId,
    required this.pointDepartId,
    required this.axeArriveeId,
    required this.pointArriveeId,
    required this.type,
    required this.dureeMinMinutes,
    required this.dureeMaxMinutes,
    required this.cout,
    this.bidirectionnelle = true,
    this.valideeTerrain = false,
    this.sourceValidation = '',
    this.instructions = '',
  })  : assert(dureeMinMinutes >= 0),
        assert(dureeMaxMinutes >= dureeMinMinutes),
        assert(cout >= 0);

  factory Correspondance.fromJson(Map<String, dynamic> json) {
    return Correspondance(
      id: json['id'] as String,
      axeDepartId: json['axeDepartId'] as String,
      pointDepartId: json['pointDepartId'] as String,
      axeArriveeId: json['axeArriveeId'] as String,
      pointArriveeId: json['pointArriveeId'] as String,
      type: TypeCorrespondance.fromJson(json['type'] as String),
      dureeMinMinutes:
          json['dureeMinMinutes'] as int? ?? json['dureeMinutes'] as int,
      dureeMaxMinutes:
          json['dureeMaxMinutes'] as int? ?? json['dureeMinutes'] as int,
      cout: json['cout'] as int,
      bidirectionnelle: json['bidirectionnelle'] as bool? ?? true,
      valideeTerrain: json['valideeTerrain'] as bool? ?? false,
      sourceValidation: json['sourceValidation'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
    );
  }

  String get lieu {
    final mots = pointDepartId.split(RegExp(r'[-_]'));
    return mots
        .where((mot) => mot.isNotEmpty)
        .map((mot) => '${mot[0].toUpperCase()}${mot.substring(1)}')
        .join(' ');
  }

  String get libelleType => switch (type) {
        TypeCorrespondance.marche => 'À pied',
        TypeCorrespondance.taxiLocal => 'Taxi local',
        TypeCorrespondance.tricycle => 'Tricycle',
        TypeCorrespondance.minibus => 'Minibus',
      };

  bool relie(String axeId, String pointId) {
    if (axeDepartId == axeId && pointDepartId == pointId) return true;
    return bidirectionnelle &&
        axeArriveeId == axeId &&
        pointArriveeId == pointId;
  }
}

class ReseauMobilite {
  final List<AxeTarifaire> axes;
  final List<Correspondance> correspondances;

  ReseauMobilite({
    required List<AxeTarifaire> axes,
    List<Correspondance> correspondances = const [],
  })  : axes = List.unmodifiable(axes),
        correspondances = List.unmodifiable(correspondances) {
    _valider();
  }

  List<Correspondance> correspondancesValideesDepuis(
    String axeId,
    String pointId,
  ) {
    return correspondances
        .where(
          (correspondance) =>
              correspondance.valideeTerrain &&
              correspondance.relie(axeId, pointId),
        )
        .toList(growable: false);
  }

  void _valider() {
    final axesParId = <String, AxeTarifaire>{};
    for (final axe in axes) {
      if (axesParId.containsKey(axe.id)) {
        throw ArgumentError('Identifiant d’axe dupliqué : ${axe.id}.');
      }
      axesParId[axe.id] = axe;
    }

    final correspondancesParId = <String>{};
    for (final correspondance in correspondances) {
      if (!correspondancesParId.add(correspondance.id)) {
        throw ArgumentError(
          'Identifiant de correspondance dupliqué : ${correspondance.id}.',
        );
      }
      if (correspondance.valideeTerrain &&
          correspondance.sourceValidation.trim().isEmpty) {
        throw ArgumentError(
          'Une correspondance validée doit indiquer sa source terrain.',
        );
      }
      _verifierPoint(
        axesParId,
        correspondance.axeDepartId,
        correspondance.pointDepartId,
      );
      _verifierPoint(
        axesParId,
        correspondance.axeArriveeId,
        correspondance.pointArriveeId,
      );
    }
  }

  void _verifierPoint(
    Map<String, AxeTarifaire> axesParId,
    String axeId,
    String pointId,
  ) {
    final axe = axesParId[axeId];
    if (axe == null) {
      throw ArgumentError('Axe de correspondance inconnu : $axeId.');
    }
    if (axe.pointPourId(pointId) == null) {
      throw ArgumentError(
        'Point de correspondance inconnu : $axeId/$pointId.',
      );
    }
  }
}
