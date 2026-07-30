import 'package:flutter/material.dart';
import '../models/stop.dart';
import '../controllers/trajet_controller.dart';
import '../models/transport_option.dart';
import 'trajet_result_page.dart';

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

  Set<String> _axesPourStop(Stop stop) {
    final nom = Stop.normaliserPourRecherche(stop.name);
    final axes = <String>{};
    for (final troncon in controller.allTroncons) {
      if (Stop.normaliserPourRecherche(troncon.depart.name) == nom ||
          Stop.normaliserPourRecherche(troncon.arrivee.name) == nom) {
        axes.add(troncon.axe);
      }
    }
    if (axes.isEmpty && stop.axe.trim().isNotEmpty) axes.add(stop.axe);
    return axes;
  }

  bool _estCorrespondance(Stop stop) {
    final nom = Stop.normaliserPourRecherche(stop.name).replaceAll(' ', '-');
    return controller.correspondances.any(
      (correspondance) =>
          correspondance.pointDepartId == nom ||
          correspondance.pointArriveeId == nom,
    );
  }

  Widget _buildStopAutocomplete({
    required String label,
    required IconData icon,
    required String? valeur,
    required ValueChanged<String> onSelected,
  }) {
    return Autocomplete<Stop>(
      key: ValueKey('$label-$valeur'),
      displayStringForOption: (stop) => stop.name,
      optionsBuilder: (value) => allStops
          .where((stop) => stop.correspondARecherche(value.text))
          .take(8),
      onSelected: (stop) => onSelected(stop.name),
      optionsViewBuilder: (context, select, options) {
        final suggestions = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, maxWidth: 520),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final stop = suggestions[index];
                  final axes = _axesPourStop(stop).join(' ↔ ');
                  final correspondance = _estCorrespondance(stop);
                  return ListTile(
                    leading: Icon(
                      correspondance
                          ? Icons.transfer_within_a_station_rounded
                          : Icons.place_outlined,
                    ),
                    title: Text(stop.name),
                    subtitle: Text(
                      [
                        if (axes.isNotEmpty) axes,
                        if (correspondance) 'Point de correspondance',
                      ].join(' • '),
                    ),
                    onTap: () => select(stop),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (valeur != null && textController.text.isEmpty) {
          textController.text = valeur;
        }
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (_) => onSelected(''),
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Saisissez un quartier ou un repère',
            prefixIcon: Icon(icon),
            suffixIcon: textController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      textController.clear();
                      onSelected('');
                    },
                  ),
            border: const OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget buildTrajetCard(_TrajetVariant variant) {
    final option = variant.option;
    final modes = option.modesUtilises;
    final colors = Theme.of(context).colorScheme;
    final isRecommended = identical(_sortedVariants.first, variant);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
                    selectedTrajet: option.trajet,
                    tarifV2: option.tarifV2,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          trajetSort.label,
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '${option.coutTotal} GNF',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...modes.map(_buildModeChip),
                    if (option.tarifV2 != null)
                      Chip(
                        avatar: const Icon(Icons.toll_rounded, size: 16),
                        label: Text(
                          '${option.tarifV2!.nombreTranches} tranche'
                          '${option.tarifV2!.nombreTranches > 1 ? 's' : ''}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildMetric(
                      Icons.route_rounded,
                      '${variant.distance.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 16),
                    _buildMetric(
                      Icons.schedule_rounded,
                      variant.libelleDuree,
                    ),
                    const SizedBox(width: 16),
                    _buildMetric(
                      Icons.alt_route_rounded,
                      '${option.trajet.troncons.length} tronçons',
                    ),
                  ],
                ),
                const Divider(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.turn_slight_right_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        variant.etapesIntermediaires.isEmpty
                            ? 'Trajet direct'
                            : 'Via ${variant.etapesIntermediaires.join(' • ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                if (option.nombreChangements > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${option.nombreChangements} changement'
                    '${option.nombreChangements > 1 ? 's' : ''} de transport',
                    style: TextStyle(
                      color: colors.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (option.trajet.correspondances.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...option.trajet.correspondances.map(
                    (correspondance) => Text(
                      'Correspondance à ${correspondance.lieu} • '
                      '${correspondance.libelleType.toLowerCase()} '
                      '${correspondance.dureeMinMinutes}–'
                      '${correspondance.dureeMaxMinutes} min',
                      style: TextStyle(
                        color: colors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (!variant.profilsValidesTerrain) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Durée pilote • coefficients à valider sur le terrain',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode) {
    final (icon, color) = switch (mode) {
      'taxi' => (Icons.local_taxi_rounded, const Color(0xFFD19B00)),
      'minibus' => (Icons.directions_bus_rounded, const Color(0xFF2474C6)),
      'tricycle' => (Icons.electric_rickshaw_rounded, const Color(0xFF168A45)),
      _ => (Icons.directions_rounded, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            mode.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
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
          return _compareValues(
            a.option.nombreChangements,
            b.option.nombreChangements,
            a.option.coutTotal,
            b.option.coutTotal,
          );
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
            _buildStopAutocomplete(
              label: 'Arrêt de départ',
              icon: Icons.my_location,
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
            _buildStopAutocomplete(
              label: 'Arrêt d’arrivée',
              icon: Icons.flag,
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
            if (trajetVariants.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${trajetVariants.length} options trouvées',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  DropdownButton<_TrajetSort>(
                    value: trajetSort,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _TrajetSort.values
                        .map(
                          (sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(sort.label),
                          ),
                        )
                        .toList(),
                    onChanged: (sort) {
                      if (sort != null) setState(() => trajetSort = sort);
                    },
                  ),
                ],
              ),
            if (trajetVariants.isNotEmpty) const SizedBox(height: 12),
            Expanded(
              child: trajetVariants.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      children: _sortedVariants.map(buildTrajetCard).toList(),
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
    required this.durationMin,
    required this.durationMax,
    required this.profilsValidesTerrain,
  });

  final TransportOption option;
  final double distance;
  final double duration;
  final double durationMin;
  final double durationMax;
  final bool profilsValidesTerrain;

  String get libelleDuree {
    if ((durationMax - durationMin).abs() < 0.5) {
      return '${duration.toStringAsFixed(0)} min';
    }
    return '${durationMin.toStringAsFixed(0)}–'
        '${durationMax.toStringAsFixed(0)} min';
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
