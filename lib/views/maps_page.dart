import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapsPage extends StatefulWidget {
  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyAkxWY7GjJGgARoAbD1DZlpFNSaJPsQQrY";

  final LatLng _center = const LatLng(9.669334, -13.558108);

  Set<Marker> markers = {};
  Map<PolylineId, Polyline> map_polylines = {}; //polylines to show direction

  // Création de TextEditingControllers pour les champs de texte
  TextEditingController departController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadMarkers() async {
    FirebaseFirestore.instance.collection('Arrets').get().then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        var data = document.data() as Map<String, dynamic>;
        GeoPoint geoPoint = data['location']; // Récupérer le GeoPoint
        var marker = Marker(
          markerId: MarkerId(document.id),
          position: LatLng(geoPoint.latitude, geoPoint.longitude), // Utiliser les coordonnées du GeoPoint
          infoWindow: InfoWindow(
            title: data['name'],
            snippet: 'Arrêt de bus',
          ),
        );
        setState(() {
          markers.add(marker);
        });
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Fonction pour récupérer les suggestions basées sur le texte saisi
  Future<List<String>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      var snapshot = await FirebaseFirestore.instance.collection('Arrets')
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs.map((doc) => doc.data()['name'].toString()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des suggestions: $e');
      return [];
    }
  }


  getDirections() async {
    List<LatLng> polylineCoordinates = [];
    var troncons = 0;

    var departure = LatLng(9.669334, -13.558108);
    var arrival = LatLng(9.572402, -13.656524);


    //addMarker(terminusList.first, 'Départ');
    //addMarker(terminusList.last, 'Destination');


    List<LatLng> allWaypoints = [
      LatLng(9.669334, -13.558108), //terminusList[0].location,
      //...terminusList.sublist(1, terminusList.length - 1).map((terminus) => terminus.location),  // Waypoints intermédiaires
      LatLng(9.680500, -13.579675),
      LatLng(9.639360, -13.615796),
      LatLng(9.611226, -13.645598),
      LatLng(9.572402, -13.656524)//terminusList[terminusList.length - 1].location  // Position d'arrivée
    ];


    // fetch the route between each pair of adjacent waypoints
    for (int i = 0; i < allWaypoints.length - 1; i++) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(allWaypoints[i].latitude, allWaypoints[i].longitude),
        PointLatLng(
            allWaypoints[i + 1].latitude, allWaypoints[i + 1].longitude),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
      } else {
        print(result.errorMessage);
      }
    }
    /*for (int i = 1; i < terminusList.length - 1; i++) {
      // add a marker for the current waypoint
      addMarker(terminusList[i], 'Point');
    }*/
    troncons = markers.length - 2;

    _loadMarkers();
    addPolyLine(polylineCoordinates);
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.deepPurpleAccent,
      points: polylineCoordinates,
      width: 8,
    );
    map_polylines[id] = polyline;
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(

        appBar: AppBar(backgroundColor: Colors.white!.withOpacity(0.5), // Fond transparent
            actions: [

            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(175.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                 return _getSuggestions(textEditingValue.text);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Départ',
                    border: OutlineInputBorder(),
                  ),
                );
              },
                ),
                    SizedBox(height: 12.0),

                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        return _getSuggestions(textEditingValue.text);
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Destination',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: getDirections,//_getRoute, // Mise à jour pour appeler la fonction de tracé d'itinéraire,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        // Définir la couleur de fond en bleu
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0), // Arrondir les coins du bouton
                        ),
                      ),
                      child: Text('Rechercher'),
                    ),


                  ],
                ),
              ),
            )),

        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.2,
          ),
          markers: markers,
          polylines: Set<Polyline>.of(map_polylines.values), // S'assurer que cette ligne est correcte
        ),
      ),
    );
  }
}
