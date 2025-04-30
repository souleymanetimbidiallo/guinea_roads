import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/trajet.dart';
import 'trajet_result_page.dart';

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
  List<Map<String, dynamic>> trajetVariants = [];

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

  Widget buildTrajetCard(Trajet trajet, List<String> modes) {
    List<Icon> icons = modes.map((mode) {
      switch (mode) {
        case 'taxi':
          return Icon(Icons.local_taxi, color: Colors.yellow[700]);
        case 'minibus':
          return Icon(Icons.directions_bus, color: Colors.blue);
        case 'tricycle':
          return Icon(Icons.electric_rickshaw, color: Colors.green);
        default:
          return Icon(Icons.directions, color: Colors.grey);
      }
    }).toList();

    int totalCost = 0;
    for (var mode in modes) {
      totalCost += trajet.getTotalCost(mode);
    }

    return Card(
      child: ListTile(
        title: Text('${modes.map((m) => m.toUpperCase()).join(" + ")} - ${trajet.troncons.length} tronçons'),
        subtitle: Row(children: [...icons, SizedBox(width: 10), Text('$totalCost GNF')]),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          final depart = findStopByName(selectedDepartName ?? '');
          final arrivee = findStopByName(selectedArriveeName ?? '');
          if (depart != null && arrivee != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrajetResultPage(
                  depart: depart,
                  arrivee: arrivee,
                  modeTransport: modes.first,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void chercherTrajets() {
    final depart = findStopByName(selectedDepartName ?? '');
    final arrivee = findStopByName(selectedArriveeName ?? '');
    if (depart != null && arrivee != null) {
      final trajet = controller.getMultiAxeTrajet(depart, arrivee);
      if (trajet != null) {
        final unique = controller.getTransportOptionsForTrajet(trajet);
        final combines = controller.getCombinedTransportOptionsForTrajet(trajet);

        setState(() {
          trajetVariants = [
            ...unique.map((t) => {"trajet": t["trajet"], "modes": [t["mode"]]}),
            ...combines
          ];
        });
      } else {
        setState(() => trajetVariants = []);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner les deux arrêts')),
      );
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
                setState(() => selectedDepartName = value);
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
              icon: Icon(Icons.swap_vert, size: 28),
              tooltip: 'Inverser les arrêts',
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
                setState(() => selectedArriveeName = value);
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
              label: Text("Rechercher les trajets"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: chercherTrajets,
            ),
            SizedBox(height: 20),
            Expanded(
              child: trajetVariants.isEmpty
                  ? Text("Aucun trajet trouvé")
                  : ListView(
                children: trajetVariants
                    .map((item) => buildTrajetCard(item["trajet"], List<String>.from(item["modes"])))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
