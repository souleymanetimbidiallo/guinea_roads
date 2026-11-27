import 'package:shared_preferences/shared_preferences.dart';
import '../models/trajet_enregistre.dart';

class HistoriqueService {
  static const String keyHistorique = "historique_trajets";
  static const int nombreMaximum = 20;

  static Future<void> ajouterTrajet(TrajetEnregistre trajet) async {
    final prefs = await SharedPreferences.getInstance();
    final trajets = await lireHistorique();
    trajets.removeWhere(
      (element) => element.identifiant == trajet.identifiant,
    );
    trajets.insert(0, trajet);
    await prefs.setStringList(
      keyHistorique,
      trajets.take(nombreMaximum).map((item) => item.toStorage()).toList(),
    );
  }

  static Future<List<TrajetEnregistre>> lireHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(keyHistorique) ?? const [])
        .map(TrajetEnregistre.fromStorage)
        .whereType<TrajetEnregistre>()
        .toList();
  }

  /// Retire un trajet de l’historique.
  static Future<void> supprimer(TrajetEnregistre trajet) async {
    final prefs = await SharedPreferences.getInstance();
    final trajets = await lireHistorique()
      ..removeWhere((element) => element.identifiant == trajet.identifiant);
    await prefs.setStringList(
      keyHistorique,
      trajets.map((item) => item.toStorage()).toList(),
    );
  }

  /// Remet un trajet supprimé à sa place (pour « Annuler »).
  static Future<void> remettre(TrajetEnregistre trajet, int position) async {
    final prefs = await SharedPreferences.getInstance();
    final trajets = await lireHistorique()
      ..removeWhere((element) => element.identifiant == trajet.identifiant);
    trajets.insert(position.clamp(0, trajets.length), trajet);
    await prefs.setStringList(
      keyHistorique,
      trajets.take(nombreMaximum).map((item) => item.toStorage()).toList(),
    );
  }

  static Future<void> viderHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyHistorique);
  }
}
