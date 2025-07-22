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
    if (widget.classes.isEmpty || widget.parents.isEmpty) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: Text(
          'Erreur',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Données manquantes pour les classes ou les parents',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(fontSize: 14)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    _selectedClassId ??= widget.classes.first['id'];
    _selectedParentId ??= widget.parents.first['id'];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.student == null ? 'Nouvel étudiant' : 'Modifier étudiant',
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactField(
                      controller: _nomController,
                      label: 'Nom',
                      icon: Icons.person,
                      validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactField(
                      controller: _prenomController,
                      label: 'Prénom',
                      icon: Icons.person_outline,
                      validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactDropdown(
                      value: _selectedClassId,
                      label: 'Classe',
                      icon: Icons.school,
                      items: widget.classes,
                      displayText: (item) => item['niveau'],
                      validator: (value) => value == null ? 'Sélection requise' : null,
                      onChanged: (value) => setState(() => _selectedClassId = value),
                    ),
                    const SizedBox(height: 12),
                    _buildCompactDropdown(
                      value: _selectedParentId,
                      label: 'Parent',
                      icon: Icons.family_restroom,
                      items: widget.parents,
                      displayText: (item) => '${item['nom']} (${item['email']})',
                      validator: (value) => value == null ? 'Sélection requise' : null,
                      onChanged: (value) => setState(() => _selectedParentId = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
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
                    onPressed: _submitForm,
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade900.withOpacity(0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: Icon(icon, size: 20, color: Colors.blue.shade900),
        isDense: true,
        filled: true,
        fillColor: Colors.blue.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildCompactDropdown({
    required int? value,
    required String label,
    required IconData icon,
    required List<dynamic> items,
    required String Function(dynamic) displayText,
    required String? Function(int?) validator,
    required void Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade900.withOpacity(0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        prefixIcon: Icon(icon, size: 20, color: Colors.blue.shade900),
        isDense: true,
        filled: true,
        fillColor: Colors.blue.shade50,
      ),
      items: items.map<DropdownMenuItem<int>>((item) {
        return DropdownMenuItem<int>(
          value: item['id'],
          child: Text(
            displayText(item),
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _submitForm() {
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
  }
}