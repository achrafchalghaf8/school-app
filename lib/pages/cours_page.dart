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
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _cours
            ..clear()
            ..addAll(data.map((e) => Cours.fromJson(e as Map<String, dynamic>)));
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showErrorSnackbar('Erreur lors de la récupération des cours: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showErrorSnackbar('Erreur réseau ou serveur: ${e.toString()}');
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
        _showSuccessSnackbar('Cours ajouté avec succès');
      } else {
        throw Exception('Erreur création cours: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la création: ${e.toString()}');
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
        _showSuccessSnackbar('Cours modifié avec succès');
      } else {
        throw Exception('Erreur mise à jour cours: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  Future<void> _deleteCours(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_coursApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchCours();
        _showSuccessSnackbar('Suppression réussie');
      } else {
        throw Exception('Erreur suppression: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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

  Future<void> _openFile(String base64String) async {
    try {
      final bytes = base64Decode(base64String);
      final fileType = _getFileTypeFromBytes(bytes);
      final extension = _getExtensionFromFileType(fileType);
      final fileName = 'cours_${DateTime.now().millisecondsSinceEpoch}.$extension';

      if (kIsWeb) {
        final mimeType = _getMimeType(fileType);
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..click();
        
        html.Url.revokeObjectUrl(url);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        final result = await OpenFile.open(file.path);
        
        if (result.type != ResultType.done) {
          _showErrorSnackbar('Aucune application pour ouvrir ce fichier');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Impossible d\'ouvrir le fichier: ${e.toString()}');
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
        _showErrorSnackbar('Fichier trop volumineux (max ${_maxFileSize ~/ 1024 ~/ 1024}MB)');
        return null;
      }

      return {
        'fileName': file.name,
        'base64': base64Encode(file.bytes!),
      };
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sélection du fichier: ${e.toString()}');
      return null;
    }
  }

  Widget _buildFilePreview(String base64String) {
    if (base64String.isEmpty || base64String == 'hhhh') {
      return const ListTile(
        leading: Icon(Icons.error, color: Colors.red),
        title: Text('Aucun fichier disponible'),
      );
    }

    try {
      final bytes = base64Decode(base64String);
      final fileType = _getFileTypeFromBytes(bytes);

      return Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _openFile(base64String),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (fileType == 'png' || fileType == 'jpg' || fileType == 'gif')
                  Image.memory(
                    bytes,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                  )
                else if (fileType == 'pdf')
                  const Column(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
                      Text('PDF - Cliquez pour ouvrir'),
                    ],
                  )
                else
                  const Column(
                    children: [
                      Icon(Icons.insert_drive_file, size: 50),
                      Text('Fichier - Cliquez pour ouvrir'),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  'Taille: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const ListTile(
        leading: Icon(Icons.error, color: Colors.red),
        title: Text('Fichier corrompu ou invalide'),
      );
    }
  }

  Future<void> _showAddOrEditDialog({Cours? cours}) async {
    final matiereCtl = TextEditingController(text: cours?.matiere ?? '');
    String localBase64 = cours?.fichier ?? '';
    String selectedFileName = localBase64.isEmpty ? '' : 'Fichier sélectionné';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: Text(cours == null ? 'Ajouter Cours' : 'Modifier Cours'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: matiereCtl,
                    decoration: const InputDecoration(
                      labelText: 'Matière',
                      hintText: 'Nom de la matière',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (localBase64.isNotEmpty) _buildFilePreview(localBase64),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final fileData = await _pickFile();
                      if (fileData != null) {
                        dialogSetState(() {
                          localBase64 = fileData['base64']!;
                          selectedFileName = fileData['fileName']!;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(localBase64.isEmpty 
                      ? 'Choisir un fichier (max 25MB)' 
                      : 'Remplacer le fichier'),
                  ),
                  if (localBase64.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        selectedFileName,
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
                  if (matiereCtl.text.trim().isEmpty) {
                    _showErrorSnackbar('Veuillez saisir une matière');
                    return;
                  }

                  if (localBase64.isEmpty) {
                    _showErrorSnackbar('Veuillez sélectionner un fichier');
                    return;
                  }

                  final payload = {
                    'matiere': matiereCtl.text.trim(),
                    'fichier': localBase64,
                    'exerciceIds': cours?.exerciceIds ?? [],
                  };

                  try {
                    if (cours == null) {
                      await _createCours(payload);
                    } else {
                      await _updateCours(cours.id, payload);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorSnackbar('Erreur: ${e.toString()}');
                    }
                  }
                },
                child: Text(cours == null ? 'Ajouter' : 'Enregistrer'),
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
      appBar: AppBar(
        title: const Text('Gestion des Cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCours,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cours.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aucun cours disponible'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchCours,
                        child: const Text('Actualiser'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _cours.length,
                  itemBuilder: (context, index) {
                    final cours = _cours[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text('#${cours.id}'),
                            ),
                            title: Text('Matière: ${cours.matiere}'),
                            subtitle: Text('${cours.exerciceIds.length} exercices associés'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showAddOrEditDialog(cours: cours),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDelete(cours.id),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildFilePreview(cours.fichier),
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce cours ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCours(id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}