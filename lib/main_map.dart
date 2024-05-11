import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Guinea Roads App'),
          backgroundColor: Colors.green[700],
        ),
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
