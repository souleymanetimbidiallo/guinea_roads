import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/trajet.dart';
import 'trajet_map_page.dart';

class TrajetResultPage extends StatefulWidget {
  final Stop depart;
  final Stop arrivee;

  const TrajetResultPage({required this.depart, required this.arrivee, Key? key}) : super(key: key);

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

  Widget _buildCoutSection(Trajet trajet) {
    final couts = trajet.getTotalCosts();
    final List<Widget> widgets = [];

    if (couts["taxi"] != null && couts["taxi"]! > 0) {
      widgets.add(Column(
        children: [
          Icon(Icons.local_taxi, color: Colors.yellow[700]),
          Text('${couts["taxi"]} GNF'),
        ],
      ));
    }

    if (couts["minibus"] != null && couts["minibus"]! > 0) {
      widgets.add(Column(
        children: [
          Icon(Icons.directions_bus, color: Colors.blue),
          Text('${couts["minibus"]} GNF'),
        ],
      ));
    }

    if (couts["tricycle"] != null && couts["tricycle"]! > 0) {
      widgets.add(Column(
        children: [
          Icon(Icons.electric_rickshaw, color: Colors.green),
          Text('${couts["tricycle"]} GNF'),
        ],
      ));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: widgets,
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

    return Scaffold(
      appBar: AppBar(title: Text('Itinéraire')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De ${widget.depart.name} à ${widget.arrivee.name}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(child: ListView(children: _buildTrajetCards(trajet!))),
            SizedBox(height: 20),
            Text('Coûts estimés :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            _buildCoutSection(trajet!),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text('Voir sur la carte'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
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
          ],
        ),
      ),
    );
  }
}