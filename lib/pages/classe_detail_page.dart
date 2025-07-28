import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/ExercicesPage.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
// Import conditionnel
import 'web_file_helper_stub.dart'
    if (dart.library.html) 'web_file_helper.dart';
import '../services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Map<String, dynamic>> _enseignants = [];
  String _niveau = '';
  bool _loading = true;
  String _error = '';
  bool _isLoading = false;
  String _connectedUserName = '';
  static const String _fileSeparator = '||SEP||XyZ1234||SEP||';

  // Define colors as constant hexadecimal values
  static const Color _primaryColor = Color(0xFF0D47A1); // Equivalent to Colors.blue.shade900
  static const Color _blueShade700 = Color(0xFF1976D2); // Equivalent to Colors.blue.shade700
  static const Color _redShade400 = Color(0xFFEF5350); // Equivalent to Colors.red.shade400

  @override
  void initState() {
    super.initState();
    _loadConnectedUserName();
    _fetchClasse();
    _fetchCoursesForClasse();
    _fetchEnseignants();
  }

  Future<void> _loadConnectedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _connectedUserName = prefs.getString('userName') ?? '';
    });
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

  Future<void> _fetchEnseignants() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/enseignants'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _enseignants = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des enseignants: $e');
    }
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

        final allClassCourses = cours
            .where((c) => relevantCourseIds.contains(c['id']))
            .toList();

        // Filtrer les cours pour ne garder que ceux dont le propriétaire correspond à l'utilisateur connecté
        final filteredCourses = allClassCourses
            .where((c) => c['proprietaire'] == _connectedUserName)
            .toList();

        setState(() {
          _cours = List<Map<String, dynamic>>.from(filteredCourses);
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
        downloadFileWeb(bytes, fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LocalizationService().translate('classes.class_detail.open_file_error')}: ${result.message}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationService().translate('classes.class_detail.download_error')}: $e')),
      );
    }
  }

  Widget _buildSingleFilePreview(String base64String, String fileName) {
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
          '${LocalizationService().translate('classes.class_detail.attached_file')}: $fileName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (isImage)
          GestureDetector(
            onTap: () => _showFullScreenImage(base64String),
            child: Image.memory(
              base64Decode(base64String),
              height: 100,
              width: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
        if (isPdf)
          const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red),
        if (!isImage && !isPdf)
          const Icon(Icons.insert_drive_file, size: 100),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _downloadAndOpenFile(base64String, fileName),
          child: Text(LocalizationService().translate('classes.class_detail.download')),
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

  Widget _buildFileItemWithDelete(Map<String, dynamic> file, VoidCallback onDelete) {
    return Stack(
      children: [
        _buildSingleFilePreview(file['base64'], file['fileName']),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.delete, color: _redShade400),
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }

  void _showAddCourseWithExerciseDialog() {
    String matiere = '';
    List<Map<String, dynamic>> selectedFiles = [];
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
            title: Text(LocalizationService().translate('classes.class_detail.add_course_title'), style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocalizationService().translate('classes.class_detail.course_info'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: LocalizationService().translate('classes.class_detail.subject'),
                      hintText: LocalizationService().translate('classes.class_detail.subject_hint'),
                      labelStyle: TextStyle(color: _primaryColor),
                    ),
                    onChanged: (val) => matiere = val,
                  ),
                  const SizedBox(height: 8),
                  

                  
                  if (selectedFiles.isNotEmpty) ...[
                    Text('${LocalizationService().translate('classes.class_detail.attached_files')}:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedFiles.asMap().entries.map((entry) {
                        return SizedBox(
                          width: 150,
                          child: _buildFileItemWithDelete(
                            entry.value,
                            () => setState(() => selectedFiles.removeAt(entry.key)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  ElevatedButton.icon(
                    icon: Icon(Icons.attach_file, color: _primaryColor),
                    label: Text(LocalizationService().translate('classes.class_detail.add_files'), style: TextStyle(color: _primaryColor)),
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result != null && result.files.isNotEmpty) {
                        final newFiles = result.files
                            .where((file) => file.bytes != null)
                            .map((file) => {
                              'fileName': file.name,
                              'base64': base64Encode(file.bytes!),
                            })
                            .toList();
                        setState(() => selectedFiles.addAll(newFiles));
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showExerciseFields = !showExerciseFields;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(showExerciseFields
                        ? LocalizationService().translate('classes.class_detail.hide_exercise_fields')
                        : LocalizationService().translate('classes.class_detail.associate_exercise'), style: TextStyle(color: _primaryColor)),
                  ),
                  
                  if (showExerciseFields) ...[
                    const Divider(),
                    Text(LocalizationService().translate('classes.class_detail.associated_exercise'),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: LocalizationService().translate('classes.class_detail.exercise_content'),
                        hintText: LocalizationService().translate('classes.class_detail.exercise_description'),
                        labelStyle: TextStyle(color: _primaryColor),
                      ),
                      onChanged: (val) => exerciceContenu = val,
                    ),
                    TextFormField(
                      initialValue: date,
                      decoration: InputDecoration(
                        labelText: LocalizationService().translate('classes.class_detail.publication_date'),
                        labelStyle: TextStyle(color: _primaryColor),
                      ),
                      onChanged: (val) => date = val,
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.attach_file, color: _primaryColor),
                      label: Text(exerciceFileName.isEmpty
                          ? LocalizationService().translate('classes.class_detail.choose_exercise_file')
                          : exerciceFileName, style: TextStyle(color: _primaryColor)),
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(color: _primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                      _buildSingleFilePreview(exerciceFichierBase64, exerciceFileName),
                  ],
                  
                  const SizedBox(height: 8),
                  Text('* ${LocalizationService().translate('classes.class_detail.required_fields')}',
                      style: TextStyle(fontStyle: FontStyle.italic, color: _primaryColor)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocalizationService().translate('common.cancel'), style: TextStyle(color: _primaryColor)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (matiere.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(LocalizationService().translate('classes.class_detail.subject_required'))),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    // Combine multiple files into single string
                    final filesString = selectedFiles
                      .map((f) => f['base64'])
                      .join(_fileSeparator);

                    final coursResponse = await http.post(
                      Uri.parse('http://localhost:8004/api/cours'),
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        "matiere": matiere,
                        "fichier": filesString.isNotEmpty 
                            ? filesString 
                            : "no content",
                        "proprietaire": _connectedUserName, // Utilisation de la variable ici
                        "exerciceIds": [],
                      }),
                    );

                    if (coursResponse.statusCode == 200 || coursResponse.statusCode == 201) {
                      final cours = jsonDecode(coursResponse.body);
                      final coursId = cours['id'];

                      // Créer un exercice par défaut dans tous les cas
                      final exerciceJson = {
                        "contenu": exerciceContenu.isNotEmpty 
                            ? exerciceContenu 
                            : "pas de contenu",
                        "datePublication": date,
                        "fichier": exerciceFichierBase64.isNotEmpty
                            ? exerciceFichierBase64
                            : "no content",
                        "classeIds": [widget.classeId],
                        "courId": coursId
                      };

                      final exerciceResponse = await http.post(
                        Uri.parse('http://localhost:8004/api/exercices'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(exerciceJson),
                      );

                      if (exerciceResponse.statusCode == 200 || exerciceResponse.statusCode == 201) {
                        // Mettre à jour le cours avec l'ID de l'exercice créé
                        final exerciceId = jsonDecode(exerciceResponse.body)['id'];
                        await http.put(
                          Uri.parse('http://localhost:8004/api/cours/$coursId'),
                          headers: {
                            'Authorization': 'Bearer ${widget.token}',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            "matiere": matiere,
                            "fichier": filesString.isNotEmpty ? filesString : "no content",
                            "proprietaire": _connectedUserName, // Et ici aussi
                            "exerciceIds": [exerciceId],
                          }),
                        );
                      }

                      Navigator.pop(ctx);
                      _fetchCoursesForClasse();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${LocalizationService().translate('classes.class_detail.creation_error')}: $e')),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(LocalizationService().translate('classes.class_detail.create'), style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCourseDialog({Map<String, dynamic>? existingCourse}) {
    String matiere = existingCourse?['matiere'] ?? '';
    List<Map<String, dynamic>> selectedFiles = [];
    
    // Parse existing files if any
    if (existingCourse != null && 
        existingCourse['fichier'] != null &&
        existingCourse['fichier'] != "no content") {
      final fileParts = existingCourse['fichier'].split(_fileSeparator);
      for (var i = 0; i < fileParts.length; i++) {
        selectedFiles.add({
          'base64': fileParts[i],
          'fileName': 'cours_${existingCourse['id']}_$i.${_getFileExtension(fileParts[i])}'
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existingCourse == null ? LocalizationService().translate('classes.class_detail.add_course_title') : LocalizationService().translate('classes.class_detail.modify_course_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: matiere,
                    decoration: InputDecoration(labelText: LocalizationService().translate('classes.class_detail.subject')),
                    onChanged: (val) => matiere = val,
                  ),
                  const SizedBox(height: 8),
                  

                  
                  if (selectedFiles.isNotEmpty) ...[
                    Text(LocalizationService().translate('classes.class_detail.attached_files')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedFiles.asMap().entries.map((entry) {
                        return SizedBox(
                          width: 150,
                          child: _buildFileItemWithDelete(
                            entry.value,
                            () => setState(() => selectedFiles.removeAt(entry.key)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(LocalizationService().translate('classes.class_detail.add_files')),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result != null && result.files.isNotEmpty) {
                        final newFiles = result.files
                            .where((file) => file.bytes != null)
                            .map((file) => {
                              'fileName': file.name,
                              'base64': base64Encode(file.bytes!),
                            })
                            .toList();
                        setState(() => selectedFiles.addAll(newFiles));
                      }
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  Text('* ' + LocalizationService().translate('classes.class_detail.required_fields'),
                      style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocalizationService().translate('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (matiere.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(LocalizationService().translate('classes.class_detail.subject_required'))),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    // Combine multiple files into single string
                    final filesString = selectedFiles
                      .map((f) => f['base64'])
                      .join(_fileSeparator);

                    if (existingCourse == null) {
                      final response = await http.post(
                        Uri.parse('http://localhost:8004/api/cours'),
                        headers: {
                          'Authorization': 'Bearer ${widget.token}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          "matiere": matiere,
                          "fichier": filesString.isNotEmpty ? filesString : "no content",
                          "proprietaire": _connectedUserName, // Utilisation ici
                          "exerciceIds": [],
                        }),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        final cours = jsonDecode(response.body);
                        final coursId = cours['id'];

                        // Créer un exercice par défaut
                        final exerciceJson = {
                          "contenu": "pas de contenu",
                          "datePublication": DateTime.now().toIso8601String().substring(0, 10),
                          "fichier": "no content",
                          "classeIds": [widget.classeId],
                          "courId": coursId
                        };

                        final exerciceResponse = await http.post(
                          Uri.parse('http://localhost:8004/api/exercices'),
                          headers: {
                            'Authorization': 'Bearer ${widget.token}',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(exerciceJson),
                        );

                        if (exerciceResponse.statusCode == 200 || exerciceResponse.statusCode == 201) {
                          final exerciceId = jsonDecode(exerciceResponse.body)['id'];
                          await http.put(
                            Uri.parse('http://localhost:8004/api/cours/$coursId'),
                            headers: {
                              'Authorization': 'Bearer ${widget.token}',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              "matiere": matiere,
                              "fichier": filesString.isNotEmpty ? filesString : "no content",
                              "proprietaire": _connectedUserName, // Et ici
                              "exerciceIds": [exerciceId],
                            }),
                          );
                        }

                        Navigator.pop(ctx);
                        _fetchCoursesForClasse();
                      }
                    } else {
                      final updated = {
                        "matiere": matiere,
                        "fichier": filesString.isNotEmpty 
                            ? filesString 
                            : "no content",
                        "proprietaire": _connectedUserName, // Et ici
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
                      SnackBar(content: Text(LocalizationService().translate('common.error') + ': $e')),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(existingCourse == null ? LocalizationService().translate('classes.class_detail.create') : LocalizationService().translate('classes.class_detail.modify')),
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
        title: Text(LocalizationService().translate('classes.class_detail.confirmation'), style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Text(LocalizationService().translate('classes.class_detail.delete_course_confirmation'), style: TextStyle(color: _primaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService().translate('common.cancel'), style: TextStyle(color: _primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: Text(LocalizationService().translate('classes.class_detail.delete'), style: TextStyle(color: Colors.white)),
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
          SnackBar(content: Text(LocalizationService().translate('common.error') + ': $e')),
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
            title: Text(LocalizationService().translate('classes.class_detail.add_exercise_title'), style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: LocalizationService().translate('classes.class_detail.content_optional'),
                      hintText: LocalizationService().translate('classes.class_detail.exercise_description'),
                      labelStyle: TextStyle(color: _primaryColor),
                    ),
                    onChanged: (val) => contenu = val,
                  ),
                  TextFormField(
                    initialValue: date,
                    decoration: InputDecoration(
                      labelText: LocalizationService().translate('classes.class_detail.publication_date'),
                      labelStyle: TextStyle(color: _primaryColor),
                    ),
                    onChanged: (val) => date = val,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.attach_file, color: _primaryColor),
                    label: Text(fileName.isEmpty ? LocalizationService().translate('classes.class_detail.choose_file_optional') : fileName, style: TextStyle(color: _primaryColor)),
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
                    _buildSingleFilePreview(fichierBase64, fileName),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LocalizationService().translate('common.cancel'), style: TextStyle(color: _primaryColor)),
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
                        "contenu": contenu.isNotEmpty ? contenu : "pas de contenu",
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
                      SnackBar(content: Text(LocalizationService().translate('common.error') + ': $e')),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(LocalizationService().translate('classes.class_detail.add_exercise'), style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> cours) {
    // Check if there are files
    final hasFiles = cours['fichier'] != null && 
                    cours['fichier'] != "no content" &&
                    cours['fichier'].isNotEmpty;

    List<Widget> filePreviews = [];
    
    if (hasFiles) {
      final fileParts = cours['fichier'].split(_fileSeparator);
      for (var i = 0; i < fileParts.length; i++) {
        final base64 = fileParts[i];
        final fileName = 'cours_${cours['id']}_$i.${_getFileExtension(base64)}';
        filePreviews.add(_buildSingleFilePreview(base64, fileName));
      }
    }

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cours['matiere'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: _primaryColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: _blueShade700),
                      onPressed: () => _showCourseDialog(existingCourse: cours),
                      tooltip: LocalizationService().translate('classes.class_detail.edit_course'),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: _redShade400),
                      onPressed: () => _deleteCourse(cours['id']),
                      tooltip: LocalizationService().translate('classes.class_detail.delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${cours['id']}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (hasFiles) ...[
              const SizedBox(height: 12),
              Text(
                'Fichiers:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              filePreviews.length == 1
                  ? Center(child: filePreviews.first)
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filePreviews.map((preview) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: preview,
                        )).toList(),
                      ),
                    ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4), // Move "Ajouter exercice" slightly left
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: Text(LocalizationService().translate('classes.class_detail.add_exercise'), style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showAddExerciseDialog(cours['id']),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 130, // Increased width to accommodate icon
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.assignment, color: _primaryColor, size: 24),
                    label: const SizedBox.shrink(), // Remove text label
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${LocalizationService().translate('classes.class_detail.page_title')}: $_niveau',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (_connectedUserName.isNotEmpty)
              Text(
                'Cours de $_connectedUserName',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: _primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            onPressed: _showAddCourseWithExerciseDialog,
            icon: const Icon(Icons.add_box, color: Colors.white),
            tooltip: LocalizationService().translate('classes.class_detail.add_course_with_exercise'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCoursesForClasse,
            tooltip: LocalizationService().translate('classes.class_detail.refresh'),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
            : _error.isNotEmpty
                ? Center(
                    child: Text(
                      _error,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                    ),
                  )
                : _cours.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _connectedUserName.isNotEmpty 
                                  ? 'Aucun cours trouvé pour $_connectedUserName dans cette classe'
                                  : LocalizationService().translate('classes.class_detail.no_courses'),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: _showAddCourseWithExerciseDialog,
                              child: const Text('Ajouter un cours', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCoursesForClasse,
                        color: _primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _cours.length,
                          itemBuilder: (context, index) => _buildCourseCard(_cours[index]),
                        ),
                      ),
      ),
      ),
    );
  }
}