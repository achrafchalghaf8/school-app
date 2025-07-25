import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/emplois_page.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';


class CoursFormPage extends StatefulWidget {
  final String token;
  final int userId;
  final List<Classe> classes;
  final Function() refreshCallback;

  const CoursFormPage({
    Key? key,
    required this.token,
    required this.userId,
    required this.classes,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  _CoursFormPageState createState() => _CoursFormPageState();
}

class _CoursFormPageState extends State<CoursFormPage> {
  String _matiere = '';
  int? _selectedClasseId;
  String _fichierBase64 = '';
  String _fileName = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Cours')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _selectedClasseId,
              items: widget.classes.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.niveau),
              )).toList(),
              onChanged: (val) => setState(() => _selectedClasseId = val),
              decoration: const InputDecoration(labelText: 'Classe'),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Matière'),
              onChanged: (val) => _matiere = val,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(_fileName.isEmpty 
                  ? 'Choisir un fichier' 
                  : 'Fichier: $_fileName'),
              onPressed: _pickFile,
            ),
            const SizedBox(height: 24),
            if (_saving) const CircularProgressIndicator(),
            if (!_saving)
              ElevatedButton(
                onPressed: _createCours,
                child: const Text('Créer le Cours'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fichierBase64 = base64Encode(result.files.single.bytes!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _createCours() async {
    if (_selectedClasseId == null || _matiere.isEmpty || _fichierBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Création du cours
      final courseResponse = await http.post(
        Uri.parse('http://localhost:8004/api/cours'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'matiere': _matiere,
          'fichier': _fichierBase64,
        }),
      );

      if (courseResponse.statusCode != 201) {
        throw Exception('Échec création cours: ${courseResponse.body}');
      }

      final newCourse = jsonDecode(courseResponse.body);
      final newCourseId = newCourse['id'] as int;

      // Création de l'exercice associé
      await http.post(
        Uri.parse('http://localhost:8004/api/exercices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'contenu': 'Support de cours: $_matiere',
          'datePublication': DateTime.now().toIso8601String().substring(0, 10),
          'fichier': _fichierBase64,
          'classeIds': [_selectedClasseId],
          'courId': newCourseId,
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours créé avec succès!')),
      );
      widget.refreshCallback();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }
}