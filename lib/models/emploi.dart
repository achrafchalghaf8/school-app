class Emploi {
  final int id;
  final String datePublication;
  final String fichier;
  final int classeId;

  Emploi({required this.id, required this.datePublication, required this.fichier, required this.classeId});

  factory Emploi.fromJson(Map<String, dynamic> json) {
    return Emploi(
      id: json['id'],
      datePublication: json['datePublication'],
      fichier: json['fichier'],
      classeId: json['classeId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'datePublication': datePublication,
    'fichier': fichier,
    'classeId': classeId,
  };
}
