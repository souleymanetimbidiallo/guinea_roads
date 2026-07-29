import 'dart:convert';

class TrajetEnregistre {
  TrajetEnregistre({
    required this.depart,
    required this.arrivee,
    required List<String> modes,
    DateTime? enregistreLe,
  })  : modes = List.unmodifiable(modes),
        enregistreLe = enregistreLe ?? DateTime.now();

  final String depart;
  final String arrivee;
  final List<String> modes;
  final DateTime enregistreLe;

  String get identifiant =>
      '${depart.toLowerCase().trim()}|${arrivee.toLowerCase().trim()}';

  String toStorage() {
    return jsonEncode({
      'depart': depart,
      'arrivee': arrivee,
      'modes': modes,
      'enregistreLe': enregistreLe.toIso8601String(),
    });
  }

  static TrajetEnregistre? fromStorage(String value) {
    try {
      final data = jsonDecode(value) as Map<String, dynamic>;
      return TrajetEnregistre(
        depart: data['depart'] as String,
        arrivee: data['arrivee'] as String,
        modes: List<String>.from(data['modes'] as List? ?? const []),
        enregistreLe: DateTime.tryParse(data['enregistreLe'] as String? ?? ''),
      );
    } on FormatException {
      return _fromLegacyValue(value);
    } on TypeError {
      return null;
    }
  }

  static TrajetEnregistre? _fromLegacyValue(String value) {
    final parts = value.split(' → ');
    if (parts.length != 2) return null;
    return TrajetEnregistre(
      depart: parts.first.trim(),
      arrivee: parts.last.trim(),
      modes: const [],
      enregistreLe: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
