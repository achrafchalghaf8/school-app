import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/emplois_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'classe_detail_page.dart';
import 'cours_form_page.dart';

class WelcomeTeacherPage extends StatefulWidget {
  final int userId;
  final String token;
  const WelcomeTeacherPage({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  State<WelcomeTeacherPage> createState() => _WelcomeTeacherPageState();
}

class _WelcomeTeacherPageState extends State<WelcomeTeacherPage> {
  List<Classe> _classes = [];
  List<Map<String, dynamic>> _cours = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchCours();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/classes'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final allClasses = data.map((e) => Classe.fromJson(e)).toList();

        setState(() {
          _classes = allClasses.where((c) => c.enseignantIds.contains(widget.userId)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau';
        _loading = false;
      });
    }
  }

  Future<void> _fetchCours() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/cours'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cours = data.map((c) => c as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      // ignore error
    }
  }

  void _navigateToCoursForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CoursFormPage(
          token: widget.token,
          userId: widget.userId,
          classes: _classes,
          refreshCallback: _fetchCours,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Enseignant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un cours',
            onPressed: _navigateToCoursForm,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _classes.isEmpty
                  ? const Center(child: Text('Aucune classe assignée'))
                  : ListView.builder(
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        final classe = _classes[index];
                        return Card(
                          margin: const EdgeInsets.all(12),
                          child: ListTile(
                            leading: const Icon(Icons.class_, size: 32),
                            title: Text(classe.niveau),
                            subtitle: Text('ID: ${classe.id}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => ClasseDetailPage(
                                    classeId: classe.id,
                                    token: widget.token,
                                    enseignantId: widget.userId, // <== transmis ici
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
