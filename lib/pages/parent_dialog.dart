import 'package:flutter/material.dart';

class ParentDialog extends StatefulWidget {
  final Map<String, dynamic>? parent;
  final Function(Map<String, dynamic>) onSave;

  const ParentDialog({
    Key? key,
    this.parent,
    required this.onSave,
  }) : super(key: key);

  @override
  _ParentDialogState createState() => _ParentDialogState();
}

class _ParentDialogState extends State<ParentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nomController;
  late TextEditingController _passwordController;
  late TextEditingController _telephoneController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
        text: widget.parent != null ? widget.parent!['email'] : '');
    _nomController = TextEditingController(
        text: widget.parent != null ? widget.parent!['nom'] : '');
    _passwordController = TextEditingController(
        text: widget.parent != null ? widget.parent!['password'] : '');
    _telephoneController = TextEditingController(
        text: widget.parent != null ? widget.parent!['telephone'] : '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomController.dispose();
    _passwordController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.parent == null ? 'Ajouter un parent' : 'Modifier le parent'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              final newParent = {
                'email': _emailController.text,
                'nom': _nomController.text,
                'password': _passwordController.text,
                'role': 'PARENT',
                'telephone': _telephoneController.text,
              };
              widget.onSave(newParent);
            }
          },
        ),
      ],
    );
  }
}