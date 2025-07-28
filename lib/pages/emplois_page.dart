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
import 'package:intl/intl.dart';
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

class Emploi {
  final int id;
  final String datePublication;
  final String fichier;
  final int classeId;

  Emploi({
    required this.id,
    required this.datePublication,
    required this.fichier,
    required this.classeId,
  });

  factory Emploi.fromJson(Map<String, dynamic> json) {
    return Emploi(
      id: json['id'] as int,
      datePublication: json['datePublication'] as String? ?? '',
      fichier: json['fichier'] as String? ?? '',
      classeId: json['classeId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datePublication': datePublication,
      'fichier': fichier,
      'classeId': classeId,
    };
  }
}

class EmploisPage extends StatefulWidget {
  const EmploisPage({Key? key}) : super(key: key);

  @override
  State<EmploisPage> createState() => _EmploisPageState();
}

class _EmploisPageState extends State<EmploisPage> {
  static const String _emploisApiUrl = 'http://localhost:8004/api/emplois';
  static const String _classesApiUrl = 'http://localhost:8004/api/classes';
  static const int _maxFileSize = 25 * 1024 * 1024;

  final List<Emploi> _emplois = [];
  final List<Classe> _classes = [];
  bool _loading = true;
  bool _loadingClasses = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Emploi> get _filteredEmplois {
    if (_searchQuery.isEmpty) return _emplois;
    
    final query = _searchQuery.toLowerCase();
    return _emplois.where((emploi) {
      final classe = _classes.firstWhere(
        (c) => c.id == emploi.classeId,
        orElse: () => Classe(id: 0, niveau: '', enseignantIds: []),
      );
      
      return classe.niveau.toLowerCase().contains(query) ||
          emploi.datePublication.toLowerCase().contains(query) ||
          emploi.id.toString().contains(query);
    }).toList();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    await Future.wait([_fetchEmplois(), _fetchClasses()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchEmplois() async {
    try {
      final response = await http.get(Uri.parse(_emploisApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _emplois
            ..clear()
            ..addAll(data.map((e) => Emploi.fromJson(e as Map<String, dynamic>)));
        });
      } else {
        _showErrorSnackbar(LocalizationService().translate('schedules.error_loading').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('schedules.network_error').replaceAll('{error}', e.toString()));
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
        _showErrorSnackbar(LocalizationService().translate('schedules.error_loading_classes').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      setState(() => _loadingClasses = false);
      _showErrorSnackbar(LocalizationService().translate('schedules.network_error').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _createEmploi(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(_emploisApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _fetchEmplois();
        _showSuccessSnackbar(LocalizationService().translate('schedules.success_add'));
      } else {
        throw Exception(LocalizationService().translate('schedules.error_create').replaceAll('{code}', '${response.statusCode}').replaceAll('{body}', response.body));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('schedules.error_create_process').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _updateEmploi(int id, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$_emploisApiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        _fetchEmplois();
        _showSuccessSnackbar(LocalizationService().translate('schedules.success_edit'));
      } else {
        throw Exception(LocalizationService().translate('schedules.error_update').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('schedules.error_update_process').replaceAll('{error}', e.toString()));
    }
  }

  Future<void> _deleteEmploi(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_emploisApiUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchEmplois();
        _showSuccessSnackbar(LocalizationService().translate('schedules.success_delete'));
      } else {
        throw Exception(LocalizationService().translate('schedules.error_delete').replaceAll('{code}', '${response.statusCode}'));
      }
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('schedules.error_delete_process').replaceAll('{error}', e.toString()));
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
          : '${LocalizationService().translate('schedules.file_default').replaceAll('{time}', '${DateTime.now().millisecondsSinceEpoch}')}.$extension';

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
      _showErrorSnackbar(LocalizationService().translate('schedules.download_error').replaceAll('{error}', e.toString()));
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
        _showErrorSnackbar(LocalizationService().translate('schedules.file_too_large').replaceAll('{size}', '${_maxFileSize ~/ 1024 ~/ 1024}'));
        return null;
      }

      return {
        'fileName': file.name,
        'base64': base64Encode(file.bytes!),
      };
    } catch (e) {
      _showErrorSnackbar(LocalizationService().translate('schedules.error_picking_file').replaceAll('{error}', e.toString()));
      return null;
    }
  }

  Widget _buildFilePreview(String base64, {String fileName = ''}) {
    try {
      final bytes = base64Decode(base64);
      final fileType = _getFileTypeFromBytes(bytes);
      final fileSize = '${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB';
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
                  fileName.isNotEmpty ? fileName : LocalizationService().translate('schedules.file'),
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
              LocalizationService().translate('schedules.invalid_file'),
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

  void _showAddOrEditDialog({Emploi? emploi}) async {
    final primaryColor = Colors.blue.shade900;
    final dateCtl = TextEditingController(
      text: emploi?.datePublication ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    int? selectedClasseId = emploi?.classeId;
    String localBase64 = emploi?.fichier ?? '';
    String selectedFileName = localBase64.isEmpty ? '' : context.tr('schedules.selected_file');

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emploi == null ? context.tr('schedules.add_schedule') : context.tr('schedules.edit_schedule'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: dateCtl,
                    decoration: InputDecoration(
                      labelText: context.tr('schedules.publication_date'),
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
                  const SizedBox(height: 16),
                  
                  _loadingClasses
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<int>(
                          value: selectedClasseId,
                          decoration: InputDecoration(
                            labelText: context.tr('schedules.class'),
                            labelStyle: TextStyle(color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _classes.map((classe) {
                            return DropdownMenuItem<int>(
                              value: classe.id,
                              child: Text(classe.niveau),
                            );
                          }).toList(),
                          onChanged: (value) {
                            dialogSetState(() {
                              selectedClasseId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return context.tr('schedules.required_class');
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),
                  
                  if (localBase64.isNotEmpty) ...[
                    Text(
                      context.tr('schedules.attached_file'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFilePreview(localBase64),
                    const SizedBox(height: 16),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file, size: 20, color: Colors.white),
                      label: Text(
                        localBase64.isEmpty
                          ? context.tr('schedules.choose_file')
                          : context.tr('schedules.replace_file'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                          context.tr('common.cancel'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (dateCtl.text.trim().isEmpty) {
                            _showErrorSnackbar(context.tr('schedules.required_date'));
                            return;
                          }

                          if (selectedClasseId == null) {
                            _showErrorSnackbar(context.tr('schedules.required_class'));
                            return;
                          }

                          if (localBase64.isEmpty) {
                            _showErrorSnackbar(context.tr('schedules.required_file'));
                            return;
                          }

                          final payload = {
                            'datePublication': dateCtl.text.trim(),
                            'classeId': selectedClasseId,
                            'fichier': localBase64,
                          };

                          try {
                            if (emploi == null) {
                              await _createEmploi(payload);
                            } else {
                              await _updateEmploi(emploi.id, payload);
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            _showErrorSnackbar('${LocalizationService().translate('common.error')}: ${e.toString()}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Text(
                          context.tr('common.save'),
                          style: const TextStyle(color: Colors.white),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade900;
    final backgroundColor = Colors.grey.shade50;

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(context.tr('schedules.page_title'), style: const TextStyle(color: Colors.white)),
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
              tooltip: context.tr('schedules.tooltip_refresh'),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: context.tr('schedules.search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _filteredEmplois.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? context.tr('schedules.no_schedules')
                                      : context.tr('schedules.no_results'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                    child: Text(
                                      context.tr('schedules.clear_search'),
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ),
                                ],
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
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                context.tr('schedules.list_title'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._filteredEmplois.map((emploi) {
                                final classe = _classes.firstWhere(
                                  (c) => c.id == emploi.classeId,
                                  orElse: () => Classe(id: 0, niveau: context.tr('common.unknown'), enseignantIds: []),
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
                                                '#${emploi.id}',
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
                                                    classe.niveau,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
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
                                                          DateTime.parse(emploi.datePublication),
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
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.blue.shade700,
                                              ),
                                              onPressed: () => _showAddOrEditDialog(emploi: emploi),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red.shade400,
                                              ),
                                              onPressed: () => _confirmDelete(emploi.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (emploi.fichier.isNotEmpty) ...[
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
                                                  context.tr('schedules.attached_file'),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade600,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                _buildFilePreview(emploi.fichier),
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
                ],
              ),
      ),
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
                context.tr('schedules.confirm_delete_title'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Text(context.tr('schedules.delete_confirmation')),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteEmploi(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                    child: Text(
                      context.tr('common.delete'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}