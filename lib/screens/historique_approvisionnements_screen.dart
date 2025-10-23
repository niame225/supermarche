// lib/screens/historique_approvisionnements_screen.dart

import 'package:flutter/material.dart';
import 'package:supermarche/models/approvisionnement.dart';
import 'package:supermarche/services/approvisionnement_service.dart';
import 'package:supermarche/utils/helpers.dart';
import 'package:supermarche/utils/constants.dart';

class HistoriqueApprovisionnementsScreen extends StatefulWidget {
  const HistoriqueApprovisionnementsScreen({super.key});

  @override
  State<HistoriqueApprovisionnementsScreen> createState() =>
      _HistoriqueApprovisionnementsScreenState();
}

class _HistoriqueApprovisionnementsScreenState
    extends State<HistoriqueApprovisionnementsScreen> {
  late Future<List<Approvisionnement>> _futureApprovisionnements;
  final ApprovisionnementService _service = ApprovisionnementService();

  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureApprovisionnements = _service.getHistoriqueApprovisionnements(
        dateDebut: _dateDebut,
        dateFin: _dateFin,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Approvisionnements'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/vente'), // ou '/approvisionner' si vous avez cet écran
            tooltip: 'Nouvel Approvisionnement',
          ),
        ],
      ),
      body: Column(
        children: [
          // === Filtre par dates ===
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrer par dates',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Date de début',
                            selectedDate: _dateDebut,
                            onSelected: (date) {
                              setState(() => _dateDebut = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'Date de fin',
                            selectedDate: _dateFin,
                            onSelected: (date) {
                              setState(() => _dateFin = date);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('🔍 Rechercher'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _dateDebut = null;
                              _dateFin = null;
                              _loadData();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('🔄 Réinitialiser'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === Liste des approvisionnements ===
          Expanded(
            child: FutureBuilder<List<Approvisionnement>>(
              future: _futureApprovisionnements,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur : ${snapshot.error.toString()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun approvisionnement trouvé.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final approvisionnements = snapshot.data!;
                final totalGlobal = approvisionnements.fold<double>(
                  0.0,
                  (sum, item) => sum + (item.prixAchat * item.quantite),
                );

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: approvisionnements.length,
                  itemBuilder: (context, index) {
                    final item = approvisionnements[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(item.nomProduit),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.dateAffichee}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${item.quantite}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${item.prixAchat.toStringAsFixed(2)} F',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${item.prixVente.toStringAsFixed(2)} F',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${(item.prixAchat * item.quantite).toStringAsFixed(2)} F',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // === Pied de page avec total ===
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Approvisionnements :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${totalGlobal.toStringAsFixed(2)} F',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime?) onSelected,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              onSelected(picked);
            }
          },
        ),
      ),
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      controller: TextEditingController(
        text: selectedDate != null ? formatDate(selectedDate) : '',
      ),
    );
  }
}