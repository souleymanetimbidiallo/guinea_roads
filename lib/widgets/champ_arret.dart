import 'package:flutter/material.dart';

import '../controllers/trajet_controller.dart';
import '../models/stop.dart';

/// Champ de saisie d’un arrêt avec suggestions (nom, axes desservis,
/// point de correspondance). Utilisé sur l’accueil et dans la recherche.
class ChampArret extends StatelessWidget {
  const ChampArret({
    super.key,
    required this.label,
    required this.icon,
    required this.valeur,
    required this.arrets,
    required this.controller,
    required this.onSelected,
    this.surFondColore = false,
  });

  final String label;
  final IconData icon;
  final String? valeur;
  final List<Stop> arrets;
  final TrajetController controller;
  final ValueChanged<String> onSelected;

  /// Style plein, sans bordure, pour un champ posé sur une carte colorée.
  final bool surFondColore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Autocomplete<Stop>(
      key: ValueKey('$label-$valeur'),
      displayStringForOption: (stop) => stop.name,
      optionsBuilder: (value) =>
          arrets.where((stop) => stop.correspondARecherche(value.text)).take(8),
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
                  final axes = controller.axesPourArret(stop).join(' ↔ ');
                  final correspondance =
                      controller.estPointDeCorrespondance(stop);
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
          textController.text = valeur!;
        }
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (_) => onSelected(''),
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Quartier ou repère',
            prefixIcon: Icon(icon),
            filled: surFondColore ? true : null,
            fillColor: surFondColore ? colors.surface : null,
            border: surFondColore
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  )
                : const OutlineInputBorder(),
            enabledBorder: surFondColore
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  )
                : null,
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
          ),
        );
      },
    );
  }
}
