import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initialise le service de notifications push
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('📱 [PUSH NOTIFICATIONS] Initialisation du service...');

    // Demander les permissions
    await _requestPermissions();

    // Configuration Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configuration générale
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialiser le plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('✅ [PUSH NOTIFICATIONS] Service initialisé avec succès');
  }

  /// Demande les permissions nécessaires
  Future<void> _requestPermissions() async {
    print('🔐 [PUSH NOTIFICATIONS] Demande des permissions...');

    // Vérifier si on est sur le web
    if (kIsWeb) {
      print('🔐 [PUSH NOTIFICATIONS] Plateforme Web - permissions automatiques');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Pour Android 13+ (API 33+)
        final status = await Permission.notification.request();
        print('🔐 [PUSH NOTIFICATIONS] Permission Android: $status');
      }

      if (Platform.isIOS) {
        // Pour iOS
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        print('🔐 [PUSH NOTIFICATIONS] Permission iOS: $result');
      }
    } catch (e) {
      print('🔐 [PUSH NOTIFICATIONS] Erreur permissions: $e');
    }
  }

  /// Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('👆 [PUSH NOTIFICATIONS] Notification tapée: ${notificationResponse.payload}');
    // Ici, vous pouvez naviguer vers une page spécifique
    // ou effectuer une action basée sur le payload
  }

  /// Affiche une notification de demande de récupération (pour le concierge)
  Future<void> showPickupRequestNotification({
    required String studentName,
    required String parentName,
  }) async {
    if (!_isInitialized) await initialize();

    print('📢 [PUSH NOTIFICATIONS] Affichage notification demande récupération');

    // Sur le web, on simule juste l'affichage
    if (kIsWeb) {
      print('🌐 [PUSH NOTIFICATIONS] Simulation notification web: $parentName souhaite récupérer $studentName');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pickup_requests',
      'Demandes de récupération',
      channelDescription: 'Notifications pour les demandes de récupération d\'enfants',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3), // Bleu
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🏫 Nouvelle demande de recuperation',
      '$parentName souhaite recuperer $studentName',
      platformChannelSpecifics,
      payload: 'pickup_request',
    );

    print('✅ [PUSH NOTIFICATIONS] Notification demande affichée');
  }

  /// Affiche une notification de réponse (pour le parent)
  Future<void> showPickupResponseNotification({
    required String studentName,
    required String status, // 'APPROVED' ou 'REJECTED'
    required String conciergeName,
  }) async {
    if (!_isInitialized) await initialize();

    print('📢 [PUSH NOTIFICATIONS] Affichage notification réponse');

    // Sur le web, on simule juste l'affichage
    if (kIsWeb) {
      final statusText = status == 'APPROVED' ? 'approuvée' : 'refusée';
      print('🌐 [PUSH NOTIFICATIONS] Simulation notification web: Demande $statusText pour $studentName par $conciergeName');
      return;
    }

    String title;
    String body;
    Color color;

    if (status == 'APPROVED') {
      title = '✅ Demande approuvée';
      body = 'Votre demande pour $studentName a été approuvée par $conciergeName. Vous pouvez venir récupérer votre enfant.';
      color = const Color(0xFF4CAF50); // Vert
    } else {
      title = '❌ Demande refusée';
      body = 'Votre demande pour $studentName a été refusée par $conciergeName.';
      color = const Color(0xFFF44336); // Rouge
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pickup_responses',
      'Réponses aux demandes',
      channelDescription: 'Notifications pour les réponses aux demandes de récupération',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: color,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: 'pickup_response_$status',
    );

    print('✅ [PUSH NOTIFICATIONS] Notification réponse affichée');
  }

  /// Affiche une notification générale
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    print('📢 [PUSH NOTIFICATIONS] Affichage notification générale: $title');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'general',
      'Notifications générales',
      channelDescription: 'Notifications générales de l\'application',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    print('✅ [PUSH NOTIFICATIONS] Notification générale affichée');
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ [PUSH NOTIFICATIONS] Toutes les notifications annulées');
  }

  /// Vérifie si les notifications sont autorisées
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) {
      return true; // Sur le web, on assume que c'est autorisé
    }

    try {
      if (Platform.isAndroid) {
        return await Permission.notification.isGranted;
      }
      return true; // Pour iOS, on assume que c'est autorisé après l'initialisation
    } catch (e) {
      print('🔐 [PUSH NOTIFICATIONS] Erreur vérification permissions: $e');
      return true; // Par défaut, on assume que c'est autorisé
    }
  }
}
