class Client {
  final int id;
  final String nom;
  final String? contact;
  final double totalDette;
  final double totalAchats;

  Client({
    required this.id,
    required this.nom,
    this.contact,
    required this.totalDette,
    required this.totalAchats,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      nom: json['nom'],
      contact: json['contact'],
      totalDette: json['total_dette'].toDouble(),
      totalAchats: json['total_achats'].toDouble(),
    );
  }
}