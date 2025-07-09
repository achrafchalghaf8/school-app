import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import 'teacher_dialog.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({Key? key}) : super(key: key);

  @override
  _TeachersPageState createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final String _teachersApiUrl = "http://localhost:8004/api/enseignants";
  final String _classesApiUrl = "http://localhost:8004/api/classes";
  
  List<dynamic> _teachers = [];
  List<dynamic> _classes = [];
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
      final [teachersResponse, classesResponse] = await Future.wait([
        http.get(Uri.parse(_teachersApiUrl)),
        http.get(Uri.parse(_classesApiUrl)),
      ]);

      if (teachersResponse.statusCode == 200 && classesResponse.statusCode == 200) {
        setState(() {
          _teachers = json.decode(teachersResponse.body);
          _classes = json.decode(classesResponse.body);
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

  Future<void> _deleteTeacher(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_teachersApiUrl/$id'));
      
      if (response.statusCode == 204) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enseignant supprimé avec succès')),
        );
      } else {
        throw Exception('Failed to delete teacher');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _showAddEditTeacherDialog({Map<String, dynamic>? teacher}) {
    showDialog(
      context: context,
      builder: (context) => TeacherDialog(
        teacher: teacher,
        classes: _classes,
        onSave: (newTeacher) async {
          Navigator.of(context).pop();
          try {
            final response = teacher == null
                ? await http.post(
                    Uri.parse(_teachersApiUrl),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode(newTeacher),
                  )
                : await http.put(
                    Uri.parse('$_teachersApiUrl/${teacher['id']}'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode(newTeacher),
                  );

            if (response.statusCode == 201 || response.statusCode == 200) {
              _fetchData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(teacher == null 
                    ? 'Enseignant ajouté avec succès' 
                    : 'Enseignant modifié avec succès')),
              );
            } else {
              throw Exception('Failed to save teacher');
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

  Widget _buildTeacherList() {
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

    if (_teachers.isEmpty) {
      return const Center(child: Text('Aucun enseignant trouvé'));
    }

    return ListView.builder(
      itemCount: _teachers.length,
      itemBuilder: (context, index) {
        final teacher = _teachers[index];
        final assignedClasses = _classes.where((c) => 
            (teacher['classeIds'] as List?)?.contains(c['id']) ?? false)
            .map((c) => c['niveau'])
            .join(', ');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(teacher['nom'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teacher['email'] ?? ''),
                Text('Spécialité: ${teacher['specialite'] ?? ''}'),
                Text('Tél: ${teacher['telephone'] ?? ''}'),
                if (assignedClasses.isNotEmpty)
                  Text('Classes: $assignedClasses'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddEditTeacherDialog(teacher: teacher),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(teacher['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int teacherId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet enseignant ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTeacher(teacherId);
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
        title: const Text('Gestion des Enseignants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditTeacherDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _buildTeacherList(),
    );
  }
}