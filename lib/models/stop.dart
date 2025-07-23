class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int order;
  final String axe;

  Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.order,
    required this.axe,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'],
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      order: json['order'],
      axe: json['axe'],
    );
  }
}
