import 'package:flutter/material.dart';
import '../services/historique_service.dart';

class HistoriquePage extends StatefulWidget {
  @override
  _HistoriquePageState createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<String> trajets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chargerHistorique();
  }

  Future<void> chargerHistorique() async {
    final data = await HistoriqueService.lireHistorique();
    print('📚 Historique lu : $data');
    setState(() {
      trajets = data;
    });
  }

  void viderHistorique() async {
    await HistoriqueService.viderHistorique();
    setState(() {
      trajets = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: viderHistorique,
          )
        ],
      ),
      body: trajets.isEmpty
          ? Center(child: Text('Aucun trajet récent.', style: TextStyle(fontSize: 18)))
          : ListView.builder(
        itemCount: trajets.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.history),
            title: Text(trajets[index]),
          );
        },
      ),
    );
  }
}
