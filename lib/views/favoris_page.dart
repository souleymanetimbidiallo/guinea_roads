import 'package:flutter/material.dart';

import '../models/trajet_enregistre.dart';
import '../services/favoris_service.dart';
import '../widgets/ligne_trajet_enregistre.dart';
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
    setState(() => favoris.remove(trajet));
    await FavorisService.supprimer(trajet.depart, trajet.arrivee);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Trajet retiré des favoris.'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              await FavorisService.ajouter(trajet);
              await _chargerFavoris();
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
    ).then((_) => _chargerFavoris());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoris.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _chargerFavoris,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(
                          'Touchez un favori pour relancer la recherche, '
                          'glissez-le vers la gauche pour le retirer.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                      for (final (index, trajet) in favoris.indexed) ...[
                        if (index > 0)
                          Divider(
                            height: 1,
                            indent: 56,
                            color: colors.outlineVariant,
                          ),
                        LigneTrajetEnregistre(
                          trajet: trajet,
                          favori: true,
                          onTap: () => _relancer(trajet),
                          onSupprime: () => _supprimer(trajet),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget etape(int numero, IconData icone, String texte) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  '$numero',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icone, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(texte, style: const TextStyle(fontSize: 15))),
            ],
          ),
        );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x33D19B00),
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
              'Gardez vos trajets habituels à portée de main : '
              'ils apparaîtront ici et sur l’accueil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pour ajouter un favori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    etape(1, Icons.search_rounded, 'Cherchez un trajet.'),
                    etape(
                      2,
                      Icons.touch_app_outlined,
                      'Ouvrez l’option qui vous convient.',
                    ),
                    etape(
                      3,
                      Icons.star_border_rounded,
                      'Touchez l’étoile en haut de l’itinéraire.',
                    ),
                  ],
                ),
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
