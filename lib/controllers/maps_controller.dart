import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guinea_roads/models/stop.dart';

class MapsController {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  String googleApiKey = "AIzaSyAkxWY7GjJGgARoAbD1DZlpFNSaJPsQQrY";

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    loadInitialMarkers();
  }

  Future<void> loadInitialMarkers() async {
    var stops = await Stop.fetchStops('');
    for (var stop in stops) {
      addMarker(stop);
    }
  }

  void addMarker(Stop stop) {
    var marker = Marker(
      markerId: MarkerId(stop.id),
      position: stop.location,
      infoWindow: InfoWindow(title: stop.name, snippet: "Arrêt"),
    );
    markers.add(marker);
  }

  Future<List<String>> getSuggestions(String query) async {
    var stops = await Stop.fetchStops(query);
    return stops.map((stop) => stop.name).toList();
  }



  Future<void> getDirections(LatLng departure, LatLng arrival, List<LatLng> waypoints) async {
    List<LatLng> polylineCoordinates = [];
    for (int i = 0; i < waypoints.length - 1; i++) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey,
        PointLatLng(waypoints[i].latitude, waypoints[i].longitude),
        PointLatLng(waypoints[i + 1].latitude, waypoints[i + 1].longitude),
        travelMode: TravelMode.driving,
      );
      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      }
    }
    addPolyLine(polylineCoordinates);
  }

  void addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("route");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.deepPurpleAccent,
      points: polylineCoordinates,
      width: 8,
    );
    polylines[id] = polyline;
  }

  Future<List<Stop>> fetchStopsBetween(LatLng start, LatLng end) async {
    // Calcul des limites géographiques pour inclure tous les points entre les deux coordonnées
    double latMin = min(start.latitude, end.latitude);
    double latMax = max(start.latitude, end.latitude);
    double lonMin = min(start.longitude, end.longitude);
    double lonMax = max(start.longitude, end.longitude);

    // Requête Firestore pour récupérer les arrêts dans ce rectangle géographique
    var querySnapshot = await FirebaseFirestore.instance
        .collection('Arrets') // Assurez-vous que 'Arrets' est le nom correct de votre collection
        .where('location.latitude', isGreaterThanOrEqualTo: latMin)
        .where('location.latitude', isLessThanOrEqualTo: latMax)
        .where('location.longitude', isGreaterThanOrEqualTo: lonMin)
        .where('location.longitude', isLessThanOrEqualTo: lonMax)
        .get();

    // Conversion des documents en instances de Stop
    List<Stop> stops = querySnapshot.docs
        .map((doc) => Stop.fromFirestore(doc))
        .toList();

    return stops;
  }
}