import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/admin_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cours {
  final int id;
  final String fichier;
  final String matiere;
  final String? proprietaire;
  final List<int> exerciceIds;

  Cours({
    required this.id,
    required this.fichier,
    required this.matiere,
    this.proprietaire,
    required this.exerciceIds,
  });

  factory Cours.fromJson(Map<String, dynamic> json) {
    return Cours(
      id: json['id'] as int,
      fichier: json['fichier'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      proprietaire: json['proprietaire'] as String?,
      exerciceIds: (json['exerciceIds'] as List).map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fichier': fichier,
      'matiere': matiere,
      'proprietaire': proprietaire,
      'exerciceIds': exerciceIds,
    };
  }
}

class CoursPage extends StatefulWidget {
  const CoursPage({Key? key}) : super(key: key);

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage> {
  static const String _coursApiUrl = 'http://localhost:8004/api/cours';
  static const String _enseignantsApiUrl = 'http://localhost:8004/api/enseignants';
  static const int _maxFileSize = 25 * 1024 * 1024;
  static const String _fileSeparator = '||SEP||XyZ1234||SEP||';

  final List<Cours> _cours = [];
  List<Cours> _filteredCours = [];
  List<Map<String, dynamic>> _enseignants = [];
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _connectedUserName = '';

  @override
  void initState() {
    super.initState();
    _loadConnectedUserName();
    _fetchCours();
    _fetchEnseignants();
    _fetchClasses();
    _searchController.addListener(_filterCours);
  }

  Future<void> _loadConnectedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _connectedUserName = prefs.getString('userName') ?? '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCours() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCours = _cours.where((cours) {
        return cours.matiere.toLowerCase().contains(query) ||
            cours.id.toString().contains(query) ||
            (cours.proprietaire?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _fetchCours() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse(_coursApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cours
            ..clear()
            ..addAll(data.map((e) => Cours.fromJson(e)));
          _filteredCours = List.from(_cours);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showErrorSnackbar(context.tr('courses.error_loading'));
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackbar('${context.tr('common.error')}: $e');
    }
  }

  Future<void> _fetchEnseignants() async {
    try {
      final response = await http.get(Uri.parse(_enseignantsApiUrl));
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

  Future<void> _fetchClasses() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8004/api/classes'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _classes = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des classes: $e');
    }
  }

  List<int> _getClassesForEnseignant(int enseignantId) {
    final enseignant = _enseignants.firstWhere(
      (e) => e['id'] == enseignantId,
      orElse: () => {},
    );
    
    if (enseignant.isNotEmpty && enseignant['classeIds'] != null) {
      return List<int>.from(enseignant['classeIds']);
    }
    return [];
  }

  Future<void> _createCoursWithExercise({
    required Map<String, dynamic> coursData,
    required List<int> classeIds,
    String? contenu,
    String? fichier,
    String? datePublication,
  }) async {
    try {
      // Créer le cours d'abord
      final coursResponse = await http.post(
        Uri.parse(_coursApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(coursData),
      );
      
      if (coursResponse.statusCode == 201 || coursResponse.statusCode == 200) {
        final cours = jsonDecode(coursResponse.body);
        final coursId = cours['id'];

        // Créer l'exercice avec les données fournies
        final exerciceJson = {
          "contenu": contenu ?? "pas de contenu",
          "datePublication": datePublication ?? DateTime.now().toIso8601String().substring(0, 10),
          "fichier": fichier ?? "no content",
          "classeIds": classeIds,
          "courId": coursId
        };

        final exerciceResponse = await http.post(
          Uri.parse('http://localhost:8004/api/exercices'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(exerciceJson),
        );

        if (exerciceResponse.statusCode == 200 || exerciceResponse.statusCode == 201) {
          // Mettre à jour le cours avec l'ID de l'exercice créé
          final exerciceId = jsonDecode(exerciceResponse.body)['id'];
          await http.put(
            Uri.parse('$_coursApiUrl/$coursId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "matiere": coursData['matiere'],
              "fichier": coursData['fichier'],
              "proprietaire": coursData['proprietaire'],
              "exerciceIds": [exerciceId],
            }),
          );
        }

        _fetchCours();
        _showSuccessSnackbar(context.tr('courses.success_add'));
      } else {
        throw Exception(context.tr('messages.operation_failed'));
      }
    } catch (e) {
      _showErrorSnackbar('${context.tr('common.error')}: $e');
    }
  }

  Future<void> _updateCours(int id, Map<String, dynamic> body) async {
    try {
      // Pour la mise à jour, on ne modifie que les champs du cours
      // sans toucher aux exercices existants
      final coursToUpdate = await http.get(Uri.parse('$_coursApiUrl/$id'));
      if (coursToUpdate.statusCode == 200) {
        final currentCours = jsonDecode(coursToUpdate.body);
        
        // Préparer le payload de mise à jour avec les exercices existants
        final updatePayload = {
          "matiere": body['matiere'],
          "fichier": body['fichier'],
          "proprietaire": body['proprietaire'],
          "exerciceIds": currentCours['exerciceIds'] ?? [], // Garder les exercices existants
        };

        final response = await http.put(
          Uri.parse('$_coursApiUrl/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updatePayload),
        );
        
        if (response.statusCode == 200) {
          _fetchCours();
          _showSuccessSnackbar(context.tr('courses.success_edit'));
        } else {
          throw Exception(context.tr('messages.operation_failed'));
        }
      } else {
        throw Exception(context.tr('messages.operation_failed'));
      }
    } catch (e) {
      _showErrorSnackbar('${context.tr('common.error')}: $e');
    }
  }

  Future<void> _deleteCours(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_coursApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchCours();
        _showSuccessSnackbar(context.tr('courses.success_delete'));
      } else {
        throw Exception(context.tr('messages.operation_failed'));
      }
    } catch (e) {
      _showErrorSnackbar('${context.tr('common.error')}: $e');
    }
  }

  String _getFileTypeFromBytes(Uint8List bytes) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
        return 'pdf';
      }
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'png';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'jpg';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      }
    }
    return 'unknown';
  }

  Future<void> _downloadAndOpenFile(String base64String, String fileName) async {
    try {
      final bytes = base64Decode(base64String);
      final fileType = _getFileTypeFromBytes(bytes);
      final extension = _getExtensionFromFileType(fileType);
      final downloadFileName = fileName.isNotEmpty 
          ? fileName 
          : 'cours_${DateTime.now().millisecondsSinceEpoch}.$extension';

      if (kIsWeb) {
        final mimeType = _getMimeType(fileType);
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..download = downloadFileName
          ..click();
        
        html.Url.revokeObjectUrl(url);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$downloadFileName');
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      _showErrorSnackbar(context.tr('courses.download_error'));
    }
  }

  String _getExtensionFromFileType(String fileType) {
    return fileType == 'pdf' ? 'pdf' 
         : fileType == 'png' ? 'png' 
         : fileType == 'jpg' ? 'jpg' 
         : fileType == 'gif' ? 'gif' 
         : 'dat';
  }

  String _getMimeType(String fileType) {
    return fileType == 'pdf' ? 'application/pdf'
         : fileType == 'png' ? 'image/png'
         : fileType == 'jpg' ? 'image/jpeg'
         : fileType == 'gif' ? 'image/gif'
         : 'application/octet-stream';
  }

  Future<List<Map<String, dynamic>>?> _pickMultipleFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return null;

      return result.files
          .where((file) => file.bytes != null && file.size <= _maxFileSize)
          .map((file) => {
                'fileName': file.name,
                'base64': base64Encode(file.bytes!),
              })
          .toList();
    } catch (e) {
      _showErrorSnackbar('${context.tr('common.error')}: $e');
      return null;
    }
  }

  Widget _buildFilePreview(String base64, {String fileName = ''}) {
    try {
      final bytes = base64Decode(base64);
      final fileType = _getFileTypeFromBytes(bytes);
      final fileSize = '${(bytes.length / 1024).toStringAsFixed(1)} KB';
      final primaryColor = Colors.blue.shade900;

      return Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 236, 232, 232).withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _downloadAndOpenFile(base64, fileName),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _buildFileTypeIcon(fileType, bytes),
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  fileName.isNotEmpty ? fileName : context.tr('common.file'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fileSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      Icons.download_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Text(
              context.tr('courses.invalid_file'),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFileTypeIcon(String fileType, Uint8List bytes) {
    switch (fileType) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
      case 'png':
      case 'jpg':
      case 'gif':
        return Image.memory(
          bytes,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
        );
      default:
        return const Icon(Icons.insert_drive_file, size: 40);
    }
  }

  Widget _buildFileItemWithDelete(Map<String, dynamic> file, VoidCallback onDelete) {
    return Stack(
      children: [
        _buildFilePreview(file['base64'], fileName: file['fileName']),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddOrEditDialog({Cours? cours}) async {
    final primaryColor = Colors.blue.shade900;
    final matiereCtl = TextEditingController(text: cours?.matiere ?? '');
    List<Map<String, dynamic>> selectedFiles = [];
    String? selectedEnseignantId;
    
    // Variables pour l'exercice (seulement pour l'ajout, pas pour l'édition)
    bool showExerciseFields = false;
    final exerciceContenuCtl = TextEditingController();
    String exerciceFichierBase64 = '';
    String exerciceFileName = '';
    final exerciceDateCtl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    List<int> selectedClasseIds = [];
    
    // Déterminer si c'est un ajout ou une édition
    final isEditing = cours != null;

    if (cours != null && cours.fichier.isNotEmpty) {
      selectedFiles = cours.fichier
          .split(_fileSeparator)
          .map((b64) => {'fileName': context.tr('courses.file'), 'base64': b64})
          .toList();
    }

    // Trouver l'ID de l'enseignant sélectionné
    if (cours?.proprietaire != null) {
      final enseignant = _enseignants.firstWhere(
        (e) => e['nom'] == cours!.proprietaire,
        orElse: () => {},
      );
      if (enseignant.isNotEmpty) {
        selectedEnseignantId = enseignant['id'].toString();
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cours == null ? context.tr('courses.add_course') : context.tr('courses.edit_course'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: matiereCtl,
                    decoration: InputDecoration(
                      labelText: context.tr('courses.course_subject'),
                      labelStyle: TextStyle(color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Dropdown pour sélectionner l'enseignant
                  DropdownButtonFormField<String>(
                    value: selectedEnseignantId,
                    decoration: InputDecoration(
                      labelText: context.tr('courses.course_owner'),
                      labelStyle: TextStyle(color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(context.tr('courses.select_teacher')),
                      ),
                      ..._enseignants.map((enseignant) => DropdownMenuItem<String>(
                        value: enseignant['id'].toString(),
                        child: Text(enseignant['nom'] ?? ''),
                      )).toList(),
                    ],
                    onChanged: (value) {
                      selectedEnseignantId = value;
                      // Charger les classes de l'enseignant sélectionné (seulement pour l'ajout)
                      if (!isEditing && value != null) {
                        selectedClasseIds = List.from(_getClassesForEnseignant(int.parse(value)));
                      } else {
                        selectedClasseIds = [];
                      }
                      dialogSetState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Affichage des classes de l'enseignant sélectionné (seulement pour l'ajout)
                  if (!isEditing) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: selectedEnseignantId != null ? primaryColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: selectedEnseignantId != null ? primaryColor.withOpacity(0.05) : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.class_,
                                color: selectedEnseignantId != null ? primaryColor : Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('courses.teacher_classes'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedEnseignantId != null ? primaryColor : Colors.grey.shade600,
                                ),
                              ),
                              if (selectedEnseignantId == null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '*',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedEnseignantId == null)
                            Text(
                              context.tr('courses.select_teacher_first'),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else if (selectedClasseIds.isEmpty)
                            Text(
                              context.tr('courses.no_classes_for_teacher'),
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('courses.select_classes_for_exercise'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    dialogSetState(() {
                                      if (selectedClasseIds.length == _getClassesForEnseignant(int.parse(selectedEnseignantId!)).length) {
                                        // Désélectionner toutes
                                        selectedClasseIds.clear();
                                      } else {
                                        // Sélectionner toutes
                                        selectedClasseIds = List.from(_getClassesForEnseignant(int.parse(selectedEnseignantId!)));
                                      }
                                    });
                                  },
                                  child: Text(
                                    selectedClasseIds.length == _getClassesForEnseignant(int.parse(selectedEnseignantId!)).length
                                        ? context.tr('courses.deselect_all')
                                        : context.tr('courses.select_all'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: selectedClasseIds.map((classeId) {
                                final classe = _classes.firstWhere(
                                  (c) => c['id'] == classeId,
                                  orElse: () => {'niveau': 'Classe inconnue'},
                                );
                                return CheckboxListTile(
                                  title: Text(
                                    classe['niveau'] ?? 'Classe inconnue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  value: selectedClasseIds.contains(classeId),
                                  onChanged: (bool? value) {
                                    dialogSetState(() {
                                      if (value == true) {
                                        if (!selectedClasseIds.contains(classeId)) {
                                          selectedClasseIds.add(classeId);
                                        }
                                      } else {
                                        selectedClasseIds.remove(classeId);
                                      }
                                    });
                                  },
                                  activeColor: primaryColor,
                                  checkColor: Colors.white,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  // Section fichiers de cours
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('courses.add_files'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (selectedFiles.isNotEmpty) ...[
                          Text(
                            context.tr('courses.associated_files'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: selectedFiles.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildFileItemWithDelete(
                                    entry.value,
                                    () => dialogSetState(() => selectedFiles.removeAt(entry.key)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.attach_file, size: 20),
                            label: Text(context.tr('courses.add_files')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final files = await _pickMultipleFiles();
                              if (files != null) {
                                dialogSetState(() => selectedFiles.addAll(files));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Section exercice (seulement pour l'ajout, pas pour l'édition)
                  if (!isEditing) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          // Bouton pour afficher/masquer les champs d'exercice
                          ElevatedButton.icon(
                            onPressed: () {
                              dialogSetState(() {
                                showExerciseFields = !showExerciseFields;
                              });
                            },
                            icon: Icon(
                              showExerciseFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: primaryColor,
                            ),
                            label: Text(
                              showExerciseFields
                                  ? context.tr('courses.hide_exercise_fields')
                                  : context.tr('courses.associate_exercise'),
                              style: TextStyle(color: primaryColor),
                            ),
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                          
                          if (showExerciseFields) ...[
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryColor.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assignment,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.tr('courses.associated_exercise'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Contenu de l'exercice
                                  TextFormField(
                                    controller: exerciceContenuCtl,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: context.tr('courses.exercise_content'),
                                      hintText: context.tr('courses.exercise_description'),
                                      labelStyle: TextStyle(color: primaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: primaryColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Date de publication
                                  TextFormField(
                                    controller: exerciceDateCtl,
                                    decoration: InputDecoration(
                                      labelText: context.tr('courses.publication_date'),
                                      labelStyle: TextStyle(color: primaryColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: primaryColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: primaryColor, width: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Fichier de l'exercice
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.attach_file, color: primaryColor),
                                    label: Text(
                                      exerciceFileName.isEmpty
                                          ? context.tr('courses.choose_exercise_file')
                                          : exerciceFileName,
                                      style: TextStyle(color: primaryColor),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      side: BorderSide(color: primaryColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onPressed: () async {
                                      final result = await FilePicker.platform.pickFiles();
                                      if (result != null && result.files.single.bytes != null) {
                                        exerciceFichierBase64 = base64Encode(result.files.single.bytes!);
                                        exerciceFileName = result.files.single.name;
                                        dialogSetState(() {});
                                      }
                                    },
                                  ),
                                  
                                  if (exerciceFileName.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildFilePreview(exerciceFichierBase64, fileName: exerciceFileName),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(
                          context.tr('common.cancel'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (matiereCtl.text.trim().isEmpty) {
                            _showErrorSnackbar(context.tr('forms.required_field'));
                            return;
                          }

                          if (selectedEnseignantId == null) {
                            _showErrorSnackbar(context.tr('courses.teacher_required'));
                            return;
                          }

                          // Trouver le nom de l'enseignant sélectionné
                          String? proprietaire;
                          final enseignant = _enseignants.firstWhere(
                            (e) => e['id'].toString() == selectedEnseignantId,
                            orElse: () => {},
                          );
                          if (enseignant.isNotEmpty) {
                            proprietaire = enseignant['nom'];
                          }

                          final coursPayload = {
                            'matiere': matiereCtl.text.trim(),
                            'fichier': selectedFiles.map((f) => f['base64']).join(_fileSeparator),
                            'proprietaire': proprietaire,
                            'exerciceIds': cours?.exerciceIds ?? [],
                          };

                          try {
                            if (cours == null) {
                              // Vérifications pour l'ajout d'un nouveau cours
                              if (selectedClasseIds.isEmpty) {
                                _showErrorSnackbar(context.tr('courses.at_least_one_class_required'));
                                return;
                              }
                              
                              // Créer le cours avec l'exercice
                              await _createCoursWithExercise(
                                coursData: coursPayload,
                                classeIds: selectedClasseIds,
                                contenu: exerciceContenuCtl.text.trim().isNotEmpty 
                                    ? exerciceContenuCtl.text.trim() 
                                    : null,
                                fichier: exerciceFichierBase64.isNotEmpty 
                                    ? exerciceFichierBase64 
                                    : null,
                                datePublication: exerciceDateCtl.text.trim().isNotEmpty 
                                    ? exerciceDateCtl.text.trim() 
                                    : null,
                              );
                            } else {
                              // Mise à jour du cours (pas de vérification des classes)
                              await _updateCours(cours.id, coursPayload);
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            _showErrorSnackbar('${context.tr('common.error')}: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(context.tr('common.save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('common.confirm_delete'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Text(context.tr('courses.delete_confirmation')),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      context.tr('common.cancel'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteCours(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: Text(context.tr('common.delete')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade900;
    final backgroundColor = Colors.grey.shade50;
    final localizationService = LocalizationService();
    final isRTL = localizationService.isRTL;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            context.tr('courses.page_title'),
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          elevation: 4,
          leading: isRTL ? null : Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            if (isRTL) Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const LanguageSelector(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchCours,
              tooltip: context.tr('common.refresh'),
            ),
          ],
        ),
        drawer: const AdminDrawer(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: () => _showAddOrEditDialog(),
          child: const Icon(Icons.add),
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: context.tr('common.search'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filteredCours.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.collections_bookmark,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('courses.no_courses_found'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _fetchCours,
                                  child: Text(context.tr('common.refresh')),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              Text(
                                context.tr('courses.page_title'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._filteredCours.map((cours) {
                                final fileParts = cours.fichier.split(_fileSeparator);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '#${cours.id}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cours.matiere,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (cours.proprietaire != null) ...[
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${context.tr('courses.owner')}: ${cours.proprietaire}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                  ],
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.assignment,
                                                        size: 14,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        context.tr('courses.exercises_count').replaceAll('{count}', cours.exerciceIds.length.toString()),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Icon(
                                                        Icons.attach_file,
                                                        size: 14,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        context.tr('courses.files_count').replaceAll('{count}', fileParts.length.toString()),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.blue.shade700,
                                              ),
                                              onPressed: () => _showAddOrEditDialog(cours: cours),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red.shade400,
                                              ),
                                              onPressed: () => _confirmDelete(cours.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (fileParts.isNotEmpty) ...[
                                        const Divider(height: 1),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.tr('courses.associated_files'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade600,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: fileParts
                                                      .map((base64) => _buildFilePreview(base64))
                                                      .toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}