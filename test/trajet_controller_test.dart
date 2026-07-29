import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/controllers/trajet_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('charge les données locales lorsque Firestore retourne une liste vide',
      () async {
    final controller = TrajetController(
      firestoreLoader: () async => [],
    );

    await controller.loadTronconsFromFirestore();

    expect(controller.allTroncons, isNotEmpty);
    expect(controller.loadedFromLocalData, isTrue);
  });

  test('charge les données locales lorsque Firestore échoue', () async {
    final controller = TrajetController(
      firestoreLoader: () async => throw Exception('hors connexion'),
    );

    await controller.loadTronconsFromFirestore();

    expect(controller.allTroncons, isNotEmpty);
    expect(controller.loadedFromLocalData, isTrue);
  });
}
