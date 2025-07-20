import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class CoursesPage extends StatefulWidget {
  final int classeId;
  final String niveauClasse;
  final String etudiantNom;

  const CoursesPage({
    Key? key,
    required this.classeId,
    required this.niveauClasse,
    required this.etudiantNom,
  }) : super(key: key);

  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<dynamic> _coursList = [];
  List<dynamic> _exercicesList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  static const String _fileSeparator = '||SEP||XyZ1234||SEP||';

  @override
  void initState() {
    super.initState();
    _fetchCoursesAndExercices();
  }

  Future<void> _fetchCoursesAndExercices() async {
    try {
      final coursResponse = await http.get(
        Uri.parse('http://localhost:8004/api/cours'),
      );

      if (coursResponse.statusCode != 200) {
        throw Exception('Failed to load courses');
      }

      final exercicesResponse = await http.get(
        Uri.parse('http://localhost:8004/api/exercices'),
      );

      if (exercicesResponse.statusCode != 200) {
        throw Exception('Failed to load exercices');
      }

      final List<dynamic> allCours = json.decode(coursResponse.body);
      final List<dynamic> allExercices = json.decode(exercicesResponse.body);

      final List<dynamic> filteredExercices = allExercices.where((exercice) {
        final List<dynamic> classeIds = exercice['classeIds'] ?? [];
        return classeIds.contains(widget.classeId);
      }).toList();

      final List<int> associatedCoursIds = filteredExercices
          .map<int>((exercice) => exercice['courId'] as int)
          .toList();

      final List<dynamic> filteredCours = allCours.where((cours) {
        return associatedCoursIds.contains(cours['id']);
      }).toList();

      setState(() {
        _coursList = filteredCours;
        _exercicesList = filteredExercices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      });
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

  Future<void> _openFile(String base64String, String fileNamePrefix, int fileIndex) async {
    try {
      final bytes = base64Decode(base64String);
      final fileType = _getFileTypeFromBytes(bytes);
      final extension = _getExtensionFromFileType(fileType);
      final fileName = '${fileNamePrefix}_${fileIndex}_${DateTime.now().millisecondsSinceEpoch}.$extension';

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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSingleFilePreview(String base64String, String fileNamePrefix, int fileIndex) {
    if (base64String.isEmpty || base64String == "no content") {
      return const SizedBox.shrink();
    }

    try {
      final bytes = base64Decode(base64String);
      final fileType = _getFileTypeFromBytes(bytes);
      final fileSize = '${(bytes.length / 1024).toStringAsFixed(1)} KB';

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade100),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openFile(base64String, fileNamePrefix, fileIndex),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        fileType == 'pdf' ? Icons.picture_as_pdf
                            : fileType == 'png' || fileType == 'jpg' || fileType == 'gif'
                                ? Icons.image
                                : Icons.insert_drive_file,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fichier ${fileIndex + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          Text(
                            fileSize,
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.blue.shade700),
                      onPressed: () => _openFile(base64String, fileNamePrefix, fileIndex),
                      tooltip: 'Télécharger',
                    ),
                  ],
                ),
                if (fileType == 'png' || fileType == 'jpg' || fileType == 'gif')
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        bytes,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: Colors.blue.shade50,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.blue.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Card(
        elevation: 1,
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(Icons.error_outline, color: Colors.redAccent),
          title: Text(
            'Fichier corrompu ou invalide',
            style: TextStyle(color: Colors.blue.shade900),
          ),
          subtitle: Text(
            'Veuillez contacter votre enseignant',
            style: TextStyle(color: Colors.blue.shade600),
          ),
        ),
      );
    }
  }

  Widget _buildFileList(String filesString, String fileNamePrefix) {
    if (filesString.isEmpty || filesString == "no content") {
      return const SizedBox.shrink();
    }

    final fileParts = filesString.split(_fileSeparator);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Fichiers ($fileNamePrefix):',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: fileParts.asMap().entries.map((entry) {
            return SizedBox(
              width: 200,
              child: _buildSingleFilePreview(entry.value, fileNamePrefix, entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'Cours - ${widget.niveauClasse}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade700,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
              : _coursList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book,
                            size: 60,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun cours disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _coursList.length,
                      itemBuilder: (context, index) {
                        final cours = _coursList[index];
                        final matiere = cours['matiere'] ?? 'Matière inconnue';
                        final fichier = cours['fichier'] ?? '';

                        final associatedExercices = _exercicesList.where((exercice) {
                          return exercice['courId'] == cours['id'];
                        }).toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.blue.shade100),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                matiere,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              subtitle: Text(
                                '${associatedExercices.length} exercice${associatedExercices.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.book,
                                  color: Colors.blue.shade700,
                                  size: 28,
                                ),
                              ),
                              iconColor: Colors.blue.shade700,
                              collapsedIconColor: Colors.blue.shade500,
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (fichier.isNotEmpty && fichier != "no content")
                                        _buildFileList(fichier, 'Cours'),
                                      if (associatedExercices.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Exercices:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...associatedExercices.map((exercice) {
                                          final exerciceFile = exercice['fichier'] ?? '';
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: Colors.blue.shade100),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      exercice['contenu'] ?? 'Exercice sans description',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.blue.shade800,
                                                      ),
                                                    ),
                                                    if (exerciceFile.isNotEmpty && exerciceFile != "no content")
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 12.0),
                                                        child: _buildFileList(exerciceFile, 'Exercice'),
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Publié le: ${exercice['datePublication'] ?? 'Date inconnue'}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}