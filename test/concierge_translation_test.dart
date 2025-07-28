import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flutter_application_1/services/localization_service.dart';
import 'package:flutter_application_1/pages/welcome_concierge_page.dart';

// Générer les mocks
@GenerateMocks([WebSocketService, SharedPreferences])
import 'concierge_translation_test.mocks.dart';

void main() {
  group('Concierge Page Translation Tests', () {
    late LocalizationService localizationService;
    late MockWebSocketService mockWebSocketService;
    late MockSharedPreferences mockSharedPreferences;

    setUpAll(() async {
      // Initialiser les mocks
      mockWebSocketService = MockWebSocketService();
      mockSharedPreferences = MockSharedPreferences();
      
      // Configuration des mocks
      when(mockSharedPreferences.getString('userName')).thenReturn('Test Concierge');
      when(mockWebSocketService.getStoredPickupRequests()).thenAnswer((_) async => []);
      when(mockWebSocketService.connect()).thenAnswer((_) async {});
      when(mockWebSocketService.isConnected).thenReturn(true);
    });

    setUp(() async {
      // Initialiser le service de localisation
      localizationService = LocalizationService();
      await localizationService.initialize();
    });

    testWidgets('Page displays French translations by default', (WidgetTester tester) async {
      // Arranger
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeConciergePage(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('ar', 'SA'),
          ],
        ),
      );

      // Attendre que le widget soit construit
      await tester.pumpAndSettle();

      // Vérifier que les textes français sont affichés
      expect(find.textContaining('Bienvenue'), findsOneWidget);
      expect(find.textContaining('Demandes de récupération'), findsOneWidget);
      expect(find.textContaining('Aucune demande de récupération'), findsOneWidget);
    });

    testWidgets('Page displays Arabic translations when language is changed', (WidgetTester tester) async {
      // Arranger - Changer la langue en arabe
      await localizationService.changeLanguage(const Locale('ar', 'SA'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeConciergePage(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('ar', 'SA'),
          ],
        ),
      );

      // Attendre que le widget soit construit
      await tester.pumpAndSettle();

      // Vérifier que les textes arabes sont affichés
      expect(find.textContaining('مرحباً'), findsOneWidget);
      expect(find.textContaining('طلبات الاستلام'), findsOneWidget);
      expect(find.textContaining('لا توجد طلبات استلام'), findsOneWidget);
    });

    test('Translation keys exist in French file', () async {
      // Charger le fichier de traduction français
      final String jsonString = await rootBundle.loadString('assets/translations/fr.json');
      final Map<String, dynamic> translations = json.decode(jsonString);

      // Vérifier que les clés de traduction existent
      expect(translations['concierge'], isNotNull);
      expect(translations['concierge']['welcome'], isNotNull);
      expect(translations['concierge']['pickup_requests'], isNotNull);
      expect(translations['concierge']['no_requests'], isNotNull);
      expect(translations['concierge']['status']['pending'], isNotNull);
      expect(translations['concierge']['status']['approved'], isNotNull);
      expect(translations['concierge']['status']['rejected'], isNotNull);
    });

    test('Translation keys exist in Arabic file', () async {
      // Charger le fichier de traduction arabe
      final String jsonString = await rootBundle.loadString('assets/translations/ar.json');
      final Map<String, dynamic> translations = json.decode(jsonString);

      // Vérifier que les clés de traduction existent
      expect(translations['concierge'], isNotNull);
      expect(translations['concierge']['welcome'], isNotNull);
      expect(translations['concierge']['pickup_requests'], isNotNull);
      expect(translations['concierge']['no_requests'], isNotNull);
      expect(translations['concierge']['status']['pending'], isNotNull);
      expect(translations['concierge']['status']['approved'], isNotNull);
      expect(translations['concierge']['status']['rejected'], isNotNull);
    });

    test('LocalizationService translates concierge keys correctly', () {
      // Tester les traductions françaises
      expect(localizationService.translate('concierge.welcome'), isNotNull);
      expect(localizationService.translate('concierge.pickup_requests'), isNotNull);
      expect(localizationService.translate('concierge.no_requests'), isNotNull);
      expect(localizationService.translate('concierge.status.pending'), isNotNull);
      expect(localizationService.translate('concierge.status.approved'), isNotNull);
      expect(localizationService.translate('concierge.status.rejected'), isNotNull);
    });
  });
} 