import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<int?> getUserIdFromStorage() async {
  if (kIsWeb) {
    try {
      final idStr = html.window.localStorage['flutter.userId'];
      if (idStr != null) {
        return int.tryParse(idStr);
      }
    } catch (_) {}
    return null;
  } else {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('flutter.userId');
  }
}

class ExercicesPage extends StatefulWidget {
  final int courId;
  final String token;
  final int classeId;

  const ExercicesPage({
    Key? key,
    required this.courId,
    required this.token,
    required this.classeId,
  }) : super(key: key);

  @override
  State<ExercicesPage> createState() => _ExercicesPageState();
}

class _ExercicesPageState extends State<ExercicesPage> {
  late Future<List<Map<String, dynamic>>> _exercicesFuture;
  late Future<List<Map<String, dynamic>>> _classesFuture;
  late Future<Map<String, dynamic>> _courFuture;
  bool _isLoading = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndRefresh();
  }

  Future<void> _loadUserIdAndRefresh() async {
    int? userId = await getUserIdFromStorage();
    setState(() {
      _userId = userId;
    });
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _exercicesFuture = _fetchExercices();
      _classesFuture = _fetchClasses();
      _courFuture = _fetchCour();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchExercices() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/exercices'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchClasses() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/classes'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (_userId != null) {
          return data
              .where((classe) => (classe['enseignantIds'] as List).contains(_userId))
              .cast<Map<String, dynamic>>()
              .toList();
        }
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load classes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchCour() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/cours/${widget.courId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load course: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String _getFileExtension(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      if (bytes.lengthInBytes >= 4) {
        if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
          return 'pdf';
        }
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';
        if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
          return 'png';
        }
      }
      return 'dat';
    } catch (e) {
      return 'dat';
    }
  }

  Future<void> _downloadAndOpenFile(String base64String, String fileName) async {
    try {
      final bytes = base64.decode(base64String);
      
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = fileName
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible d\'ouvrir le fichier: ${result.message}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement: $e')),
      );
    }
  }

  Widget _buildFilePreview(String base64String, String fileName) {
    if (base64String.isEmpty || base64String == "no content") {
      return const SizedBox.shrink();
    }

    final fileExtension = fileName.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);
    final isPdf = fileExtension == 'pdf';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Fichier joint: $fileName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (isImage)
          GestureDetector(
            onTap: () => _showFullScreenImage(base64String),
            child: Image.memory(
              base64Decode(base64String),
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        if (isPdf)
          const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
        if (!isImage && !isPdf)
          const Icon(Icons.insert_drive_file, size: 50),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _downloadAndOpenFile(base64String, fileName),
          child: const Text('Télécharger'),
        ),
      ],
    );
  }

  void _showFullScreenImage(String base64String) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(
            base64Decode(base64String),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _showAddExerciseDialog() async {
    try {
      final classes = await _classesFuture;
      final cour = await _courFuture;
      String contenu = '';
      String fichierBase64 = '';
      String fileName = '';
      String date = DateTime.now().toIso8601String().substring(0, 10);
      List<int> selectedClassIds = classes.any((c) => c['id'] == widget.classeId)
          ? [widget.classeId]
          : (classes.isNotEmpty ? [classes.first['id']] : []);

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter un exercice'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Matière: ${cour['matiere']}'),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contenu (optionnel)',
                        hintText: 'Description de l\'exercice'),
                      onChanged: (val) => contenu = val,
                    ),
                    TextFormField(
                      initialValue: date,
                      decoration: const InputDecoration(labelText: 'Date de publication'),
                      onChanged: (val) => date = val,
                    ),
                    const SizedBox(height: 10),
                    const Text('Classes assignées:'),
                    if (classes.isEmpty)
                      const Text('Aucune classe disponible'),
                    ...classes.map((classe) => CheckboxListTile(
                      title: Text('${classe['niveau']} (ID: ${classe['id']})'),
                      value: selectedClassIds.contains(classe['id']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedClassIds.add(classe['id']);
                          } else {
                            selectedClassIds.remove(classe['id']);
                          }
                        });
                      },
                    )).toList(),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(fileName.isEmpty ? 'Joindre un fichier (optionnel)' : fileName),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.single.bytes != null) {
                          fichierBase64 = base64Encode(result.files.single.bytes!);
                          fileName = result.files.single.name;
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final response = await http.post(
                        Uri.parse('http://localhost:8004/api/exercices'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          "contenu": contenu.isNotEmpty ? contenu : "no content",
                          "datePublication": date,
                          "fichier": fichierBase64.isNotEmpty ? fichierBase64 : "no content",
                          "classeIds": selectedClassIds,
                          "courId": widget.courId
                        }),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        Navigator.pop(ctx);
                        _refreshData();
                      } else {
                        throw Exception('Erreur de création: ${response.statusCode}');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Ajouter'),
                ),
              ],
            );
          }
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    }
  }

  void _showEditExerciseDialog(Map<String, dynamic> exercise) async {
    try {
      final classes = await _classesFuture;
      final cour = await _courFuture;
      String contenu = exercise['contenu'] != "no content" ? exercise['contenu'] : '';
      String? fichierBase64 = exercise['fichier'] != "no content" ? exercise['fichier'] : null;
      String fileName = fichierBase64 != null ? 'Fichier joint' : '';
      String date = exercise['datePublication'] ?? DateTime.now().toIso8601String().substring(0, 10);
      List<int> selectedClassIds = (exercise['classeIds'] as List?)?.where((id) => classes.any((c) => c['id'] == id)).map((id) => id as int).toList() ?? (classes.isNotEmpty ? [classes.first['id']] : []);
      bool fileRemoved = false;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier l\'exercice'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Matière: ${cour['matiere']}'),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: contenu,
                      decoration: const InputDecoration(
                        labelText: 'Contenu (optionnel)',
                        hintText: 'Description de l\'exercice'),
                      onChanged: (val) => contenu = val,
                    ),
                    TextFormField(
                      initialValue: date,
                      decoration: const InputDecoration(labelText: 'Date de publication'),
                      onChanged: (val) => date = val,
                    ),
                    const SizedBox(height: 10),
                    const Text('Classes assignées:'),
                    if (classes.isEmpty)
                      const Text('Aucune classe disponible'),
                    ...classes.map((classe) => CheckboxListTile(
                      title: Text('${classe['niveau']} (ID: ${classe['id']})'),
                      value: selectedClassIds.contains(classe['id']),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedClassIds.add(classe['id']);
                          } else {
                            selectedClassIds.remove(classe['id']);
                          }
                        });
                      },
                    )).toList(),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(fileName.isEmpty ? 'Joindre un fichier (optionnel)' : fileName),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.single.bytes != null) {
                          fichierBase64 = base64Encode(result.files.single.bytes!);
                          fileName = result.files.single.name;
                          fileRemoved = false;
                          setState(() {});
                        }
                      },
                    ),
                    if (fichierBase64 != null || exercise['fichier'] != "no content")
                      TextButton(
                        onPressed: () {
                          fichierBase64 = null;
                          fileName = '';
                          fileRemoved = true;
                          setState(() {});
                        },
                        child: const Text('Supprimer le fichier', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final Map<String, dynamic> updateData = {
                        'id': exercise['id'],
                        'courId': widget.courId,
                        'contenu': contenu.isNotEmpty && contenu != (exercise['contenu'] != "no content" ? exercise['contenu'] : '')
                          ? contenu
                          : (exercise['contenu'] != "no content" ? exercise['contenu'] : ''),
                        'datePublication': date != (exercise['datePublication'] ?? '')
                          ? date
                          : (exercise['datePublication'] ?? ''),
                        'classeIds': selectedClassIds,
                        'fichier': fileRemoved
                          ? "no content"
                          : (fichierBase64 ?? (exercise['fichier'] != "no content" ? exercise['fichier'] : "no content")),
                      };

                      final response = await http.put(
                        Uri.parse('http://localhost:8004/api/exercices/${exercise['id']}'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(updateData),
                      );

                      if (response.statusCode == 200) {
                        Navigator.pop(ctx);
                        _refreshData();
                      } else {
                        throw Exception('Erreur de modification: ${response.statusCode}');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Enregistrer'),
                ),
              ],
            );
          }
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    }
  }

  Future<void> _deleteExercise(int exerciseId) async {
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
        setState(() => _isLoading = true);
        await http.delete(
          Uri.parse('http://localhost:8004/api/exercices/$exerciseId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _refreshData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _courFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Exercices - ${snapshot.data!['matiere']}');
            } else if (snapshot.hasError) {
              return const Text('Exercices');
            }
            return const Text('Chargement...');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExerciseDialog,
            tooltip: 'Ajouter un exercice',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final exercices = snapshot.data ?? [];
          if (exercices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun exercice trouvé'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showAddExerciseDialog,
                    child: const Text('Ajouter un exercice'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: exercices.length,
            itemBuilder: (context, index) {
              final ex = exercices[index];
              final hasFile = ex['fichier'] != null && ex['fichier'] != "no content";
              final fileName = hasFile ? 'exercice_${ex['id']}.${_getFileExtension(ex['fichier'])}' : '';

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ex['contenu'] != "no content" 
                                  ? ex['contenu'] 
                                  : 'Exercice ${ex['id']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditExerciseDialog(ex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteExercise(ex['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Date: ${ex['datePublication'] ?? 'Non spécifiée'}'),
                      Text('Classes: ${ex['classeIds']?.join(', ') ?? 'Aucune'}'),
                      if (hasFile) 
                        _buildFilePreview(ex['fichier'], fileName),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}