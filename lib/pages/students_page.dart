import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import 'student_dialog.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> students = [];
  List<dynamic> classes = [];
  List<dynamic> parents = [];
  bool isLoading = true;
  final String studentsApiUrl = "http://localhost:8004/api/etudiants";
  final String classesApiUrl = "http://localhost:8004/api/classes";
  final String parentsApiUrl = "http://localhost:8004/api/parents";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final studentsResponse = await http.get(Uri.parse(studentsApiUrl));
      final classesResponse = await http.get(Uri.parse(classesApiUrl));
      final parentsResponse = await http.get(Uri.parse(parentsApiUrl));

      if (studentsResponse.statusCode == 200 && 
          classesResponse.statusCode == 200 &&
          parentsResponse.statusCode == 200) {
        setState(() {
          students = json.decode(studentsResponse.body);
          classes = json.decode(classesResponse.body);
          parents = json.decode(parentsResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final response = await http.delete(Uri.parse('$studentsApiUrl/$id'));
      if (response.statusCode == 204) {
        fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant supprimé avec succès')),
        );
      } else {
        throw Exception('Failed to delete student');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void showAddEditStudentDialog({Map<String, dynamic>? student}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StudentDialog(
          student: student,
          classes: classes,
          parents: parents,
          onSave: (newStudent) async {
            Navigator.of(context).pop();
            try {
              final response = student == null
                  ? await http.post(
                      Uri.parse(studentsApiUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newStudent),
                    )
                  : await http.put(
                      Uri.parse('$studentsApiUrl/${student['id']}'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newStudent),
                    );

              if (response.statusCode == 201 || response.statusCode == 200) {
                fetchData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(student == null 
                      ? 'Étudiant ajouté avec succès' 
                      : 'Étudiant modifié avec succès')),
                );
              } else {
                throw Exception('Failed to save student');
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          },
        );
      },
    );
  }

  String getClassName(int classId) {
    try {
      return classes.firstWhere((c) => c['id'] == classId)['niveau'] ?? 'Inconnu';
    } catch (e) {
      return 'Inconnu';
    }
  }

  String getParentName(int parentId) {
    try {
      final parent = parents.firstWhere((p) => p['id'] == parentId);
      return '${parent['nom']} (${parent['telephone']})';
    } catch (e) {
      return 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Étudiants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddEditStudentDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text('Aucun étudiant trouvé'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text('${student['prenom']} ${student['nom']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Classe: ${getClassName(student['classeId'])}'),
                            Text('Parent: ${getParentName(student['parentId'])}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  showAddEditStudentDialog(student: student),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirmer la suppression'),
                                      content: const Text(
                                          'Voulez-vous vraiment supprimer cet étudiant ?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Annuler'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                        TextButton(
                                          child: const Text('Supprimer'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            deleteStudent(student['id']);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () =>
                            showAddEditStudentDialog(student: student),
                      ),
                    );
                  },
                ),
    );
  }
}