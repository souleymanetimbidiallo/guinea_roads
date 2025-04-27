import 'package:flutter/material.dart';
import 'package:guinea_roads/views/trajet_result_page.dart';
import '../controllers/trajet_controller.dart';
import '../models/stop.dart';

class RecherchePage extends StatefulWidget {
  @override
  _RecherchePageState createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  final TrajetController controller = TrajetController();
  bool isLoading = true;
  List<Stop> allStops = [];
  String? selectedDepartName;
  String? selectedArriveeName;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await controller.loadTronconsFromFirestore();
    setState(() {
      allStops = controller.extractAllStops();
      isLoading = false;
    });
  }

  Stop? findStopByName(String name) {
    try {
      return allStops.firstWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  void swapStops() {
    setState(() {
      final temp = selectedDepartName;
      selectedDepartName = selectedArriveeName;
      selectedArriveeName = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Rechercher un trajet")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Rechercher un trajet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  decoration: InputDecoration(
                    labelText: 'Arrêt de départ',
                    prefixIcon: Icon(Icons.my_location),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            IconButton(
              icon: Icon(Icons.swap_vert, size: 30),
              onPressed: swapStops,
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
                  decoration: InputDecoration(
                    labelText: 'Arrêt d\'arrivée',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.search),
              label: Text("Rechercher le trajet"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                final depart = findStopByName(selectedDepartName ?? '');
                final arrivee = findStopByName(selectedArriveeName ?? '');
                if (depart != null && arrivee != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrajetResultPage(depart: depart, arrivee: arrivee),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Veuillez sélectionner les deux arrêts')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
