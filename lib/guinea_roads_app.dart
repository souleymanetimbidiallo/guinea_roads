import 'package:flutter/material.dart';
import 'package:guinea_roads/views/splash_screen.dart';

class GuineaRoadsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guinea Roads',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}
