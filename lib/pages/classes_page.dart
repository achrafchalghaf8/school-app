import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import 'class_dialog.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({Key? key}) : super(key: key);

  @override
  _ClassesPageState createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final String _classesApiUrl = "http://localhost:8004/api/classes";
  final String _enseignantsApiUrl = "http://localhost:8004/api/enseignants";
  
  List<dynamic> _classes = [];
  List<dynamic> _enseignants = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final [classesResponse, enseignantsResponse] = await Future.wait([
        http.get(Uri.parse(_classesApiUrl)),
        http.get(Uri.parse(_enseignantsApiUrl)),
      ]);

      if (classesResponse.statusCode == 200 && enseignantsResponse.statusCode == 200) {
        setState(() {
          _classes = json.decode(classesResponse.body);
          _enseignants = json.decode(enseignantsResponse.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteClass(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_classesApiUrl/$id'));
      
      if (response.statusCode == 204) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classe supprimée avec succès')),
        );
      } else {
        throw Exception('Failed to delete class');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _showAddEditClassDialog({Map<String, dynamic>? classe}) {
    showDialog(
      context: context,
      builder: (context) => ClassDialog(
        classe: classe,
        enseignants: _enseignants,
        onSave: (newClasse) async {
          Navigator.of(context).pop();
          try {
            if (classe == null) {
              // Ajout d'une nouvelle classe
              final response = await http.post(
                Uri.parse(_classesApiUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'niveau': newClasse['niveau'],
                  'enseignantIds': newClasse['enseignantIds'],
                }),
              );
              
              if (response.statusCode == 201) {
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Classe ajoutée avec succès')),
                );
              } else {
                throw Exception('Failed to add class');
              }
            } else {
              // Mise à jour d'une classe existante
              final response = await http.put(
                Uri.parse('$_classesApiUrl/${newClasse['id']}'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'niveau': newClasse['niveau'],
                  'enseignantIds': newClasse['enseignantIds'],
                }),
              );
              
              if (response.statusCode == 200) {
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Classe modifiée avec succès')),
                );
              } else {
                throw Exception('Failed to update class');
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  String _getEnseignantsNames(List<int> enseignantIds) {
    return _enseignants
        .where((enseignant) => enseignantIds.contains(enseignant['id']))
        .map((enseignant) => enseignant['nom'])
        .join(', ');
  }

  Widget _buildClassList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Erreur de chargement'),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return const Center(child: Text('Aucune classe trouvée'));
    }

    return ListView.builder(
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classe = _classes[index];
        final enseignantIds = List<int>.from(classe['enseignantIds'] ?? []);
        final enseignantsNames = _getEnseignantsNames(enseignantIds);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(classe['niveau'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (enseignantsNames.isNotEmpty)
                  Text('Enseignants: $enseignantsNames'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddEditClassDialog(classe: classe),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(classe['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int classId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette classe ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClass(classId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditClassDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _buildClassList(),
    );
  }
}