import 'dart:convert';
import 'dart:io';

/// Script de test pour vérifier l'API des notifications
void main() async {
  print('🧪 [TEST] Démarrage des tests de l\'API notifications');
  
  final client = HttpClient();
  final baseUrl = 'localhost:8004';
  final apiPath = '/api/notifications';
  
  try {
    // Test 1: Récupérer toutes les notifications
    print('\n📋 [TEST 1] Récupération de toutes les notifications...');
    await testGetAllNotifications(client, baseUrl, apiPath);
    
    // Test 2: Créer une nouvelle notification
    print('\n📝 [TEST 2] Création d\'une nouvelle notification...');
    await testCreateNotification(client, baseUrl, apiPath);
    
    // Test 3: Vérifier que la notification a été créée
    print('\n🔍 [TEST 3] Vérification de la création...');
    await testGetAllNotifications(client, baseUrl, apiPath);
    
    print('\n✅ [TEST] Tous les tests terminés avec succès !');
    
  } catch (e) {
    print('\n❌ [TEST] Erreur lors des tests: $e');
  } finally {
    client.close();
  }
}

Future<void> testGetAllNotifications(HttpClient client, String baseUrl, String apiPath) async {
  try {
    final request = await client.get(baseUrl, 8004, apiPath);
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 [GET] Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final List<dynamic> notifications = jsonDecode(responseBody);
      print('📊 [GET] ${notifications.length} notifications trouvées');
      
      for (int i = 0; i < notifications.length && i < 3; i++) {
        final notif = notifications[i];
        print('   - ID: ${notif['id']}, Contenu: "${notif['contenu']?.substring(0, 50)}..."');
      }
      
      if (notifications.length > 3) {
        print('   ... et ${notifications.length - 3} autres notifications');
      }
    } else {
      print('❌ [GET] Erreur HTTP: ${response.statusCode}');
      print('❌ [GET] Response: $responseBody');
    }
  } catch (e) {
    print('❌ [GET] Erreur: $e');
  }
}

Future<void> testCreateNotification(HttpClient client, String baseUrl, String apiPath) async {
  try {
    final notification = {
      'contenu': 'Test de notification créée le ${DateTime.now().toString().substring(0, 19)} - Système de notifications fonctionnel !',
      'date': DateTime.now().toIso8601String(),
      'compteIds': [1, 2, 3, 4], // Envoyer à plusieurs utilisateurs
    };
    
    final request = await client.post(baseUrl, 8004, apiPath);
    request.headers.set('Content-Type', 'application/json');
    
    final jsonData = jsonEncode(notification);
    request.write(jsonData);
    
    print('📤 [POST] Envoi de la notification...');
    print('📤 [POST] Données: ${notification['contenu']}');
    print('📤 [POST] Destinataires: ${notification['compteIds']}');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📤 [POST] Status: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ [POST] Notification créée avec succès !');
      if (responseBody.isNotEmpty) {
        try {
          final responseData = jsonDecode(responseBody);
          print('✅ [POST] ID de la nouvelle notification: ${responseData['id']}');
        } catch (e) {
          print('✅ [POST] Response: $responseBody');
        }
      }
    } else {
      print('❌ [POST] Erreur HTTP: ${response.statusCode}');
      print('❌ [POST] Response: $responseBody');
    }
  } catch (e) {
    print('❌ [POST] Erreur: $e');
  }
}
