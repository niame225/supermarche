class Vente {
  final int id;
  final String date;
  final String produitNom;
  final int quantite;
  final double prixUnitaire;
  final double total;
  final double benefice;

  Vente({
    required this.id,
    required this.date,
    required this.produitNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.total,
    required this.benefice,
  });

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      id: json['id'],
      date: json['date'],
      produitNom: json['produit_nom'] ?? 'Inconnu',
      quantite: json['quantite'],
      prixUnitaire: json['prix_unitaire'].toDouble(),
      total: json['total'].toDouble(),
      benefice: (json['benefice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}