import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/ExercicesPage.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ClasseDetailPage extends StatefulWidget {
  final int classeId;
  final String token;
  final int enseignantId;

  const ClasseDetailPage({
    super.key,
    required this.classeId,
    required this.token,
    required this.enseignantId,
  });

  @override
  State<ClasseDetailPage> createState() => _ClasseDetailPageState();
}

class _ClasseDetailPageState extends State<ClasseDetailPage> {
  List<Map<String, dynamic>> _cours = [];
  String _niveau = '';
  bool _loading = true;
  String _error = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClasse();
    _fetchCoursesForClasse();
  }

  Future<void> _fetchClasse() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/classes/${widget.classeId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _niveau = data['niveau'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCoursesForClasse() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final exercisesResponse = await http.get(
        Uri.parse('http://localhost:8004/api/exercices'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      final coursResponse = await http.get(
        Uri.parse('http://localhost:8004/api/cours'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (exercisesResponse.statusCode == 200 &&
          coursResponse.statusCode == 200) {
        final exercises = jsonDecode(exercisesResponse.body) as List;
        final cours = jsonDecode(coursResponse.body) as List;

        final classExercises = exercises
            .where((e) =>
                (e['classeIds'] as List).contains(widget.classeId))
            .toList();

        final relevantCourseIds =
            classExercises.map((e) => e['courId']).toSet();

        final classCourses = cours
            .where((c) => relevantCourseIds.contains(c['id']))
            .toList();

        setState(() {
          _cours = List<Map<String, dynamic>>.from(classCourses);
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

  void _showAddCourseWithExerciseDialog() {
    String matiere = '';
    String coursFichierBase64 = '';
    String coursFileName = '';
    bool showExerciseFields = false;
    
    String exerciceContenu = '';
    String exerciceFichierBase64 = '';
    String exerciceFileName = '';
    String date = DateTime.now().toIso8601String().substring(0, 10);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ajouter un nouveau cours'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Informations du cours', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Matière*',
                      hintText: 'Nom de la matière'),
                    onChanged: (val) => matiere = val,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(coursFileName.isEmpty 
                        ? 'Choisir fichier cours (optionnel)' 
                        : coursFileName),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.bytes != null) {
                        coursFichierBase64 = base64Encode(result.files.single.bytes!);
                        coursFileName = result.files.single.name;
                        setState(() {});
                      }
                    },
                  ),
                  if (coursFileName.isNotEmpty)
                    _buildFilePreview(coursFichierBase64, coursFileName),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showExerciseFields = !showExerciseFields;
                      });
                    },
                    child: Text(showExerciseFields 
                        ? 'Masquer les champs d\'exercice' 
                        : 'Associer un exercice'),
                  ),
                  
                  if (showExerciseFields) ...[
                    const Divider(),
                    const Text('Exercice associé', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contenu de l\'exercice (optionnel)',
                        hintText: 'Description de l\'exercice'),
                      onChanged: (val) => exerciceContenu = val,
                    ),
                    TextFormField(
                      initialValue: date,
                      decoration: const InputDecoration(
                        labelText: 'Date de publication'),
                      onChanged: (val) => date = val,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(exerciceFileName.isEmpty 
                          ? 'Choisir fichier exercice (optionnel)' 
                          : exerciceFileName),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null && result.files.single.bytes != null) {
                          exerciceFichierBase64 = base64Encode(result.files.single.bytes!);
                          exerciceFileName = result.files.single.name;
                          setState(() {});
                        }
                      },
                    ),
                    if (exerciceFileName.isNotEmpty)
                      _buildFilePreview(exerciceFichierBase64, exerciceFileName),
                  ],
                  
                  const SizedBox(height: 8),
                  const Text('* Champs obligatoires', 
                      style: TextStyle(fontStyle: FontStyle.italic)),
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
                  if (matiere.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('La matière est obligatoire')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final coursResponse = await http.post(
                      Uri.parse('http://localhost:8004/api/cours'),
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        "matiere": matiere,
                        "fichier": coursFichierBase64.isNotEmpty 
                            ? coursFichierBase64 
                            : "no content",
                        "exerciceIds": [],
                      }),
                    );

                    if (coursResponse.statusCode == 200 || coursResponse.statusCode == 201) {
                      final cours = jsonDecode(coursResponse.body);
                      final coursId = cours['id'];

                      if (showExerciseFields) {
                        final exerciceJson = {
                          "contenu": exerciceContenu.isNotEmpty 
                              ? exerciceContenu 
                              : "no content",
                          "datePublication": date,
                          "fichier": exerciceFichierBase64.isNotEmpty
                              ? exerciceFichierBase64
                              : "no content",
                          "classeIds": [widget.classeId],
                          "courId": coursId
                        };

                        await http.post(
                          Uri.parse('http://localhost:8004/api/exercices'),
                          headers: {
                            'Authorization': 'Bearer ${widget.token}',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(exerciceJson),
                        );
                      }

                      Navigator.pop(ctx);
                      _fetchCoursesForClasse();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de la création: $e')),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Créer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCourseDialog({Map<String, dynamic>? existingCourse}) {
    String matiere = existingCourse?['matiere'] ?? '';
    String fichierBase64 = existingCourse?['fichier'] ?? '';
    String fileName = fichierBase64.isNotEmpty && fichierBase64 != "no content" 
        ? 'cours_${existingCourse?['id']}.${_getFileExtension(fichierBase64)}' 
        : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingCourse == null ? 'Ajouter un cours' : 'Modifier le cours'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: matiere,
                    decoration: const InputDecoration(labelText: 'Matière*'),
                    onChanged: (val) => matiere = val,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(fileName.isEmpty ? 'Choisir un fichier (optionnel)' : fileName),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.bytes != null) {
                        fichierBase64 = base64Encode(result.files.single.bytes!);
                        fileName = result.files.single.name;
                        setState(() {});
                      }
                    },
                  ),
                  if (fileName.isNotEmpty)
                    _buildFilePreview(fichierBase64, fileName),
                  if (existingCourse != null && existingCourse['fichier'] != "no content")
                    TextButton(
                      onPressed: () {
                        fichierBase64 = "no content";
                        fileName = '';
                        setState(() {});
                      },
                      child: const Text('Supprimer le fichier', style: TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 8),
                  const Text('* Champs obligatoires', 
                      style: TextStyle(fontStyle: FontStyle.italic)),
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
                  if (matiere.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('La matière est obligatoire')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    if (existingCourse == null) {
                      final response = await http.post(
                        Uri.parse('http://localhost:8004/api/cours'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          "matiere": matiere,
                          "fichier": fichierBase64.isNotEmpty ? fichierBase64 : "no content",
                          "exerciceIds": [],
                        }),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        final cours = jsonDecode(response.body);
                        final coursId = cours['id'];
                        Navigator.pop(ctx);
                        _fetchCoursesForClasse();
                      }
                    } else {
                      final updated = {
                        "matiere": matiere,
                        "fichier": fichierBase64.isNotEmpty 
                            ? fichierBase64 
                            : existingCourse['fichier'],
                        "exerciceIds": existingCourse['exerciceIds'] ?? [],
                      };

                      await http.put(
                        Uri.parse('http://localhost:8004/api/cours/${existingCourse['id']}'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(updated),
                      );
                      Navigator.pop(ctx);
                      _fetchCoursesForClasse();
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
                    : Text(existingCourse == null ? 'Créer' : 'Modifier'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteCourse(int coursId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer ce cours ?'),
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
          Uri.parse('http://localhost:8004/api/cours/$coursId'),
          headers: {'Authorization': 'Bearer ${widget.token}'},
        );
        _fetchCoursesForClasse();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddExerciseDialog(int courId) {
    String contenu = '';
    String fichierBase64 = '';
    String fileName = '';
    String date = DateTime.now().toIso8601String().substring(0, 10);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ajouter un exercice'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(fileName.isEmpty ? 'Choisir un fichier (optionnel)' : fileName),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null && result.files.single.bytes != null) {
                        fichierBase64 = base64Encode(result.files.single.bytes!);
                        fileName = result.files.single.name;
                        setState(() {});
                      }
                    },
                  ),
                  if (fileName.isNotEmpty)
                    _buildFilePreview(fichierBase64, fileName),
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
                        "classeIds": [widget.classeId],
                        "courId": courId
                      }),
                    );

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.pop(ctx);
                      _fetchCoursesForClasse();
                    } else {
                      throw Exception('Erreur lors de la création: ${response.statusCode}');
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
        },
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> cours) {
    final hasFile = cours['fichier'] != null && cours['fichier'] != "no content";
    final fileName = hasFile ? 'cours_${cours['id']}.${_getFileExtension(cours['fichier'])}' : '';

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
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
                    cours['matiere'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showCourseDialog(existingCourse: cours),
                      tooltip: 'Modifier le cours',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCourse(cours['id']),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
            Text('ID: ${cours['id']}'),
            if (hasFile) 
              _buildFilePreview(cours['fichier'], fileName),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Ajouter exercice'),
                  onPressed: () => _showAddExerciseDialog(cours['id']),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text('Voir exercices'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExercicesPage(
                          courId: cours['id'],
                          token: widget.token,
                          classeId: widget.classeId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classe: $_niveau'),
        actions: [
          IconButton(
            onPressed: _showAddCourseWithExerciseDialog,
            icon: const Icon(Icons.add_box),
            tooltip: 'Ajouter cours avec exercice',
          ),
          IconButton(
            onPressed: () => _showCourseDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un cours simple',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCoursesForClasse,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _cours.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Aucun cours trouvé', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _showAddCourseWithExerciseDialog,
                            child: const Text('Ajouter un cours'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchCoursesForClasse,
                      child: ListView.builder(
                        itemCount: _cours.length,
                        itemBuilder: (context, index) => _buildCourseCard(_cours[index]),
                      ),
                    ),
    );
  }
}