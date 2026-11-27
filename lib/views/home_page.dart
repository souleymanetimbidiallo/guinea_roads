import 'package:flutter/material.dart';

import '../controllers/trajet_controller.dart';
import '../models/stop.dart';
import '../models/trajet_enregistre.dart';
import '../services/favoris_service.dart';
import '../services/historique_service.dart';
import '../widgets/champ_arret.dart';
import '../widgets/modes_transport.dart';
import 'about_page.dart';
import 'recherche_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onVoirHistorique});

  /// Ouvre l’onglet Historique (fourni par l’écran principal).
  final VoidCallback? onVoirHistorique;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TrajetController controller = TrajetController();
  List<Stop> arrets = [];
  bool arretsCharges = false;
  String? depart;
  String? arrivee;
  List<_TrajetRecent> recents = [];

  @override
  void initState() {
    super.initState();
    _chargerArrets();
    _chargerRecents();
  }

  Future<void> _chargerArrets() async {
    try {
      await controller.loadTronconsFromFirestore();
      if (!mounted) return;
      setState(() {
        arrets = controller.extractAllStops()
          ..sort((a, b) => a.name.compareTo(b.name));
        arretsCharges = true;
      });
    } catch (_) {
      if (mounted) setState(() => arretsCharges = true);
    }
  }

  Future<void> _chargerRecents() async {
    try {
      final favoris = await FavorisService.lireFavoris();
      final historique = await HistoriqueService.lireHistorique();
      final liste = <_TrajetRecent>[
        if (favoris.isNotEmpty) _TrajetRecent(favoris.first, favori: true),
        ...historique
            .where(
              (trajet) =>
                  favoris.isEmpty ||
                  trajet.identifiant != favoris.first.identifiant,
            )
            .take(favoris.isEmpty ? 3 : 2)
            .map((trajet) => _TrajetRecent(trajet)),
      ];
      if (mounted) setState(() => recents = liste);
    } catch (_) {
      // Pas de trajets enregistrés lisibles : la section reste masquée.
    }
  }

  Future<void> _rechercher({String? de, String? vers}) async {
    final origine = de ?? depart;
    final destination = vers ?? arrivee;
    if (origine == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un départ et une arrivée dans les listes.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecherchePage(
          initialDepartName: origine,
          initialArriveeName: destination,
          autoSearch: true,
        ),
      ),
    );
    _chargerRecents();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Image.asset('assets/images/logo.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Guinea Roads',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Se déplacer simplement à Conakry',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Plus d’options',
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (_) => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'a-propos',
                      child: ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('À propos'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _carteRecherche(context),
            if (recents.isNotEmpty) ...[
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Vos trajets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.onVoirHistorique != null)
                    TextButton(
                      onPressed: widget.onVoirHistorique,
                      child: const Text('Tout voir'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _carteListe(
                context,
                recents.map((recent) => _ligneRecent(context, recent)).toList(),
              ),
            ],
            const SizedBox(height: 26),
            const Text(
              'Prix d’un tronçon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _carteListe(context, [
              _ligneTarif(context, ModeTransport.taxi, 'Tous les axes', 2000),
              _ligneTarif(
                context,
                ModeTransport.minibus,
                'Le Prince · Autoroute Fidel Castro',
                1500,
              ),
              _ligneTarif(
                context,
                ModeTransport.tricycle,
                'Corniche Nord · Dixinn–Hamdallaye · Sonfonia–Kagbelen',
                2500,
              ),
            ]),
            const SizedBox(height: 14),
            Text(
              'Version bêta · données disponibles hors connexion',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteRecherche(BuildContext context) {
    const vert = Color(0xFF0B6B51);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vert,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Où allez-vous ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (!arretsCharges)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 34),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ChampArret(
                        label: 'Départ',
                        icon: Icons.trip_origin_rounded,
                        valeur: depart,
                        arrets: arrets,
                        controller: controller,
                        surFondColore: true,
                        onSelected: (valeur) =>
                            depart = valeur.isEmpty ? null : valeur,
                      ),
                      const SizedBox(height: 8),
                      ChampArret(
                        label: 'Arrivée',
                        icon: Icons.flag_rounded,
                        valeur: arrivee,
                        arrets: arrets,
                        controller: controller,
                        surFondColore: true,
                        onSelected: (valeur) =>
                            arrivee = valeur.isEmpty ? null : valeur,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Inverser départ et arrivée',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF095A44),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.swap_vert_rounded),
                  onPressed: () => setState(() {
                    final temp = depart;
                    depart = arrivee;
                    arrivee = temp;
                  }),
                ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.search_rounded),
            label: const Text('Rechercher les trajets'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6EDBB0),
              foregroundColor: const Color(0xFF05382A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: arretsCharges ? () => _rechercher() : null,
          ),
        ],
      ),
    );
  }

  Widget _carteListe(BuildContext context, List<Widget> lignes) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < lignes.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            lignes[index],
          ],
        ],
      ),
    );
  }

  Widget _ligneRecent(BuildContext context, _TrajetRecent recent) {
    final colors = Theme.of(context).colorScheme;
    final trajet = recent.trajet;
    final details = [
      if (recent.favori) 'Favori',
      if (!recent.favori && trajet.enregistreLe.year > 1970)
        _date(trajet.enregistreLe),
      if (trajet.modes.isNotEmpty)
        trajet.modes.map((m) => ModeTransport.pour(m).libelle).toSet().join(
              ' + ',
            ),
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color:
              recent.favori ? const Color(0x33D19B00) : colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          recent.favori ? Icons.star_rounded : Icons.history_rounded,
          color: recent.favori ? const Color(0xFFD19B00) : colors.primary,
          size: 20,
        ),
      ),
      title: Text(
        '${trajet.depart} → ${trajet.arrivee}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: details.isEmpty ? null : Text(details),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _rechercher(de: trajet.depart, vers: trajet.arrivee),
    );
  }

  Widget _ligneTarif(
    BuildContext context,
    ModeTransport mode,
    String ouCirculer,
    int prix,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(mode.icone, color: mode.couleur),
      title: Text(
        mode.libelle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(ouCirculer),
      trailing: Text(
        '${_milliers(prix)} GNF',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }

  static String _milliers(int valeur) => valeur
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ' ');

  static String _date(DateTime date) {
    const mois = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final jour = date.day == 1 ? '1er' : '${date.day}';
    return '$jour ${mois[date.month - 1]}';
  }
}

class _TrajetRecent {
  const _TrajetRecent(this.trajet, {this.favori = false});

  final TrajetEnregistre trajet;
  final bool favori;
}
