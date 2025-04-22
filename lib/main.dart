import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Obligatoire avant un appel async dans main
  await Firebase.initializeApp();            // 🔥 C'est ce qui manquait !
  runApp(GuineaRoadsApp());
}

class GuineaRoadsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guinea Roads',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}
