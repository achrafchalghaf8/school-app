import 'package:flutter/material.dart';
import 'admin_drawer.dart';

class WelcomeAdminPage extends StatelessWidget {
  const WelcomeAdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'Espace Administrateur',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 8,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/notifications');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
        children: [
          _buildAdminCard(
            context,
            icon: Icons.class_,
            title: 'Classes',
            route: '/admin/classes',
          ),
          _buildAdminCard(
            context,
            icon: Icons.account_circle,
            title: 'Comptes',
            route: '/admin/accounts',
          ),
          _buildAdminCard(
            context,
            icon: Icons.school,
            title: 'Étudiants',
            route: '/admin/students',
          ),
          _buildAdminCard(
            context,
            icon: Icons.assignment,
            title: 'Exercices',
            route: '/admin/exercises',
          ),
          _buildAdminCard(
            context,
            icon: Icons.book,
            title: 'Cours',
            route: '/admin/courses',
          ),
          _buildAdminCard(
            context,
            icon: Icons.person,
            title: 'Enseignants',
            route: '/admin/teachers',
          ),
          _buildAdminCard(
            context,
            icon: Icons.family_restroom,
            title: 'Parents',
            route: '/admin/parents',
          ),
          _buildAdminCard(
            context,
            icon: Icons.calendar_today,
            title: 'Emploi du temps',
            route: '/admin/schedule',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        highlightColor: Colors.blue.shade900.withOpacity(0.1),
        splashColor: Colors.blue.shade900.withOpacity(0.2),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.blue.shade900,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}