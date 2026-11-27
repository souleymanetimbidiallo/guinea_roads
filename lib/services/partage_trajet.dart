import '../models/correspondance.dart';
import '../models/trajet.dart';
import '../models/troncon.dart';
import '../widgets/modes_transport.dart';

/// Une suite de tronçons faits avec le même véhicule (même axe, même mode).
class EtapeTrajet {
  EtapeTrajet(this.axe, this.mode, this.troncons);

  final String axe;
  final String mode;
  final List<Troncon> troncons;

  /// Correspondance à faire avant de commencer cette étape.
  Correspondance? correspondanceAvant;

  int get prix => troncons.fold<int>(
        0,
        (total, troncon) => total + (troncon.prixParType[mode] ?? 0),
      );

  /// Arrêts traversés sans descendre.
  List<String> get arretsTraverses => [
        for (var i = 0; i < troncons.length - 1; i++) troncons[i].arrivee.name,
      ];
}

/// Découpe un trajet en étapes et place chaque correspondance avant l’étape
/// qui la suit (les correspondances sont rangées dans l’ordre du trajet, une
/// par changement d’axe).
List<EtapeTrajet> etapesDuTrajet(Trajet trajet, List<String> modes) {
  final etapes = <EtapeTrajet>[];
  for (var i = 0; i < trajet.troncons.length; i++) {
    final troncon = trajet.troncons[i];
    final mode = modes[i];
    final precedente = etapes.isEmpty ? null : etapes.last;
    if (precedente != null &&
        precedente.axe == troncon.axe &&
        precedente.mode == mode) {
      precedente.troncons.add(troncon);
    } else {
      etapes.add(EtapeTrajet(troncon.axe, mode, [troncon]));
    }
  }
  final correspondances = [...trajet.correspondances];
  for (var k = 1; k < etapes.length; k++) {
    if (etapes[k].axe != etapes[k - 1].axe && correspondances.isNotEmpty) {
      etapes[k].correspondanceAvant = correspondances.removeAt(0);
    }
  }
  return etapes;
}

String milliers(int valeur) =>
    valeur.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ' ');

/// Texte d’un itinéraire à envoyer par WhatsApp, SMS, Messenger…
String texteDePartage({
  required Trajet trajet,
  required List<String> modes,
  required int prixTotal,
  required String duree,
  required double distanceKm,
  bool afficherPrixParEtape = true,
}) {
  final etapes = etapesDuTrajet(trajet, modes);
  final depart = trajet.troncons.first.depart.name;
  final arrivee = trajet.troncons.last.arrivee.name;
  final lignes = <String>[
    'Trajet $depart → $arrivee',
    [
      '${milliers(prixTotal)} GNF',
      duree,
      if (distanceKm > 0) '${distanceKm.toStringAsFixed(1)} km',
    ].join(' · '),
    '',
  ];

  for (var k = 0; k < etapes.length; k++) {
    final etape = etapes[k];
    final correspondance = etape.correspondanceAvant;
    if (correspondance != null) {
      lignes.add(
        '   Changement à ${correspondance.lieu} : '
        '${correspondance.libelleType.toLowerCase()}, '
        '${correspondance.dureeMinMinutes}–${correspondance.dureeMaxMinutes} min'
        '${correspondance.cout > 0 ? ', ${milliers(correspondance.cout)} GNF' : ''}',
      );
    }
    final nombre = etape.troncons.length;
    lignes.add(
      '${k + 1}. ${ModeTransport.pour(etape.mode).libelle} (${etape.axe}) : '
      '${etape.troncons.first.depart.name} → ${etape.troncons.last.arrivee.name}'
      ' · $nombre tronçon${nombre > 1 ? 's' : ''}'
      '${afficherPrixParEtape ? ' · ${milliers(etape.prix)} GNF' : ''}',
    );
  }

  lignes
    ..add('')
    ..add('Estimations à confirmer sur le terrain. Calculé avec Guinea Roads.');
  return lignes.join('\n');
}
