import 'dart:convert';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import '../models/profil_transport.dart';

class ProfilTransportDataService {
  ProfilTransportDataService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<List<ProfilTransport>> charger() async {
    final contenu = await _assetBundle
        .loadString('assets/data/profils_transport_pilotes.json');
    final donnees = json.decode(contenu) as List;
    return donnees
        .map((item) => ProfilTransport.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
