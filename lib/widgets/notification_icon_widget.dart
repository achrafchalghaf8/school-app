import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationIconWidget extends StatefulWidget {
  final VoidCallback? onTap;
  
  const NotificationIconWidget({Key? key, this.onTap}) : super(key: key);

  @override
  _NotificationIconWidgetState createState() => _NotificationIconWidgetState();
}

class _NotificationIconWidgetState extends State<NotificationIconWidget> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    print('🔔 [NOTIFICATION ICON] Chargement du compteur');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('userId') ?? 0;
      
      if (_userId > 0) {
        final count = await _notificationService.getUnreadNotificationCount(_userId);
        
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
        
        print('🔔 [NOTIFICATION ICON] Compteur mis à jour: $_unreadCount');
      }
    } catch (e) {
      print('❌ [NOTIFICATION ICON] Erreur: $e');
    }
  }

  /// Méthode publique pour rafraîchir le compteur depuis l'extérieur
  Future<void> refreshCount() async {
    print('🔄 [NOTIFICATION ICON] Rafraîchissement du compteur demandé');
    await _loadUnreadCount();
  }

  /// Méthode pour réinitialiser le compteur à 0 (quand toutes les notifications sont lues)
  void resetCount() {
    print('🔄 [NOTIFICATION ICON] Réinitialisation du compteur à 0');
    if (mounted) {
      setState(() {
        _unreadCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            print('🔔 [NOTIFICATION ICON] Icône cliquée');
            widget.onTap?.call();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
