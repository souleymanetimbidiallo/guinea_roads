import 'dart:ui' as ui;

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
  GoogleMapController? mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  final GoogleRoutesService _directionsService = GoogleRoutesService();
  LatLngBounds? trajetBounds;

  bool trajetsCharges = false;
  String? routeWarning;
  double totalDistance = 0;
  double totalDuration = 0;

  static const _mapStyle = '''
[
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#52615b"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dce9e4"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f4f7f5"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#b8dce8"}]}
]
''';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupMap());
  }

  Future<void> _setupMap() async {
    if (widget.arrets.isEmpty) return;

    List<LatLng> latLngs = [];
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    for (var index = 0; index < widget.arrets.length; index++) {
      final stop = widget.arrets[index];
      final latLng = LatLng(stop.latitude, stop.longitude);
      latLngs.add(latLng);
      final isDepart = index == 0;
      final isArrivee = index == widget.arrets.length - 1;
      final markerColor = isDepart
          ? const Color(0xFF087F5B)
          : isArrivee
              ? const Color(0xFFC63D36)
              : const Color(0xFF2474C6);
      final markerLabel = isDepart
          ? 'D'
          : isArrivee
              ? 'A'
              : '$index';

      markers.add(
        Marker(
          markerId: MarkerId('${stop.id}-$index'),
          position: latLng,
          icon: await _createMarker(markerColor, markerLabel, pixelRatio),
          infoWindow: InfoWindow(
            title: stop.name,
            snippet: isDepart
                ? 'Départ'
                : isArrivee
                    ? 'Arrivée'
                    : 'Étape $index',
          ),
          anchor: const Offset(0.5, 0.5),
          zIndex: isDepart || isArrivee ? 2 : 1,
        ),
      );
    }

    trajetBounds = _calculateBounds(latLngs);
    if (mounted) setState(() {});

    try {
      await _loadPolylineFromGoogle(widget.arrets);
      if (!mounted) return;
      setState(() {
        trajetsCharges = true;
      });
    } catch (e) {
      debugPrint('Impossible de charger les trajets : $e');
      if (!mounted) return;
      setState(() {
        trajetsCharges = false;
      });
    }
  }

  Future<BitmapDescriptor> _createMarker(
    Color color,
    String label,
    double pixelRatio,
  ) async {
    const logicalSize = 48.0;
    final size = (logicalSize * pixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.38;

    canvas.drawCircle(
      center + Offset(0, size * 0.05),
      radius,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, size * 0.05),
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.045,
    );

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: size * 0.32,
        fontWeight: FontWeight.w800,
      ),
    )..pushStyle(ui.TextStyle(color: Colors.white));
    paragraphBuilder.addText(label);
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));
    canvas.drawParagraph(
      paragraph,
      Offset(0, (size - paragraph.height) / 2),
    );

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
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
        routeWarning = 'Une partie du tracé est approximative.';
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
    if (trajetBounds != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(trajetBounds!, 70),
      );
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
            onMapCreated: (controller) {
              mapController = controller;
              controller.setMapStyle(_mapStyle);
              if (trajetBounds != null) {
                Future<void>.delayed(
                  const Duration(milliseconds: 250),
                  _centrerSurTrajet,
                );
              }
            },
            initialCameraPosition: initialPosition,
            markers: markers,
            polylines: trajetsCharges ? polylines : {},
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),
          if (routeWarning != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          routeWarning!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!trajetsCharges)
            Positioned(
              top: routeWarning == null ? 16 : 84,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Chargement du tracé…',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 146,
            left: 16,
            child: FloatingActionButton.small(
              onPressed: _centrerSurTrajet,
              tooltip: 'Centrer sur le trajet',
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            context,
                            Icons.route_rounded,
                            '${totalDistance.toStringAsFixed(1)} km',
                            'Distance',
                          ),
                        ),
                        Container(
                          height: 38,
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        Expanded(
                          child: _buildMetric(
                            context,
                            Icons.schedule_rounded,
                            '${totalDuration.toStringAsFixed(0)} min',
                            'Durée',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(
                          context,
                          const Color(0xFFD19B00),
                          'Taxi',
                        ),
                        _buildLegendItem(
                          context,
                          const Color(0xFF2474C6),
                          'Minibus',
                        ),
                        _buildLegendItem(
                          context,
                          const Color(0xFF168A45),
                          'Tricycle',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    Color color,
    String label,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
