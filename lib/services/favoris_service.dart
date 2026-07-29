import 'package:shared_preferences/shared_preferences.dart';

import '../models/trajet_enregistre.dart';

class FavorisService {
  static const String keyFavoris = 'trajets_favoris';

  static Future<List<TrajetEnregistre>> lireFavoris() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(keyFavoris) ?? const [])
        .map(TrajetEnregistre.fromStorage)
        .whereType<TrajetEnregistre>()
        .toList();
  }

  static Future<bool> contient(String depart, String arrivee) async {
    final trajet = TrajetEnregistre(
      depart: depart,
      arrivee: arrivee,
      modes: const [],
    );
    final favoris = await lireFavoris();
    return favoris.any(
      (element) => element.identifiant == trajet.identifiant,
    );
  }

  static Future<void> ajouter(TrajetEnregistre trajet) async {
    final prefs = await SharedPreferences.getInstance();
    final favoris = await lireFavoris();
    favoris.removeWhere(
      (element) => element.identifiant == trajet.identifiant,
    );
    favoris.insert(0, trajet);
    await prefs.setStringList(
      keyFavoris,
      favoris.map((item) => item.toStorage()).toList(),
    );
  }

  static Future<void> supprimer(String depart, String arrivee) async {
    final prefs = await SharedPreferences.getInstance();
    final identifiant = TrajetEnregistre(
      depart: depart,
      arrivee: arrivee,
      modes: const [],
    ).identifiant;
    final favoris = await lireFavoris();
    favoris.removeWhere((element) => element.identifiant == identifiant);
    await prefs.setStringList(
      keyFavoris,
      favoris.map((item) => item.toStorage()).toList(),
    );
  }

  static Future<bool> basculer(TrajetEnregistre trajet) async {
    if (await contient(trajet.depart, trajet.arrivee)) {
      await supprimer(trajet.depart, trajet.arrivee);
      return false;
    }
    await ajouter(trajet);
    return true;
  }
}
