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
              ? const Center(
                  child: Text(
                    'Aucun trajet récent.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerHistorique,
                  child: ListView.separated(
                    itemCount: trajets.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final trajet = trajets[index];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text('${trajet.depart} → ${trajet.arrivee}'),
                        subtitle: Text(_dateLabel(trajet.enregistreLe)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _relancer(trajet),
                      );
                    },
                  ),
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
