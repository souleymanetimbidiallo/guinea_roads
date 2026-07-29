import 'package:flutter/material.dart';
import 'package:guinea_roads/views/splash_screen.dart';

class GuineaRoadsApp extends StatelessWidget {
  const GuineaRoadsApp({super.key});

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
      themeMode:
          ThemeMode.system, // 🔥 Bascule automatiquement selon le téléphone
      home: SplashScreen(),
    );
  }
}
