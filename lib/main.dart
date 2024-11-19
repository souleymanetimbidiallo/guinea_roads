import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guinea_roads/views/maps_page.dart';
import 'package:guinea_roads/views/register_page.dart';
import 'bottom_nav_bar.dart';
import 'login_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      initialRoute: '/',
      routes: {
       '/': (context) => BottomNavBar(),
        // '/': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
      },

      debugShowCheckedModeBanner: false,
    );
  }
}