import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('À propos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
        Center(
        child: Image.asset(
        'assets/images/logo.png',
          width: 100,
          height: 100,
        ),
      ),
      SizedBox(height: 20),
      Text('Guinea Roads',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      SizedBox(height: 10),
      Text('Version 1.0.0', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
      SizedBox(height: 20),
      Divider(thickness: 1.2),
      SizedBox(height: 20),
      Text(
          '🚀 À propos de l''application',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 10),
    Text(
    'Guinea Roads est une application mobile destinée à améliorer la mobilité urbaine à Conakry en permettant aux citoyens de trouver les meilleurs trajets en taxi, minibus ou tricycle.',
    style: TextStyle(fontSize: 16, height: 1.5),
    textAlign: TextAlign.justify,
    ),
    SizedBox(height: 30),
    Text(
    '🧑‍💻 Développement',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 10),
    Text(
    '',
    style: TextStyle(fontSize: 16, height: 1.5),
    textAlign: TextAlign.justify,
    ),
    SizedBox(height: 30),
    Text(
    '📩 Contact',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 10),
    Text(
    'guinearoads@email.com',
    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
    ),
    ],
    ),
    ),
    );
  }
}
