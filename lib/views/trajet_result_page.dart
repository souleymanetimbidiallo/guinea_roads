import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/trajet.dart';
import 'trajet_map_page.dart';

class TrajetResultPage extends StatefulWidget {
  final Stop depart;
  final Stop arrivee;
  final String modeTransport;

  const TrajetResultPage({
    required this.depart,
    required this.arrivee,
    required this.modeTransport,
    Key? key,
  }) : super(key: key);

  @override
  _TrajetResultPageState createState() => _TrajetResultPageState();
}

class _TrajetResultPageState extends State<TrajetResultPage> {
  final TrajetController controller = TrajetController();
  Trajet? trajet;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await controller.loadTronconsFromFirestore();
    final result = controller.getMultiAxeTrajet(widget.depart, widget.arrivee);
    setState(() {
      trajet = result;
      isLoading = false;
    });
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

  Widget _buildModeInfo(String mode, int cost, int troncons) {
    Icon icon;
    int temps = 0;
    switch (mode) {
      case 'taxi':
        icon = Icon(Icons.local_taxi, color: Colors.yellow[700]);
        temps = 2;
        break;
      case 'minibus':
        icon = Icon(Icons.directions_bus, color: Colors.blue);
        temps = 5;
        break;
      case 'tricycle':
        icon = Icon(Icons.electric_rickshaw, color: Colors.green);
        temps = 3;
        break;
      default:
        icon = Icon(Icons.directions, color: Colors.grey);
        temps = 4;
    }

    final dureeEstimee = troncons * temps;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        icon,
        Text(' ${mode.toUpperCase()} - $cost GNF'),
        Text('⏱️ ~${dureeEstimee} min'),
      ],
    );
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
    final cost = controller.calculerCoutTrajetParModes(trajet!, [widget.modeTransport]);
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
            _buildModeInfo(widget.modeTransport, cost, tronconCount),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
