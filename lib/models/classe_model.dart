class Classe {
  final int id;
  final String niveau;
  final List<int> enseignantIds;

  Classe({
    required this.id,
    required this.niveau,
    required this.enseignantIds,
  });

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      id: json['id'] as int,
      niveau: json['niveau'] as String,
      enseignantIds: (json['enseignantIds'] as List).map((e) => e as int).toList(),
    );
  }
}