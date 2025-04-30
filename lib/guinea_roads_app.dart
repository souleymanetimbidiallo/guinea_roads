import 'package:flutter/material.dart';
import 'package:guinea_roads/views/splash_screen.dart';

class GuineaRoadsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guinea Roads',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // Mode clair
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Mode sombre automatique
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black87,
        ),
      ),
      themeMode: ThemeMode.system, // 🔥 Bascule automatiquement selon le téléphone
      home: SplashScreen(),
    );
  }
}
