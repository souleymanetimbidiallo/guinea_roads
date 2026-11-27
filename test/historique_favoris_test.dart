import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/models/trajet_enregistre.dart';
import 'package:guinea_roads/services/historique_service.dart';
import 'package:guinea_roads/views/favoris_page.dart';
import 'package:guinea_roads/views/historique_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrajetEnregistre _trajet(String depart, String arrivee, DateTime date) =>
    TrajetEnregistre(
      depart: depart,
      arrivee: arrivee,
      modes: const ['taxi', 'minibus'],
      enregistreLe: date,
    );

void main() {
  final maintenant = DateTime(2026, 11, 26, 18);

  test('nomme les jours de l’historique', () {
    expect(libelleJour(DateTime(2026, 11, 26, 9), maintenant), 'Aujourd’hui');
    expect(libelleJour(DateTime(2026, 11, 25, 22), maintenant), 'Hier');
    expect(
        libelleJour(DateTime(2026, 11, 23), maintenant), 'Lundi 23 novembre');
    expect(libelleJour(DateTime(2026, 8, 1), maintenant), 'Samedi 1er août');
    expect(libelleJour(DateTime(2025, 12, 31), maintenant),
        'Mercredi 31 décembre 2025');
    expect(libelleJour(DateTime.fromMillisecondsSinceEpoch(0), maintenant),
        'Plus ancien');
  });

  test('supprime un trajet puis le remet à sa place', () async {
    SharedPreferences.setMockInitialValues({});
    final a = _trajet('Aéroport', 'Madina', DateTime(2026, 11, 26));
    final b = _trajet('Bambeto', 'Cosa', DateTime(2026, 11, 25));
    await HistoriqueService.ajouterTrajet(b);
    await HistoriqueService.ajouterTrajet(a);

    await HistoriqueService.supprimer(a);
    expect((await HistoriqueService.lireHistorique()).map((t) => t.depart),
        ['Bambeto']);

    await HistoriqueService.remettre(a, 0);
    expect((await HistoriqueService.lireHistorique()).map((t) => t.depart),
        ['Aéroport', 'Bambeto']);
  });

  testWidgets('groupe l’historique par jour en lignes compactes',
      (tester) async {
    final semantique = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      HistoriqueService.keyHistorique: [
        _trajet('Aéroport', 'Madina', DateTime(2026, 11, 26, 9, 5)).toStorage(),
        _trajet('Bambeto', 'Cosa', DateTime(2026, 11, 25, 20)).toStorage(),
      ],
    });
    await tester.pumpWidget(
      MaterialApp(home: HistoriquePage(maintenant: () => maintenant)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Aéroport → Madina'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Taxi \+ Minibus')), findsNWidgets(2));
    expect(find.byIcon(Icons.local_taxi_rounded), findsNWidgets(2));

    await tester.drag(find.text('Bambeto → Cosa'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Bambeto → Cosa'), findsNothing);
    expect(find.text('Trajet retiré de l’historique.'), findsOneWidget);
    expect((await HistoriqueService.lireHistorique()), hasLength(1));
    semantique.dispose();
  });

  testWidgets('explique comment ajouter un favori', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: FavorisPage()));
    await tester.pumpAndSettle();

    expect(find.text('Aucun trajet favori'), findsOneWidget);
    expect(find.text('Pour ajouter un favori'), findsOneWidget);
    expect(
        find.text('Touchez l’étoile en haut de l’itinéraire.'), findsOneWidget);
  });
}
