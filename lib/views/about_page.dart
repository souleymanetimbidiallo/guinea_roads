import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('À propos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guinea Roads', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Version 1.0', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(
              'Guinea Roads est une application visant à améliorer la mobilité urbaine à Conakry.\n\n'
                  'Développée avec Flutter & Firebase.\n\n'
                  'Contact : guinearoads@email.com',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
