import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8004/api';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  // Méthodes existantes inchangées
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return User.fromJson(data);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<List<User>> getAccounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/comptes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load accounts: ${response.statusCode}');
    }
  }

  Future<User> createAccount(User user, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comptes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'email': user.email,
        'nom': user.nom,
        'password': password,
        'role': user.role,
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create account: ${response.statusCode}');
    }
  }

  Future<User> updateAccount(User user, {String? password}) async {
    final body = {
      'email': user.email,
      'nom': user.nom,
      'role': user.role,
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/comptes/${user.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update account: ${response.statusCode}');
    }
  }

  Future<void> deleteAccount(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/comptes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account: ${response.statusCode}');
    }
  }

  Future<List<User>> getAdmins() async {
    final response = await http.get(
      Uri.parse('$baseUrl/comptes?role=ADMIN'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load admins: ${response.statusCode}');
    }
  }

  // NOUVELLES METHODES AJOUTÉES (POST/DELETE via /admins)
  Future<User> createAdmin({
    required String email,
    required String nom,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'email': email,
        'nom': nom,
        'password': password,
        'role': 'ADMIN',
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create admin: ${response.statusCode}');
    }
  }

  Future<void> deleteAdmin(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admins/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete admin: ${response.statusCode}');
    }
  }
}