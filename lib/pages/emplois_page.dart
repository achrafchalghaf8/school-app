import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class Emploi {
  final int id;
  final String datePublication;
  final String fichier; // base64 string
  final int classeId;

  Emploi({
    required this.id,
    required this.datePublication,
    required this.fichier,
    required this.classeId,
  });

  factory Emploi.fromJson(Map<String, dynamic> json) {
    return Emploi(
      id: json['id'] as int,
      datePublication: json['datePublication'] as String? ?? '',
      fichier: json['fichier'] as String? ?? '',
      classeId: json['classeId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datePublication': datePublication,
      'fichier': fichier,
      'classeId': classeId,
    };
  }
}

class EmploisPage extends StatefulWidget {
  const EmploisPage({Key? key}) : super(key: key);

  @override
  State<EmploisPage> createState() => _EmploisPageState();
}

class _EmploisPageState extends State<EmploisPage> {
  static const String _apiUrl = 'http://localhost:8004/api/emplois';

  final List<Emploi> _emplois = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmplois();
  }

  Future<void> _fetchEmplois() async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _emplois
            ..clear()
            ..addAll(data.map((e) => Emploi.fromJson(e as Map<String, dynamic>)));
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        debugPrint('Erreur de récupération: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la récupération des emplois')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      debugPrint('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau ou serveur')),
      );
    }
  }

  Future<void> _createEmploi(Map<String, dynamic> body) async {
    debugPrint('=== CRÉATION EMPLOI ===');
    debugPrint('URL: $_apiUrl');
    debugPrint('Données envoyées:');
    debugPrint('- datePublication: ${body['datePublication']}');
    debugPrint('- classeId: ${body['classeId']}');
    debugPrint('- fichier (longueur): ${body['fichier']?.toString().length ?? 0} caractères');
    if (body['fichier'] != null && body['fichier'].toString().isNotEmpty) {
      debugPrint('- fichier (début): ${body['fichier'].toString().substring(0, 50)}...');
    }

    final jsonBody = jsonEncode(body);
    debugPrint('JSON body (longueur): ${jsonBody.length} caractères');

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody
      );

      debugPrint('=== RÉPONSE SERVEUR ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Erreur création emploi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('=== ERREUR RÉSEAU ===');
      debugPrint('Exception: $e');
      rethrow;
    }
  }

  Future<void> _updateEmploi(int id, Map<String, dynamic> body) async {
    final response = await http.put(Uri.parse('$_apiUrl/$id'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour emploi');
    }
  }

  Future<void> _deleteEmploi(int id) async {
    final response = await http.delete(Uri.parse('$_apiUrl/$id'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      _fetchEmplois();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }

  String _previewBase64(String data, [int max = 30]) {
    if (data.isEmpty) return '—';
    return data.length <= max ? data : '${data.substring(0, max)}...';
  }

  Future<Map<String, String>?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final fileName = result.files.single.name;

      // Vérifier la taille du fichier (limite à 100KB pour test)
      const maxSize = 100 * 1024; // 100KB
      if (bytes.length > maxSize) {
        debugPrint('Fichier trop volumineux: ${bytes.length} bytes (max: $maxSize)');
        return null;
      }

      final base64Str = base64Encode(bytes);
      debugPrint('=== FICHIER SÉLECTIONNÉ ===');
      debugPrint('Nom: $fileName');
      debugPrint('Taille originale: ${bytes.length} bytes');
      debugPrint('Taille base64: ${base64Str.length} caractères');
      debugPrint('Base64 (début): ${base64Str.substring(0, 30)}...');

      return {
        'fileName': fileName,
        'base64': base64Str,
      };
    }
    return null;
  }

  Future<void> _showAddOrEditDialog({Emploi? emploi}) async {
    final dateCtl = TextEditingController(text: emploi?.datePublication ?? DateTime.now().toString().substring(0, 10));
    final classeCtl = TextEditingController(text: emploi?.classeId.toString() ?? '');
    String localBase64 = emploi?.fichier ?? '';
      String selectedFileName = '';
    String buttonLabel = localBase64.isEmpty ? 'Choisir un fichier' : 'Fichier sélectionné';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: Text(emploi == null ? 'Ajouter Emploi' : 'Modifier Emploi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: dateCtl,
                    decoration: const InputDecoration(labelText: 'Date Publication'),
                  ),
                  TextField(
                    controller: classeCtl,
                    decoration: const InputDecoration(labelText: 'Classe ID'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final fileData = await _pickFile();
                      if (fileData != null) {
                        dialogSetState(() {
                          localBase64 = fileData['base64']!;
                          selectedFileName = fileData['fileName']!;
                          buttonLabel = selectedFileName;
                        });
                      } else {
                        dialogSetState(() {
                          buttonLabel = 'Erreur: fichier trop volumineux ou invalide';
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(buttonLabel),
                  ),
                  if (localBase64.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Début base64 : ${_previewBase64(localBase64)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validation des données
                  if (dateCtl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez saisir une date')),
                    );
                    return;
                  }

                  final classeId = int.tryParse(classeCtl.text);
                  if (classeId == null || classeId <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez saisir un ID de classe valide')),
                    );
                    return;
                  }

                  // Temporairement : permettre l'ajout sans fichier pour tester
                  // if (localBase64.isEmpty) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('Veuillez sélectionner un fichier')),
                  //   );
                  //   return;
                  // }

                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final payload = {
                    'datePublication': dateCtl.text.trim(),
                    'classeId': classeId,
                    'fichier': localBase64.isEmpty ? 'test_sans_fichier' : localBase64,
                  };

                  try {
                    if (emploi == null) {
                      await _createEmploi(payload);
                    } else {
                      await _updateEmploi(emploi.id, payload);
                    }
                    if (mounted) {
                      navigator.pop();
                      _fetchEmplois();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(emploi == null ? 'Ajouté avec succès' : 'Modifié avec succès')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: Text(emploi == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liste des Emplois')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _emplois.isEmpty
              ? const Center(child: Text('Aucun emploi trouvé'))
              : ListView.separated(
                  itemCount: _emplois.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final emploi = _emplois[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${emploi.id}')),
                      title: Text('Classe: ${emploi.classeId}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: ${emploi.datePublication}'),
                          const SizedBox(height: 4),
                          Text('Base64: ${_previewBase64(emploi.fichier)}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddOrEditDialog(emploi: emploi),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: Text('Supprimer emploi #${emploi.id} ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteEmploi(emploi.id);
                                      },
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
