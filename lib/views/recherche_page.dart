import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/transport_option.dart';
import '../services/score_recommandation_service.dart';
import 'trajet_result_page.dart';
import '../widgets/champ_arret.dart';
import '../widgets/modes_transport.dart';

class RecherchePage extends StatefulWidget {
  const RecherchePage({
    super.key,
    this.initialDepartName,
    this.initialArriveeName,
    this.autoSearch = false,
  });

  final String? initialDepartName;
  final String? initialArriveeName;
  final bool autoSearch;

  @override
  State<RecherchePage> createState() => _RecherchePageState();
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
  _TrajetSort trajetSort = _TrajetSort.recommande;
  bool autoSearchTriggered = false;

  @override
  void initState() {
    super.initState();
    selectedDepartName = widget.initialDepartName;
    selectedArriveeName = widget.initialArriveeName;
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
      if (widget.autoSearch && !autoSearchTriggered) {
        autoSearchTriggered = true;
        await chercherTrajets();
      }
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

  void _ouvrirOption(_TrajetVariant variant) {
    final depart = findStopByName(selectedDepartName ?? '');
    final arrivee = findStopByName(selectedArriveeName ?? '');
    if (depart == null || arrivee == null) return;
    final option = variant.option;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrajetResultPage(
          depart: depart,
          arrivee: arrivee,
          modes: option.modesParTroncon,
          selectedTrajet: option.trajet,
          tarifV2: option.tarifV2,
        ),
      ),
    );
  }

  Widget buildTrajetCard(_TrajetVariant variant, {required bool enTete}) {
    final option = variant.option;
    final colors = Theme.of(context).colorScheme;
    final changements = variant.pointsDeChangement;
    final badge = !enTete
        ? null
        : trajetSort == _TrajetSort.recommande
            ? 'Recommandé · ${variant.raisonRecommandation.toLowerCase()}'
            : trajetSort.label;
    final details = [
      '${variant.distance.toStringAsFixed(1)} km',
      '${option.trajet.troncons.length} tronçon'
          '${option.trajet.troncons.length > 1 ? 's' : ''}',
      if (option.tarifV2 != null)
        '${option.tarifV2!.nombreTranches} tranche'
            '${option.tarifV2!.nombreTranches > 1 ? 's' : ''}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: enTete
              ? BorderSide(color: colors.primary, width: 2)
              : BorderSide(color: colors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _ouvrirOption(variant),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            variant.libelleDuree,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            details,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_milliers(option.coutTotal)} GNF',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _LigneTrajet(variant: variant),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        option.trajet.troncons.first.depart.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        changements.isNotEmpty
                            ? changements.join(' · ')
                            : variant.etapesIntermediaires.isEmpty
                                ? ''
                                : 'via ${variant.etapesIntermediaires.join(' · ')}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: changements.isNotEmpty
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                          fontWeight: changements.isNotEmpty
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        option.trajet.troncons.last.arrivee.name,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: colors.outlineVariant),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final (index, mode)
                              in variant.modesSuccessifs.indexed) ...[
                            if (index > 0)
                              Text(
                                '→',
                                style:
                                    TextStyle(color: colors.onSurfaceVariant),
                              ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ModeTransport.pour(mode).couleur,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              ModeTransport.pour(mode).libelle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                          Text(
                            changements.isEmpty
                                ? '· sans changement'
                                : '· ${changements.length} changement'
                                    '${changements.length > 1 ? 's' : ''}',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _milliers(int valeur) => valeur
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ' ');

  /// Mentions sur les données encore pilotes, regroupées dans un seul
  /// bandeau au lieu d’être répétées sur chaque carte.
  List<String> get _mentionsPilotes => [
        if (trajetVariants.any((v) => !v.profilsValidesTerrain))
          'Les durées sont calculées avec des coefficients pilotes, '
              'à valider sur le terrain.',
        if (trajetVariants.any((v) => v.congestionPiloteAppliquee))
          'L’effet des heures de pointe est une hypothèse pilote.',
        if (trajetVariants
            .any((v) => v.option.trajet.correspondancesAConfirmer))
          'Certaines correspondances n’ont pas encore été vérifiées sur '
              'place.',
      ];

  Widget _bandeauPilote() {
    final mentions = _mentionsPilotes;
    if (mentions.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Données à confirmer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final mention in mentions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $mention'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Compris'),
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Durées et correspondances estimées, à confirmer '
                          'sur le terrain. ',
                      children: [
                        TextSpan(
                          text: 'En savoir plus',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultats() {
    final variantes = _sortedVariants;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$selectedDepartName → $selectedArriveeName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${variantes.length} option${variantes.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier le trajet',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => setState(() => trajetVariants = []),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sort in _TrajetSort.values)
                ChoiceChip(
                  label: Text(sort.label),
                  selected: trajetSort == sort,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => trajetSort = sort),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _bandeauPilote(),
          for (final (index, variant) in variantes.indexed)
            buildTrajetCard(variant, enTete: index == 0),
        ],
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
      final trajets = controller.getAlternativeTrajets(depart, arrivee);
      if (trajets.isNotEmpty) {
        final options = trajets
            .expand(
              (trajet) => controller.getTransportOptions(trajet).take(3),
            )
            .toList(growable: false);
        final metrics = await Future.wait(
          options.map(controller.getDistanceAndDurationForOption),
        );
        final scores = const ScoreRecommandationService().calculer([
          for (var index = 0; index < options.length; index++)
            CandidatRecommandation(
              cout: options[index].coutTotal,
              dureeMinutes: metrics[index]['duration'] ?? 0,
              changements: options[index].nombreChangements +
                  options[index].trajet.correspondances.length,
            ),
        ]);

        if (!mounted) return;
        setState(() {
          trajetVariants = [
            for (var index = 0; index < options.length; index++)
              _TrajetVariant(
                option: options[index],
                distance: metrics[index]['distance'] ?? 0,
                duration: metrics[index]['duration'] ?? 0,
                durationMin: metrics[index]['durationMin'] ?? 0,
                durationMax: metrics[index]['durationMax'] ?? 0,
                profilsValidesTerrain:
                    metrics[index]['profilsValidesTerrain'] == 1,
                congestionPiloteAppliquee:
                    metrics[index]['congestionPiloteAppliquee'] == 1 &&
                        metrics[index]['congestionValideeTerrain'] != 1,
                scoreRecommandation: scores[index].valeur,
                raisonRecommandation: scores[index].raison,
              ),
          ];
          if (trajetVariants.isEmpty) {
            searchMessage =
                'Aucun moyen de transport disponible sur ce trajet.';
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          searchMessage = switch (controller.dernierEchec) {
            EchecRechercheTrajet.correspondanceNonValidee =>
              'Ce trajet nécessite une correspondance qui n’est pas encore '
                  'validée sur le terrain. Essaie un autre arrêt proche.',
            EchecRechercheTrajet.arretInconnu =>
              'Un des arrêts n’est pas encore relié au réseau disponible.',
            _ => 'Aucun trajet validé ne relie actuellement ces deux arrêts.',
          };
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

  Widget _buildEmptyState() {
    final hasMessage = searchMessage != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasMessage ? Icons.info_outline_rounded : Icons.route_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              searchMessage ?? 'Sélectionnez un départ et une arrivée.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasMessage) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () => setState(() => searchMessage = null),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Modifier les arrêts'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_TrajetVariant> get _sortedVariants {
    final variants = [...trajetVariants];
    variants.sort((a, b) {
      switch (trajetSort) {
        case _TrajetSort.moinsCher:
          return _compareValues(
            a.option.coutTotal,
            b.option.coutTotal,
            a.duration,
            b.duration,
          );
        case _TrajetSort.plusRapide:
          return _compareAvailableDurations(a, b);
        case _TrajetSort.moinsChangements:
          return _compareValues(
            a.option.nombreChangements,
            b.option.nombreChangements,
            a.option.coutTotal,
            b.option.coutTotal,
          );
        case _TrajetSort.recommande:
          return b.scoreRecommandation.compareTo(a.scoreRecommandation);
      }
    });
    return variants;
  }

  int _compareAvailableDurations(_TrajetVariant a, _TrajetVariant b) {
    if (a.duration <= 0 && b.duration > 0) return 1;
    if (b.duration <= 0 && a.duration > 0) return -1;
    return _compareValues(
      a.duration,
      b.duration,
      a.option.coutTotal,
      b.option.coutTotal,
    );
  }

  int _compareValues(
    num firstA,
    num firstB,
    num secondA,
    num secondB,
  ) {
    final first = firstA.compareTo(firstB);
    return first != 0 ? first : secondA.compareTo(secondB);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Rechercher un trajet")),
        body: const Center(child: CircularProgressIndicator()),
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

    if (trajetVariants.isNotEmpty) return _resultats();

    return Scaffold(
      appBar: AppBar(title: const Text('Planifier un trajet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Où souhaitez-vous aller ?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comparez les itinéraires et les moyens de transport.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (controller.loadedFromLocalData)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mode hors connexion : données locales utilisées.',
                      ),
                    ),
                  ],
                ),
              ),
            ChampArret(
              arrets: allStops,
              controller: controller,
              label: 'Arrêt de départ',
              icon: Icons.trip_origin_rounded,
              valeur: selectedDepartName,
              onSelected: (value) {
                selectedDepartName = value.isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.swap_vert_rounded),
              tooltip: 'Inverser les arrêts',
              onPressed: () {
                setState(() {
                  final temp = selectedDepartName;
                  selectedDepartName = selectedArriveeName;
                  selectedArriveeName = temp;
                });
              },
            ),
            const SizedBox(height: 8),
            ChampArret(
              arrets: allStops,
              controller: controller,
              label: 'Arrêt d’arrivée',
              icon: Icons.flag_rounded,
              valeur: selectedArriveeName,
              onSelected: (value) {
                selectedArriveeName = value.isEmpty ? null : value;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: isSearching ? null : chercherTrajets,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildEmptyState()),
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
    required this.durationMin,
    required this.durationMax,
    required this.profilsValidesTerrain,
    required this.congestionPiloteAppliquee,
    required this.scoreRecommandation,
    required this.raisonRecommandation,
  });

  final TransportOption option;
  final double distance;
  final double duration;
  final double durationMin;
  final double durationMax;
  final bool profilsValidesTerrain;
  final bool congestionPiloteAppliquee;
  final double scoreRecommandation;
  final String raisonRecommandation;

  String get libelleDuree {
    if ((durationMax - durationMin).abs() < 0.5) {
      return '${duration.toStringAsFixed(0)} min';
    }
    return '${durationMin.toStringAsFixed(0)}–'
        '${durationMax.toStringAsFixed(0)} min';
  }

  /// Arrêts où l’on change de véhicule : changement de mode ou d’axe.
  List<String> get pointsDeChangement {
    final troncons = option.trajet.troncons;
    final modes = option.modesParTroncon;
    return [
      for (var i = 1; i < troncons.length; i++)
        if (modes[i] != modes[i - 1] || troncons[i].axe != troncons[i - 1].axe)
          troncons[i].depart.name,
    ];
  }

  /// Modes dans l’ordre du trajet, sans répétition consécutive.
  List<String> get modesSuccessifs {
    final resultat = <String>[];
    for (final mode in option.modesParTroncon) {
      if (resultat.isEmpty || resultat.last != mode) resultat.add(mode);
    }
    return resultat;
  }

  List<String> get etapesIntermediaires {
    final troncons = option.trajet.troncons;
    if (troncons.length <= 1) return const [];
    return troncons
        .take(troncons.length - 1)
        .map((t) => t.arrivee.name)
        .toList();
  }
}

enum _TrajetSort {
  recommande('Recommandé'),
  moinsCher('Moins cher'),
  plusRapide('Plus rapide'),
  moinsChangements('Moins de changements');

  const _TrajetSort(this.label);
  final String label;
}

/// Ligne du trajet : un trait par tronçon, coloré selon le mode, et un
/// point creux à chaque changement de véhicule.
class _LigneTrajet extends StatelessWidget {
  const _LigneTrajet({required this.variant});

  final _TrajetVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final troncons = variant.option.trajet.troncons;
    final modes = variant.option.modesParTroncon;
    Widget point({bool changement = false}) => Container(
          width: changement ? 16 : 12,
          height: changement ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: changement ? colors.surface : colors.onSurface,
            border: changement
                ? Border.all(color: colors.onSurface, width: 3)
                : null,
          ),
        );

    return ExcludeSemantics(
      child: Row(
        children: [
          point(),
          for (var i = 0; i < troncons.length; i++) ...[
            if (i > 0 &&
                (modes[i] != modes[i - 1] ||
                    troncons[i].axe != troncons[i - 1].axe))
              point(changement: true),
            Expanded(
              child: Container(
                height: 6,
                color: ModeTransport.pour(modes[i]).couleur,
              ),
            ),
          ],
          point(),
        ],
      ),
    );
  }
}
