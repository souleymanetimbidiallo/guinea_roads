import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class MapsPage extends StatefulWidget {
  final String? selectedDeparture;
  MapsPage({Key? key, this.selectedDeparture}) : super(key: key);

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  static const int carCostPerStop = 2000;
  static const int tricycleCostPerStop = 2500;
  List<LatLng> stops = [];

  String estimatedCost = '';//Variable pour l'estimation de cout

  late GoogleMapController mapController;
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyAkxWY7GjJGgARoAbD1DZlpFNSaJPsQQrY";

  final LatLng _center = const LatLng(9.669334, -13.558108);

  Set<Marker> markers = {};
  Map<PolylineId, Polyline> mapPolylines = {}; //polylines to show direction

  // Création de TextEditingControllers pour les champs de texte
  TextEditingController departController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  String? selectedDeparture;
  String? selectedDestination;
  String? selectedTransportMode = 'taxi';

  List<Map<String, dynamic>> transportOptions = [];

  @override
  void initState() {
    super.initState();
    selectedDeparture = widget.selectedDeparture; // Utilisation du paramètre du constructeur
    departController.text = selectedDeparture ?? '';
    _loadMarkers();
    _loadTransportOptions();
  }
  List<LatLng> listDesArrets = [];

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
    } catch (error) {
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
        icon = IconData(int.parse(option['icon']), fontFamily: 'MaterialIcons');
      } catch (e) {
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

  // Calcul de cout

  int calculateCost(String transportMode, int numberOfStops) {
    int costPerStop;
    if (transportMode == 'taxi') {
      costPerStop = carCostPerStop;
    } else if (transportMode == 'tricycle') {
      costPerStop = tricycleCostPerStop;
    } else {
      //return 0; // ou gérer d'autres modes de transport
      throw Exception('Mode de transport inconnu');
    }

    return costPerStop * numberOfStops;
  }


  Future<int> calculateNumberOfStops(LatLng departure, LatLng arrival) async {
    // Récupérer les noms des arrêts pour le départ et l'arrivée
    String departureStopName = await getStopNameFromLatLng(departure);
    String arrivalStopName = await getStopNameFromLatLng(arrival);

    print('Departure stop name: $departureStopName'); // Debugging
    print('Arrival stop name: $arrivalStopName'); // Debugging

    // Récupérer l'ordre du point de départ
    int departureOrder = await getStopOrder(departureStopName);

    // Récupérer l'ordre du point d'arrivée
    int arrivalOrder = await getStopOrder(arrivalStopName);

    // Si l'ordre de départ est supérieur à l'ordre d'arrivée, échanger les valeurs
    if (departureOrder > arrivalOrder) {
      int temp = departureOrder;
      departureOrder = arrivalOrder;
      arrivalOrder = temp;
    }

    // Calculer le nombre d'arrêts en fonction de l'ordre des arrêts
    int numberOfStops = arrivalOrder - departureOrder;

    return numberOfStops;
  }

  Future<String> getStopNameFromLatLng(LatLng latLng) async {
    // Récupérer les données des arrêts depuis la base de données Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Arrets').get();

    // Parcourir les documents pour trouver l'arrêt le plus proche des coordonnées fournies
    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      GeoPoint geoPoint = data['location'];
      LatLng stopLatLng = LatLng(geoPoint.latitude, geoPoint.longitude);

      // Vérifier si les coordonnées correspondent
      if (stopLatLng == latLng) {
        // Retourner le nom de l'arrêt
        return data['name'];
      }
    }

    // Si aucun arrêt n'est trouvé pour les coordonnées fournies, renvoyer une chaîne vide
    return '';
  }

  Future<int> getStopOrder(String stopName) async {
    // Récupérer l'ordre de l'arrêt à partir de la base de données
    // Vous pouvez utiliser la latitude et la longitude de l'arrêt pour rechercher dans la collection Arrets
    // Puis, vous pouvez extraire l'ordre de l'arrêt à partir des données récupérées
    // Enfin, retournez l'ordre de l'arrêt

    // Exemple de code à adapter à votre base de données :
    var snapshot = await FirebaseFirestore.instance.collection('Arrets')
        .where('name', isEqualTo: stopName)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data() as Map<String, dynamic>;
      return data['order'];
    } else {
      throw Exception('Ordre de l\'arrêt non trouvé');
    }
  }

  Future<List<LatLng>> getStopsBetween(LatLng departure, LatLng arrival) async {
    List<LatLng> stops = [];

    // Récupérer les arrêts depuis la base de données
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Arrets').get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      GeoPoint geoPoint = data['location'];
      LatLng stop = LatLng(geoPoint.latitude, geoPoint.longitude);
      stops.add(stop);
    }

    // Tri des arrêts par distance à partir du départ pour simuler les arrêts intermédiaires dans l'ordre
    stops.sort((a, b) => calculateDistance(departure, a).compareTo(calculateDistance(departure, b)));

    // Filtrer les arrêts entre le départ et l'arrivée
    List<LatLng> stopsBetween = [];
    //List<LatLng> stopsBetween = await getStopsBetween(departure, arrival);

    bool started = false;
    for (var stop in stops) {
      if (!started && calculateDistance(departure, stop) < calculateDistance(departure, arrival)) {
        started = true;
      }
      if (started && calculateDistance(stop, arrival) < calculateDistance(departure, arrival)) {
        stopsBetween.add(stop);
      }
      if (calculateDistance(stop, arrival) == 0) {
        break;
      }
    }

    //return stops;
    return stopsBetween;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Rayon de la Terre en kilomètres

    // Conversion des degrés en radians
    double lat1Radians = _degreesToRadians(point1.latitude);
    double lon1Radians = _degreesToRadians(point1.longitude);
    double lat2Radians = _degreesToRadians(point2.latitude);
    double lon2Radians = _degreesToRadians(point2.longitude);

    // Calcul des différences de latitude et de longitude
    double dLat = _degreesToRadians(lat2Radians - lat1Radians);
    double dLon = _degreesToRadians(lon2Radians - lon1Radians);

    // Formule de Haversine pour calculer la distance entre deux points

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Radians) * cos(lat2Radians) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }



  void getDirections() async {
    if (selectedDeparture == null || selectedDestination == null) {
      print('Veuillez sélectionner à la fois un départ et une destination.');
      return;
    }

    try {
      final LatLng departure = await _getLatLngFromStopName(selectedDeparture!);
      final LatLng arrival = await _getLatLngFromStopName(selectedDestination!);

      // Récupérer les arrêts entre le départ et l'arrivée
      List<LatLng> stopsBetween = await getStopsBetween(departure, arrival);

      // Créer une liste complète des points du tracé en incluant le départ, les arrêts intermédiaires, et l'arrivée
      List<LatLng> polylineCoordinates = [departure, ...stopsBetween, arrival];

//    Récupérer le tracé de l'itinéraire complet
      List<LatLng> routeCoordinates = [];

      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          googleAPiKey,
          PointLatLng(polylineCoordinates[i].latitude, polylineCoordinates[i].longitude),
          PointLatLng(polylineCoordinates[i + 1].latitude, polylineCoordinates[i + 1].longitude),
          travelMode: TravelMode.driving,
        );
        if (result.points.isNotEmpty) {
          result.points.forEach((PointLatLng point) {
            routeCoordinates.add(LatLng(point.latitude, point.longitude));
          });
        }
      }
      addPolyLine(routeCoordinates);

      // Récupérer l'itinéraire entre le départ et l'arrivée
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(departure.latitude, departure.longitude),
        PointLatLng(arrival.latitude, arrival.longitude),
        travelMode: TravelMode.driving,
      );

      // Ajouter les points du tracé de l'itinéraire principal
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
        // Calculer le nombre d'arrêts entre le point de départ et le point d'arrivée
        int numberOfStops = await calculateNumberOfStops(departure, arrival);

        // Récupérer les arrêts entre le départ et l'arrivée
        List<LatLng> stopsBetween = await getStopsBetween(departure, arrival);

        // Mettre à jour la liste des arrêts
        setState(() {
          stops = stopsBetween;
        });

        int totalCost = calculateCost(selectedTransportMode!, numberOfStops); // Changer 'Voiture' par le mode de transport choisi

        setState(() {
          estimatedCost = '$totalCost FG';
        });
      } else {
        print(result.errorMessage);
      }
    } catch (e) {
      print('Erreur lors de la récupération des coordonnées: $e');
    }
  }

  void addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.deepPurpleAccent,
      points: polylineCoordinates,
      width: 8,
    );
    setState(() {
      mapPolylines[id] = polyline;
    });
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
          backgroundColor: Colors.white.withOpacity(0.5), // Fond transparent
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

                  if (estimatedCost.isNotEmpty) Text('Coût estimé: $estimatedCost'),
                  SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed: getDirections, // Mise à jour pour appeler la fonction de tracé d'itinéraire,
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
          polylines: Set<Polyline>.of(mapPolylines.values), // S'assurer que cette ligne est correcte
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
