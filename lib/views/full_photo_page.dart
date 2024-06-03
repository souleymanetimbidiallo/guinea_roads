import 'package:flutter/material.dart';

class FullPhotoPage extends StatelessWidget {
  final String photoUrl;

  FullPhotoPage({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Pour retourner à la page précédente lorsqu'on clique sur l'image
          },
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
