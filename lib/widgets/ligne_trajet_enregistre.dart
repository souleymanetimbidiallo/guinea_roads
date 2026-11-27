import 'package:flutter/material.dart';

import '../models/trajet_enregistre.dart';
import 'modes_transport.dart';

/// Une ligne compacte « Départ → Arrivée » pour l’historique et les favoris.
/// Glisser vers la gauche la supprime.
class LigneTrajetEnregistre extends StatelessWidget {
  const LigneTrajetEnregistre({
    super.key,
    required this.trajet,
    this.detail,
    required this.onTap,
    required this.onSupprime,
    this.favori = false,
  });

  final TrajetEnregistre trajet;

  /// Texte après les icônes des modes (heure, « Favori »…).
  final String? detail;
  final VoidCallback onTap;
  final VoidCallback onSupprime;
  final bool favori;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dismissible(
      key:
          ValueKey('${favori ? 'favori' : 'historique'}-${trajet.identifiant}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onSupprime(),
      background: Container(
        color: colors.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Supprimer',
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: colors.onErrorContainer),
          ],
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          favori ? Icons.star_rounded : Icons.history_rounded,
          color: favori ? ModeTransport.taxi.couleur : colors.primary,
        ),
        title: Text(
          '${trajet.depart} → ${trajet.arrivee}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              IconesModes(modes: trajet.modes),
              if (trajet.modes.isNotEmpty && (detail ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
              ],
              if ((detail ?? '').isNotEmpty)
                Flexible(child: Text(detail!, overflow: TextOverflow.ellipsis)),
              if (trajet.modes.isEmpty && (detail ?? '').isEmpty)
                const Text('Touchez pour recalculer'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
