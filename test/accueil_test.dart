import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/views/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('l’accueil propose la recherche, les trajets et les tarifs',
      (tester) async {
    final semantique = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'trajets_favoris': [
        '{"depart":"Sonfonia T7","arrivee":"Kobayah Pharmacie Dara",'
            '"modes":["taxi"],"enregistreLe":"2026-07-30T13:33:00"}',
      ],
    });

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Où allez-vous ?'), findsOneWidget);
    expect(find.text('Départ'), findsOneWidget);
    expect(find.text('Arrivée'), findsOneWidget);
    expect(find.text('Rechercher les trajets'), findsOneWidget);
    expect(find.text('Sonfonia T7 → Kobayah Pharmacie Dara'), findsOneWidget);
    expect(find.text('Favori'), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp(r'Favori[\s\S]*Taxi|Taxi[\s\S]*Favori')),
        findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tricycle'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Prix d’un tronçon'), findsOneWidget);
    expect(find.text('2 000 GNF'), findsOneWidget);
    expect(find.text('1 500 GNF'), findsOneWidget);
    expect(find.text('2 500 GNF'), findsOneWidget);
    semantique.dispose();
  });
}
