import 'package:flutter/material.dart';
import 'admin_drawer.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class WelcomeAdminPage extends StatelessWidget {
  const WelcomeAdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          context.tr('admin.welcome'),
          style: const TextStyle(
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
            icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/notifications');
            },
            tooltip: 'Notifications',
          ),
          const LanguageSelector(),
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
            title: context.tr('admin.classes'),
            route: '/admin/classes',
          ),
          _buildAdminCard(
            context,
            icon: Icons.security,
            title: context.tr('admin.concierges'),
            route: '/admin/accounts',
          ),
          _buildAdminCard(
            context,
            icon: Icons.school,
            title: context.tr('admin.students'),
            route: '/admin/students',
          ),
          _buildAdminCard(
            context,
            icon: Icons.assignment,
            title: context.tr('admin.exercises'),
            route: '/admin/exercises',
          ),
          _buildAdminCard(
            context,
            icon: Icons.book,
            title: context.tr('admin.courses'),
            route: '/admin/courses',
          ),
          _buildAdminCard(
            context,
            icon: Icons.person,
            title: context.tr('admin.teachers'),
            route: '/admin/teachers',
          ),
          _buildAdminCard(
            context,
            icon: Icons.family_restroom,
            title: context.tr('admin.parents'),
            route: '/admin/parents',
          ),
          _buildAdminCard(
            context,
            icon: Icons.calendar_today,
            title: context.tr('admin.schedule'),
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