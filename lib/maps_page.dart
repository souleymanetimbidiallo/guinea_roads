import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class MapsPage extends StatefulWidget {
  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(9.537029, -13.678470);
  final Set<Marker> markers = {
    Marker(
      markerId: const MarkerId('Palais du Peuple'),
      position: const LatLng(9.537029, -13.678470),
      infoWindow: const InfoWindow(
        title: "Palais du Peuple",
        snippet: "Un centre culturel important",
      ),
    ),
    Marker(
      markerId: const MarkerId('Monument de la Révolution'),
      position: const LatLng(9.639828, -13.578433),
      infoWindow: const InfoWindow(
        title: "Monument de la Révolution",
        snippet: "Monument historique",
      ),
    ),
    Marker(
      markerId: const MarkerId('Stade du 28 Septembre'),
      position: const LatLng(9.537897, -13.661401),
      infoWindow: const InfoWindow(
        title: "Stade du 28 Septembre",
        snippet: "Stade national",
      ),
    ),
    Marker(
      markerId: const MarkerId('Cathédrale Sainte-Marie'),
      position: const LatLng(9.531642, -13.677792),
      infoWindow: const InfoWindow(
        title: "Cathédrale Sainte-Marie",
        snippet: "Cathédrale historique",
      ),
    ),
    Marker(
      markerId: const MarkerId('Musée National de Guinée'),
      position: const LatLng(9.540725, -13.673776),
      infoWindow: const InfoWindow(
        title: "Musée National de Guinée",
        snippet: "Musée national",
      ),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Départ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        // Action à effectuer lors du clic sur le bouton
                      },

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
            zoom: 15.0,
          ),
          markers: markers,
        ),
      ),
    );
  }
}
