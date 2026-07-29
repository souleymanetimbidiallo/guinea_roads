import 'package:flutter/material.dart';

import '../models/trajet_enregistre.dart';
import '../services/historique_service.dart';
import 'recherche_page.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<TrajetEnregistre> trajets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    final data = await HistoriqueService.lireHistorique();
    if (!mounted) return;
    setState(() {
      trajets = data;
      isLoading = false;
    });
  }

  Future<void> _confirmerSuppression() async {
    if (trajets.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider l’historique ?'),
        content:
            const Text('Cette action supprimera tous les trajets récents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await HistoriqueService.viderHistorique();
    await _chargerHistorique();
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
    ).then((_) => _chargerHistorique());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Vider l’historique',
            onPressed: trajets.isEmpty ? null : _confirmerSuppression,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trajets.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _chargerHistorique,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: trajets.length,
                    itemBuilder: (context, index) {
                      final trajet = trajets[index];
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
                                  _routeIcon(context, Icons.history_rounded),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trajet.depart,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Icon(
                                            Icons.arrow_downward_rounded,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        Text(
                                          trajet.arrivee,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _dateLabel(trajet.enregistreLe),
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
                                  const Icon(Icons.chevron_right_rounded),
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
            _routeIcon(context, Icons.history_rounded, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Aucun trajet récent',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Les itinéraires que vous consultez apparaîtront ici.',
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

  Widget _routeIcon(
    BuildContext context,
    IconData icon, {
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: size * 0.5,
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return 'Ancien trajet';
  final local = date.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}'
      ' à ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
