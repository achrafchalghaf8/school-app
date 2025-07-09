import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text(widget.classe == null ? 'Ajouter une classe' : 'Modifier la classe'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _niveauController,
                decoration: const InputDecoration(labelText: 'Niveau'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un niveau';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Enseignants assignés:'),
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
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Enregistrer'),
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
    );
  }
}