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

class Cours {
  final int id;
  final String fichier;
  final String matiere;
  final List<int> exerciceIds;

  Cours({
    required this.id,
    required this.fichier,
    required this.matiere,
    required this.exerciceIds,
  });

  factory Cours.fromJson(Map<String, dynamic> json) {
    return Cours(
      id: json['id'] as int,
      fichier: json['fichier'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      exerciceIds: (json['exerciceIds'] as List).map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fichier': fichier,
      'matiere': matiere,
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
  static const int _maxFileSize = 25 * 1024 * 1024;
  static const String _fileSeparator = '||SEP||XyZ1234||SEP||';

  final List<Cours> _cours = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCours();
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
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showErrorSnackbar('Erreur de chargement: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackbar('Erreur: $e');
    }
  }

  Future<void> _createCours(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(_coursApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _fetchCours();
        _showSuccessSnackbar('Cours ajouté');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
    }
  }

  Future<void> _updateCours(int id, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$_coursApiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        _fetchCours();
        _showSuccessSnackbar('Cours modifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
    }
  }

  Future<void> _deleteCours(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_coursApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchCours();
        _showSuccessSnackbar('Cours supprimé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
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
      _showErrorSnackbar('Erreur lors du téléchargement: $e');
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
      _showErrorSnackbar('Erreur: $e');
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
              color: Colors.grey.withOpacity(0.2),
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
                // File type icon
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
                
                // File name
                Text(
                  fileName.isNotEmpty ? fileName : 'Fichier',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // File size and download
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
            const Text(
              'Fichier invalide',
              style: TextStyle(color: Colors.red),
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

    if (cours != null && cours.fichier.isNotEmpty) {
      selectedFiles = cours.fichier
          .split(_fileSeparator)
          .map((b64) => {'fileName': 'Fichier cours', 'base64': b64})
          .toList();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cours == null ? 'Ajouter un cours' : 'Modifier le cours',
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
                      labelText: 'Matière',
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
                  
                  if (selectedFiles.isNotEmpty) ...[
                    Text(
                      'Fichiers joints',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 20),
                  ],
                  
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file, size: 20),
                        label: const Text('Ajouter des fichiers', style: TextStyle(
        color: Colors.white,
      ),),
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
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (matiereCtl.text.trim().isEmpty) {
                            _showErrorSnackbar('Veuillez saisir une matière');
                            return;
                          }

                          final payload = {
                            'matiere': matiereCtl.text.trim(),
                            'fichier': selectedFiles.map((f) => f['base64']).join(_fileSeparator),
                            'exerciceIds': cours?.exerciceIds ?? [],
                          };

                          try {
                            if (cours == null) {
                              await _createCours(payload);
                            } else {
                              await _updateCours(cours.id, payload);
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            _showErrorSnackbar('Erreur: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                      child: const Text(
    'Enregistrer',
    style: TextStyle(
      color: Colors.white, 
    ),),
                      ),
                    ],
                  ),
                ],
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
                'Confirmer la suppression',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Voulez-vous vraiment supprimer ce cours ?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Annuler',
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
                    child: const Text('Supprimer'),
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Cours', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 4,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchCours,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(), // Votre drawer admin
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
          : _cours.isEmpty
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
                        'Aucun cours disponible',
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
                        child: const Text('Actualiser', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Liste des cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._cours.map((cours) {
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
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.assignment,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${cours.exerciceIds.length} exercices',
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
                                              '${fileParts.length} fichiers',
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
                                      'FICHIERS ASSOCIÉS',
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
    );
  }
}