import 'package:flutter/material.dart';
import 'home_page.dart';
import 'recherche_page.dart';
import 'historique_page.dart';
import 'favoris_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _indexHistorique = 2;
  int _currentIndex = 0;

  Widget _page(int index) => switch (index) {
        0 => HomePage(
            onVoirHistorique: () =>
                setState(() => _currentIndex = _indexHistorique),
          ),
        1 => const RecherchePage(),
        2 => const HistoriquePage(),
        _ => const FavorisPage(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _page(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Recherche',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Favoris',
          ),
        ],
      ),
    );
  }
}
