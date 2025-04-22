import 'troncon.dart';

class Trajet {
  final List<Troncon> troncons;

  Trajet({required this.troncons});

  int getTotalCost(String type) {
    return troncons.fold(0, (total, t) => total + (t.prixParType[type] ?? 0));
  }
}