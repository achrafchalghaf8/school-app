import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class EmploiDialog extends StatefulWidget {
  final Map<String, dynamic>? emploi;
  final Future<void> Function() onSave;

  const EmploiDialog({
    Key? key,
    this.emploi,
    required this.onSave,
  }) : super(key: key);

  @override
  _EmploiDialogState createState() => _EmploiDialogState();
}

class _EmploiDialogState extends State<EmploiDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _classeIdController;
  File? _selectedFile;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.emploi?['datePublication'] ?? '');
    _classeIdController = TextEditingController(text: widget.emploi?['classeId']?.toString() ?? '');
    _fileName = widget.emploi?['fichier'];
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true, // pour web
      );

      if (result != null) {
        final fileExtension = path.extension(result.files.single.name).toLowerCase();
        final originalFileName = result.files.single.name;
        String? newFilePath;
        String? relativePath;
        if (kIsWeb) {
          setState(() {
            _fileName = originalFileName;
          });
        } else {
          // Pour mobile/desktop, on copie dans files/images ou files/pdf à la racine du projet
          String projectDir = Directory.current.path;
          // Si on est dans un sous-dossier (ex: build/), on remonte jusqu'à trouver pubspec.yaml
          while (!File(path.join(projectDir, 'pubspec.yaml')).existsSync()) {
            final parent = Directory(projectDir).parent.path;
            if (parent == projectDir) break;
            projectDir = parent;
          }
          Directory targetDir;
          if (['.pdf'].contains(fileExtension)) {
            targetDir = Directory(path.join(projectDir, 'files', 'pdf'));
            relativePath = path.join('files', 'pdf', originalFileName);
          } else {
            targetDir = Directory(path.join(projectDir, 'files', 'images'));
            relativePath = path.join('files', 'images', originalFileName);
          }
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
          newFilePath = path.join(targetDir.path, originalFileName);
          // Toujours écrire le fichier, même s'il existe déjà (remplacement)
          if (result.files.single.path != null) {
            await File(result.files.single.path!).copy(newFilePath);
          } else if (result.files.single.bytes != null) {
            await File(newFilePath).writeAsBytes(result.files.single.bytes!);
          }
          setState(() {
            _fileName = relativePath;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier : $e')),
      );
    }
  }

  Future<void> _sendToBackend() async {
    final uri = widget.emploi == null
        ? Uri.parse("http://localhost:8004/api/emplois")
        : Uri.parse("http://localhost:8004/api/emplois/${widget.emploi!['id']}");

    final Map<String, dynamic> data = {
      'datePublication': _dateController.text,
      'classeId': int.parse(_classeIdController.text),
    };

    // Toujours renseigner le champ fichier, même si on édite sans changer le fichier
    if (_fileName != null && _fileName!.isNotEmpty) {
      data['fichier'] = _fileName;
    } else if (widget.emploi != null && widget.emploi!['fichier'] != null) {
      data['fichier'] = widget.emploi!['fichier'];
    }

    try {
      final response = await (widget.emploi == null
          ? http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data))
          : http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await widget.onSave();
        Navigator.of(context).pop();
      } else {
        throw Exception('Erreur HTTP {response.statusCode}: {response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.emploi == null ? 'Ajouter un emploi du temps' : 'Modifier l\'emploi du temps'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (AAAA-MM-JJ)'),
                validator: (value) => (value == null || value.isEmpty) ? 'Date requise' : null,
              ),
              TextFormField(
                controller: _classeIdController,
                decoration: const InputDecoration(labelText: 'ID Classe'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Classe requise' : null,
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Sélectionner un fichier'),
              ),
              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Fichier sélectionné: $_fileName'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _sendToBackend();
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
