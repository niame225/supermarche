class Produit {
  final String nom;
  final double prixVente;
  final double prixFinal;
  final int quantiteDisponible;
  final double promotion;

  Produit({
    required this.nom,
    required this.prixVente,
    required this.prixFinal,
    required this.quantiteDisponible,
    required this.promotion,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      nom: json['nom'],
      prixVente: json['prix_vente'].toDouble(),
      prixFinal: json['prix_final'].toDouble(),
      quantiteDisponible: json['quantite_disponible'],
      promotion: json['promotion'].toDouble(),
    );
  }
}