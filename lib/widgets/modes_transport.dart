import 'package:flutter/material.dart';

/// Couleur, icône et nom affiché de chaque mode de transport, partagés par
/// tous les écrans pour que le taxi, le minibus et le tricycle restent
/// reconnaissables partout.
class ModeTransport {
  const ModeTransport._(this.libelle, this.icone, this.couleur);

  final String libelle;
  final IconData icone;
  final Color couleur;

  static const taxi = ModeTransport._(
    'Taxi',
    Icons.local_taxi_rounded,
    Color(0xFFD19B00),
  );
  static const minibus = ModeTransport._(
    'Minibus',
    Icons.directions_bus_rounded,
    Color(0xFF2F7FD8),
  );
  static const tricycle = ModeTransport._(
    'Tricycle',
    Icons.electric_rickshaw_rounded,
    Color(0xFF1F9D57),
  );
  static const autre = ModeTransport._(
    'Autre',
    Icons.directions_rounded,
    Colors.grey,
  );

  static ModeTransport pour(String mode) => switch (mode) {
        'taxi' => taxi,
        'minibus' => minibus,
        'tricycle' => tricycle,
        _ => autre,
      };
}

/// Modes d’un trajet dans l’ordre, sans doublon (« taxi », « minibus »…).
List<String> modesUniques(List<String> modes) {
  final uniques = <String>[];
  for (final mode in modes) {
    if (!uniques.contains(mode)) uniques.add(mode);
  }
  return uniques;
}

/// Petites icônes colorées des modes d’un trajet. Les lecteurs d’écran
/// entendent « Taxi + Minibus ». Rien n’est affiché sans mode connu.
class IconesModes extends StatelessWidget {
  const IconesModes({super.key, required this.modes, this.taille = 18});

  final List<String> modes;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final uniques = modesUniques(modes);
    if (uniques.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: uniques.map((m) => ModeTransport.pour(m).libelle).join(' + '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, mode) in uniques.indexed) ...[
            if (index > 0) const SizedBox(width: 4),
            Icon(
              ModeTransport.pour(mode).icone,
              size: taille,
              color: ModeTransport.pour(mode).couleur,
            ),
          ],
        ],
      ),
    );
  }
}
