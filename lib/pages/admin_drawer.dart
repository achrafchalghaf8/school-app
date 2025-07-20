import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 8.0,
      child: Container(
        color: Colors.blue.shade900.withOpacity(0.95),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            ..._buildMenuItems(context),
            const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
            _buildLogoutTile(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade800,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Menu Administrateur',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gestion du Système',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final menuItems = [
      {'icon': Icons.dashboard, 'title': 'Tableau de bord', 'route': '/admin/dashboard'},
      {'icon': Icons.account_circle, 'title': 'Comptes', 'route': '/admin/accounts'},
      {'icon': Icons.admin_panel_settings, 'title': 'Administrateurs', 'route': '/admin/administrators'},
      {'icon': Icons.school, 'title': 'Étudiants', 'route': '/admin/students'},
      {'icon': Icons.person, 'title': 'Enseignants', 'route': '/admin/teachers'},
      {'icon': Icons.family_restroom, 'title': 'Parents', 'route': '/admin/parents'},
      {'icon': Icons.class_, 'title': 'Classes', 'route': '/admin/classes'},
      {'icon': Icons.book, 'title': 'Cours', 'route': '/admin/courses'},
      {'icon': Icons.assignment, 'title': 'Exercices', 'route': '/admin/exercises'},
      {'icon': Icons.calendar_today, 'title': 'Emploi du temps', 'route': '/admin/schedule'},
      {'icon': Icons.notifications, 'title': 'Notifications', 'route': '/admin/notifications'},
      {'icon': Icons.settings, 'title': 'Paramètres', 'route': '/admin/settings'},
    ];

    return menuItems
        .asMap()
        .entries
        .map((entry) => _buildListTile(
              context,
              icon: entry.value['icon'] as IconData,
              title: entry.value['title'] as String,
              route: entry.value['route'] as String,
              index: entry.key,
            ))
        .toList();
  }

  Widget _buildListTile(BuildContext context,
      {required IconData icon, required String title, required String route, required int index}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Afficher une boîte de dialogue de confirmation
            bool confirmLogout = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmation'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Annuler'),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    TextButton(
                      child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                );
              },
            ) ?? false;

            if (confirmLogout) {
              // Supprimer les données du local storage
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Naviguer vers la page de login et supprimer toutes les routes précédentes
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (Route<dynamic> route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.exit_to_app,
                  color: Colors.redAccent,
                  size: 24,
                ),
                SizedBox(width: 16),
                Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}