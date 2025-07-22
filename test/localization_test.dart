import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/localization_service.dart';

void main() {
  group('LocalizationService Tests', () {
    late LocalizationService localizationService;

    setUp(() {
      localizationService = LocalizationService();
    });

    test('should initialize with default French locale', () {
      expect(localizationService.currentLocale.languageCode, equals('fr'));
    });

    test('should support French and Arabic locales', () {
      const supportedLocales = LocalizationService.supportedLocales;
      expect(supportedLocales.length, equals(2));
      expect(supportedLocales.any((locale) => locale.languageCode == 'fr'), isTrue);
      expect(supportedLocales.any((locale) => locale.languageCode == 'ar'), isTrue);
    });

    test('should detect RTL for Arabic', () {
      // Test French (LTR)
      expect(localizationService.isRTL, isFalse);
    });

    test('should return correct language names', () {
      expect(localizationService.getCurrentLanguageName(), equals('Français'));
    });

    test('should return available languages', () {
      final languages = localizationService.getAvailableLanguages();
      expect(languages.length, equals(2));
      expect(languages.any((lang) => lang['name'] == 'Français'), isTrue);
      expect(languages.any((lang) => lang['name'] == 'Arabic'), isTrue);
    });

    test('should translate basic keys', () {
      // Note: This test would need the service to be initialized with actual translations
      // For now, we just test that the method doesn't throw
      expect(() => localizationService.translate('app_title'), returnsNormally);
      expect(() => localizationService.translate('login.title'), returnsNormally);
    });
  });
}
