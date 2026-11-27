import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../models/tarification.dart';
import '../controllers/trajet_controller.dart';
import '../models/trajet.dart';
import '../models/troncon.dart';
import '../models/transport_option.dart';
import '../models/trajet_enregistre.dart';
import '../services/favoris_service.dart';
import '../services/historique_service.dart';
import 'trajet_map_page.dart';
import '../models/correspondance.dart';
import '../widgets/modes_transport.dart';
import '../services/partage_trajet.dart';
import 'package:share_plus/share_plus.dart';

class TrajetResultPage extends StatefulWidget {
  final Stop depart;
  final Stop arrivee;
  final List<String> modes;
  final Trajet? selectedTrajet;
  final TarifTrajet? tarifV2;

  const TrajetResultPage({
    required this.depart,
    required this.arrivee,
    required this.modes,
    this.selectedTrajet,
    this.tarifV2,
    super.key,
  });

  @override
  State<TrajetResultPage> createState() => _TrajetResultPageState();
}

class _TrajetResultPageState extends State<TrajetResultPage> {
  final TrajetController controller = TrajetController();
  Trajet? trajet;
  bool isLoading = true;
  double distance = 0;
  double duration = 0;
  double durationMin = 0;
  double durationMax = 0;
  bool profilsValidesTerrain = true;
  bool congestionPiloteAppliquee = false;
  bool congestionValideeTerrain = true;
  bool isFavorite = false;
  bool favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await controller.loadTronconsFromFirestore();
    final result = widget.selectedTrajet ??
        controller.getMultiAxeTrajet(widget.depart, widget.arrivee);
    if (result != null) {
      final option = TransportOption(
        trajet: result,
        modesParTroncon: widget.modes,
        tarifV2: widget.tarifV2,
      );
      final metrics = await controller.getDistanceAndDurationForOption(option);
      var favorite = false;
      try {
        final trajetEnregistre = _trajetEnregistre();
        await HistoriqueService.ajouterTrajet(trajetEnregistre);
        favorite = await FavorisService.contient(
          widget.depart.name,
          widget.arrivee.name,
        );
      } catch (error) {
        debugPrint('Sauvegarde locale indisponible : $error');
      }
      if (!mounted) return;
      setState(() {
        trajet = result;
        distance = metrics['distance']!;
        duration = metrics['duration']!;
        durationMin = metrics['durationMin']!;
        durationMax = metrics['durationMax']!;
        profilsValidesTerrain = metrics['profilsValidesTerrain'] == 1;
        congestionPiloteAppliquee = metrics['congestionPiloteAppliquee'] == 1;
        congestionValideeTerrain = metrics['congestionValideeTerrain'] == 1;
        isFavorite = favorite;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  TrajetEnregistre _trajetEnregistre() {
    return TrajetEnregistre(
      depart: widget.depart.name,
      arrivee: widget.arrivee.name,
      modes: widget.modes,
    );
  }

  Future<void> _toggleFavorite() async {
    if (favoriteLoading) return;
    setState(() => favoriteLoading = true);
    bool favorite;
    try {
      favorite = await FavorisService.basculer(_trajetEnregistre());
    } catch (error) {
      if (!mounted) return;
      setState(() => favoriteLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier les favoris.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      isFavorite = favorite;
      favoriteLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          favorite
              ? 'Trajet ajouté aux favoris.'
              : 'Trajet retiré des favoris.',
        ),
      ),
    );
  }

  List<Widget> _frise(Trajet trajet) {
    final etapes = etapesDuTrajet(trajet, widget.modes);
    final colors = Theme.of(context).colorScheme;
    final widgets = <Widget>[
      _ligneFrise(
        marqueur: _point(colors.primary),
        bas: ModeTransport.pour(etapes.first.mode).couleur,
        contenu: _noeud(etapes.first.troncons.first.depart.name, 'Départ'),
      ),
    ];
    for (var k = 0; k < etapes.length; k++) {
      final etape = etapes[k];
      if (k > 0) {
        final precedente = etapes[k - 1];
        final arrivee = precedente.troncons.last.arrivee.name;
        final reprise = etape.troncons.first.depart.name;
        widgets.add(
          _ligneFrise(
            marqueur: _anneau(colors.onSurface),
            haut: ModeTransport.pour(precedente.mode).couleur,
            bas: ModeTransport.pour(etape.mode).couleur,
            contenu: _noeud(
              arrivee == reprise ? reprise : '$arrivee → $reprise',
              'Changement de véhicule',
              correspondance: etape.correspondanceAvant,
            ),
          ),
        );
      }
      widgets.add(_ligneEtape(etape));
    }
    widgets.add(
      _ligneFrise(
        marqueur: Icon(Icons.flag_rounded, size: 20, color: colors.primary),
        haut: ModeTransport.pour(etapes.last.mode).couleur,
        contenu: _noeud(etapes.last.troncons.last.arrivee.name, 'Arrivée'),
      ),
    );
    return widgets;
  }

  Widget _point(Color couleur) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
      );

  Widget _anneau(Color couleur) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: couleur, width: 3),
        ),
      );

  /// Une ligne de la frise : le trait vertical et son repère à gauche,
  /// le contenu à droite.
  Widget _ligneFrise({
    required Widget marqueur,
    required Widget contenu,
    Color? haut,
    Color? bas,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 6,
                  height: 12,
                  color: haut ?? Colors.transparent,
                ),
                SizedBox(height: 20, child: Center(child: marqueur)),
                Expanded(
                  child: Container(width: 6, color: bas ?? Colors.transparent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: contenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noeud(String nom, String role, {Correspondance? correspondance}) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nom,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(role, style: TextStyle(color: colors.onSurfaceVariant)),
        if (correspondance != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      correspondance.type == TypeCorrespondance.marche
                          ? Icons.directions_walk_rounded
                          : Icons.local_taxi_rounded,
                      size: 20,
                      color: colors.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${correspondance.libelleType} · '
                        '${correspondance.dureeMinMinutes}–'
                        '${correspondance.dureeMaxMinutes} min · '
                        '${correspondance.cout == 0 ? 'gratuit' : '${milliers(correspondance.cout)} GNF'}',
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (correspondance.instructions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    correspondance.instructions,
                    style: TextStyle(color: colors.onTertiaryContainer),
                  ),
                ],
                if (correspondance.aConfirmer) ...[
                  const SizedBox(height: 6),
                  Text(
                    'À confirmer sur le terrain',
                    style: TextStyle(
                      color: colors.onTertiaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _ligneEtape(EtapeTrajet etape) {
    final colors = Theme.of(context).colorScheme;
    final mode = ModeTransport.pour(etape.mode);
    final prix = etape.troncons.fold<int>(
      0,
      (total, troncon) => total + (troncon.prixParType[etape.mode] ?? 0),
    );
    final nombre = etape.troncons.length;
    final arrets = [
      for (var i = 0; i < etape.troncons.length - 1; i++)
        etape.troncons[i].arrivee.name,
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Center(child: Container(width: 6, color: mode.couleur)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(mode.icone, color: mode.couleur, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: mode.libelle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(
                                  text: ' · ${etape.axe}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        '$nombre tronçon${nombre > 1 ? 's' : ''}',
                        if (widget.tarifV2 == null) '${milliers(prix)} GNF',
                      ].join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (arrets.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Arrêts : ${arrets.join(' · ')}',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeInfo(int cost) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _summaryMetric(
                Icons.payments_outlined,
                'Prix total',
                '${milliers(cost)} GNF',
              ),
            ),
            Expanded(
              child: _summaryMetric(
                Icons.route_rounded,
                'Distance',
                '${distance.toStringAsFixed(1)} km',
              ),
            ),
            Expanded(
              child: _summaryMetric(
                Icons.schedule_rounded,
                'Durée',
                (durationMax - durationMin).abs() < 0.5
                    ? '${duration.toStringAsFixed(0)} min'
                    : '${durationMin.toStringAsFixed(0)}–'
                        '${durationMax.toStringAsFixed(0)} min',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 7),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String get _libelleDuree => (durationMax - durationMin).abs() < 0.5
      ? '${duration.toStringAsFixed(0)} min'
      : '${durationMin.toStringAsFixed(0)}–${durationMax.toStringAsFixed(0)} min';

  Future<void> _partager(int cout) async {
    final texte = texteDePartage(
      trajet: trajet!,
      modes: widget.modes,
      prixTotal: cout,
      duree: _libelleDuree,
      distanceKm: distance,
      afficherPrixParEtape: widget.tarifV2 == null,
    );
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      texte,
      subject: 'Trajet ${widget.depart.name} → ${widget.arrivee.name}',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  Map<Troncon, String> _buildTronconModes() {
    final mapping = <Troncon, String>{};
    for (int i = 0; i < trajet!.troncons.length; i++) {
      final troncon = trajet!.troncons[i];
      mapping[troncon] = widget.modes[i];
    }
    return mapping;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinéraire')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (trajet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinéraire')),
        body: const Center(child: Text('Aucun itinéraire trouvé')),
      );
    }

    final axeCount = trajet!.troncons.map((t) => t.axe).toSet().length;
    final option = TransportOption(
      trajet: trajet!,
      modesParTroncon: widget.modes,
      tarifV2: widget.tarifV2,
    );
    final cost = option.coutTotal;
    final mentions = [
      if (!profilsValidesTerrain)
        'Durée calculée avec des coefficients pilotes, à valider sur le '
            'terrain.',
      if (congestionPiloteAppliquee && !congestionValideeTerrain)
        'Effet des heures de pointe estimé : hypothèse pilote.',
      if (widget.tarifV2 != null)
        'Tarif pilote par tranches : ${widget.tarifV2!.nombreTranches} '
            'tranche${widget.tarifV2!.nombreTranches > 1 ? 's' : ''} '
            'facturée${widget.tarifV2!.nombreTranches > 1 ? 's' : ''}.',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinéraire'),
        actions: [
          IconButton(
            tooltip: 'Partager le trajet',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _partager(cost),
          ),
          IconButton(
            onPressed: favoriteLoading ? null : _toggleFavorite,
            tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            icon: favoriteLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isFavorite ? Icons.star : Icons.star_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            widget.depart.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: Color(0xFF087F5B),
            ),
          ),
          Text(
            widget.arrivee.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                axeCount > 1 ? Icons.alt_route_rounded : Icons.straight_rounded,
                size: 18,
              ),
              label: Text(
                axeCount > 1
                    ? '$axeCount axes empruntés'
                    : 'Trajet sur un seul axe',
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildModeInfo(cost),
          if (mentions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mentions.join('\n'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          const Text(
            'Étapes du trajet',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ..._frise(trajet!),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          icon: const Icon(Icons.map_rounded),
          label: const Text('Voir sur la carte'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrajetMapPage(
                  arrets: trajet!.troncons
                      .map((t) => t.depart)
                      .followedBy([trajet!.troncons.last.arrivee]).toList(),
                  title: '${widget.depart.name} → ${widget.arrivee.name}',
                  tronconModes: _buildTronconModes(),
                  correspondances: trajet!.correspondances,
                  corridors: controller.corridors,
                  dureeEstimeeMin: durationMin,
                  dureeEstimeeMax: durationMax,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
