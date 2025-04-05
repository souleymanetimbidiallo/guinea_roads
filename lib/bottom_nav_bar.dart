/*import 'package:flutter/material.dart';
import 'package:guinea_roads/models/profil_model.dart';

import 'views/profil_page.dart';
import 'views/arrets_page.dart';
import 'views/maps_page.dart';*/

import 'package:flutter/material.dart';
import 'package:guinea_roads/views/profil_page.dart';
import 'package:guinea_roads/views/arrets_page.dart';
import 'package:guinea_roads/views/maps_page.dart';


void main() {
  runApp(MaterialApp(
    home: BottomNavBar(),
  ));
}

class BottomNavBar extends StatefulWidget {
  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    MapsPage(),
    ArretsPage(),
    ProfilPage(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.house),
            label: 'Accueil',
          ),


          BottomNavigationBarItem(
            icon: Icon(Icons.map_sharp),
            label: 'Arrets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
