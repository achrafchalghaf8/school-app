import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../pages/admin_notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({Key? key}) : super(key: key);

  @override
  _NotificationTestWidgetState createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _notificationService.createGeneralNotification(
        contenu: 'Ceci est une notification de test envoyée le ${DateTime.now().toString().substring(0, 19)}',
        compteIds: [_currentUserId], // Envoyer à l'utilisateur actuel
      );

      if (success) {
        _showSuccessSnackbar('Notification de test envoyée avec succès !');
      } else {
        _showErrorSnackbar('Erreur lors de l\'envoi de la notification de test');
      }
    } catch (e) {
      print('❌ [TEST NOTIFICATION] Erreur: $e');
      _showErrorSnackbar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPickupTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _notificationService.sendPickupRequestNotification(
        studentName: 'Test Étudiant',
        parentName: 'Test Parent',
        parentId: _currentUserId,
      );

      if (success) {
        _showSuccessSnackbar('Notification de demande de récupération envoyée !');
      } else {
        _showErrorSnackbar('Erreur lors de l\'envoi de la notification de récupération');
      }
    } catch (e) {
      print('❌ [TEST PICKUP] Erreur: $e');
      _showErrorSnackbar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openAdminPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminNotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.purple.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Test des Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Utilisateur actuel: $_currentUserId',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Bouton pour notification générale
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotification,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'Envoyer notification test',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bouton pour notification de récupération
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendPickupTestNotification,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.child_care, color: Colors.white),
              label: const Text(
                'Test récupération enfant',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bouton pour page d'administration
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAdminPage,
              icon: Icon(Icons.admin_panel_settings, color: Colors.blue.shade700),
              label: Text(
                'Administration des notifications',
                style: TextStyle(color: Colors.blue.shade700),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les notifications sont enregistrées dans l\'API backend et visibles dans la page notifications.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
