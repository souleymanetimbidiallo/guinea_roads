import '../models/correspondance.dart';
import '../models/segment_transport.dart';
import '../models/stop.dart';

class EtapeSegmentPondere {
  const EtapeSegmentPondere({required this.segmentId, required this.inverse});
  final String segmentId;
  final bool inverse;
}

class ResultatRoutagePondere {
  const ResultatRoutagePondere({
    required this.segments,
    required this.correspondances,
    required this.poids,
  });

  final List<EtapeSegmentPondere> segments;
  final List<Correspondance> correspondances;
  final double poids;
}

class RoutagePondereService {
  const RoutagePondereService();

  ResultatRoutagePondere? calculer({
    required Iterable<SegmentTransport> segments,
    required Iterable<Correspondance> correspondances,
    required String depart,
    required String arrivee,
  }) {
    final graphe = <String, List<_Arc>>{};
    final noeudsDepart = <String>{};
    final noeudsArrivee = <String>{};
    final departId = _slug(depart);
    final arriveeId = _slug(arrivee);

    for (final segment in segments) {
      final from = '${segment.axeId}|${_slug(segment.depart.name)}';
      final to = '${segment.axeId}|${_slug(segment.arrivee.name)}';
      if (_slug(segment.depart.name) == departId) noeudsDepart.add(from);
      if (_slug(segment.arrivee.name) == departId) noeudsDepart.add(to);
      if (_slug(segment.depart.name) == arriveeId) noeudsArrivee.add(from);
      if (_slug(segment.arrivee.name) == arriveeId) noeudsArrivee.add(to);
      graphe.putIfAbsent(from, () => []).add(
            _Arc.segment(to, segment.id, inverse: false),
          );
      if (segment.bidirectionnel) {
        graphe.putIfAbsent(to, () => []).add(
              _Arc.segment(from, segment.id, inverse: true),
            );
      }
    }

    for (final correspondance
        in correspondances.where((item) => item.valideeTerrain)) {
      final from =
          '${correspondance.axeDepartId}|${correspondance.pointDepartId}';
      final to =
          '${correspondance.axeArriveeId}|${correspondance.pointArriveeId}';
      final poids = 1 +
          (correspondance.dureeMinMinutes + correspondance.dureeMaxMinutes) /
              20 +
          correspondance.cout / 5000;
      graphe.putIfAbsent(from, () => []).add(
            _Arc.correspondance(to, correspondance, poids),
          );
      if (correspondance.bidirectionnelle) {
        graphe.putIfAbsent(to, () => []).add(
              _Arc.correspondance(from, correspondance, poids),
            );
      }
    }

    if (noeudsDepart.isEmpty || noeudsArrivee.isEmpty) return null;
    final distances = <String, double>{
      for (final noeud in noeudsDepart) noeud: 0,
    };
    final precedents = <String, _Precedent>{};
    final visites = <String>{};

    while (true) {
      String? courant;
      var meilleureDistance = double.infinity;
      for (final entree in distances.entries) {
        if (!visites.contains(entree.key) && entree.value < meilleureDistance) {
          courant = entree.key;
          meilleureDistance = entree.value;
        }
      }
      if (courant == null) return null;
      if (noeudsArrivee.contains(courant)) {
        return _reconstruire(courant, meilleureDistance, precedents);
      }
      visites.add(courant);
      for (final arc in graphe[courant] ?? const <_Arc>[]) {
        final candidate = meilleureDistance + arc.poids;
        if (candidate < (distances[arc.vers] ?? double.infinity)) {
          distances[arc.vers] = candidate;
          precedents[arc.vers] = _Precedent(courant, arc);
        }
      }
    }
  }

  ResultatRoutagePondere _reconstruire(
    String fin,
    double poids,
    Map<String, _Precedent> precedents,
  ) {
    final segments = <EtapeSegmentPondere>[];
    final correspondances = <Correspondance>[];
    var courant = fin;
    while (precedents.containsKey(courant)) {
      final precedent = precedents[courant]!;
      final arc = precedent.arc;
      if (arc.segmentId != null) {
        segments.insert(
          0,
          EtapeSegmentPondere(
            segmentId: arc.segmentId!,
            inverse: arc.inverse,
          ),
        );
      } else if (arc.correspondance != null) {
        correspondances.insert(0, arc.correspondance!);
      }
      courant = precedent.noeud;
    }
    return ResultatRoutagePondere(
      segments: segments,
      correspondances: correspondances,
      poids: poids,
    );
  }
}

class _Arc {
  const _Arc({
    required this.vers,
    required this.poids,
    this.segmentId,
    this.inverse = false,
    this.correspondance,
  });

  factory _Arc.segment(String vers, String id, {required bool inverse}) =>
      _Arc(vers: vers, poids: 1, segmentId: id, inverse: inverse);

  factory _Arc.correspondance(
    String vers,
    Correspondance correspondance,
    double poids,
  ) =>
      _Arc(vers: vers, poids: poids, correspondance: correspondance);

  final String vers;
  final double poids;
  final String? segmentId;
  final bool inverse;
  final Correspondance? correspondance;
}

class _Precedent {
  const _Precedent(this.noeud, this.arc);
  final String noeud;
  final _Arc arc;
}

String _slug(String valeur) => Stop.normaliserPourRecherche(valeur)
    .replaceAll(' ', '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
