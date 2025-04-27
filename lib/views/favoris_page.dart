import 'package:flutter/material.dart';

class FavorisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favoris')),
      body: Center(
        child: Text('Aucun favori pour l\'instant.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
