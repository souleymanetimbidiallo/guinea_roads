import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/guinea_roads_app.dart';

void main() {
  testWidgets('affiche les informations de démarrage',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GuineaRoadsApp());

    expect(find.text('Guinea Roads'), findsOneWidget);
    expect(find.text('Vos trajets, plus simplement.'), findsOneWidget);
    expect(find.text('CONAKRY • GUINÉE'), findsOneWidget);
  });
}
