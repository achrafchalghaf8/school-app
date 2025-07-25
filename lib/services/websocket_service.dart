import 'dart:convert';
import 'dart:developer';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';

// Stockage global simulé pour les demandes de récupération
class GlobalPickupStorage {
  static final List<Map<String, dynamic>> _requests = [];

  static void addRequest(Map<String, dynamic> request) {
    _requests.add(request);
    print('🌍 [GLOBAL STORAGE] Demande ajoutée. Total: ${_requests.length}');
  }

  static List<Map<String, dynamic>> getAllRequests() {
    print('🌍 [GLOBAL STORAGE] Récupération de ${_requests.length} demandes');
    return List.from(_requests);
  }

  static void updateRequest(String requestId, String status, String conciergeName) {
    for (int i = 0; i < _requests.length; i++) {
      if (_requests[i]['id'] == requestId) {
        _requests[i]['status'] = status;
        _requests[i]['conciergeName'] = conciergeName;
        _requests[i]['responseTimestamp'] = DateTime.now().toIso8601String();
        print('🌍 [GLOBAL STORAGE] Demande $requestId mise à jour: $status');
        break;
      }
    }
  }
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  String? _userEmail;
  String? _userPassword;
  int? _userId;
  final http.Client _httpClient = http.Client();
  String? _userRole;
  final NotificationService _notificationService = NotificationService();

  // Callbacks pour les notifications
  Function(Map<String, dynamic>)? onPickupRequestReceived;
  Function(Map<String, dynamic>)? onPickupResponseReceived;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('userEmail');
    _userPassword = prefs.getString('userPassword');
    _userId = prefs.getInt('userId');
    _userRole = prefs.getString('userRole');
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _storePickupRequestLocally(Map<String, dynamic> request) async {
    print('💾 [STORAGE] Début stockage global');

    // Ajouter la nouvelle demande avec un ID unique
    request['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    request['status'] = 'PENDING';
    print('💾 [STORAGE] ID généré: ${request['id']}');
    print('💾 [STORAGE] Status: ${request['status']}');

    // Utiliser le stockage global
    GlobalPickupStorage.addRequest(Map<String, dynamic>.from(request));
    print('✅ [STORAGE] Sauvegarde globale terminée');

    log('Demande stockée globalement avec ID: ${request['id']}');
  }

  Future<List<Map<String, dynamic>>> getStoredPickupRequests() async {
    print('🔍 [CONCIERGE] Début récupération des demandes');

    // Utiliser le stockage global
    List<Map<String, dynamic>> requests = GlobalPickupStorage.getAllRequests();

    print('🔍 [CONCIERGE] Demandes trouvées dans le stockage global: ${requests.length}');
    log('Nombre de demandes stockées globalement: ${requests.length}');

    for (var request in requests) {
      print('🔍 [CONCIERGE] Demande: ${request['studentName']} - Status: ${request['status']} - ID: ${request['id']}');
      log('Demande trouvée: ${request['studentName']} - Status: ${request['status']}');
    }

    print('🔍 [CONCIERGE] Total demandes retournées: ${requests.length}');
    return requests;
  }

  Future<void> updatePickupRequestStatus(String requestId, String status, String conciergeName) async {
    print('🔄 [UPDATE] Mise à jour demande $requestId -> $status');

    // Récupérer les détails de la demande avant mise à jour
    final requests = GlobalPickupStorage.getAllRequests();
    final request = requests.firstWhere((r) => r['id'] == requestId, orElse: () => {});

    if (request.isNotEmpty) {
      // Utiliser le stockage global
      GlobalPickupStorage.updateRequest(requestId, status, conciergeName);

      // Envoyer notification au parent
      print('📢 [CONCIERGE] Envoi notification au parent...');
      await _notificationService.sendPickupResponseNotification(
        studentName: request['studentName'] ?? 'Étudiant',
        parentName: request['parentName'] ?? 'Parent',
        parentId: request['parentId'] ?? 0,
        status: status,
        conciergeName: conciergeName,
      );

      log('Demande mise à jour: $requestId -> $status');
    } else {
      print('❌ [UPDATE] Demande $requestId non trouvée');
    }
  }

  Future<bool> connect() async {
    if (_isConnected) return true;

    try {
      await initialize();

      if (_userEmail == null || _userPassword == null) {
        log('WebSocket: Informations d\'authentification manquantes');
        // Pour l'instant, simulons une connexion réussie
        _isConnected = true;
        return true;
      }

      // Désactiver temporairement WebSocket et simuler une connexion
      log('WebSocket temporairement désactivé - simulation de connexion réussie');
      _isConnected = true;
      return true;

      /* Code WebSocket désactivé temporairement
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: 'http://localhost:8004/ws',
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onError,
          onWebSocketError: _onWebSocketError,
        ),
      );

      _stompClient!.activate();

      // Attendre un peu pour la connexion
      await Future.delayed(const Duration(seconds: 2));

      return _isConnected;
      */
    } catch (e) {
      log('Erreur lors de la connexion WebSocket: $e');
      return false;
    }
  }

  void _onConnect(StompFrame frame) {
    log('WebSocket connecté avec succès');
    _isConnected = true;
    _authenticateAndSubscribe();
  }

  void _authenticateAndSubscribe() {
    if (!_isConnected || _stompClient == null) return;

    // Envoyer les informations d'authentification
    if (_userEmail != null && _userPassword != null) {
      final loginRequest = {
        'email': _userEmail!,
        'password': _userPassword!,
      };

      _stompClient!.send(
        destination: '/app/auth/login',
        body: json.encode(loginRequest),
      );

      // Attendre un peu puis s'abonner aux canaux
      Future.delayed(const Duration(milliseconds: 500), () {
        _subscribeToChannels();
      });
    } else {
      _subscribeToChannels();
    }
  }

  void _onDisconnect(StompFrame frame) {
    log('WebSocket déconnecté');
    _isConnected = false;
  }

  void _onError(StompFrame frame) {
    log('Erreur STOMP: ${frame.body}');
  }

  void _onWebSocketError(dynamic error) {
    log('Erreur WebSocket: $error');
  }

  void _subscribeToChannels() {
    if (!_isConnected || _stompClient == null) return;

    // S'abonner aux notifications selon le rôle
    if (_userRole == 'CONCIERGE') {
      // Les concierges reçoivent toutes les demandes de récupération
      _stompClient!.subscribe(
        destination: '/topic/pickup-requests',
        callback: (StompFrame frame) {
          if (frame.body != null) {
            try {
              final data = json.decode(frame.body!);
              log('Demande de récupération reçue: $data');
              onPickupRequestReceived?.call(data);
            } catch (e) {
              log('Erreur lors du parsing de la demande: $e');
            }
          }
        },
      );
    } else if (_userRole == 'PARENT') {
      // Les parents reçoivent les réponses à leurs demandes
      _stompClient!.subscribe(
        destination: '/user/queue/pickup-responses',
        callback: (StompFrame frame) {
          if (frame.body != null) {
            try {
              final data = json.decode(frame.body!);
              log('Réponse de récupération reçue: $data');
              onPickupResponseReceived?.call(data);
            } catch (e) {
              log('Erreur lors du parsing de la réponse: $e');
            }
          }
        },
      );
    }
  }

  Future<bool> sendPickupRequest({
    required int studentId,
    required String studentName,
    required String parentName,
    String? reason,
  }) async {
    print('🚀 [PARENT] Début envoi demande de récupération');
    print('🚀 [PARENT] Étudiant: $studentName (ID: $studentId)');
    print('🚀 [PARENT] Parent: $parentName');
    print('🚀 [PARENT] Service connecté: $_isConnected');

    if (!_isConnected) {
      print('❌ [PARENT] Service non connecté - abandon');
      log('Service non connecté');
      return false;
    }

    try {
      final request = {
        'studentId': studentId,
        'studentName': studentName,
        'parentId': _userId,
        'parentName': parentName,
        'reason': reason ?? 'Demande de récupération',
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('📝 [PARENT] Données de la demande: $request');

      // Stocker la demande localement
      print('💾 [PARENT] Stockage local en cours...');
      await _storePickupRequestLocally(request);

      // Envoyer notification au concierge
      print('📢 [PARENT] Envoi notification au concierge...');
      await _notificationService.sendPickupRequestNotification(
        studentName: studentName,
        parentName: parentName,
        parentId: _userId ?? 0,
      );

      print('✅ [PARENT] Demande stockée avec succès !');
      log('Demande de récupération stockée localement: $request');
      return true;
    } catch (e) {
      print('❌ [PARENT] Erreur lors du stockage: $e');
      log('Erreur lors de l\'envoi de la demande: $e');
      return false;
    }
  }

  Future<bool> sendPickupResponse({
    required String requestId,
    required String response,
    required String conciergeName,
  }) async {
    if (!_isConnected || _stompClient == null) {
      log('WebSocket non connecté');
      return false;
    }

    try {
      final responseData = {
        'type': 'PICKUP_RESPONSE',
        'requestId': requestId,
        'response': response,
        'conciergeId': _userId,
        'conciergeName': conciergeName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _stompClient!.send(
        destination: '/app/pickup/response',
        body: json.encode(responseData),
      );

      log('Réponse de récupération envoyée: $responseData');
      return true;
    } catch (e) {
      log('Erreur lors de l\'envoi de la réponse: $e');
      return false;
    }
  }

  void disconnect() {
    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
    }
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    onPickupRequestReceived = null;
    onPickupResponseReceived = null;
  }
}
