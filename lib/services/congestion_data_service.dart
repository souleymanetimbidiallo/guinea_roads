import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../models/creneau_congestion.dart';

class CongestionDataService {
  CongestionDataService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<List<CreneauCongestion>> charger() async {
    final contenu = await _assetBundle
        .loadString('assets/data/creneaux_congestion_pilotes.json');
    final donnees = json.decode(contenu) as List;
    return donnees
        .map((item) => CreneauCongestion.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
