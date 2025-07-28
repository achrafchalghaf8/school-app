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
    final primaryColor = Colors.blue.shade900;
    final accentColor = Colors.blue.shade600;
    final backgroundColor = Colors.grey.shade50;

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => AlertDialog(
        title: Text(
          widget.classe == null ? context.tr('classes.add_class') : context.tr('classes.edit_class'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('classes.form_level'),
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _niveauController,
                  decoration: InputDecoration(
                    hintText: context.tr('classes.form_level_placeholder'),
                    hintStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade600),
                    ),
                  ),
                  style: TextStyle(color: primaryColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('classes.validation_level_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '${context.tr('classes.assigned_teachers')}:',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: widget.enseignants.map((enseignant) {
                      return CheckboxListTile(
                        title: Text(
                          enseignant['nom'] ?? '',
                          style: TextStyle(color: primaryColor),
                        ),
                        value: _selectedEnseignants.contains(enseignant['id']),
                        onChanged: (bool? value) {
                          _toggleEnseignantSelection(enseignant['id']);
                        },
                        activeColor: accentColor,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              context.tr('common.cancel'),
              style: TextStyle(color: primaryColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
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