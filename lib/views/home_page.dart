import 'package:flutter/material.dart';
import 'package:guinea_roads/views/recherche_page.dart';
import 'package:guinea_roads/views/favoris_page.dart';
import 'package:guinea_roads/views/historique_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
              ),
              SizedBox(height: 20),
              Text(
                "Guinea Roads",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "Explorez les itinéraires les plus efficaces en taxi, minibus ou tricycle à Conakry.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.search),
                label: Text("Trouver un trajet"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecherchePage()),
                  );
                },
              ),
              SizedBox(height: 40),
              Text(
                "Modes de transport disponibles",
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _transportIcon("Taxi", "assets/images/taxi.png"),
                  _transportIcon("Minibus", "assets/images/minibus.png"),
                  _transportIcon("Tricycle", "assets/images/tricycle.png"),
                  _transportIcon("Conakry Express (bientôt)", "assets/images/train.png", grayed: true),
                ],
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickAccess(context, "Historique", Icons.history, HistoriquePage()),
                  _quickAccess(context, "Favoris", Icons.star, FavorisPage()),
                ],
              ),
              SizedBox(height: 30),
              Text(
                "Version bêta – vos retours sont précieux !",
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transportIcon(String label, String assetPath, {bool grayed = false}) {
    return Column(
      children: [
        Opacity(
          opacity: grayed ? 0.5 : 1.0,
          child: Image.asset(
            assetPath,
            width: 60,
            height: 60,
          ),
        ),
        SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _quickAccess(BuildContext context, String label, IconData icon, Widget page) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
