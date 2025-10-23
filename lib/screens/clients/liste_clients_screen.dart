// lib/screens/clients/liste_clients_screen.dart

import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/api_service.dart';

class ListeClientsScreen extends StatefulWidget {
  const ListeClientsScreen({Key? key}) : super(key: key);

  @override
  State<ListeClientsScreen> createState() => _ListeClientsScreenState();
}

class _ListeClientsScreenState extends State<ListeClientsScreen> {
  List<Client> _clients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerClients();
  }

  Future<void> _chargerClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await ApiService.getClients();
      setState(() => _clients = clients);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des Clients")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? const Center(child: Text("Aucun client"))
              : ListView.builder(
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final c = _clients[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(c.nom),
                        subtitle: Text(c.contact ?? ""),
                        trailing: Text("${c.totalDette} F"),
                      ),
                    );
                  },
                ),
    );
  }
}