import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'maps_page.dart';

class ArretsPage extends StatefulWidget {
  @override
  _ArretsPageState createState() => _ArretsPageState();
}

class _ArretsPageState extends State<ArretsPage> {
  final Stream<QuerySnapshot> _arretsStream = FirebaseFirestore.instance.collection('Arrets').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Arrêts'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {

            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _arretsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.directions_bus), // Ici tu peux mettre l'icône que tu souhaites
                  title: Text(data['name']),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapsPage()),
                  ),
                ),
              );
            }).toList(),
          );

        },
      ),
    );
  }
}

