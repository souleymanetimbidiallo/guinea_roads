class CreneauCongestion {
  const CreneauCongestion({
    required this.id,
    required this.nom,
    required this.joursSemaine,
    required this.debutMinutes,
    required this.finMinutes,
    required this.niveau,
    this.axeId,
    this.valideTerrain = false,
    this.source = '',
  });

  final String id;
  final String nom;
  final List<int> joursSemaine;
  final int debutMinutes;
  final int finMinutes;
  final double niveau;
  final String? axeId;
  final bool valideTerrain;
  final String source;

  factory CreneauCongestion.fromJson(Map<String, dynamic> json) {
    final debut = _minutesDepuisHeure(json['debut'] as String);
    final fin = _minutesDepuisHeure(json['fin'] as String);
    final niveau = (json['niveau'] as num).toDouble();
    if (niveau < 0 || niveau > 1) {
      throw const FormatException(
          'Le niveau de congestion doit être entre 0 et 1.');
    }
    return CreneauCongestion(
      id: json['id'] as String,
      nom: json['nom'] as String,
      joursSemaine: List<int>.from(json['joursSemaine'] as List),
      debutMinutes: debut,
      finMinutes: fin,
      niveau: niveau,
      axeId: json['axeId'] as String?,
      valideTerrain: json['valideTerrain'] as bool? ?? false,
      source: json['source'] as String? ?? '',
    );
  }

  bool correspond(DateTime date, String axe) {
    if (!joursSemaine.contains(date.weekday)) return false;
    if (axeId != null && axeId != _slug(axe)) return false;
    final minute = date.hour * 60 + date.minute;
    if (debutMinutes <= finMinutes) {
      return minute >= debutMinutes && minute < finMinutes;
    }
    return minute >= debutMinutes || minute < finMinutes;
  }
}

int _minutesDepuisHeure(String valeur) {
  final parties = valeur.split(':');
  if (parties.length != 2) {
    throw FormatException('Heure invalide : $valeur');
  }
  final heure = int.parse(parties[0]);
  final minute = int.parse(parties[1]);
  if (heure < 0 || heure > 23 || minute < 0 || minute > 59) {
    throw FormatException('Heure invalide : $valeur');
  }
  return heure * 60 + minute;
}

String _slug(String valeur) {
  return valeur
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[àáâä]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
