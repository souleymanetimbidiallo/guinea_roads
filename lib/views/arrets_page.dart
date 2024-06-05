import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guinea_roads/controllers/stop_controller.dart';
import 'package:guinea_roads/views/maps_page.dart';

class ArretsPage extends StatefulWidget {
  @override
  _ArretsPageState createState() => _ArretsPageState();
}

class _ArretsPageState extends State<ArretsPage> {
  ArretsController controller = ArretsController();

  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _arrets = [];
  List<DocumentSnapshot> _filteredArrets = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterArrets);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterArrets);
    _searchController.dispose();
    super.dispose();
  }

  void _filterArrets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredArrets = _arrets.where((document) {
        final name = (document.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un arrêt...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.recupererArrets(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          _arrets = snapshot.data!.docs;
          _filteredArrets = _arrets.where((document) {
            final name = (document.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
            return name.contains(_searchController.text.toLowerCase());
          }).toList();

          return ListView.builder(
            itemCount: _filteredArrets.length,
            itemBuilder: (context, index) {
              final data = _filteredArrets[index].data() as Map<String, dynamic>;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.directions_bus, color: Colors.white),
                  ),
                  title: Text(
                    data['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  subtitle: Text('Cliquez pour voir sur la carte'),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapsPage(
                        selectedDeparture: data['name'], // Pass the stop name to MapsPage
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
