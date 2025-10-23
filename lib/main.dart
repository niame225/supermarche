// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/vente_screen.dart';
import 'screens/historique_ventes_screen.dart';
import 'screens/historique_approvisionnements_screen.dart';
import 'screens/credits/nouveau_credit_screen.dart';
import 'screens/credits/historique_credits_screen.dart';
import 'screens/bilan_jour_screen.dart';
import 'screens/clients/liste_clients_screen.dart';
import 'screens/printer_selection_screen.dart';

void main() {
  // Optionnel : désactiver les logs de débogage en production
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(const SupermarcheApp());
}

class SupermarcheApp extends StatelessWidget {
  const SupermarcheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supermarché - Gestion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/dashboard': (context) => DashboardScreen(
              magasinNom: "Dakar Centre", // À remplacer dynamiquement après login
            ),
        '/vente': (context) => VenteScreen(
              magasinNom: "Dakar Centre",
              magasinAdresse: "Dakar",
            ),
        '/historique-ventes': (context) => const HistoriqueVentesScreen(),
        '/historique-appros': (context) => const HistoriqueApprovisionnementsScreen(),
        '/credits/nouveau': (context) => const NouveauCreditScreen(),
        '/credits/historique': (context) => const HistoriqueCreditsScreen(),
        '/bilan-jour': (context) => const BilanJourScreen(),
        '/clients': (context) => const ListeClientsScreen(),
        '/impression': (context) => const PrinterSelectionScreen(),
      },
    );
  }
}