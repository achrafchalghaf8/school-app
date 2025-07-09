import 'package:flutter/material.dart';

class WelcomeParentPage extends StatelessWidget {
  const WelcomeParentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Parent')),
      body: const Center(
        child: Text('Bienvenue Parent!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}