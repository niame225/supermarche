// lib/screens/historique_ventes_screen.dart

import 'package:flutter/material.dart';
import '../models/vente.dart';
import '../services/api_service.dart';
import '../utils/receipt_formatter.dart';
import '../services/print_service_manager.dart';

class HistoriqueVentesScreen extends StatefulWidget {
  const HistoriqueVentesScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueVentesScreen> createState() => _HistoriqueVentesScreenState();
}

class _HistoriqueVentesScreenState extends State<HistoriqueVentesScreen> {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  List<Vente> _ventes = [];
  double _totalVentes = 0.0;
  double _totalBenefice = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerVentes();
  }

  Future<void> _chargerVentes() async {
    setState(() => _isLoading = true);
    try {
      final ventes = await ApiService.getHistoriqueVentes(
        dateDebut: _dateDebut?.toIso8601String().split('T')[0],
        dateFin: _dateFin?.toIso8601String().split('T')[0],
      );
      setState(() {
        _ventes = ventes;
        _totalVentes = ventes.fold(0.0, (sum, v) => sum + v.total);
        _totalBenefice = ventes.fold(0.0, (sum, v) => sum + v.benefice);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _imprimerReçu(int venteId) async {
    try {
      final data = await ApiService.getDetailsVente(venteId);
      if (data['success'] == true) {
        final receiptText = ReceiptFormatter.formatReceipt(
          magasinNom: "Dakar Centre", // À adapter dynamiquement si possible
          magasinAdresse: "Dakar",
          date: data['date'],
          produits: List<Map<String, dynamic>>.from(data['produits']),
          total: data['total'],
          montantPaye: data['montant_paye'] ?? data['total'], // fallback
        );
        await PrintServiceManager.printReceipt(receiptText);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur impression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historique des Ventes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filtres par dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Filtrer par dates", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: "Date de début"),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dateDebut ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setState(() => _dateDebut = date);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: "Date de fin"),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dateFin ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                setState(() => _dateFin = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _chargerVentes,
                          child: const Text("Rechercher"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _dateDebut = null;
                              _dateFin = null;
                            });
                            _chargerVentes();
                          },
                          child: const Text("Réinitialiser"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tableau des ventes
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_ventes.isEmpty)
              const Center(child: Text("Aucune vente trouvée"))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _ventes.length,
                  itemBuilder: (context, index) {
                    final vente = _ventes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(flex: 2, child: Text(vente.date)),
                            Expanded(flex: 3, child: Text(vente.produitNom)),
                            Expanded(flex: 1, child: Text(vente.quantite.toString())),
                            Expanded(flex: 2, child: Text('${vente.prixUnitaire} F')),
                            Expanded(flex: 2, child: Text('${vente.total} F')),
                            Expanded(flex: 2, child: Text('${vente.benefice} F', style: const TextStyle(color: Colors.green))),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: () => _imprimerReçu(vente.id),
                                child: const Text("Imprimer", style: TextStyle(fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // === TOTAL CUMULÉ EN BAS ===
            if (_ventes.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_totalVentes.toStringAsFixed(2)} F",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Bénéfice : ${_totalBenefice.toStringAsFixed(2)} F",
                          style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}