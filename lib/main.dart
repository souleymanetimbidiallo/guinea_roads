import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guinea_roads/guinea_roads_app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // 👉 Active le stockage offline
  );

  runApp(GuineaRoadsApp());
}
