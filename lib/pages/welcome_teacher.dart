import 'package:flutter/material.dart';

class WelcomeTeacherPage extends StatelessWidget {
  const WelcomeTeacherPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Enseignant')),
      body: const Center(
        child: Text('Bienvenue Enseignant!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}