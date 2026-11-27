import 'package:flutter/material.dart';

import '../models/trajet_enregistre.dart';
import 'modes_transport.dart';

/// Une ligne compacte « Départ → Arrivée » pour l’historique et les favoris.
/// Glisser vers la gauche la supprime.
class LigneTrajetEnregistre extends StatelessWidget {
  const LigneTrajetEnregistre({
    super.key,
    required this.trajet,
    required this.detail,
    required this.onTap,
    required this.onSupprime,
    this.favori = false,
  });

  final TrajetEnregistre trajet;
  final String detail;
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
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

/// Modes d’un trajet enregistré, dans l’ordre et sans doublon.
String libelleModes(List<String> modes) {
  final uniques = <String>[];
  for (final mode in modes) {
    if (!uniques.contains(mode)) uniques.add(mode);
  }
  return uniques.map((mode) => ModeTransport.pour(mode).libelle).join(' + ');
}
