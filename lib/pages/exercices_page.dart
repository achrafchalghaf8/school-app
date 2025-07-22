import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import 'admin_drawer.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class Classe {
  final int id;
  final String niveau;
  final List<int> enseignantIds;

  Classe({
    required this.id,
    required this.niveau,
    required this.enseignantIds,
  });

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      id: json['id'] as int,
      niveau: json['niveau'] as String,
      enseignantIds: (json['enseignantIds'] as List).map((e) => e as int).toList(),
    );
  }
}

class Cours {
  final int id;
  final String matiere;

  Cours({
    required this.id,
    required this.matiere,
  });

  factory Cours.fromJson(Map<String, dynamic> json) {
    return Cours(
      id: json['id'] as int,
      matiere: json['matiere'] as String,
    );
  }
}

class Exercice {
  final int id;
  final String contenu;
  final String datePublication;
  final String fichier;
  final List<int> classeIds;
  final int courId;

  Exercice({
    required this.id,
    required this.contenu,
    required this.datePublication,
    required this.fichier,
    required this.classeIds,
    required this.courId,
  });

  factory Exercice.fromJson(Map<String, dynamic> json) {
    return Exercice(
      id: json['id'] as int,
      contenu: json['contenu'] as String? ?? '',
      datePublication: json['datePublication'] as String? ?? '',
      fichier: json['fichier'] as String? ?? '',
      classeIds: (json['classeIds'] as List).map((e) => e as int).toList(),
      courId: json['courId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contenu': contenu,
      'datePublication': datePublication,
      'fichier': fichier,
      'classeIds': classeIds,
      'courId': courId,
    };
  }
}

class ExercicesPage extends StatefulWidget {
  const ExercicesPage({Key? key}) : super(key: key);

  @override
  State<ExercicesPage> createState() => _ExercicesPageState();
}

class _ExercicesPageState extends State<ExercicesPage> {
  static const String _exercicesApiUrl = 'http://localhost:8004/api/exercices';
  static const String _classesApiUrl = 'http://localhost:8004/api/classes';
  static const String _coursApiUrl = 'http://localhost:8004/api/cours';
  static const int _maxFileSize = 25 * 1024 * 1024;

  final List<Exercice> _exercices = [];
  final List<Classe> _classes = [];
  final List<Cours> _cours = [];
  bool _loading = true;
  bool _loadingClasses = true;
  bool _loadingCours = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    await Future.wait([_fetchExercices(), _fetchClasses(), _fetchCours()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchExercices() async {
    try {
      final response = await http.get(Uri.parse(_exercicesApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _exercices
            ..clear()
            ..addAll(data.map((e) => Exercice.fromJson(e as Map<String, dynamic>)));
        });
      } else {
        _showErrorSnackbar(LocalizationService().translate('exercises.error_loading').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('exercises.network_error').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _fetchClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final response = await http.get(Uri.parse(_classesApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _classes
            ..clear()
            ..addAll(data.map((e) => Classe.fromJson(e as Map<String, dynamic>)));
          _loadingClasses = false;
        });
      } else {
        setState(() => _loadingClasses = false);
        _showErrorSnackbar(LocalizationService().translate('exercises.error_loading_classes').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      setState(() => _loadingClasses = false);
      _showErrorSnackbar(LocalizationService().translate('exercises.network_error').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _fetchCours() async {
    setState(() => _loadingCours = true);
    try {
      final response = await http.get(Uri.parse(_coursApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _cours
            ..clear()
            ..addAll(data.map((e) => Cours.fromJson(e as Map<String, dynamic>)));
          _loadingCours = false;
        });
      } else {
        setState(() => _loadingCours = false);
        _showErrorSnackbar(LocalizationService().translate('exercises.error_loading_courses').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      setState(() => _loadingCours = false);
      _showErrorSnackbar(LocalizationService().translate('exercises.network_error').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _createExercice(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(_exercicesApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _fetchExercices();
        _showSuccessSnackbar(LocalizationService().translate('exercises.success_add'));
      } else {
        throw Exception(LocalizationService().translate('exercises.error_create').replaceAll('{code}', '${response.statusCode}').replaceAll('{body}', response.body));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('exercises.error_create_process').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _updateExercice(int id, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$_exercicesApiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        _fetchExercices();
        _showSuccessSnackbar(LocalizationService().translate('exercises.success_edit'));
      } else {
        throw Exception(LocalizationService().translate('exercises.error_update').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('exercises.error_update_process').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _deleteExercice(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_exercicesApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchExercices();
        _showSuccessSnackbar(LocalizationService().translate('exercises.success_delete'));
      } else {
        throw Exception(LocalizationService().translate('exercises.error_delete').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('exercises.error_delete_process').replaceAll('{error}', e.toString()));
    }
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
          : '${LocalizationService().translate('exercises.file_default').replaceAll('{time}', '${DateTime.now().millisecondsSinceEpoch}')}.$extension';

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
      _showErrorSnackbar(LocalizationService().translate('exercises.download_error').replaceAll('{error}', e.toString()));
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

  Future<Map<String, dynamic>?> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'gif'],
      );
      
      if (result == null || result.files.single.bytes == null) return null;

      final file = result.files.single;
      
      if (file.size > _maxFileSize) {
        _showErrorSnackbar(LocalizationService().translate('exercises.file_too_large').replaceAll('{size}', '${_maxFileSize ~/ 1024 ~/ 1024}'));
        return null;
      }

      return {
        'fileName': file.name,
        'base64': base64Encode(file.bytes!),
      };
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('exercises.error_picking_file').replaceAll('{error}', e.toString()));
      return null;
    }
  }

  Widget _buildFilePreview(String base64, {String fileName = ''}) {
    try {
      final bytes = base64Decode(base64);
      final fileType = _getFileTypeFromBytes(bytes);
      final fileSize = '${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB';
      final primaryColor = Colors.blue.shade900;

      return SizedBox(
        width: 150,
        child: Container(
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _downloadAndOpenFile(base64, fileName),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: _buildFileTypeIcon(fileType, bytes),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName.isNotEmpty ? fileName : LocalizationService().translate('exercises.file'),
                    style: const TextStyle(
                      fontSize: 10,
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
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Icon(
                        Icons.download_rounded,
                        size: 12,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return SizedBox(
        width: 150,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
              const SizedBox(height: 4),
              Text(
                LocalizationService().translate('exercises.invalid_file'),
                style: const TextStyle(color: Colors.red, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildFileTypeIcon(String fileType, Uint8List bytes) {
    switch (fileType) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red);
      case 'png':
      case 'jpg':
      case 'gif':
        return Image.memory(
          bytes,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
        );
      default:
        return const Icon(Icons.insert_drive_file, size: 20);
    }
  }

  void _showAddOrEditDialog({Exercice? exercice}) async {
    final primaryColor = Colors.blue.shade900;
    final contenuCtl = TextEditingController(text: exercice?.contenu ?? '');
    final dateCtl = TextEditingController(
      text: exercice?.datePublication ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    List<int> selectedClasseIds = exercice?.classeIds ?? [];
    int? selectedCourId = exercice?.courId;
    String localBase64 = exercice?.fichier ?? '';
    String selectedFileName = localBase64.isEmpty ? '' : context.tr('exercises.selected_file');

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercice == null ? context.tr('exercises.add_exercise') : context.tr('exercises.edit_exercise'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: contenuCtl,
                        decoration: InputDecoration(
                          labelText: context.tr('exercises.content'),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: dateCtl,
                        decoration: InputDecoration(
                          labelText: context.tr('exercises.publication_date'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(context.tr('exercises.classes'), style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        constraints: BoxConstraints(maxHeight: 150),
                        child: _loadingClasses
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _classes.length,
                                itemBuilder: (context, index) {
                                  final classe = _classes[index];
                                  return CheckboxListTile(
                                    title: Text(classe.niveau),
                                    value: selectedClasseIds.contains(classe.id),
                                    onChanged: (bool? selected) {
                                      dialogSetState(() {
                                        if (selected == true) {
                                          selectedClasseIds.add(classe.id);
                                        } else {
                                          selectedClasseIds.remove(classe.id);
                                        }
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                    dense: true,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(context.tr('exercises.courses'), style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedCourId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: _cours.map((cour) {
                          return DropdownMenuItem<int>(
                            value: cour.id,
                            child: Text(cour.matiere),
                          );
                        }).toList(),
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedCourId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      if (localBase64.isNotEmpty) ...[
                        _buildFilePreview(localBase64, fileName: selectedFileName),
                        const SizedBox(height: 16),
                      ],
                      
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text(localBase64.isEmpty
                            ? context.tr('exercises.add_file')
                            : context.tr('exercises.replace_file')),
                        onPressed: () async {
                          final fileData = await _pickFile();
                          if (fileData != null) {
                            dialogSetState(() {
                              localBase64 = fileData['base64']!;
                              selectedFileName = fileData['fileName']!;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.tr('common.cancel')),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (contenuCtl.text.trim().isEmpty) {
                                _showErrorSnackbar(context.tr('exercises.required_content'));
                                return;
                              }

                              if (dateCtl.text.trim().isEmpty) {
                                _showErrorSnackbar(context.tr('exercises.required_date'));
                                return;
                              }

                              if (selectedClasseIds.isEmpty) {
                                _showErrorSnackbar(context.tr('exercises.required_class'));
                                return;
                              }

                              if (selectedCourId == null) {
                                _showErrorSnackbar(context.tr('exercises.required_course'));
                                return;
                              }

                              if (localBase64.isEmpty) {
                                _showErrorSnackbar(context.tr('exercises.required_file'));
                                return;
                              }

                              final payload = {
                                'contenu': contenuCtl.text.trim(),
                                'datePublication': dateCtl.text.trim(),
                                'classeIds': selectedClasseIds,
                                'courId': selectedCourId,
                                'fichier': localBase64,
                              };

                              try {
                                if (exercice == null) {
                                  await _createExercice(payload);
                                } else {
                                  await _updateExercice(exercice.id, payload);
                                }
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                _showErrorSnackbar('${LocalizationService().translate('common.error')}: ${e.toString()}');
                              }
                            },
                            child: Text(context.tr('common.save')),
                          ),
                        ],
                      ),
                    ],
                  ),
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('exercises.confirm_delete_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 12),
              Text(context.tr('exercises.delete_confirmation')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.tr('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteExercice(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: Text(context.tr('common.delete'), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade900;
    final backgroundColor = Colors.grey.shade50;

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(context.tr('exercises.page_title'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          const LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
            tooltip: context.tr('exercises.tooltip_refresh'),
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
          : _exercices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('exercises.no_exercises'),
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
                        onPressed: _fetchData,
                        child: Text(context.tr('common.refresh'), style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('exercises.list_title'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._exercices.map((exercice) {
                        final classesText = exercice.classeIds
                            .map((id) => _classes.firstWhere(
                                  (c) => c.id == id,
                                  orElse: () => Classe(id: 0, niveau: context.tr('common.unknown'), enseignantIds: []),
                                ).niveau)
                            .join(', ');

                        final cours = _cours.firstWhere(
                          (c) => c.id == exercice.courId,
                          orElse: () => Cours(id: 0, matiere: context.tr('common.unknown')),
                        );

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
                                        '#${exercice.id}',
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
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.school,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    classesText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    DateFormat('dd/MM/yyyy').format(
                                                      DateTime.parse(exercice.datePublication),
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
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
                                      onPressed: () => _showAddOrEditDialog(exercice: exercice),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade400,
                                      ),
                                      onPressed: () => _confirmDelete(exercice.id),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  exercice.contenu,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              if (exercice.fichier.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          context.tr('exercises.attached_file'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildFilePreview(exercice.fichier),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      ),
    );
  }
}