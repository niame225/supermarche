class BilanJour {
  final double totalVentes;
  final double beneficeVentes;
  final double totalAppros;
  final double totalDepenses;
  final double totalPaiementsCredits;
  final double liquiditeActuelle;
  final double beneficeNetJour;

  BilanJour({
    required this.totalVentes,
    required this.beneficeVentes,
    required this.totalAppros,
    required this.totalDepenses,
    required this.totalPaiementsCredits,
    required this.liquiditeActuelle,
    required this.beneficeNetJour,
  });

  factory BilanJour.fromJson(Map<String, dynamic> json) {
    return BilanJour(
      totalVentes: json['total_ventes'].toDouble(),
      beneficeVentes: json['benefice_ventes'].toDouble(),
      totalAppros: json['total_appros'].toDouble(),
      totalDepenses: json['total_depenses'].toDouble(),
      totalPaiementsCredits: json['total_paiements_credits'].toDouble(),
      liquiditeActuelle: json['liquidite_actuelle'].toDouble(),
      beneficeNetJour: json['benefice_net_jour'].toDouble(),
    );
  }
}