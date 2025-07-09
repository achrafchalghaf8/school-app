import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu Administrateur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.dashboard,
            title: 'Tableau de bord',
            route: '/admin/dashboard',
          ),
          _buildListTile(
            context,
            icon: Icons.account_circle,
            title: 'Comptes',
            route: '/admin/accounts',
          ),
          _buildListTile(
            context,
            icon: Icons.admin_panel_settings,
            title: 'Administrateurs',
            route: '/admin/administrators',
          ),
          _buildListTile(
            context,
            icon: Icons.school,
            title: 'Étudiants',
            route: '/admin/students',
          ),
          _buildListTile(
            context,
            icon: Icons.person,
            title: 'Enseignants',
            route: '/admin/teachers',
          ),
          _buildListTile(
            context,
            icon: Icons.family_restroom,
            title: 'Parents',
            route: '/admin/parents',
          ),
          _buildListTile(
            context,
            icon: Icons.class_,
            title: 'Classes',
            route: '/admin/classes',
          ),
          _buildListTile(
            context,
            icon: Icons.book,
            title: 'Cours',
            route: '/admin/courses',
          ),
          _buildListTile(
            context,
            icon: Icons.assignment,
            title: 'Exercices',
            route: '/admin/exercises',
          ),
          _buildListTile(
            context,
            icon: Icons.calendar_today,
            title: 'Emploi du temps',
            route: '/admin/schedule',
          ),
          _buildListTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            route: '/admin/notifications',
          ),
          _buildListTile(
            context,
            icon: Icons.settings,
            title: 'Paramètres',
            route: '/admin/settings',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Déconnexion'),
            onTap: () {
              // Ajoutez ici la logique de déconnexion
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context,
      {required IconData icon, required String title, required String route}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}