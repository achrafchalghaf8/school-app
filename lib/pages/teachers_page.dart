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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Implémenter la fonctionnalité de recherche si nécessaire
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
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _deleteTeacher(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_teachersApiUrl/$id'));
      
      if (response.statusCode == 204) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enseignant supprimé avec succès'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Failed to delete teacher');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showAddEditTeacherDialog({Map<String, dynamic>? teacher}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: TeacherDialog(
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
                  SnackBar(
                    content: Text(teacher == null 
                        ? 'Enseignant ajouté avec succès' 
                        : 'Enseignant modifié avec succès'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                throw Exception('Failed to save teacher');
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${e.toString()}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue.shade900));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Erreur de chargement', style: TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _fetchData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_teachers.isEmpty) {
      return const Center(child: Text('Aucun enseignant trouvé', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _teachers.length,
      itemBuilder: (context, index) {
        final teacher = _teachers[index];
        final assignedClasses = _classes.where((c) => 
            (teacher['classeIds'] as List?)?.contains(c['id']) ?? false)
            .map((c) => c['niveau'])
            .join(', ');

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade900,
              child: Text(
                teacher['nom']?[0]?.toUpperCase() ?? 'E',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              teacher['nom'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  teacher['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  'Spécialité: ${teacher['specialite'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'Tél: ${teacher['telephone'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (assignedClasses.isNotEmpty)
                  Text(
                    'Classes: $assignedClasses',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade900),
                  onPressed: () => _showAddEditTeacherDialog(teacher: teacher),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(teacher['id']),
                  tooltip: 'Supprimer',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: Text(
          'Confirmer la suppression',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Voulez-vous vraiment supprimer cet enseignant ?'),
        actions: [
          TextButton(
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w600)),
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
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Gestion des Enseignants',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un enseignant',
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.blue.shade900),
                  onPressed: () {
                    _searchController.clear();
                    _fetchData();
                  },
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade900.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildTeacherList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        onPressed: () => _showAddEditTeacherDialog(),
        child: const Icon(Icons.add, size: 28),
        tooltip: 'Ajouter un enseignant',
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}