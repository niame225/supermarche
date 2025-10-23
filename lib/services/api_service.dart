// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produit.dart';
import '../models/vente.dart';
import '../models/approvisionnement.dart';
import '../models/credit.dart';
import '../models/client.dart';
import '../models/bilan_jour.dart';

class ApiService {
  // 🔧 URL corrigée : suppression des espaces en fin
  static const String baseUrl = 'https://comptableperso.pythonanywhere.com';

  // === PRODUITS ===
  static Future<List<String>> getNomsProduits() async {
    final response = await http.get(Uri.parse('$baseUrl/api/produits/noms'));
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return List<String>.from(body);
      }
    }
    throw Exception('Échec du chargement des noms de produits');
  }

  static Future<Produit> getPrixProduit(String nom) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/produit/prix?nom=${Uri.encodeComponent(nom)}'),
    );
    if (response.statusCode == 200) {
      return Produit.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Produit non trouvé');
    } else {
      throw Exception('Erreur serveur (${response.statusCode})');
    }
  }

  // === VENTES ===
  static Future<Map<String, dynamic>> validerVente({
    required String saisie,
    required double montantPaye,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ventes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'saisie': saisie,
        'montant_paye': montantPaye,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data;
      } else {
        final error = data['error'] ?? 'Erreur inconnue';
        throw Exception('Échec validation : $error');
      }
    } else {
      throw Exception('Erreur API vente (${response.statusCode})');
    }
  }

  static Future<List<Vente>> getHistoriqueVentes({
    String? dateDebut,
    String? dateFin,
  }) async {
    final params = <String, String>{};
    if (dateDebut != null) params['date_debut'] = dateDebut;
    if (dateFin != null) params['date_fin'] = dateFin;

    final uri = Uri(
      scheme: 'https',
      host: 'comptableperso.pythonanywhere.com',
      path: 'ventes/historique-dates',
      queryParameters: params,
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('ventes')) {
        final ventesJson = data['ventes'] as List;
        return ventesJson.map((v) => Vente.fromJson(v)).toList();
      }
    }
    throw Exception('Échec du chargement de l\'historique');
  }

  static Future<Map<String, dynamic>> getDetailsVente(int venteId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ventes/$venteId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data;
      } else {
        final error = data['error'] ?? 'Données invalides';
        throw Exception('Erreur détails vente : $error');
      }
    } else {
      throw Exception('Vente non trouvée (${response.statusCode})');
    }
  }

  // === APPROVISIONNEMENTS ===
  static Future<List<Approvisionnement>> getHistoriqueAppros({
    String? dateDebut,
    String? dateFin,
  }) async {
    final params = <String, String>{};
    if (dateDebut != null) params['date_debut'] = dateDebut;
    if (dateFin != null) params['date_fin'] = dateFin;

    final uri = Uri(
      scheme: 'https',
      host: 'comptableperso.pythonanywhere.com',
      path: 'approvisionner/historique',
      queryParameters: params,
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('appros')) {
        final approsJson = data['appros'] as List;
        return approsJson.map((a) => Approvisionnement.fromJson(a)).toList();
      }
    }
    throw Exception('Échec du chargement de l\'historique des approvisionnements');
  }

  // === CRÉDITS ===
  static Future<Map<String, dynamic>> enregistrerCredit({
    required String client,
    required String produits,
    required double montant,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/credits'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': client,
        'produits': produits,
        'montant': montant,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erreur lors de l\'enregistrement du crédit');
  }

  static Future<List<Credit>> getHistoriqueCredits() async {
    final response = await http.get(Uri.parse('$baseUrl/api/credits/historique'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((c) => Credit.fromJson(c)).toList();
    }
    throw Exception('Erreur chargement historique crédits');
  }

  // === CLIENTS ===
  static Future<List<Client>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/api/clients/recherche?term='));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((c) => Client.fromJson(c)).toList();
    }
    throw Exception('Erreur chargement clients');
  }

  // === BILAN DU JOUR ===
  static Future<BilanJour> getBilanJour() async {
    final response = await http.get(Uri.parse('$baseUrl/api/bilan/jour'));
    if (response.statusCode == 200) {
      return BilanJour.fromJson(json.decode(response.body));
    }
    throw Exception('Erreur chargement bilan du jour');
  }
}