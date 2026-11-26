import 'package:flutter_test/flutter_test.dart';
import 'package:guinea_roads/views/trajet_map_page.dart'
    show formaterDureeEstimee;

void main() {
  test('affiche une fourchette lorsque les bornes diffèrent', () {
    expect(formaterDureeEstimee(85.2, 126.4), '85–126 min');
  });

  test('affiche une seule valeur lorsque les bornes sont égales', () {
    expect(formaterDureeEstimee(32.1, 32.3), '32 min');
  });
}
