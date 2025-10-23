// lib/screens/credits/nouveau_credit_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NouveauCreditScreen extends StatefulWidget {
  const NouveauCreditScreen({Key? key}) : super(key: key);

  @override
  State<NouveauCreditScreen> createState() => _NouveauCreditScreenState();
}

class _NouveauCreditScreenState extends State<NouveauCreditScreen> {
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _produitsController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouveau Crédit")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(labelText: "Nom du client *"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _produitsController,
              decoration: const InputDecoration(
                labelText: "Produits *",
                hintText: "Ex: Laitx2, Painx1",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montantController,
              decoration: const InputDecoration(labelText: "Montant total (F) *"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final client = _clientController.text.trim();
                  final produits = _produitsController.text.trim();
                  final montant = double.tryParse(_montantController.text) ?? 0.0;
                  if (client.isEmpty || produits.isEmpty || montant <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tous les champs sont requis.")));
                    return;
                  }
                  try {
                    await ApiService.enregistrerCredit(
                      client: client,
                      produits: produits,
                      montant: montant,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Crédit enregistré !")));
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $e")));
                  }
                },
                icon: const Icon(Icons.credit_card),
                label: const Text("Enregistrer le crédit"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}