import 'package:flutter/material.dart';

class StudentDialog extends StatefulWidget {
  final Map<String, dynamic>? student;
  final List<dynamic> classes;
  final List<dynamic> parents;
  final Function(Map<String, dynamic>) onSave;

  const StudentDialog({
    Key? key,
    this.student,
    required this.classes,
    required this.parents,
    required this.onSave,
  }) : super(key: key);

  @override
  _StudentDialogState createState() => _StudentDialogState();
}

class _StudentDialogState extends State<StudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  int? _selectedClassId;
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(
        text: widget.student != null ? widget.student!['nom'] : '');
    _prenomController = TextEditingController(
        text: widget.student != null ? widget.student!['prenom'] : '');
    _selectedClassId = widget.student != null ? widget.student!['classeId'] : null;
    _selectedParentId = widget.student != null ? widget.student!['parentId'] : null;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier que les listes ne sont pas vides
    if (widget.classes.isEmpty || widget.parents.isEmpty) {
      return AlertDialog(
        title: Text('Erreur'),
        content: Text('Données manquantes pour les classes ou les parents'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    // Initialiser les valeurs si elles sont null
    _selectedClassId ??= widget.classes.first['id'];
    _selectedParentId ??= widget.parents.first['id'];

    return AlertDialog(
      title: Text(widget.student == null ? 'Ajouter un étudiant' : 'Modifier l\'étudiant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prénom';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedClassId,
                decoration: InputDecoration(labelText: 'Classe'),
                items: widget.classes.map<DropdownMenuItem<int>>((classe) {
                  return DropdownMenuItem<int>(
                    value: classe['id'],
                    child: Text(classe['niveau']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une classe';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedParentId,
                decoration: InputDecoration(labelText: 'Parent'),
                items: widget.parents.map<DropdownMenuItem<int>>((parent) {
                  return DropdownMenuItem<int>(
                    value: parent['id'],
                    child: Text('${parent['nom']} (${parent['email']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedParentId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner un parent';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Enregistrer'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newStudent = {
                'nom': _nomController.text,
                'prenom': _prenomController.text,
                'classeId': _selectedClassId,
                'parentId': _selectedParentId,
              };
              if (widget.student != null) {
                newStudent['id'] = widget.student!['id'];
              }
              widget.onSave(newStudent);
            }
          },
        ),
      ],
    );
  }
}