import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'push_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final String baseUrl = 'http://localhost:8004/api/notifications';
  final PushNotificationService _pushService = PushNotificationService();

  /// Envoie une notification au parent quand le concierge répond à une demande
  Future<bool> sendPickupResponseNotification({
    required String studentName,
    required String parentName,
    required int parentId,
    required String status, // 'APPROVED' ou 'REJECTED'
    required String conciergeName,
  }) async {
    print('📢 [NOTIFICATION] Envoi notification au parent $parentName');

    try {
      String contenu;
      if (status == 'APPROVED') {
        contenu = 'Votre demande de recuperation pour $studentName a ete approuvee par $conciergeName. Vous pouvez venir recuperer votre enfant.';
      } else {
        contenu = 'Votre demande de recuperation pour $studentName a ete refusee par $conciergeName.';
      }

      final notification = {
        'contenu': contenu,
        'date': DateTime.now().toIso8601String(),
        'compteIds': [parentId], // Envoyer au parent concerné
      };

      print('📢 [NOTIFICATION] Contenu: $contenu');
      print('📢 [NOTIFICATION] Destinataire: Parent ID $parentId');

      // Enregistrer la notification dans l'API backend
      final success = await _saveNotificationToAPI(notification);

      if (success) {
        // Afficher la notification push native
        print('📱 [NOTIFICATION] Envoi notification push au parent...');
        await _pushService.showPickupResponseNotification(
          studentName: studentName,
          status: status,
          conciergeName: conciergeName,
        );

        print('✅ [NOTIFICATION] Notification envoyée avec succès (API + push)');
        log('Notification envoyée au parent $parentId: $contenu');
        return true;
      } else {
        // Fallback vers le stockage local en cas d'échec de l'API
        print('⚠️ [NOTIFICATION] Échec API, utilisation du stockage local');
        _addNotificationToLocalStorage(Map<String, dynamic>.from(notification), parentId);

        await _pushService.showPickupResponseNotification(
          studentName: studentName,
          status: status,
          conciergeName: conciergeName,
        );

        return true;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur lors de l\'envoi: $e');
      log('Erreur notification: $e');
      return false;
    }
  }

  /// Envoie une notification au concierge quand un parent fait une demande
  Future<bool> sendPickupRequestNotification({
    required String studentName,
    required String parentName,
    required int parentId,
  }) async {
    print('📢 [NOTIFICATION] Envoi notification aux concierges');

    try {
      final contenu = 'Nouvelle demande de récupération: $parentName souhaite récupérer $studentName.';

      // Récupérer tous les IDs des concierges (pour simplifier, on utilise un ID fixe)
      // Dans un vrai système, il faudrait récupérer tous les IDs des concierges
      final conciergeIds = await _getConciergeIds();

      final notification = {
        'contenu': contenu,
        'date': DateTime.now().toIso8601String(),
        'compteIds': conciergeIds,
      };

      print('📢 [NOTIFICATION] Contenu: $contenu');
      print('📢 [NOTIFICATION] Destinataires: Concierges $conciergeIds');

      // Enregistrer la notification dans l'API backend
      final success = await _saveNotificationToAPI(notification);

      if (success) {
        // Afficher la notification push native pour les concierges
        print('📱 [NOTIFICATION] Envoi notification push aux concierges...');
        await _pushService.showPickupRequestNotification(
          studentName: studentName,
          parentName: parentName,
        );

        print('✅ [NOTIFICATION] Notification envoyée aux concierges (API + push)');
        log('Notification envoyée aux concierges: $contenu');
        return true;
      } else {
        print('⚠️ [NOTIFICATION] Échec API, notification push uniquement');
        await _pushService.showPickupRequestNotification(
          studentName: studentName,
          parentName: parentName,
        );
        return true;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur lors de l\'envoi: $e');
      return false;
    }
  }

  /// Stockage local simulé des notifications (pour le développement)
  static final Map<int, List<Map<String, dynamic>>> _localNotifications = {};

  /// Enregistre une notification dans l'API backend
  Future<bool> _saveNotificationToAPI(Map<String, dynamic> notification) async {
    try {
      print('💾 [NOTIFICATION API] Envoi vers: $baseUrl');
      print('💾 [NOTIFICATION API] Données: $notification');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notification),
      );

      print('💾 [NOTIFICATION API] Status: ${response.statusCode}');
      print('💾 [NOTIFICATION API] Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [NOTIFICATION API] Notification enregistrée avec succès');
        return true;
      } else {
        print('❌ [NOTIFICATION API] Erreur HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ [NOTIFICATION API] Erreur réseau: $e');
      return false;
    }
  }

  /// Récupère les notifications pour un utilisateur depuis l'API
  Future<List<Map<String, dynamic>>> getNotificationsForUser(int userId) async {
    print('📱 [NOTIFICATION] Récupération notifications pour utilisateur $userId');

    try {
      // Essayer d'abord l'API backend
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allNotifications = jsonDecode(response.body);
        print('📱 [NOTIFICATION API] ${allNotifications.length} notifications récupérées de l\'API');

        // Filtrer les notifications pour cet utilisateur
        final userNotifications = allNotifications
            .where((notif) =>
                notif['compteIds'] != null &&
                (notif['compteIds'] as List).contains(userId))
            .map((notif) => Map<String, dynamic>.from(notif))
            .toList();

        // Trier par date (plus récentes en premier)
        userNotifications.sort((a, b) {
          final dateA = DateTime.parse(a['date']);
          final dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA);
        });

        print('📱 [NOTIFICATION API] ${userNotifications.length} notifications pour utilisateur $userId');
        return userNotifications;
      } else {
        print('⚠️ [NOTIFICATION API] Erreur HTTP: ${response.statusCode}, utilisation stockage local');
        return _getNotificationsFromLocalStorage(userId);
      }
    } catch (e) {
      print('❌ [NOTIFICATION API] Erreur: $e, utilisation stockage local');
      return _getNotificationsFromLocalStorage(userId);
    }
  }

  /// Récupère les notifications depuis le stockage local (fallback)
  List<Map<String, dynamic>> _getNotificationsFromLocalStorage(int userId) {
    final notifications = _localNotifications[userId] ?? [];

    // Trier par date (plus récentes en premier)
    notifications.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });

    print('📱 [NOTIFICATION LOCAL] ${notifications.length} notifications trouvées (stockage local)');
    return notifications;
  }

  /// Ajoute une notification au stockage local (pour le développement)
  void _addNotificationToLocalStorage(Map<String, dynamic> notification, int userId) {
    if (_localNotifications[userId] == null) {
      _localNotifications[userId] = [];
    }

    // Ajouter un ID unique et le statut non lu
    notification['id'] = DateTime.now().millisecondsSinceEpoch;
    notification['isRead'] = false;

    _localNotifications[userId]!.add(notification);
    print('📱 [NOTIFICATION] Notification ajoutée au stockage local pour utilisateur $userId');
  }

  /// Récupère les IDs des concierges (version simplifiée)
  Future<List<int>> _getConciergeIds() async {
    // Pour simplifier, on retourne un ID fixe de concierge
    // Dans un vrai système, il faudrait faire un appel API pour récupérer tous les concierges
    return [3]; // ID du concierge par défaut
  }

  /// Compte les notifications non lues pour un utilisateur
  Future<int> getUnreadNotificationCount(int userId) async {
    print('🔢 [NOTIFICATION] Comptage notifications non lues pour utilisateur $userId');

    try {
      final notifications = await getNotificationsForUser(userId);
      final unreadCount = notifications.where((notif) => notif['isRead'] != true).length;

      print('🔢 [NOTIFICATION] $unreadCount notifications non lues trouvées');
      return unreadCount;
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur comptage: $e');
      return 0;
    }
  }

  /// Crée une notification générale
  Future<bool> createGeneralNotification({
    required String contenu,
    required List<int> compteIds,
  }) async {
    print('📢 [NOTIFICATION] Création notification générale');

    try {
      final notification = {
        'contenu': contenu,
        'date': DateTime.now().toIso8601String(),
        'compteIds': compteIds,
      };

      print('📢 [NOTIFICATION] Contenu: $contenu');
      print('📢 [NOTIFICATION] Destinataires: $compteIds');

      // Enregistrer dans l'API backend
      final success = await _saveNotificationToAPI(notification);

      if (success) {
        print('✅ [NOTIFICATION] Notification générale créée avec succès');
        return true;
      } else {
        print('⚠️ [NOTIFICATION] Échec API, stockage local');
        // Fallback vers le stockage local pour chaque utilisateur
        for (int userId in compteIds) {
          _addNotificationToLocalStorage(Map<String, dynamic>.from(notification), userId);
        }
        return true;
      }
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur création notification: $e');
      return false;
    }
  }

  /// Marque une notification comme lue (stockage local uniquement pour le moment)
  Future<bool> markNotificationAsRead(int userId, int notificationId) async {
    try {
      final notifications = _localNotifications[userId] ?? [];

      for (var notification in notifications) {
        if (notification['id'] == notificationId) {
          notification['isRead'] = true;
          print('✅ [NOTIFICATION] Notification $notificationId marquée comme lue');
          return true;
        }
      }

      print('❌ [NOTIFICATION] Notification $notificationId non trouvée');
      return false;
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur marquage lu: $e');
      return false;
    }
  }

  /// Marque toutes les notifications comme lues pour un utilisateur (stockage local uniquement pour le moment)
  Future<bool> markAllNotificationsAsRead(int userId) async {
    try {
      final notifications = _localNotifications[userId] ?? [];

      for (var notification in notifications) {
        notification['isRead'] = true;
      }

      print('✅ [NOTIFICATION] Toutes les notifications marquées comme lues pour utilisateur $userId');
      return true;
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur marquage toutes lues: $e');
      return false;
    }
  }

  /// Marque toutes les notifications comme lues quand on ouvre la page (simulation de lecture)
  Future<bool> markAllAsReadOnView(int userId) async {
    print('👁️ [NOTIFICATION] Marquage automatique comme lues lors de la visualisation');
    return await markAllNotificationsAsRead(userId);
  }
}
