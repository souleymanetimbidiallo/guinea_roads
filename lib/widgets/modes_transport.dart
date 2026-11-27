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
