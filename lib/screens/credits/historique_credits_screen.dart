// lib/screens/credits/historique_credits_screen.dart

import 'package:flutter/material.dart';
import '../models/credit.dart';
import '../services/api_service.dart';

class HistoriqueCreditsScreen extends StatefulWidget {
  const HistoriqueCreditsScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueCreditsScreen> createState() => _HistoriqueCreditsScreenState();
}

class _HistoriqueCreditsScreenState extends State<HistoriqueCreditsScreen> {
  List<Credit> _credits = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerCredits();
  }

  Future<void> _chargerCredits() async {
    setState(() => _isLoading = true);
    try {
      final credits = await ApiService.getHistoriqueCredits();
      setState(() => _credits = credits);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historique des Crédits")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _credits.isEmpty
              ? const Center(child: Text("Aucun crédit trouvé"))
              : ListView.builder(
                  itemCount: _credits.length,
                  itemBuilder: (context, index) {
                    final c = _credits[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(c.clientNom),
                        subtitle: Text("Total: ${c.total} F • ${c.date}"),
                        trailing: Text(
                          c.estRegle ? "✅ Réglé" : "⚠️ Impayé",
                          style: TextStyle(color: c.estRegle ? Colors.green : Colors.red),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}