import 'package:flutter/material.dart';

import '../models/trajet_enregistre.dart';
import '../services/historique_service.dart';
import '../widgets/ligne_trajet_enregistre.dart';
import 'recherche_page.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key, this.maintenant});

  /// Date de référence pour « Aujourd’hui » et « Hier » (tests).
  final DateTime Function()? maintenant;

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

  Future<void> _supprimer(TrajetEnregistre trajet) async {
    final position = trajets.indexOf(trajet);
    setState(() => trajets.remove(trajet));
    await HistoriqueService.supprimer(trajet);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Trajet retiré de l’historique.'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              await HistoriqueService.remettre(trajet, position);
              await _chargerHistorique();
            },
          ),
        ),
      );
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

  /// Trajets regroupés par jour, dans l’ordre de l’historique.
  List<MapEntry<String, List<TrajetEnregistre>>> get _parJour {
    final maintenant = (widget.maintenant ?? DateTime.now)();
    final groupes = <String, List<TrajetEnregistre>>{};
    for (final trajet in trajets) {
      groupes
          .putIfAbsent(libelleJour(trajet.enregistreLe, maintenant), () => [])
          .add(trajet);
    }
    return groupes.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
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
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Text(
                          'Glissez un trajet vers la gauche pour le supprimer.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                      for (final groupe in _parJour) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                          child: Text(
                            groupe.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        for (final (index, trajet) in groupe.value.indexed) ...[
                          if (index > 0)
                            Divider(
                              height: 1,
                              indent: 56,
                              color: colors.outlineVariant,
                            ),
                          LigneTrajetEnregistre(
                            trajet: trajet,
                            detail: [
                              if (trajet.enregistreLe.millisecondsSinceEpoch >
                                  0)
                                _heure(trajet.enregistreLe),
                              if (trajet.modes.isNotEmpty)
                                libelleModes(trajet.modes),
                            ].join(' · '),
                            onTap: () => _relancer(trajet),
                            onSupprime: () => _supprimer(trajet),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 36,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun trajet récent',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Les itinéraires que vous consultez apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
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

String _heure(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// « Aujourd’hui », « Hier », « Lundi 24 novembre »… pour grouper par jour.
String libelleJour(DateTime date, DateTime maintenant) {
  if (date.millisecondsSinceEpoch == 0) return 'Plus ancien';
  const jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  const mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final local = date.toLocal();
  final jour = DateTime(local.year, local.month, local.day);
  final aujourdHui =
      DateTime(maintenant.year, maintenant.month, maintenant.day);
  final ecart = aujourdHui.difference(jour).inDays;
  if (ecart == 0) return 'Aujourd’hui';
  if (ecart == 1) return 'Hier';
  final numero = local.day == 1 ? '1er' : '${local.day}';
  final annee = local.year == maintenant.year ? '' : ' ${local.year}';
  return '${jours[local.weekday - 1]} $numero ${mois[local.month - 1]}$annee';
}
