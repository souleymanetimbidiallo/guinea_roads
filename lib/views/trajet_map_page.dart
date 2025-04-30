import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/stop.dart';

class TrajetMapPage extends StatefulWidget {
  final List<Stop> arrets;
  final String title;

  const TrajetMapPage({
    required this.arrets,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  State<TrajetMapPage> createState() => _TrajetMapPageState();
}

class _TrajetMapPageState extends State<TrajetMapPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  final String googleApiKey = 'AIzaSyAkxWY7GjJGgARoAbD1DZlpFNSaJPsQQrY';
  LatLngBounds? trajetBounds;

  bool trajetsCharges = false; // nouveau flag

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
      print('🚫 Impossible de charger les trajets, connexion ? $e');
      setState(() {
        trajetsCharges = false;
      });
    }
  }

  Future<void> _loadPolylineFromGoogle(List<Stop> stops) async {
    if (stops.length < 2) return;

    PolylinePoints polylinePoints = PolylinePoints();
    for (int i = 0; i < stops.length - 1; i++) {
      final stop1 = stops[i];
      final stop2 = stops[i + 1];

      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(stop1.latitude, stop1.longitude),
        PointLatLng(stop2.latitude, stop2.longitude),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        polylines.add(Polyline(
          polylineId: PolylineId('$i'),
          points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          color: Colors.blueAccent,
          width: 5,
        ));
      }
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
      mapController.animateCamera(CameraUpdate.newLatLngBounds(trajetBounds!, 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.arrets.isNotEmpty
        ? CameraPosition(
      target: LatLng(widget.arrets.first.latitude, widget.arrets.first.longitude),
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
            polylines: trajetsCharges ? polylines : {}, // ➔ seulement si trajets chargés
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 80,
            left: 16,
            child: FloatingActionButton(
              onPressed: _centrerSurTrajet,
              child: Icon(Icons.center_focus_strong),
              tooltip: "Centrer sur la carte",
              mini: true,
            ),
          ),
        ],
      ),
    );
  }
}
