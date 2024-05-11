import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Demo',
      home: ArretsPage(),
    );
  }
}

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
              return ListTile(
                title: Text(data['name']),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
