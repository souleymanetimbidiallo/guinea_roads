// lib/views/trajet_map_page.dart
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupMap());
  }

  void _setupMap() async {
    if (widget.arrets.isEmpty) return;

    for (var stop in widget.arrets) {
      markers.add(
        Marker(
          markerId: MarkerId(stop.name),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(title: stop.name),
        ),
      );
    }

    await _loadPolylineFromGoogle(widget.arrets);
    setState(() {});
  }

  Future<void> _loadPolylineFromGoogle(List<Stop> stops) async {
    if (stops.length < 2) return;

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> fullPath = [];

    for (int i = 0; i < stops.length - 1; i++) {
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(stops[i].latitude, stops[i].longitude),
        PointLatLng(stops[i + 1].latitude, stops[i + 1].longitude),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        fullPath.addAll(result.points.map(
              (p) => LatLng(p.latitude, p.longitude),
        ));
      }
    }

    polylines.add(Polyline(
      polylineId: PolylineId('real_path'),
      points: fullPath,
      color: Colors.deepPurple,
      width: 5,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.arrets.isNotEmpty
        ? CameraPosition(
      target: LatLng(
        widget.arrets.first.latitude,
        widget.arrets.first.longitude,
      ),
      zoom: 13,
    )
        : CameraPosition(target: LatLng(9.65, -13.60), zoom: 12);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: initialPosition,
        markers: markers,
        polylines: polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}