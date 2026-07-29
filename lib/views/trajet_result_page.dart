import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/trajet.dart';
import '../models/troncon.dart';
import '../models/transport_option.dart';
import '../models/trajet_enregistre.dart';
import '../services/favoris_service.dart';
import '../services/historique_service.dart';
import 'trajet_map_page.dart';

class TrajetResultPage extends StatefulWidget {
  final Stop depart;
  final Stop arrivee;
  final List<String> modes;
  final Trajet? selectedTrajet;

  const TrajetResultPage({
    required this.depart,
    required this.arrivee,
    required this.modes,
    this.selectedTrajet,
    Key? key,
  }) : super(key: key);

  @override
  _TrajetResultPageState createState() => _TrajetResultPageState();
}

class _TrajetResultPageState extends State<TrajetResultPage> {
  final TrajetController controller = TrajetController();
  Trajet? trajet;
  bool isLoading = true;
  double distance = 0;
  double duration = 0;
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
      final metrics = await controller.getDistanceAndDuration(result);
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

  List<Widget> _buildTrajetCards(Trajet trajet) {
    List<Widget> widgets = [];
    String? currentAxe;
    List<Widget> currentList = [];

    void pushCurrentCard() {
      if (currentList.isNotEmpty && currentAxe != null) {
        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.signpost_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentAxe,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ...currentList,
                ],
              ),
            ),
          ),
        );
      }
      currentList = [];
    }

    for (var index = 0; index < trajet.troncons.length; index++) {
      final troncon = trajet.troncons[index];
      final mode = widget.modes[index];
      if (troncon.axe != currentAxe) {
        pushCurrentCard();
        currentAxe = troncon.axe;
      }
      currentList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${troncon.depart.name} → ${troncon.arrivee.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${troncon.prixParType[mode]} GNF',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _modeChip(mode),
            ],
          ),
        ),
      );
    }
    pushCurrentCard();
    return widgets;
  }

  Widget _buildModeInfo(List<String> modes, int cost) {
    final modesUtilises = <String>[];
    for (final mode in modes) {
      if (!modesUtilises.contains(mode)) modesUtilises.add(mode);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    Icons.payments_outlined,
                    'Prix total',
                    '$cost GNF',
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
                    '${duration.toStringAsFixed(0)} min',
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: modesUtilises.map(_modeChip).toList(),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _modeChip(String mode) {
    final (icon, color) = switch (mode) {
      'taxi' => (Icons.local_taxi_rounded, const Color(0xFFD19B00)),
      'minibus' => (Icons.directions_bus_rounded, const Color(0xFF2474C6)),
      'tricycle' => (Icons.electric_rickshaw_rounded, const Color(0xFF168A45)),
      _ => (Icons.directions_rounded, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            mode.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
        appBar: AppBar(title: Text('Itinéraire')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (trajet == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Itinéraire')),
        body: Center(child: Text('Aucun itinéraire trouvé')),
      );
    }

    final axeCount = trajet!.troncons.map((t) => t.axe).toSet().length;
    final option = TransportOption(
      trajet: trajet!,
      modesParTroncon: widget.modes,
    );
    final cost = option.coutTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinéraire'),
        actions: [
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
          _buildModeInfo(widget.modes, cost),
          const SizedBox(height: 26),
          const Text(
            'Étapes du trajet',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._buildTrajetCards(trajet!),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.map_rounded),
        label: const Text('Voir sur la carte'),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
