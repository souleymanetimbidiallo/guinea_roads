import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase and Maps Demo',
      home:  BottomNavBar(

      ),

      debugShowCheckedModeBanner: false,
    );
  }
}