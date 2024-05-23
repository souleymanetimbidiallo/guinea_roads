import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guinea_roads/models/stop.dart'; // Importez votre modèle

class ArretsController {
  late TextEditingController searchController;
  late List<Stop> arrets;
  late List<Stop> filteredArrets;

  ArretsController() {
    searchController = TextEditingController();
    arrets = [];
    filteredArrets = [];
    searchController.addListener(_filterArrets);
  }

  void dispose() {
    searchController.removeListener(_filterArrets);
    searchController.dispose();
  }

  void _filterArrets() {
    final query = searchController.text.toLowerCase();
    filteredArrets = arrets.where((stop) => stop.name.toLowerCase().contains(query)).toList();
  }

  Future<List<Stop>> fetchStops(String query) async {
    arrets = await Stop.fetchStops(query);
    _filterArrets();
    return arrets;
  }

  Stream<QuerySnapshot> recupererArrets(){
    return FirebaseFirestore.instance.collection('Arrets').snapshots();
  }
}
