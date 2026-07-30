import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/correspondance.dart';

class CorrespondanceDataService {
  CorrespondanceDataService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  static const cheminParDefaut = 'assets/data/correspondances_validees.json';

  final AssetBundle _assetBundle;

  Future<List<Correspondance>> charger({
    String chemin = cheminParDefaut,
  }) async {
    final contenu = await _assetBundle.loadString(chemin);
    return decoder(contenu);
  }

  List<Correspondance> decoder(String contenu) {
    final donnees = json.decode(contenu);
    if (donnees is! List) {
      throw const FormatException(
        'Le fichier des correspondances doit contenir une liste.',
      );
    }
    return donnees
        .map(
          (item) => Correspondance.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }
}
