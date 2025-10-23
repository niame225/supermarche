// lib/models/approvisionnement.dart

class Approvisionnement {
  final int id;
  final DateTime date;
  final String nomProduit;
  final int quantite;
  final double prixAchat;
  final double prixVente;

  String get dateAffichee => '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  Approvisionnement({
    required this.id,
    required this.date,
    required this.nomProduit,
    required this.quantite,
    required this.prixAchat,
    required this.prixVente,
  });

  factory Approvisionnement.fromJson(Map<String, dynamic> json) {
    // Gestion sécurisée des champs
    final id = json['id'] as int? ?? 0;
    final quantite = json['quantite'] as int? ?? 0;
    final prixAchat = (json['prix_achat'] as num?)?.toDouble() ?? 0.0;
    final prixVente = (json['prix_vente'] as num?)?.toDouble() ?? 0.0;

    // Nom du produit : votre API utilise "nom", pas "produit_nom"
    final nomProduit = json['nom'] as String? ?? 'Produit inconnu';

    // Parsing de la date
    DateTime date;
    final dateStr = json['date'];
    if (dateStr is String) {
      // Format ISO 8601 attendu : "2025-04-05T14:30:00"
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // Fallback sur maintenant si parsing échoue
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    return Approvisionnement(
      id: id,
      date: date,
      nomProduit: nomProduit,
      quantite: quantite,
      prixAchat: prixAchat,
      prixVente: prixVente,
    );
  }
}