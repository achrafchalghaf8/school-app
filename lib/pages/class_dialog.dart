import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class ClassDialog extends StatefulWidget {
  final Map<String, dynamic>? classe;
  final Function(Map<String, dynamic>) onSave;
  final List<dynamic> enseignants;

  const ClassDialog({
    Key? key,
    this.classe,
    required this.onSave,
    required this.enseignants,
  }) : super(key: key);

  @override
  _ClassDialogState createState() => _ClassDialogState();
}

class _ClassDialogState extends State<ClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _niveauController;
  late List<int> _selectedEnseignants;

  @override
  void initState() {
    super.initState();
    _niveauController = TextEditingController(
        text: widget.classe?['niveau'] ?? '');
    
    // Initialiser les enseignants sélectionnés
    _selectedEnseignants = List<int>.from(widget.classe?['enseignantIds'] ?? []);
  }

  @override
  void dispose() {
    _niveauController.dispose();
    super.dispose();
  }

  void _toggleEnseignantSelection(int enseignantId) {
    setState(() {
      if (_selectedEnseignants.contains(enseignantId)) {
        _selectedEnseignants.remove(enseignantId);
      } else {
        _selectedEnseignants.add(enseignantId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => AlertDialog(
      title: Text(widget.classe == null ? context.tr('classes.add_class') : context.tr('classes.edit_class')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _niveauController,
                decoration: InputDecoration(labelText: context.tr('classes.form_level')),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr('classes.validation_level_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('${context.tr('classes.assigned_teachers')}:'),
              const SizedBox(height: 8),
              ...widget.enseignants.map((enseignant) {
                return CheckboxListTile(
                  title: Text(enseignant['nom'] ?? ''),
                  value: _selectedEnseignants.contains(enseignant['id']),
                  onChanged: (bool? value) {
                    _toggleEnseignantSelection(enseignant['id']);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(context.tr('common.cancel')),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(context.tr('common.save')),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newClasse = {
                'niveau': _niveauController.text,
                'enseignantIds': _selectedEnseignants,
              };
              if (widget.classe != null && widget.classe!['id'] != null) {
                newClasse['id'] = widget.classe!['id'];
              }
              widget.onSave(newClasse);
            }
          },
        ),
      ],
      ),
    );
  }
}