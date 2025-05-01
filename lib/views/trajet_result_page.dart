import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/trajet.dart';
import '../models/troncon.dart';
import 'trajet_map_page.dart';

class TrajetResultPage extends StatefulWidget {
  final Stop depart;
  final Stop arrivee;
  final List<String> modes;

  const TrajetResultPage({
    required this.depart,
    required this.arrivee,
    required this.modes,
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

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await controller.loadTronconsFromFirestore();
    final result = controller.getMultiAxeTrajet(widget.depart, widget.arrivee);
    if (result != null) {
      final metrics = await controller.getDistanceAndDuration(result);
      setState(() {
        trajet = result;
        distance = metrics['distance']!;
        duration = metrics['duration']!;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Widget> _buildTrajetCards(Trajet trajet) {
    List<Widget> widgets = [];
    String? currentAxe;
    List<Widget> currentList = [];

    void pushCurrentCard() {
      if (currentList.isNotEmpty && currentAxe != null) {
        widgets.add(
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            margin: EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Axe : $currentAxe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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

    for (final troncon in trajet.troncons) {
      if (troncon.axe != currentAxe) {
        pushCurrentCard();
        currentAxe = troncon.axe;
      }
      currentList.add(ListTile(
        leading: Icon(Icons.arrow_forward),
        title: Text('${troncon.depart.name} → ${troncon.arrivee.name}'),
      ));
    }
    pushCurrentCard();
    return widgets;
  }

  Widget _buildModeInfo(List<String> modes, int cost, int troncons) {
    final icon = Icon(Icons.directions, color: Colors.deepPurple);
    final dureeEstimee = troncons * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            icon,
            Text('${modes.map((m) => m.toUpperCase()).join(" + ")} - $cost GNF'),
            Text('~${dureeEstimee} min'),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📍 ${distance.toStringAsFixed(1)} km   ⏱️ ${duration.toStringAsFixed(0)} min', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Map<Troncon, String> _buildTronconModes() {
    final mapping = <Troncon, String>{};
    int modeIndex = 0;
    for (int i = 0; i < trajet!.troncons.length; i++) {
      final troncon = trajet!.troncons[i];
      final mode = modeIndex < widget.modes.length ? widget.modes[modeIndex] : widget.modes.last;
      mapping[troncon] = mode;

      if (i < trajet!.troncons.length - 1) {
        final next = trajet!.troncons[i + 1];
        if ((next.prixParType[mode] ?? 0) == 0 && modeIndex + 1 < widget.modes.length) {
          modeIndex++;
        }
      }
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
    final cost = controller.calculerCoutTrajetParModes(trajet!, widget.modes);
    final tronconCount = trajet!.troncons.length;

    return Scaffold(
      appBar: AppBar(title: Text('Itinéraire')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De ${widget.depart.name} à ${widget.arrivee.name}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(axeCount > 1 ? '🔁 Ce trajet change d\'axe' : '✔️ Trajet sur un seul axe'),
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
                arrets: trajet!.troncons.map((t) => t.depart).followedBy([trajet!.troncons.last.arrivee]).toList(),
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
