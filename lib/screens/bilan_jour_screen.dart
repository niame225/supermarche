// lib/screens/bilan_jour_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BilanJourScreen extends StatefulWidget {
  const BilanJourScreen({Key? key}) : super(key: key);

  @override
  State<BilanJourScreen> createState() => _BilanJourScreenState();
}

class _BilanJourScreenState extends State<BilanJourScreen> {
  Map<String, dynamic>? _bilan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerBilan();
  }

  Future<void> _chargerBilan() async {
    setState(() => _isLoading = true);
    try {
      final bilan = await ApiService.getBilanJour();
      setState(() => _bilan = bilan);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_bilan == null) return const Scaffold(body: Center(child: Text("Aucune donnée")));

    return Scaffold(
      appBar: AppBar(title: const Text("Bilan du Jour")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Ventes", _bilan!['total_ventes'], Colors.blue),
            _buildStatCard("Bénéfice Ventes", _bilan!['benefice_ventes'], Colors.green),
            _buildStatCard("Approvisionnements", _bilan!['total_appros'], Colors.orange),
            _buildStatCard("Dépenses", _bilan!['total_depenses'], Colors.red),
            _buildStatCard("Paiements Crédits", _bilan!['total_paiements_credits'], Colors.purple),
            _buildStatCard("Liquidité Actuelle", _bilan!['liquidite_actuelle'], Colors.teal),
            _buildStatCard("Bénéfice Net", _bilan!['benefice_net_jour'], Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 18)),
            Text("${value.toStringAsFixed(2)} F", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}