import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/parent_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';

class ParentsPage extends StatefulWidget {
  const ParentsPage({Key? key}) : super(key: key);

  @override
  _ParentsPageState createState() => _ParentsPageState();
}

class _ParentsPageState extends State<ParentsPage> {
  List<dynamic> parents = [];
  bool isLoading = true;
  final String apiUrl = "http://localhost:8004/api/parents";

  @override
  void initState() {
    super.initState();
    fetchParents();
  }

  Future<void> fetchParents() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          parents = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load parents');
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

  Future<void> deleteParent(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 204) {
        fetchParents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent supprimé avec succès')),
        );
      } else {
        throw Exception('Failed to delete parent');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void showAddEditParentDialog({Map<String, dynamic>? parent}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ParentDialog(
          parent: parent,
          onSave: (newParent) async {
            Navigator.of(context).pop();
            try {
              final response = parent == null
                  ? await http.post(
                      Uri.parse(apiUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newParent),
                    )
                  : await http.put(
                      Uri.parse('$apiUrl/${parent['id']}'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newParent),
                    );

              if (response.statusCode == 201 || response.statusCode == 200) {
                fetchParents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(parent == null 
                      ? 'Parent ajouté avec succès' 
                      : 'Parent modifié avec succès')),
                );
              } else {
                throw Exception('Failed to save parent');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Parents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddEditParentDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchParents,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : parents.isEmpty
              ? const Center(child: Text('Aucun parent trouvé'))
              : ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parent = parents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(parent['nom']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(parent['email']),
                            Text('Tél: ${parent['telephone']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  showAddEditParentDialog(parent: parent),
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
                                          'Voulez-vous vraiment supprimer ce parent ?'),
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
                                            deleteParent(parent['id']);
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
                            showAddEditParentDialog(parent: parent),
                      ),
                    );
                  },
                ),
    );
  }
}