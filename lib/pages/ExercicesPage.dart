import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Future<int?> getUserIdFromStorage() async {
  if (kIsWeb) {
    try {
      // Le stockage local web n'est disponible que sur le web
      // Ce code doit être déplacé dans un helper web si besoin
      return null;
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

  // Define colors as constant hexadecimal values
  static const Color _primaryColor = Color(0xFF0D47A1); // Equivalent to Colors.blue.shade900
  static const Color _blueShade700 = Color(0xFF1976D2); // Equivalent to Colors.blue.shade700
  static const Color _redShade400 = Color(0xFFEF5350); // Equivalent to Colors.red.shade400

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
        // Filtrer les exercices pour ne garder que ceux qui appartiennent au cours actuel
        final filteredExercices = data.where((ex) => ex['courId'] == widget.courId).toList();
        return filteredExercices.cast<Map<String, dynamic>>();
      } else {
        throw Exception(LocalizationService().translate('exercises.failed_load_exercises'));
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
        throw Exception(LocalizationService().translate('exercises.failed_load_classes'));
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
        throw Exception(LocalizationService().translate('exercises.failed_load_course'));
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
        downloadFileWeb(bytes, fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LocalizationService().translate('exercises.open_file_error')}: ${result.message}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationService().translate('exercises.download_error')}: $e')),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text(
          '${LocalizationService().translate('exercises.file_attached')}: $fileName',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
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
          child: Text(LocalizationService().translate('exercises.download')),
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
              title: Text(LocalizationService().translate('exercises.add_exercise'), style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${LocalizationService().translate('exercises.subject')}: ${cour['matiere']}', style: TextStyle(color: _primaryColor)),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: LocalizationService().translate('exercises.exercise_content'),
                        hintText: LocalizationService().translate('exercises.content_placeholder'),
                        labelStyle: TextStyle(color: _primaryColor),
                      ),
                      onChanged: (val) => contenu = val,
                    ),
                    TextFormField(
                      initialValue: date,
                      decoration: InputDecoration(
                        labelText: LocalizationService().translate('exercises.publication_date'),
                        labelStyle: TextStyle(color: _primaryColor),
                      ),
                      onChanged: (val) => date = val,
                    ),
                    const SizedBox(height: 10),
                    Text(classes.isEmpty
                      ? LocalizationService().translate('exercises.select_classes')
                      : LocalizationService().translate('exercises.assign_to_classes') + ':',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                    if (classes.isEmpty)
                      Text(LocalizationService().translate('exercises.select_classes'), style: TextStyle(color: _primaryColor)),
                    ...classes.map((classe) => CheckboxListTile(
                      title: Text('${classe['niveau']} (ID: ${classe['id']})', style: TextStyle(color: _primaryColor)),
                      value: selectedClassIds.contains(classe['id']),
                      checkColor: Colors.white,
                      activeColor: _primaryColor,
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
                      icon: Icon(Icons.attach_file, color: _primaryColor),
                      label: Text(fileName.isEmpty ? LocalizationService().translate('exercises.choose_file') : fileName, style: TextStyle(color: _primaryColor)),
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
                        throw Exception('${LocalizationService().translate('exercises.creation_error')}: ${response.statusCode}');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${LocalizationService().translate('common.error')}: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(LocalizationService().translate('exercises.create'), style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationService().translate('exercises.load_error')}: $e')),
      );
    }
  }

  void _showEditExerciseDialog(Map<String, dynamic> exercise) async {
    try {
      final classes = await _classesFuture;
      final cour = await _courFuture;
      String contenu = exercise['contenu'] != "no content" ? exercise['contenu'] : '';
      String? fichierBase64 = exercise['fichier'] != "no content" ? exercise['fichier'] : null;
      String fileName = fichierBase64 != null ? LocalizationService().translate('exercises.file_attached') : '';
      String date = exercise['datePublication'] ?? DateTime.now().toIso8601String().substring(0, 10);
      List<int> selectedClassIds = (exercise['classeIds'] as List?)?.where((id) => classes.any((c) => c['id'] == id)).map((id) => id as int).toList() ?? (classes.isNotEmpty ? [classes.first['id']] : []);
      bool fileRemoved = false;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(LocalizationService().translate('exercises.edit_exercise'), style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${LocalizationService().translate('exercises.subject')}: ${cour['matiere']}', style: TextStyle(color: _primaryColor)),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: contenu,
                      decoration: InputDecoration(
                        labelText: LocalizationService().translate('exercises.exercise_content'),
                        hintText: LocalizationService().translate('exercises.content_placeholder'),
                        labelStyle: TextStyle(color: _primaryColor),
                      ),
                      onChanged: (val) => contenu = val,
                    ),
                    TextFormField(
                      initialValue: date,
                      decoration: InputDecoration(
                        labelText: LocalizationService().translate('exercises.publication_date'),
                        labelStyle: TextStyle(color: _primaryColor),
                      ),
                      onChanged: (val) => date = val,
                    ),
                    const SizedBox(height: 10),
                    Text(classes.isEmpty
                      ? LocalizationService().translate('exercises.select_classes')
                      : LocalizationService().translate('exercises.assign_to_classes') + ':',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                    if (classes.isEmpty)
                      Text(LocalizationService().translate('exercises.select_classes'), style: TextStyle(color: _primaryColor)),
                    ...classes.map((classe) => CheckboxListTile(
                      title: Text('${classe['niveau']} (ID: ${classe['id']})', style: TextStyle(color: _primaryColor)),
                      value: selectedClassIds.contains(classe['id']),
                      checkColor: Colors.white,
                      activeColor: _primaryColor,
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
                      icon: Icon(Icons.attach_file, color: _primaryColor),
                      label: Text(fileName.isEmpty ? LocalizationService().translate('exercises.choose_file') : fileName, style: TextStyle(color: _primaryColor)),
                      style: ElevatedButton.styleFrom(
                        side: BorderSide(color: _primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                        child: Text(LocalizationService().translate('common.delete_file'), style: TextStyle(color: _redShade400)),
                      ),
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
                        throw Exception('${LocalizationService().translate('exercises.update_error')}: ${response.statusCode}');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${LocalizationService().translate('common.error')}: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(LocalizationService().translate('exercises.update'), style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationService().translate('exercises.load_error')}: $e')),
      );
    }
  }

  Future<void> _deleteExercise(int exerciseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocalizationService().translate('exercises.confirmation'), style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Text(LocalizationService().translate('exercises.delete_confirmation'), style: TextStyle(color: _primaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocalizationService().translate('common.cancel'), style: TextStyle(color: _primaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: Text(LocalizationService().translate('exercises.delete'), style: TextStyle(color: Colors.white)),
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
          SnackBar(content: Text('${LocalizationService().translate('exercises.delete_error')}: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _courFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(LocalizationService().translate('exercises.page_title').replaceAll('{subject}', snapshot.data!['matiere']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
            } else if (snapshot.hasError) {
              return const Text('Exercices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
            }
            return const Text('Chargement...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
          },
        ),
        backgroundColor: _primaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: _showAddExerciseDialog,
            tooltip: LocalizationService().translate('exercises.add_exercise'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: LocalizationService().translate('exercises.refresh'),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _exercicesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                ),
              );
            }
            final exercices = snapshot.data ?? [];
            if (exercices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      LocalizationService().translate('exercises.no_exercises'),
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
                      onPressed: _showAddExerciseDialog,
                      child: Text(LocalizationService().translate('exercises.add_exercise'), style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                _refreshData();
              },
              color: _primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: exercices.length,
                itemBuilder: (context, index) {
                  final ex = exercices[index];
                  final hasFile = ex['fichier'] != null && ex['fichier'] != "no content";
                  final fileName = hasFile ? 'exercice_${ex['id']}.${_getFileExtension(ex['fichier'])}' : '';

                  return Card(
                    margin: const EdgeInsets.all(12),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Center vertically within the card
                        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally within the card
                        children: [
                          Text(
                            ex['contenu'] != "no content" 
                                ? ex['contenu'] 
                                : 'Exercice ${ex['id']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: _primaryColor,
                            ),
                            textAlign: TextAlign.center, // Center the text
                          ),
                          const SizedBox(height: 16),
                          if (hasFile) _buildFilePreview(ex['fichier'], fileName),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Center the buttons horizontally
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: _blueShade700),
                                onPressed: () => _showEditExerciseDialog(ex),
                                tooltip: LocalizationService().translate('exercises.edit_exercise'),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: _redShade400),
                                onPressed: () => _deleteExercise(ex['id']),
                                tooltip: LocalizationService().translate('exercises.delete'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${ex['datePublication'] ?? 'Non spécifiée'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                       
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}