import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../models/corridor_axe.dart';

class CorridorDataService {
  CorridorDataService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<List<CorridorAxe>> charger() async {
    final contenu = await _assetBundle
        .loadString('assets/data/corridors_axes_pilotes.json');
    return (json.decode(contenu) as List)
        .map((item) => CorridorAxe.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
