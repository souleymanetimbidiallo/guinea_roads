import 'package:shared_preferences/shared_preferences.dart';

class HistoriqueService {
  static const String keyHistorique = "historique_trajets";

  static Future<void> ajouterTrajet(String depart, String arrivee) async {
    final prefs = await SharedPreferences.getInstance();
    final trajets = prefs.getStringList(keyHistorique) ?? [];
    trajets.insert(0, "$depart → $arrivee");
    await prefs.setStringList(keyHistorique, trajets.take(10).toList());

    print("📚 Historique sauvegardé : ${prefs.getStringList(keyHistorique)}");
  }


  static Future<List<String>> lireHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyHistorique) ?? [];
  }

  static Future<void> viderHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyHistorique);
  }
}
