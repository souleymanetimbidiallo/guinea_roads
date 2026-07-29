import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/transport_option.dart';
import 'trajet_result_page.dart';

class RecherchePage extends StatefulWidget {
  @override
  _RecherchePageState createState() => _RecherchePageState();
}

class _RecherchePageState extends State<RecherchePage> {
  final TrajetController controller = TrajetController();
  bool isLoading = true;
  bool isSearching = false;
  String? loadError;
  String? searchMessage;
  List<Stop> allStops = [];
  String? selectedDepartName;
  String? selectedArriveeName;
  List<_TrajetVariant> trajetVariants = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      await controller.loadTronconsFromFirestore();
      if (!mounted) return;
      setState(() {
        allStops = controller.extractAllStops()
          ..sort((a, b) => a.name.compareTo(b.name));
        loadError = null;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = 'Impossible de charger les arrêts.';
        isLoading = false;
      });
    }
  }

  Stop? findStopByName(String name) {
    final normalizedName = name.toLowerCase().trim();
    try {
      return allStops.firstWhere(
        (stop) => stop.name.toLowerCase().trim() == normalizedName,
      );
    } catch (e) {
      return null;
    }
  }

  Widget buildTrajetCard(_TrajetVariant variant) {
    final option = variant.option;
    final modes = option.modesUtilises;
    final icons = modes.map((mode) {
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

    return Card(
      child: ListTile(
        title: Text(
          '${modes.map((m) => m.toUpperCase()).join(" + ")}'
          ' - ${option.trajet.troncons.length} tronçons',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...icons,
                const SizedBox(width: 10),
                Text('${option.coutTotal} GNF'),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '📍 ${variant.distance.toStringAsFixed(1)} km'
              '   ⏱️ ${variant.duration.toStringAsFixed(0)} min',
            ),
            if (option.nombreChangements > 0)
              Text(
                '${option.nombreChangements} changement'
                '${option.nombreChangements > 1 ? 's' : ''} de transport',
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
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
                  modes: option.modesParTroncon,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> chercherTrajets() async {
    final depart = findStopByName(selectedDepartName ?? '');
    final arrivee = findStopByName(selectedArriveeName ?? '');

    if (depart == null || arrivee == null) {
      _showMessage('Sélectionnez deux arrêts proposés dans les listes.');
      return;
    }
    if (depart.id == arrivee.id ||
        depart.name.toLowerCase().trim() == arrivee.name.toLowerCase().trim()) {
      _showMessage('Le départ et l’arrivée doivent être différents.');
      return;
    }

    setState(() {
      isSearching = true;
      searchMessage = null;
      trajetVariants = [];
    });

    try {
      final trajet = controller.getMultiAxeTrajet(depart, arrivee);
      if (trajet != null) {
        final options = controller.getTransportOptions(trajet);
        final metrics = await controller.getDistanceAndDuration(trajet);

        if (!mounted) return;
        setState(() {
          trajetVariants = options
              .map(
                (option) => _TrajetVariant(
                  option: option,
                  distance: metrics['distance'] ?? 0,
                  duration: metrics['duration'] ?? 0,
                ),
              )
              .toList();
          if (trajetVariants.isEmpty) {
            searchMessage =
                'Aucun moyen de transport disponible sur ce trajet.';
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          searchMessage = 'Aucun trajet ne relie ces deux arrêts.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        searchMessage = 'Une erreur est survenue pendant le calcul du trajet.';
      });
    } finally {
      if (mounted) {
        setState(() => isSearching = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Rechercher un trajet")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rechercher un trajet')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    loadError = null;
                  });
                  loadData();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Rechercher un trajet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (controller.loadedFromLocalData)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mode hors connexion : données locales utilisées.',
                  textAlign: TextAlign.center,
                ),
              ),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                return allStops
                    .map((s) => s.name)
                    .where((name) =>
                        name.toLowerCase().contains(value.text.toLowerCase()))
                    .toList();
              },
              onSelected: (value) {
                setState(() => selectedDepartName = value);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
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
              onPressed: () {
                setState(() {
                  final temp = selectedDepartName;
                  selectedDepartName = selectedArriveeName;
                  selectedArriveeName = temp;
                });
              },
            ),
            SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                return allStops
                    .map((s) => s.name)
                    .where((name) =>
                        name.toLowerCase().contains(value.text.toLowerCase()))
                    .toList();
              },
              onSelected: (value) {
                setState(() => selectedArriveeName = value);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
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
              icon: isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(
                isSearching ? 'Calcul en cours…' : 'Rechercher les trajets',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: isSearching ? null : chercherTrajets,
            ),
            SizedBox(height: 20),
            Expanded(
              child: trajetVariants.isEmpty
                  ? Center(
                      child: Text(
                        searchMessage ??
                            'Sélectionnez un départ et une arrivée.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      children: trajetVariants.map(buildTrajetCard).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrajetVariant {
  const _TrajetVariant({
    required this.option,
    required this.distance,
    required this.duration,
  });

  final TransportOption option;
  final double distance;
  final double duration;
}
