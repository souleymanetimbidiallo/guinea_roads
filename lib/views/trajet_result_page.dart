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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Axe : $currentAxe',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent)),
                  SizedBox(height: 10),
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
      currentList.add(ListTile(
        leading: Icon(Icons.arrow_forward),
        title: Text('${troncon.depart.name} → ${troncon.arrivee.name}'),
        subtitle: Text('${troncon.prixParType[mode]} GNF'),
        trailing: Chip(label: Text(mode.toUpperCase())),
      ));
    }
    pushCurrentCard();
    return widgets;
  }

  Widget _buildModeInfo(List<String> modes, int cost, int troncons) {
    final icon = Icon(Icons.directions, color: Colors.deepPurple);
    final dureeEstimee = troncons * 3;
    final modesUtilises = <String>[];
    for (final mode in modes) {
      if (!modesUtilises.contains(mode)) modesUtilises.add(mode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            icon,
            Text(
              '${modesUtilises.map((m) => m.toUpperCase()).join(" + ")}'
              ' - $cost GNF',
            ),
            Text('~${dureeEstimee} min'),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                '📍 ${distance.toStringAsFixed(1)} km   ⏱️ ${duration.toStringAsFixed(0)} min',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
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
    final tronconCount = trajet!.troncons.length;

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De ${widget.depart.name} à ${widget.arrivee.name}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(axeCount > 1
                ? '🔁 Ce trajet change d\'axe'
                : '✔️ Trajet sur un seul axe'),
            SizedBox(height: 20),
            _buildModeInfo(widget.modes, cost, tronconCount),
            SizedBox(height: 20),
            Expanded(child: ListView(children: _buildTrajetCards(trajet!))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.map),
        label: Text('Carte'),
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
