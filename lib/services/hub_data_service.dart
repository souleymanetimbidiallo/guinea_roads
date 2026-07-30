import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../models/hub_mobilite.dart';

class HubDataService {
  HubDataService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<List<HubMobilite>> charger() async {
    final contenu =
        await _assetBundle.loadString('assets/data/hubs_valides.json');
    return (json.decode(contenu) as List)
        .map((item) => HubMobilite.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
