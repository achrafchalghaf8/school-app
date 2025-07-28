import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourseExercisesPage extends StatefulWidget {
  final int courseId;
  final String token;

  const CourseExercisesPage({
    super.key,
    required this.courseId,
    required this.token,
  });

  @override
  State<CourseExercisesPage> createState() => _CourseExercisesPageState();
}

class _CourseExercisesPageState extends State<CourseExercisesPage> {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;
  String _error = '';
  String _courseTitle = '';

  @override
  void initState() {
    super.initState();
    _fetchCourseDetails();
    _fetchExercises();
  }

  Future<void> _fetchCourseDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/cours/${widget.courseId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _courseTitle = data['matiere'] ?? 'Cours sans titre';
        });
      }
    } catch (e) {
      setState(() {
        _courseTitle = 'Erreur de chargement';
      });
    }
  }

  Future<void> _fetchExercises() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/exercices?courId=${widget.courseId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _exercises = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur de chargement: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  void _deleteExercise(int exerciseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet exercice ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await http.delete(
          Uri.parse('http://localhost:8004/api/exercices/$exerciseId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchExercises();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercices: $_courseTitle'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _exercises.isEmpty
                  ? const Center(
                      child: Text('Aucun exercice trouvé',
                          style: TextStyle(fontSize: 18)))
                  : RefreshIndicator(
                      onRefresh: _fetchExercises,
                      child: ListView.builder(
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                exercise['contenu'] ?? 'Exercice sans titre',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${exercise['datePublication']}'),
                                  Text('ID: ${exercise['id']}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteExercise(exercise['id']),
                                tooltip: 'Supprimer',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}