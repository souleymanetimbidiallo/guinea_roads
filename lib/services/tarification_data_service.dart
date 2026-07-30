import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/tarification.dart';

class TarificationDataService {
  TarificationDataService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  static const cheminParDefaut = 'assets/data/axes_tarifaires_pilotes.json';

  final AssetBundle _assetBundle;

  Future<List<AxeTarifaire>> chargerAxes({
    String chemin = cheminParDefaut,
  }) async {
    final contenu = await _assetBundle.loadString(chemin);
    return decoderAxes(contenu);
  }

  List<AxeTarifaire> decoderAxes(String contenu) {
    final donnees = json.decode(contenu);
    if (donnees is! List) {
      throw const FormatException(
        'Le fichier tarifaire doit contenir une liste d’axes.',
      );
    }

    return donnees
        .map(
          (item) => AxeTarifaire.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
