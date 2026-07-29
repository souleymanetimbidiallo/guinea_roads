import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/stop.dart';
import '../models/troncon.dart';
import '../services/google_directions_service.dart';

class TrajetMapPage extends StatefulWidget {
  final List<Stop> arrets;
  final String title;
  final Map<Troncon, String>? tronconModes;

  const TrajetMapPage({
    required this.arrets,
    required this.title,
    this.tronconModes,
    Key? key,
  }) : super(key: key);

  @override
  State<TrajetMapPage> createState() => _TrajetMapPageState();
}

class _TrajetMapPageState extends State<TrajetMapPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  final GoogleRoutesService _directionsService = GoogleRoutesService();
  LatLngBounds? trajetBounds;

  bool trajetsCharges = false;
  String? routeWarning;
  double totalDistance = 0;
  double totalDuration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupMap());
  }

  Future<void> _setupMap() async {
    if (widget.arrets.isEmpty) return;

    List<LatLng> latLngs = [];

    for (var stop in widget.arrets) {
      final latLng = LatLng(stop.latitude, stop.longitude);
      latLngs.add(latLng);

      markers.add(
        Marker(
          markerId: MarkerId(stop.name),
          position: latLng,
          infoWindow: InfoWindow(title: stop.name),
        ),
      );
    }

    trajetBounds = _calculateBounds(latLngs);

    try {
      await _loadPolylineFromGoogle(widget.arrets);
      setState(() {
        trajetsCharges = true;
      });
    } catch (e) {
      debugPrint('Impossible de charger les trajets : $e');
      setState(() {
        trajetsCharges = false;
      });
    }
  }

  Future<void> _loadPolylineFromGoogle(List<Stop> stops) async {
    if (stops.length < 2) return;

    double distance = 0;
    double duration = 0;
    String? warning;

    for (int i = 0; i < stops.length - 1; i++) {
      final stop1 = stops[i];
      final stop2 = stops[i + 1];

      try {
        final result = await _directionsService.getDrivingRoute(stop1, stop2);

        if (result.points.isNotEmpty) {
          final color = _getColorForTroncon(stop1.name, stop2.name);

          polylines.add(Polyline(
            polylineId: PolylineId('route-$i'),
            points: result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            color: color,
            width: 5,
          ));

          distance += result.distanceKm;
          duration += result.durationMinutes;
        } else {
          _addFallbackPolyline(i, stop1, stop2);
        }
      } catch (error) {
        debugPrint('Google Directions indisponible : $error');
        warning ??= error.toString();
        _addFallbackPolyline(i, stop1, stop2);
      }
    }

    if (!mounted) return;
    setState(() {
      totalDistance = distance;
      totalDuration = duration;
      if (warning != null) {
        routeWarning =
            'Tracé routier indisponible ($warning). Ligne pointillée approximative.';
      }
    });
  }

  void _addFallbackPolyline(int index, Stop from, Stop to) {
    routeWarning =
        'Tracé routier indisponible. La ligne pointillée est approximative.';
    polylines.add(
      Polyline(
        polylineId: PolylineId('fallback-$index'),
        points: [
          LatLng(from.latitude, from.longitude),
          LatLng(to.latitude, to.longitude),
        ],
        color: _getColorForTroncon(from.name, to.name),
        width: 4,
        patterns: [PatternItem.dash(16), PatternItem.gap(10)],
      ),
    );
  }

  Color _getColorForTroncon(String from, String to) {
    if (widget.tronconModes != null) {
      for (final entry in widget.tronconModes!.entries) {
        final t = entry.key;
        final m = entry.value;
        if ((t.depart.name == from && t.arrivee.name == to) ||
            (t.depart.name == to && t.arrivee.name == from)) {
          return _colorForMode(m);
        }
      }
    }
    return Colors.blueAccent;
  }

  Color _colorForMode(String mode) {
    switch (mode) {
      case 'taxi':
        return Colors.yellow;
      case 'minibus':
        return Colors.blue;
      case 'tricycle':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (var p in points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _centrerSurTrajet() {
    if (trajetBounds != null) {
      mapController
          .animateCamera(CameraUpdate.newLatLngBounds(trajetBounds!, 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.arrets.isNotEmpty
        ? CameraPosition(
            target: LatLng(
                widget.arrets.first.latitude, widget.arrets.first.longitude),
            zoom: 13,
          )
        : CameraPosition(target: LatLng(9.65, -13.60), zoom: 12);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: initialPosition,
            markers: markers,
            polylines: trajetsCharges ? polylines : {},
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),
          if (routeWarning != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.circular(10),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    routeWarning!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 140,
            left: 16,
            child: FloatingActionButton(
              onPressed: _centrerSurTrajet,
              child: Icon(Icons.center_focus_strong),
              tooltip: "Centrer sur la carte",
              mini: true,
            ),
          ),
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(Colors.yellow, 'Taxi'),
                      _buildLegendItem(Colors.blue, 'Minibus'),
                      _buildLegendItem(Colors.green, 'Tricycle'),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                      '📍 ${totalDistance.toStringAsFixed(1)} km   ⏱️ ${totalDuration.toStringAsFixed(0)} min',
                      style: TextStyle(color: Colors.white))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
