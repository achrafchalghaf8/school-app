import 'package:flutter/material.dart';
import '../services/localization_service.dart';

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
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Dialog(
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
                    widget.teacher == null ? context.tr('teachers.add_teacher') : context.tr('teachers.edit_teacher'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: _emailController,
                    label: context.tr('teachers.form_email'),
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('teachers.validation_email_required');
                      }
                      return null;
                    },
                  ),
                  _buildFormField(
                    controller: _nomController,
                    label: context.tr('teachers.form_name'),
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('teachers.validation_name_required');
                      }
                      return null;
                    },
                  ),
                  if (widget.teacher == null)
                    _buildFormField(
                      controller: _passwordController,
                      label: context.tr('teachers.form_password'),
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.tr('teachers.validation_password_required');
                        }
                        if (value.length < 6) {
                          return context.tr('teachers.validation_password_length');
                        }
                        return null;
                      },
                    ),
                  _buildFormField(
                    controller: _specialiteController,
                    label: context.tr('teachers.form_specialty'),
                    icon: Icons.work,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('teachers.validation_specialty_required');
                      }
                      return null;
                    },
                  ),
                  _buildFormField(
                    controller: _telephoneController,
                    label: context.tr('teachers.form_phone'),
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('teachers.validation_phone_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${context.tr('teachers.assigned_classes')}:',
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
                        child: Text(context.tr('common.cancel')),
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
                        child: Text(context.tr('common.save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}