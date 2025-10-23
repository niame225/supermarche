// lib/screens/wifi_settings_screen.dart

import 'package:flutter/material.dart';
import '../services/tcp_printer_service.dart';
import '../utils/receipt_formatter.dart';

class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '9100');

  bool _isConnecting = false;
  bool _isConnected = false;
  String _status = "Non connecté";

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _checkConnection();
  }

  Future<void> _loadSavedSettings() async {
    // Optionnel : charger depuis SharedPreferences si vous implémentez la persistance
    // Pour l'instant, on laisse vide (à compléter si besoin)
  }

  Future<void> _checkConnection() async {
    final isConnected = TcpPrinterService.instance.isConnected;
    setState(() {
      _isConnected = isConnected;
      _status = isConnected ? "Connecté" : "Non connecté";
    });
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final portStr = _portController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez entrer une adresse IP")));
      return;
    }

    int port;
    try {
      port = int.parse(portStr);
      if (port < 1 || port > 65535) throw FormatException();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Port invalide (1–65535)")));
      return;
    }

    setState(() {
      _isConnecting = true;
      _status = "Connexion en cours...";
    });

    try {
      TcpPrinterService.instance.configure(ip, port: port);
      final success = await TcpPrinterService.instance.connect();
      if (success) {
        setState(() {
          _isConnected = true;
          _status = "Connecté à $ip:$port";
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Connecté !")));
        // Optionnel : sauvegarder dans SharedPreferences
      } else {
        setState(() {
          _isConnected = false;
          _status = "Échec de la connexion";
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Impossible de se connecter")));
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
        _status = "Erreur : $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $e")));
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _testPrint() async {
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
      await TcpPrinterService.instance.printReceipt(testReceipt);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Reçu test envoyé !")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuration WiFi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("État de la connexion", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_status)),
                      ],
                    ),
                    if (_isConnected)
                      TextButton.icon(
                        onPressed: () async {
                          await TcpPrinterService.instance.disconnect();
                          setState(() {
                            _isConnected = false;
                            _status = "Déconnecté";
                            _ipController.clear();
                            _portController.text = '9100';
                          });
                        },
                        icon: const Icon(Icons.disconnect),
                        label: const Text("Déconnecter"),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Champs de configuration
            const Text("Paramètres de l'imprimante", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "Adresse IP",
                hintText: "Ex: 192.168.1.100",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: false),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: "Port",
                hintText: "9100 (standard)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // Boutons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _connect,
                  icon: const Icon(Icons.connect_without_contact),
                  label: const Text("Se connecter"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isConnected ? _testPrint : null,
                  icon: const Icon(Icons.print),
                  label: const Text("Imprimer test"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Informations utiles
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ℹ️ Informations", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("• Le port standard pour les imprimantes ESC/POS est 9100."),
                    Text("• Assurez-vous que l'imprimante et le téléphone sont sur le même réseau WiFi."),
                    Text("• Si la connexion échoue, vérifiez le pare-feu ou redémarrez l'imprimante."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}