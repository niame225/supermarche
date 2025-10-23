// lib/screens/printer_selection_screen.dart

import 'package:flutter/material.dart';
import '../services/print_service_manager.dart';
import '../utils/receipt_formatter.dart';
import 'bluetooth_settings_screen.dart';
import 'wifi_settings_screen.dart';

class PrinterSelectionScreen extends StatefulWidget {
  const PrinterSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSelectionScreen> createState() => _PrinterSelectionScreenState();
}

class _PrinterSelectionScreenState extends State<PrinterSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choix du mode d'impression"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sélectionnez le mode d'impression à utiliser pour les reçus :",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Option Bluetooth
            Card(
              child: ListTile(
                leading: const Icon(Icons.bluetooth, color: Colors.blue),
                title: const Text("Bluetooth"),
                subtitle: const Text("Pour imprimantes portables sans fil"),
                trailing: Radio<PrintMode>(
                  value: PrintMode.bluetooth,
                  groupValue: PrintServiceManager.mode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        PrintServiceManager.mode = value;
                      });
                    }
                  },
                ),
                onTap: () {
                  PrintServiceManager.mode = PrintMode.bluetooth;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BluetoothSettingsScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Option WiFi
            Card(
              child: ListTile(
                leading: const Icon(Icons.wifi, color: Colors.green),
                title: const Text("WiFi (TCP/IP)"),
                subtitle: const Text("Pour imprimantes fixes sur le réseau local"),
                trailing: Radio<PrintMode>(
                  value: PrintMode.wifi,
                  groupValue: PrintServiceManager.mode,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        PrintServiceManager.mode = value;
                      });
                    }
                  },
                ),
                onTap: () {
                  PrintServiceManager.mode = PrintMode.wifi;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WifiSettingsScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Statut global
            FutureBuilder<bool>(
              future: _checkConnection(),
              builder: (context, snapshot) {
                bool connected = snapshot.data ?? false;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          connected ? Icons.check_circle : Icons.error,
                          color: connected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          connected
                              ? "Imprimante connectée et prête"
                              : "Aucune imprimante connectée",
                          style: TextStyle(
                            color: connected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Bouton d'impression de test global
            ElevatedButton.icon(
              onPressed: () async {
                final testReceipt = ReceiptFormatter.formatReceipt(
                  magasinNom: "Dakar Centre",
                  magasinAdresse: "Dakar",
                  date: DateTime.now().toString().substring(0, 19),
                  produits: [
                    {"nom": "Produit de test", "total_ligne": 1500.00}
                  ],
                  total: 1500.00,
                  montantPaye: 2000.00,
                );

                try {
                  await PrintServiceManager.printReceipt(testReceipt);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Reçu test imprimé avec succès !")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Échec impression : $e")),
                  );
                }
              },
              icon: const Icon(Icons.print),
              label: const Text("Imprimer un reçu de test"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkConnection() async {
    return PrintServiceManager.isConnected;
  }
}