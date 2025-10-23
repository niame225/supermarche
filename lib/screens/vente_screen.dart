import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../utils/receipt_formatter.dart';
import '../services/bluetooth_printer_service.dart'; // ← Ajouté

class VenteScreen extends StatefulWidget {
  final String magasinNom;
  final String magasinAdresse;

  const VenteScreen({
    Key? key,
    required this.magasinNom,
    required this.magasinAdresse,
  }) : super(key: key);

  @override
  State<VenteScreen> createState() => _VenteScreenState();
}

class _VenteScreenState extends State<VenteScreen> {
  final TextEditingController _produitsController = TextEditingController();
  final TextEditingController _montantPayeController = TextEditingController();

  List<String> _tousLesProduits = [];
  List<String> _suggestions = [];
  double _totalCalcule = 0.0;
  bool _showTotal = false;
  bool _showMonnaie = false;
  String _monnaieLabel = 'Monnaie à rendre :';
  Color _monnaieColor = Colors.green;
  double _monnaieMontant = 0.0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerProduits();
    _montantPayeController.addListener(_calculerMonnaie);
  }

  Future<void> _chargerProduits() async {
    try {
      final noms = await ApiService.getNomsProduits();
      setState(() {
        _tousLesProduits = noms;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement produits: $e')),
      );
    }
  }

  void _afficherSuggestions(String texte) {
    final partie = texte.split(',').last.trim();
    if (partie.contains('x') || partie.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final suggestions = _tousLesProduits
        .where((nom) => nom.toLowerCase().startsWith(partie.toLowerCase()))
        .take(10)
        .toList();
    setState(() => _suggestions = suggestions);
  }

  void _insererSuggestion(String nom) {
    final texte = _produitsController.text;
    final parties = texte.split(',');
    if (parties.isEmpty) return;
    parties[parties.length - 1] = '$nom x';
    _produitsController.text = parties.join(',');
    _produitsController.selection = TextSelection.collapsed(
      offset: _produitsController.text.length,
    );
    setState(() => _suggestions = []);
  }

  Future<void> _calculerTotal(String saisie) async {
    if (saisie.trim().isEmpty) {
      setState(() {
        _showTotal = false;
        _totalCalcule = 0.0;
        _calculerMonnaie();
      });
      return;
    }

    final items = saisie.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    double total = 0.0;
    bool erreur = false;

    for (final item in items) {
      if (!item.contains('x')) continue;
      final parts = item.split('x');
      if (parts.length < 2) continue;
      final nom = parts.sublist(0, parts.length - 1).join('x').trim();
      final qteStr = parts.last.trim();
      final qte = int.tryParse(qteStr);
      if (qte == null || qte <= 0) continue;

      try {
        final produit = await ApiService.getPrixProduit(nom);
        if (qte > produit.quantiteDisponible) {
          erreur = true;
          continue;
        }
        total += produit.prixFinal * qte;
      } catch (e) {
        erreur = true;
      }
    }

    setState(() {
      _totalCalcule = total;
      _showTotal = true;
      if (erreur && total == 0) {
        // Gestion d'erreur optionnelle
      }
      _calculerMonnaie();
    });
  }

  void _calculerMonnaie() {
    final montantPaye = double.tryParse(_montantPayeController.text) ?? 0.0;
    if (montantPaye > 0 && _totalCalcule > 0) {
      final monnaie = montantPaye - _totalCalcule;
      setState(() {
        _monnaieMontant = monnaie.abs();
        _showMonnaie = true;
        if (monnaie < 0) {
          _monnaieLabel = 'Montant insuffisant :';
          _monnaieColor = Colors.red;
        } else {
          _monnaieLabel = 'Monnaie à rendre :';
          _monnaieColor = Colors.green;
        }
      });
    } else {
      setState(() {
        _showMonnaie = false;
      });
    }
  }

  Future<void> _validerVente() async {
    final saisie = _produitsController.text.trim();
    final montantPayeStr = _montantPayeController.text;
    if (saisie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer des produits')));
      return;
    }
    final montantPaye = double.tryParse(montantPayeStr);
    if (montantPaye == null || montantPaye <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant payé invalide')));
      return;
    }

    if (_totalCalcule > 0 && montantPaye < _totalCalcule) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Montant insuffisant'),
          content: Text(
            'Le montant payé (${montantPaye.toStringAsFixed(2)} F) est inférieur au total (${_totalCalcule.toStringAsFixed(2)} F).\n\nContinuer quand même ?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.validerVente(
        saisie: saisie,
        montantPaye: montantPaye,
      );

      if (response['success'] == true) {
        // === GÉNÉRATION DU REÇU ===
        final receiptText = ReceiptFormatter.formatReceipt(
          magasinNom: widget.magasinNom,
          magasinAdresse: widget.magasinAdresse,
          date: response['date'],
          produits: List<Map<String, dynamic>>.from(response['produits']),
          total: response['total'],
          montantPaye: montantPaye,
        );

        // === IMPRESSION BLUETOOTH ===
        try {
          await BluetoothPrinterService.instance.printReceipt(receiptText);
          // Optionnel : afficher un message de succès
        } catch (e) {
          // Proposer d'imprimer plus tard ou de configurer l'imprimante
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Imprimante non connectée. Reçu sauvegardé.')),
          );
        }

        // Réinitialiser
        _produitsController.clear();
        _montantPayeController.clear();
        setState(() {
          _showTotal = false;
          _showMonnaie = false;
          _totalCalcule = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Vente réussie !\nTotal : ${response['total']} F\nMonnaie : ${_monnaieMontant.toStringAsFixed(2)} F')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${response['error'] ?? 'Erreur inconnue'}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Vente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Naviguer vers historique_ventes
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              // Champ produits
              TextField(
                controller: _produitsController,
                decoration: const InputDecoration(
                  labelText: 'Produits *',
                  hintText: 'Ex: Laitx2, Painx1, Bananex3',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _afficherSuggestions(value);
                  // Débouncer manuel simplifié
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (_produitsController.text == value) {
                      _calculerTotal(value);
                    }
                  });
                },
              ),
              if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_suggestions[index]),
                        onTap: () => _insererSuggestion(_suggestions[index]),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),

              // Total
              if (_showTotal)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total à payer :', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_totalCalcule.toStringAsFixed(2)} F', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Montant payé
              TextField(
                controller: _montantPayeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant payé par le client (F) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Monnaie
              if (_showMonnaie)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _monnaieColor.withOpacity(0.1),
                    border: Border.all(color: _monnaieColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_monnaieLabel, style: TextStyle(fontWeight: FontWeight.bold, color: _monnaieColor)),
                      Text('${_monnaieMontant.toStringAsFixed(2)} F', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _monnaieColor)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Bouton valider
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _validerVente,
                  icon: const Icon(Icons.cash),
                  label: const Text('Valider la vente', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}