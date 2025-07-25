class User {
  final int id;
  final String email;
  final String nom;
  final String role;
  final String token;
  final String tokenExpiration;

  User({
    required this.id,
    required this.email,
    required this.nom,
    required this.role,
    required this.token,
    required this.tokenExpiration,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      role: json['role'] ?? 'PARENT',
      token: json['token'] ?? '',
      tokenExpiration: json['tokenExpiration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'role': role,
    };
  }
}