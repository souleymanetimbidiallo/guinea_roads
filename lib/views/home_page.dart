// lib/views/home_page.dart
import 'package:flutter/material.dart';
import 'package:guinea_roads/views/trajet_map_page.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TrajetController controller = TrajetController();
  bool isLoading = true;
  String? error;
  List<Stop> allStops = [];
  String? selectedDepartName;
  String? selectedArriveeName;
  Stop? selectedDepart;
  Stop? selectedArrivee;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      await controller.loadTronconsFromFirestore();
      allStops = controller.extractAllStops();
    } catch (e) {
      error = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Stop? findStopByName(String name) {
    try {
      return allStops.firstWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  void rechercherTrajet() {
    final depart = findStopByName(selectedDepartName ?? '');
    final arrivee = findStopByName(selectedArriveeName ?? '');

    if (depart != null && arrivee != null) {
      final trajet = controller.getMultiAxeTrajet(depart, arrivee);
      if (trajet != null) {
        setState(() {
          selectedDepart = depart;
          selectedArrivee = arrivee;
          showResult = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucun itinéraire trouvé.')),
        );
      }
    }
  }

  void swapStops() {
    if (selectedDepartName == null || selectedArriveeName == null) return;

    setState(() {
      final temp = selectedDepartName;
      selectedDepartName = selectedArriveeName;
      selectedArriveeName = temp;
      rechercherTrajet();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Guinea Roads')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Guinea Roads')),
        body: Center(child: Text('Erreur : $error')),
      );
    }

    final trajet = (selectedDepart != null && selectedArrivee != null)
        ? controller.getMultiAxeTrajet(selectedDepart!, selectedArrivee!)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text('Guinea Roads')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                return allStops
                    .map((s) => s.name)
                    .where((name) => name.toLowerCase().contains(value.text.toLowerCase()))
                    .toList();
              },
              onSelected: (value) {
                setState(() {
                  selectedDepartName = value;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                controller.text = selectedDepartName ?? '';
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(labelText: 'Arrêt de départ'),
                );
              },
            ),
            SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                return allStops
                    .map((s) => s.name)
                    .where((name) => name.toLowerCase().contains(value.text.toLowerCase()))
                    .toList();
              },
              onSelected: (value) {
                setState(() {
                  selectedArriveeName = value;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                controller.text = selectedArriveeName ?? '';
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(labelText: 'Arrêt d\'arrivée'),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: rechercherTrajet,
              child: Text("Rechercher l'itinéraire"),
            ),
            TextButton(
              onPressed: swapStops,
              child: Text("⇄ Inverser départ / arrivée"),
            ),
            SizedBox(height: 10),
            if (showResult && trajet != null) ...[
              Text('Itinéraire de ${selectedDepart!.name} à ${selectedArrivee!.name} :'),
              ...trajet.troncons.map((t) => ListTile(
                title: Text('${t.depart.name} → ${t.arrivee.name}'),
                subtitle: Text('Axe: ${t.axe}'),
              )),
              SizedBox(height: 20),
              Text('Coût estimé :'),
              Text('Taxi: ${trajet.getTotalCost("taxi")} GNF - Minibus: ${trajet.getTotalCost("minibus")} GNF - Tricycle: ${trajet.getTotalCost("tricycle")} GNF'),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrajetMapPage(
                        arrets: trajet.troncons
                            .map((t) => t.depart)
                            .followedBy([trajet.troncons.last.arrivee])
                            .toList(),
                        title: '${selectedDepart!.name} → ${selectedArrivee!.name}',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.map),
                label: Text('Voir sur la carte'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
