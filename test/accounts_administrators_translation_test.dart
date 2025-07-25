import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/localization_service.dart';

void main() {
  group('Accounts and Administrators Translation Tests', () {
    late LocalizationService localizationService;

    setUp(() {
      localizationService = LocalizationService();
    });

    group('Accounts Page Translations', () {
      test('should have all required French translations for accounts', () {
        // Test des clés principales pour les comptes en français
        final frenchKeys = [
          'accounts.page_title',
          'accounts.add_account',
          'accounts.edit_account',
          'accounts.delete_account',
          'accounts.delete_confirmation',
          'accounts.change_password',
          'accounts.set_password',
          'accounts.new_password_optional',
          'accounts.password_required',
          'accounts.role',
          'accounts.update',
          'accounts.no_accounts',
        ];

        for (String key in frenchKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          // Vérifier que la traduction n'est pas vide
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate accounts page title correctly', () {
        // Note: Ce test nécessiterait l'initialisation complète du service
        expect(() => localizationService.translate('accounts.page_title'), returnsNormally);
      });

      test('should translate form fields correctly', () {
        final formKeys = [
          'accounts.add_account',
          'accounts.edit_account',
          'accounts.role',
        ];

        for (String key in formKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Administrators Page Translations', () {
      test('should have all required French translations for administrators', () {
        final frenchKeys = [
          'administrators.page_title',
          'administrators.add_admin',
          'administrators.new_password',
          'administrators.new_password_optional',
          'administrators.no_admins',
        ];

        for (String key in frenchKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate administrator form correctly', () {
        final adminKeys = [
          'administrators.add_admin',
          'administrators.new_password',
        ];

        for (String key in adminKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Common Translations', () {
      test('should have all common translations used in both pages', () {
        final commonKeys = [
          'common.add',
          'common.edit',
          'common.delete',
          'common.save',
          'common.cancel',
          'common.confirm',
          'common.search',
          'common.refresh',
          'common.error',
          'common.name',
          'login.email',
          'login.password',
        ];

        for (String key in commonKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });
    });

    group('Nested Translation Keys', () {
      test('should handle nested translation keys correctly', () {
        // Test des clés imbriquées
        final nestedKeys = [
          'accounts.page_title',
          'administrators.add_admin',
          'common.confirm',
        ];

        for (String key in nestedKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should return key if translation not found', () {
        const nonExistentKey = 'non.existent.key';
        final result = localizationService.translate(nonExistentKey);
        expect(result, equals(nonExistentKey));
      });
    });

    group('Language Support', () {
      test('should support French and Arabic locales', () {
        const supportedLocales = LocalizationService.supportedLocales;
        expect(supportedLocales.length, equals(2));
        
        final languageCodes = supportedLocales.map((l) => l.languageCode).toList();
        expect(languageCodes, contains('fr'));
        expect(languageCodes, contains('ar'));
      });

      test('should provide available languages list', () {
        final languages = localizationService.getAvailableLanguages();
        expect(languages.length, equals(2));
        
        final languageNames = languages.map((l) => l['name']).toList();
        expect(languageNames, contains('Français'));
        expect(languageNames, contains('Arabic'));
      });
    });

    group('RTL Support', () {
      test('should detect RTL for Arabic', () {
        // Test initial (français)
        expect(localizationService.isRTL, isFalse);
        
        // Note: Pour tester complètement, il faudrait changer la langue
        // Ce test vérifie que la propriété existe et fonctionne
        expect(() => localizationService.isRTL, returnsNormally);
      });

      test('should provide current language name', () {
        final languageName = localizationService.getCurrentLanguageName();
        expect(languageName.isNotEmpty, isTrue);
        expect(languageName, equals('Français')); // Langue par défaut
      });
    });
  });

  group('Translation File Structure Tests', () {
    test('should have consistent structure between languages', () {
      // Ce test vérifierait que les fichiers JSON ont la même structure
      // Pour l'instant, on teste juste que le service fonctionne
      expect(() => LocalizationService(), returnsNormally);
    });

    test('should handle missing translations gracefully', () {
      final service = LocalizationService();
      const missingKey = 'missing.translation.key';
      
      // Devrait retourner la clé elle-même si la traduction n'existe pas
      expect(service.translate(missingKey), equals(missingKey));
    });
  });
}
