import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class WelcomeAdminPage extends StatelessWidget {
  const WelcomeAdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Administrateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/notifications');
            },
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(
            context,
            icon: Icons.class_,
            title: 'Classes',
            route: '/admin/classes',
            color: Colors.blue,
          ),
          _buildAdminCard(
            context,
            icon: Icons.account_circle,
            title: 'Comptes',
            route: '/admin/accounts',
            color: Colors.green,
          ),
          _buildAdminCard(
            context,
            icon: Icons.school,
            title: 'Étudiants',
            route: '/admin/students',
            color: Colors.orange,
          ),
          _buildAdminCard(
            context,
            icon: Icons.assignment,
            title: 'Exercices',
            route: '/admin/exercises',
            color: Colors.purple,
          ),
          _buildAdminCard(
            context,
            icon: Icons.book,
            title: 'Cours',
            route: '/admin/courses',
            color: Colors.red,
          ),
          _buildAdminCard(
            context,
            icon: Icons.person,
            title: 'Enseignants',
            route: '/admin/teachers',
            color: Colors.teal,
          ),
          _buildAdminCard(
            context,
            icon: Icons.family_restroom,
            title: 'Parents',
            route: '/admin/parents',
            color: Colors.indigo,
          ),
          _buildAdminCard(
            context,
            icon: Icons.calendar_today,
            title: 'Emploi du temps',
            route: '/admin/schedule',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context,
      {required IconData icon, required String title, required String route, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: color.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}