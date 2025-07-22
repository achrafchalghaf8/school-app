import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../services/localization_service.dart';

class EmploiDuTempsPage extends StatefulWidget {
  final int classeId;
  final String etudiantNom;
  final String niveauClasse;

  const EmploiDuTempsPage({
    Key? key,
    required this.classeId,
    required this.etudiantNom,
    required this.niveauClasse,
  }) : super(key: key);

  @override
  _EmploiDuTempsPageState createState() => _EmploiDuTempsPageState();
}

class _EmploiDuTempsPageState extends State<EmploiDuTempsPage> {
  List<Map<String, dynamic>> _emplois = [];
  Map<String, dynamic>? _selectedEmploi;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isDownloading = false;
  Uint8List? _fileBytes;
  String? _fileType;
  String? _fileName;
  bool _showImageFullScreen = false;

  @override
  void initState() {
    super.initState();
    _fetchEmploiDuTemps();
  }

  Future<void> _fetchEmploiDuTemps() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/emplois'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        // Filtrer les emplois de la classe courante
        final emploisClasse = data
            .where((emploi) => emploi['classeId'] == widget.classeId)
            .map((emploi) => Map<String, dynamic>.from(emploi))
            .toList();

        // Trier par date de publication (plus récent en premier)
        emploisClasse.sort((a, b) {
          final dateA = DateTime.tryParse(a['datePublication'] ?? '') ?? DateTime(1900);
          final dateB = DateTime.tryParse(b['datePublication'] ?? '') ?? DateTime(1900);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _emplois = emploisClasse;
          // Sélectionner automatiquement le plus récent
          _selectedEmploi = emploisClasse.isNotEmpty ? emploisClasse.first : null;
          _isLoading = false;
        });

        // Préparer automatiquement le fichier le plus récent
        if (emploisClasse.isNotEmpty) {
          _prepareFile(emploisClasse.first);
        }
      } else {
        throw Exception(LocalizationService().translate('parents.schedule.failed_load_schedule'));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${LocalizationService().translate('parents.schedule.loading_error')}: ${e.toString()}';
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

  Future<void> _prepareFile([Map<String, dynamic>? emploi]) async {
    final targetEmploi = emploi ?? _selectedEmploi;
    if (targetEmploi == null || targetEmploi['fichier'] == null) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = '';
    });

    try {
      String base64String = targetEmploi['fichier'].toString();

      // Nettoyer la chaîne base64
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      base64String = base64String
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9+/=]'), '');

      while (base64String.length % 4 != 0) {
        base64String += '=';
      }

      if (base64String.isEmpty) {
        throw Exception(LocalizationService().translate('parents.schedule.empty_base64_file'));
      }

      final bytes = base64.decode(base64String);
      final fileType = _getFileTypeFromBytes(bytes);
      final extension = _getExtensionFromFileType(fileType);
      final fileName = 'emploi_${targetEmploi['id']}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      setState(() {
        _fileBytes = bytes;
        _fileType = fileType;
        _fileName = fileName;
        _selectedEmploi = targetEmploi;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${LocalizationService().translate('parents.schedule.prepare_file_error')}: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('common.error')}: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _openFile() async {
    if (_fileBytes == null || _fileName == null || _fileType == null) return;

    try {
      if (kIsWeb) {
        final mimeType = _getMimeType(_fileType!);
        final blob = html.Blob([_fileBytes!], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..download = _fileName!
          ..click();
        
        html.Url.revokeObjectUrl(url);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$_fileName');
        await file.writeAsBytes(_fileBytes!);
        final result = await OpenFile.open(file.path);
        
        if (result.type != ResultType.done) {
          _showErrorSnackbar(LocalizationService().translate('parents.schedule.no_app_open_file'));
        }
      }
    } catch (e) {
      _showErrorSnackbar('${LocalizationService().translate('parents.schedule.cannot_open_file')}: ${e.toString()}');
    }
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

  Widget _buildFileContent() {
    if (_fileBytes == null || _fileType == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 60,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('parents.schedule.no_file_display'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          if (_fileType == 'png' || _fileType == 'jpg' || _fileType == 'gif')
            GestureDetector(
              onTap: () {
                setState(() {
                  _showImageFullScreen = true;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _fileBytes!,
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 350,
                    color: Colors.blue.shade50,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (_fileType == 'pdf')
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 80,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('parents.schedule.pdf_click_open'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openFile,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      size: 80,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('parents.schedule.file_click_open'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('parents.schedule.size').replaceAll('{size}', (_fileBytes!.length / 1024).toStringAsFixed(1)),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.blue.shade700),
                      onPressed: _openFile,
                      tooltip: context.tr('parents.schedule.download'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _fileName ?? context.tr('parents.schedule.file'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    if (_selectedEmploi == null || _selectedEmploi!['fichier'] == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 60,
              color: Colors.blue.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('parents.schedule.no_schedule_available'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final datePublication = DateTime.tryParse(_selectedEmploi!['datePublication'] ?? '');
    final dateStr = datePublication != null
        ? '${datePublication.day}/${datePublication.month}/${datePublication.year}'
        : _selectedEmploi!['datePublication'] ?? context.tr('parents.schedule.unknown_date');

    return Column(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blue.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('parents.schedule.most_recent_schedule'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('parents.schedule.published_on').replaceAll('{date}', dateStr),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                ),
                Text(
                  context.tr('parents.schedule.class').replaceAll('{class}', widget.niveauClasse),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _isDownloading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('parents.schedule.loading_file'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildFileContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          context.tr('parents.schedule.page_title').replaceAll('{class}', widget.niveauClasse),
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
                _fileBytes = null;
                _selectedEmploi = null;
              });
              _fetchEmploiDuTemps();
            },
            tooltip: context.tr('parents.schedule.refresh'),
          ),
        ],
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error,
                              size: 60,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = '';
                                });
                                _fetchEmploiDuTemps();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                context.tr('parents.schedule.retry'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.blue.shade100),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('parents.schedule.student').replaceAll('{name}', widget.etudiantNom),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('parents.schedule.class').replaceAll('{class}', widget.niveauClasse),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('parents.schedule.schedules_available').replaceAll('{count}', _emplois.length.toString()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildFilePreview(),
                          ),
                        ],
                      ),
                    ),
                    if (_showImageFullScreen && (_fileType == 'png' || _fileType == 'jpg' || _fileType == 'gif'))
                      Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Image.memory(
                                _fileBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () {
                                  setState(() {
                                    _showImageFullScreen = false;
                                  });
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: FloatingActionButton(
                                backgroundColor: Colors.blue.shade700,
                                onPressed: _openFile,
                                child: const Icon(Icons.download, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}