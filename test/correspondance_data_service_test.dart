import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/correspondance.dart';
import 'package:guinea_roads/models/segment_transport.dart';
import 'package:guinea_roads/models/troncon.dart';
import 'package:guinea_roads/services/calcul_correspondance_service.dart';
import 'package:guinea_roads/services/correspondance_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<Troncon>> chargerTroncons() async {
    final contenu =
        await rootBundle.loadString('assets/data/troncons_backup.json');
    return (json.decode(contenu) as List)
        .map((item) => Troncon.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  test('garde la correspondance terrain de Hamdallaye', () async {
    final correspondances = await CorrespondanceDataService().charger();
    final hamdallaye = correspondances.singleWhere(
      (item) => item.id == 'hamdallaye-le-prince-corniche-nord',
    );

    expect(hamdallaye.type, TypeCorrespondance.marche);
    expect(hamdallaye.dureeMinMinutes, 2);
    expect(hamdallaye.dureeMaxMinutes, 4);
    expect(hamdallaye.cout, 0);
    expect(hamdallaye.bidirectionnelle, isTrue);
    expect(hamdallaye.valideeTerrain, isTrue);
    expect(
      hamdallaye.instructions,
      'Contourner le rond-point selon le point d’arrivée.',
    );
  });

  test('les nouvelles correspondances restent à confirmer et sourcées',
      () async {
    final correspondances = await CorrespondanceDataService().charger();
    final aConfirmer = correspondances.where((item) => item.aConfirmer);

    expect(aConfirmer, isNotEmpty);
    expect(correspondances.where((item) => item.valideeTerrain), hasLength(1));
    for (final correspondance in correspondances) {
      expect(correspondance.sourceValidation.trim(), isNotEmpty);
      expect(correspondance.lieu.trim(), isNotEmpty);
      expect(
        correspondance.dureeMaxMinutes,
        greaterThanOrEqualTo(correspondance.dureeMinMinutes),
      );
    }
    final ids = correspondances.map((item) => item.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('chaque correspondance relie des arrêts existants', () async {
    final correspondances = await CorrespondanceDataService().charger();
    final points = <String>{};
    for (final troncon in await chargerTroncons()) {
      final segment = SegmentTransport.depuisTroncon(troncon);
      points
        ..add('${segment.axeId}|${_slug(troncon.depart.name)}')
        ..add('${segment.axeId}|${_slug(troncon.arrivee.name)}');
    }

    for (final correspondance in correspondances) {
      expect(
        points,
        contains(
          '${correspondance.axeDepartId}|${correspondance.pointDepartId}',
        ),
        reason: correspondance.id,
      );
      expect(
        points,
        contains(
          '${correspondance.axeArriveeId}|${correspondance.pointArriveeId}',
        ),
        reason: correspondance.id,
      );
    }
  });

  test('conserve la fourchette dans le calcul des pénalités', () async {
    final correspondances = await CorrespondanceDataService().charger();
    final hamdallaye = correspondances.where(
      (item) => item.id == 'hamdallaye-le-prince-corniche-nord',
    );

    final resultat = const CalculCorrespondanceService().calculer(hamdallaye);

    expect(resultat.coutTotal, 0);
    expect(resultat.dureeTotaleMinMinutes, 2);
    expect(resultat.dureeTotaleMaxMinutes, 4);
    expect(resultat.nombreChangements, 1);
    expect(resultat.nombreAConfirmer, 0);
  });
}

String _slug(String valeur) => valeur
    .toLowerCase()
    .replaceAll(RegExp(r'[àáâä]'), 'a')
    .replaceAll(RegExp(r'[èéêë]'), 'e')
    .replaceAll(RegExp(r'[ìíîï]'), 'i')
    .replaceAll(RegExp(r'[òóôö]'), 'o')
    .replaceAll(RegExp(r'[ùúûü]'), 'u')
    .replaceAll(RegExp(r'[ç]'), 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
