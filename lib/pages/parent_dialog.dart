import 'package:flutter/material.dart';
import '../services/localization_service.dart';

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
    final primaryColor = Colors.blue.shade900;
    final accentColor = Colors.blue.shade600;
    final backgroundColor = Colors.grey.shade50;

    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => AlertDialog(
        title: Text(
          widget.parent == null ? context.tr('parents.add_parent') : context.tr('parents.edit_parent'),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: context.tr('parents.form_email'),
                    labelStyle: TextStyle(color: primaryColor),
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
                      return context.tr('parents.validation_email_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: context.tr('parents.form_name'),
                    labelStyle: TextStyle(color: primaryColor),
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
                      return context.tr('parents.validation_name_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: context.tr('parents.form_password'),
                    labelStyle: TextStyle(color: primaryColor),
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
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('parents.validation_password_required');
                    }
                    if (value.length < 6) {
                      return context.tr('parents.validation_password_length');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  decoration: InputDecoration(
                    labelText: context.tr('parents.form_phone'),
                    labelStyle: TextStyle(color: primaryColor),
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
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('parents.validation_phone_required');
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
      ),
    );
  }
}