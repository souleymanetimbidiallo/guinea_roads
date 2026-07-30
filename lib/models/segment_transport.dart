import 'stop.dart';
import 'troncon.dart';

class SegmentTransport {
  SegmentTransport({
    required this.id,
    required this.axeId,
    required this.depart,
    required this.arrivee,
    required Iterable<String> transportsDisponibles,
    this.bidirectionnel = true,
    this.valideTerrain = false,
    this.sourceValidation = '',
  }) : transportsDisponibles = Set.unmodifiable(transportsDisponibles);

  final String id;
  final String axeId;
  final Stop depart;
  final Stop arrivee;
  final Set<String> transportsDisponibles;
  final bool bidirectionnel;
  final bool valideTerrain;
  final String sourceValidation;

  factory SegmentTransport.depuisTroncon(Troncon troncon) {
    final axeId = _slug(troncon.axe);
    return SegmentTransport(
      id: '$axeId-${_slug(troncon.depart.name)}-${_slug(troncon.arrivee.name)}',
      axeId: axeId,
      depart: troncon.depart,
      arrivee: troncon.arrivee,
      transportsDisponibles: troncon.prixParType.entries
          .where((entree) => entree.value > 0)
          .map((entree) => entree.key),
      sourceValidation: 'Migration depuis les tronçons V1',
    );
  }
}

String _slug(String valeur) => Stop.normaliserPourRecherche(valeur)
    .replaceAll(' ', '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
