import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapsPage extends StatefulWidget {
  final String? selectedDeparture;
  MapsPage({Key? key, this.selectedDeparture}) : super(key: key);

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

  String? selectedDeparture;
  String? selectedDestination;

  List<Map<String, dynamic>> transportOptions = [];

  @override
  void initState() {
    super.initState();
    selectedDeparture = widget.selectedDeparture; // Utilisation du paramètre du constructeur
    departController.text = selectedDeparture ?? '';
    _loadMarkers();
    _loadTransportOptions();
  }

  Future<void> _loadMarkers() async {
    FirebaseFirestore.instance.collection('Arrets').get().then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        var data = document.data() as Map<String, dynamic>;
        GeoPoint geoPoint = data['location']; // Récupérer le GeoPoint
        var marker = Marker(
          markerId: MarkerId(document.id),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          // Pour Utiliser les coordonnées du GeoPoint
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

  Future<void> _loadTransportOptions() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('ModesTransports').get();
      List<Map<String, dynamic>> options = [];
      for (var document in querySnapshot.docs) {
        var data = document.data();
        print("Document data: $data"); // pour vérifier les données récupérées

        // Vérification et conversion du champ 'icon' en chaîne de caractères
        if (data['icon'] is int) {
          data['icon'] = data['icon'].toString();
        }
        options.add(data as Map<String, dynamic>);
      }
      setState(() {
        transportOptions = options;
      });

      // Impression pour vérifier les données récupérées
      print("Options de transport récupérées: $transportOptions");
    } catch(error) {
      print("Erreur lors de la récupération des options de transport: $error");
    }
    }

  // Méthode pour construire les cartes de mode de transport
  List<Widget> _buildTransportOptionCards() {
    if (transportOptions.isEmpty) {
      return [Text('Aucune option de transport disponible.')];
    }
    return transportOptions.map((option) {
      print("Option de transport: $option"); // Pour vérifier chaque option

      // Conversion de l'icône en IconData en tenant compte du type de données
      IconData? icon;
      try {
         icon = IconData(
            int.parse(option['icon']), fontFamily: 'MaterialIcons');
      }catch(e){
        print("Erreur lors de la conversion de l'icône : $e");
      }

      if (icon != null) {
        return _buildTransportOption(icon, option['name']);
      } else {
        return Card(
          child: ListTile(
            leading: Icon(Icons.error),
            title: Text(option['name']),
            subtitle: Text("Erreur de l'icône"),
          ),
        );
      }
    }).toList();

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
          .startAt([query.toLowerCase()])
          .endAt([query.toLowerCase() + '\uf8ff'])
          .get();

      return snapshot.docs.map((doc) => doc.data()['name'].toString()).toList();
    } catch (e) {
      print('Erreur lors de la récupération des suggestions: $e');
      return [];
    }
  }

  Future<LatLng> _getLatLngFromStopName(String stopName) async {
    var snapshot = await FirebaseFirestore.instance.collection('Arrets')
        .where('name', isEqualTo: stopName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data() as Map<String, dynamic>;
      GeoPoint geoPoint = data['location'];
      return LatLng(geoPoint.latitude, geoPoint.longitude);
    } else {
      throw Exception('Arrêt non trouvé');
    }
  }

  void getDirections() async {
    if (selectedDeparture == null || selectedDestination == null) {
      print('Veuillez sélectionner à la fois un départ et une destination.');
      return;
    }

    try {
      final LatLng departure = await _getLatLngFromStopName(selectedDeparture!);
      final LatLng arrival = await _getLatLngFromStopName(selectedDestination!);

      final List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPiKey,
      PointLatLng(departure.latitude, departure.longitude),
      PointLatLng(arrival.latitude, arrival.longitude),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      addPolyLine(polylineCoordinates);
    } else {
      print(result.errorMessage);
    }
  } catch(e){
  print('Erreur lors de la récupération des coordonnées: $e');
  }
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

  // Pour faire la commutation des valeurs dans départ et destination
  void swapLocations() {
    setState(() {
      // Échanger les valeurs entre le départ et la destination
      String? temp = selectedDeparture;
      selectedDeparture = selectedDestination;
      selectedDestination = temp;

      // Mettre à jour les contrôleurs de texte
      departController.text = selectedDeparture ?? '';
      destinationController.text = selectedDestination ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white!.withOpacity(0.5), // Fond transparent
          actions: [],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(245.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return _getSuggestions(textEditingValue.text);
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            textEditingController.text = departController.text; // Associe le contrôleur de texte
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Départ',
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                          onSelected: (String selection) {
                            setState(() {
                              selectedDeparture = selection;
                              departController.text = selection;
                            });
                            print('Départ sélectionné : $selection');
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: swapLocations, // Appeler la méthode d'échange
                          child: Icon(Icons.swap_horiz), // Icône de flèche bidirectionnelle horizontale
                        ),
                      ),

                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            return _getSuggestions(textEditingValue.text);
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            textEditingController.text = destinationController.text; // Associe le contrôleur de texte
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Destination',
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                          onSelected: (String selection) {
                            setState(() {
                              selectedDestination = selection;
                              destinationController.text = selection;
                            });
                            print('Destination sélectionnée : $selection');
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Card(
                    //color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildTransportOptionCards(),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
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
                  SizedBox(height: 5.0),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildTransportOption(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40.0),
        SizedBox(height: 4.0),
        Text(label, style: TextStyle(fontSize: 12.0)),
      ],
    );
  }
}

