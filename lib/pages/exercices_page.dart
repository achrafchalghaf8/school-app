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
        _showErrorSnackbar('Erreur lors de la récupération des exercices: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur réseau ou serveur: ${e.toString()}');
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
        _showErrorSnackbar('Erreur lors de la récupération des classes: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingClasses = false);
      _showErrorSnackbar('Erreur réseau ou serveur: ${e.toString()}');
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
        _showErrorSnackbar('Erreur lors de la récupération des cours: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingCours = false);
      _showErrorSnackbar('Erreur réseau ou serveur: ${e.toString()}');
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
        _showSuccessSnackbar('Exercice ajouté avec succès');
      } else {
        throw Exception('Erreur création exercice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la création: ${e.toString()}');
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
        _showSuccessSnackbar('Exercice modifié avec succès');
      } else {
        throw Exception('Erreur mise à jour exercice: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  Future<void> _deleteExercice(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_exercicesApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchExercices();
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
      final fileName = 'exercice_${DateTime.now().millisecondsSinceEpoch}.$extension';

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
    if (base64String.isEmpty) {
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

  Future<void> _showAddOrEditDialog({Exercice? exercice}) async {
    final contenuCtl = TextEditingController(text: exercice?.contenu ?? '');
    final dateCtl = TextEditingController(
      text: exercice?.datePublication ?? DateTime.now().toString().substring(0, 10),
    );
    List<int> selectedClasseIds = exercice?.classeIds ?? [];
    int? selectedCourId = exercice?.courId;
    String localBase64 = exercice?.fichier ?? '';
    String selectedFileName = localBase64.isEmpty ? '' : 'Fichier sélectionné';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: Text(exercice == null ? 'Ajouter Exercice' : 'Modifier Exercice'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contenuCtl,
                    decoration: const InputDecoration(
                      labelText: 'Contenu',
                      hintText: 'Description de l\'exercice',
                    ),
                    maxLines: 3,
                  ),
                  TextField(
                    controller: dateCtl,
                    decoration: const InputDecoration(
                      labelText: 'Date Publication',
                      hintText: 'AAAA-MM-JJ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _loadingClasses
                      ? const CircularProgressIndicator()
                      : InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Classes',
                            border: OutlineInputBorder(),
                          ),
                          child: Column(
                            children: [
                              ..._classes.map((classe) {
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
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                  const SizedBox(height: 16),
                  _loadingCours
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int>(
                          value: selectedCourId,
                          decoration: const InputDecoration(
                            labelText: 'Cours',
                            border: OutlineInputBorder(),
                          ),
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
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un cours';
                            }
                            return null;
                          },
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
                  if (contenuCtl.text.trim().isEmpty) {
                    _showErrorSnackbar('Veuillez saisir un contenu');
                    return;
                  }

                  if (dateCtl.text.trim().isEmpty) {
                    _showErrorSnackbar('Veuillez saisir une date');
                    return;
                  }

                  if (selectedClasseIds.isEmpty) {
                    _showErrorSnackbar('Veuillez sélectionner au moins une classe');
                    return;
                  }

                  if (selectedCourId == null) {
                    _showErrorSnackbar('Veuillez sélectionner un cours');
                    return;
                  }

                  if (localBase64.isEmpty) {
                    _showErrorSnackbar('Veuillez sélectionner un fichier');
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
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorSnackbar('Erreur: ${e.toString()}');
                    }
                  }
                },
                child: Text(exercice == null ? 'Ajouter' : 'Enregistrer'),
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
        title: const Text('Gestion des Exercices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aucun exercice disponible'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Actualiser'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _exercices.length,
                  itemBuilder: (context, index) {
                    final exercice = _exercices[index];
                    final classesText = exercice.classeIds
                        .map((id) => _classes.firstWhere(
                              (c) => c.id == id,
                              orElse: () => Classe(id: 0, niveau: 'Inconnue', enseignantIds: []),
                            ).niveau)
                        .join(', ');
                    
                    final cours = _cours.firstWhere(
                      (c) => c.id == exercice.courId,
                      orElse: () => Cours(id: 0, matiere: 'Inconnue'),
                    );

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              child: Text('#${exercice.id}'),
                            ),
                            title: Text('Cours: ${cours.matiere}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Classes: $classesText'),
                                Text('Date: ${exercice.datePublication}'),
                                Text(exercice.contenu),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showAddOrEditDialog(exercice: exercice),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDelete(exercice.id),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildFilePreview(exercice.fichier),
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
        content: const Text('Voulez-vous vraiment supprimer cet exercice ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteExercice(id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}