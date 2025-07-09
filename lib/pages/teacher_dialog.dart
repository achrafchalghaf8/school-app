import 'package:flutter/material.dart';

class TeacherDialog extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  final Function(Map<String, dynamic>) onSave;
  final List<dynamic> classes;

  const TeacherDialog({
    Key? key,
    this.teacher,
    required this.onSave,
    required this.classes,
  }) : super(key: key);

  @override
  _TeacherDialogState createState() => _TeacherDialogState();
}

class _TeacherDialogState extends State<TeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nomController;
  late TextEditingController _passwordController;
  late TextEditingController _specialiteController;
  late TextEditingController _telephoneController;
  late List<int> _selectedClasses;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
        text: widget.teacher?['email'] ?? '');
    _nomController = TextEditingController(
        text: widget.teacher?['nom'] ?? '');
    _passwordController = TextEditingController(
        text: widget.teacher?['password'] ?? '');
    _specialiteController = TextEditingController(
        text: widget.teacher?['specialite'] ?? '');
    _telephoneController = TextEditingController(
        text: widget.teacher?['telephone'] ?? '');
    
    // Initialiser les classes sélectionnées
    _selectedClasses = List<int>.from(widget.teacher?['classeIds'] ?? []);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomController.dispose();
    _passwordController.dispose();
    _specialiteController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _toggleClassSelection(int classId) {
    setState(() {
      if (_selectedClasses.contains(classId)) {
        _selectedClasses.remove(classId);
      } else {
        _selectedClasses.add(classId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'Ajouter un enseignant' : 'Modifier l\'enseignant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              if (widget.teacher == null) // Only show password field for new teachers
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _specialiteController,
                decoration: const InputDecoration(labelText: 'Spécialité'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une spécialité';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Classes assignées:'),
              const SizedBox(height: 8),
              ...widget.classes.map((classItem) {
                return CheckboxListTile(
                  title: Text(classItem['niveau'] ?? ''),
                  value: _selectedClasses.contains(classItem['id']),
                  onChanged: (bool? value) {
                    _toggleClassSelection(classItem['id']);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Enregistrer'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newTeacher = {
                'email': _emailController.text,
                'nom': _nomController.text,
                if (widget.teacher == null) 'password': _passwordController.text,
                'role': 'ENSEIGNANT',
                'specialite': _specialiteController.text,
                'telephone': _telephoneController.text,
                'classeIds': _selectedClasses,
              };
              widget.onSave(newTeacher);
            }
          },
        ),
      ],
    );
  }
}