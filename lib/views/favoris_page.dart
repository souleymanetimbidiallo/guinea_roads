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
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _chargerFavoris,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: favoris.length,
                    itemBuilder: (context, index) {
                      final trajet = favoris[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _relancer(trajet),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF2C2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFB27A00),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${trajet.depart} → ${trajet.arrivee}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _modesLabel(trajet.modes),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    tooltip: 'Supprimer',
                                    onPressed: () => _supprimer(trajet),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2C2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 38,
                color: Color(0xFFB27A00),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun trajet favori',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez une étoile depuis le détail d’un itinéraire pour le retrouver ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecherchePage()),
              ),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Chercher un trajet'),
            ),
          ],
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
