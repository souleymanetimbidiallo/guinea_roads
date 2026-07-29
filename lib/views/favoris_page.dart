import 'package:flutter/material.dart';

import '../models/trajet_enregistre.dart';
import '../services/favoris_service.dart';
import 'recherche_page.dart';

class FavorisPage extends StatefulWidget {
  const FavorisPage({super.key});

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  List<TrajetEnregistre> favoris = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }

  Future<void> _chargerFavoris() async {
    final data = await FavorisService.lireFavoris();
    if (!mounted) return;
    setState(() {
      favoris = data;
      isLoading = false;
    });
  }

  Future<void> _supprimer(TrajetEnregistre trajet) async {
    await FavorisService.supprimer(trajet.depart, trajet.arrivee);
    await _chargerFavoris();
  }

  void _relancer(TrajetEnregistre trajet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecherchePage(
          initialDepartName: trajet.depart,
          initialArriveeName: trajet.arrivee,
          autoSearch: true,
        ),
      ),
    ).then((_) => _chargerFavoris());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoris.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun favori pour l’instant.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerFavoris,
                  child: ListView.separated(
                    itemCount: favoris.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final trajet = favoris[index];
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text('${trajet.depart} → ${trajet.arrivee}'),
                        subtitle: Text(_modesLabel(trajet.modes)),
                        onTap: () => _relancer(trajet),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Supprimer',
                          onPressed: () => _supprimer(trajet),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

String _modesLabel(List<String> modes) {
  final uniques = <String>[];
  for (final mode in modes) {
    if (!uniques.contains(mode)) uniques.add(mode);
  }
  return uniques.isEmpty
      ? 'Touchez pour recalculer'
      : uniques.map((mode) => mode.toUpperCase()).join(' + ');
}
