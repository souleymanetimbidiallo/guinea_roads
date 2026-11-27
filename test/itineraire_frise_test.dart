import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';
import 'package:guinea_roads/views/trajet_result_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la frise montre les étapes et les correspondances dans l’ordre',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final controller = TrajetController(firestoreLoader: () async => []);
    await tester.runAsync(controller.loadTronconsFromFirestore);
    final stops = controller.extractAllStops();
    final depart = stops.firstWhere((s) => s.name == 'Km 36');
    final arrivee = stops.firstWhere((s) => s.name == 'Kagbelen');
    final trajet = controller.getMultiAxeTrajet(depart, arrivee)!;

    await tester.pumpWidget(
      MaterialApp(
        home: TrajetResultPage(
          depart: depart,
          arrivee: arrivee,
          modes: List.filled(trajet.troncons.length, 'taxi'),
          selectedTrajet: trajet,
        ),
      ),
    );
    for (var i = 0;
        i < 20 && find.text('Étapes du trajet').evaluate().isEmpty;
        i++) {
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    expect(find.text('Départ'), findsOneWidget);
    expect(find.text('Arrivée'), findsOneWidget);
    expect(find.text('Changement de véhicule'), findsNWidgets(2));
    expect(find.text('Taxi · Transversale 9'), findsOneWidget);
    expect(find.text('Voir sur la carte'), findsOneWidget);

    double y(String texte) => tester.getTopLeft(find.text(texte).last).dy;
    expect(y('Lansanayah'), lessThan(y('Cimenterie')));
    expect(y('Cimenterie'), lessThan(y('Kagbelen')));
  });
}
