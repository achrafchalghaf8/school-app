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
    _emailController = TextEditingController(text: widget.teacher?['email'] ?? '');
    _nomController = TextEditingController(text: widget.teacher?['nom'] ?? '');
    _passwordController = TextEditingController(text: widget.teacher?['password'] ?? '');
    _specialiteController = TextEditingController(text: widget.teacher?['specialite'] ?? '');
    _telephoneController = TextEditingController(text: widget.teacher?['telephone'] ?? '');
    
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FormFieldValidator<String>? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacher == null ? 'Ajouter un enseignant' : 'Modifier l\'enseignant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un email';
                      }
                      return null;
                    },
                  ),
                  _buildFormField(
                    controller: _nomController,
                    label: 'Nom',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  ),
                  if (widget.teacher == null)
                    _buildFormField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock,
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
                  _buildFormField(
                    controller: _specialiteController,
                    label: 'Spécialité',
                    icon: Icons.work,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une spécialité';
                      }
                      return null;
                    },
                  ),
                  _buildFormField(
                    controller: _telephoneController,
                    label: 'Téléphone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un numéro de téléphone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Classes assignées:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.classes.map((classItem) {
                          return CheckboxListTile(
                            title: Text(
                              classItem['niveau'] ?? '',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                            value: _selectedClasses.contains(classItem['id']),
                            onChanged: (bool? value) => _toggleClassSelection(classItem['id']),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}