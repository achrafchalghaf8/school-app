import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'emploi_dialog.dart';
import 'admin_drawer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // pour ouverture fichiers web

class EmploisPage extends StatefulWidget {
  const EmploisPage({Key? key}) : super(key: key);

  @override
  _EmploisPageState createState() => _EmploisPageState();
}

class _EmploisPageState extends State<EmploisPage> {
  final String _apiUrl = "http://localhost:8004/api/emplois";
  List<dynamic> _emplois = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmplois();
  }

  Future<void> _fetchEmplois() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          _emplois = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _deleteEmploi(int id) async {
    try {
      final response = await http.delete(Uri.parse("$_apiUrl/$id"));
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchEmplois();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emploi supprimé')),
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _viewFile(String fileName) async {
    final url = "http://localhost:8004/uploads/$fileName";
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      // TODO: gérer ouverture fichier sur mobile/desktop (ex: OpenFile)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emplois du Temps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => EmploiDialog(
                emploi: null,
                onSave: _fetchEmplois,
              ),
            ),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _emplois.length,
              itemBuilder: (context, index) {
                final emploi = _emplois[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text('Classe: ${emploi['classeId']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${emploi['datePublication']}'),
                        if (emploi['fichier'] != null)
                          InkWell(
                            onTap: () => _viewFile(emploi['fichier']),
                            child: Text(
                              'Fichier: ${emploi['fichier']}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => EmploiDialog(
                              emploi: emploi,
                              onSave: _fetchEmplois,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmation'),
                                content: const Text('Supprimer cet emploi ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _deleteEmploi(emploi['id']);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
