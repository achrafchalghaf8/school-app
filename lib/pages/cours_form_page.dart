import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/emplois_page.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../services/localization_service.dart';


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
  String? _selectedEnseignantId;
  List<Map<String, dynamic>> _enseignants = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchEnseignants();
  }

  Future<void> _fetchEnseignants() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/enseignants'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _enseignants = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des enseignants: $e');
    }
  }

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
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Matière'),
              onChanged: (val) => _matiere = val,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEnseignantId,
              decoration: InputDecoration(labelText: context.tr('courses.course_owner')),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(context.tr('courses.select_teacher')),
                ),
                ..._enseignants.map((enseignant) => DropdownMenuItem<String>(
                  value: enseignant['id'].toString(),
                  child: Text(enseignant['nom'] ?? ''),
                )).toList(),
              ],
              onChanged: (val) => setState(() => _selectedEnseignantId = val),
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
      // Trouver le nom de l'enseignant sélectionné
      String? proprietaire;
      if (_selectedEnseignantId != null) {
        final enseignant = _enseignants.firstWhere(
          (e) => e['id'].toString() == _selectedEnseignantId,
          orElse: () => {},
        );
        if (enseignant.isNotEmpty) {
          proprietaire = enseignant['nom'];
        }
      }

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
          'proprietaire': proprietaire,
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