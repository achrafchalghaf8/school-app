import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/localization_service.dart';

void main() {
  group('Parents and Teachers Translation Tests', () {
    late LocalizationService localizationService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      localizationService = LocalizationService();
      await localizationService.initialize();
    });

    group('Teachers Page Translations', () {
      test('should have all required French translations for teachers', () {
        final teacherKeys = [
          'teachers.page_title',
          'teachers.search_placeholder',
          'teachers.add_teacher',
          'teachers.edit_teacher',
          'teachers.delete_confirmation',
          'teachers.add_success',
          'teachers.edit_success',
          'teachers.delete_success',
          'teachers.delete_error',
          'teachers.loading_error',
          'teachers.no_teachers',
          'teachers.specialty',
          'teachers.phone',
          'teachers.classes',
        ];

        for (String key in teacherKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate teacher interface elements correctly', () {
        final interfaceKeys = [
          'teachers.page_title',
          'teachers.search_placeholder',
          'teachers.add_teacher',
        ];

        for (String key in interfaceKeys) {
          final translation = localizationService.translate(key);
          expect(translation, isNot(equals(key))); // Should not return the key itself
          expect(translation.isNotEmpty, isTrue);
        }
      });

      test('should translate teacher success and error messages', () {
        final messageKeys = [
          'teachers.add_success',
          'teachers.edit_success',
          'teachers.delete_success',
          'teachers.delete_error',
          'teachers.loading_error',
        ];

        for (String key in messageKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Parents Page Translations', () {
      test('should have all required French translations for parents', () {
        final parentKeys = [
          'parents.page_title',
          'parents.search_placeholder',
          'parents.add_parent',
          'parents.edit_parent',
          'parents.delete_confirmation',
          'parents.add_success',
          'parents.edit_success',
          'parents.delete_success',
          'parents.delete_error',
          'parents.loading_error',
          'parents.no_parents',
          'parents.phone',
        ];

        for (String key in parentKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate parent interface elements correctly', () {
        final interfaceKeys = [
          'parents.page_title',
          'parents.search_placeholder',
          'parents.add_parent',
        ];

        for (String key in interfaceKeys) {
          final translation = localizationService.translate(key);
          expect(translation, isNot(equals(key))); // Should not return the key itself
          expect(translation.isNotEmpty, isTrue);
        }
      });

      test('should translate parent success and error messages', () {
        final messageKeys = [
          'parents.add_success',
          'parents.edit_success',
          'parents.delete_success',
          'parents.delete_error',
          'parents.loading_error',
        ];

        for (String key in messageKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should translate parent status messages', () {
        final statusKeys = [
          'parents.no_parents',
          'parents.loading_error',
        ];

        for (String key in statusKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Common Elements Translations', () {
      test('should have all common action translations', () {
        final commonKeys = [
          'common.add',
          'common.edit',
          'common.delete',
          'common.save',
          'common.cancel',
          'common.refresh',
          'common.retry',
          'common.error',
          'common.confirm_delete',
        ];

        for (String key in commonKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate confirmation dialogs correctly', () {
        final confirmationKeys = [
          'common.confirm_delete',
          'common.cancel',
          'common.delete',
        ];

        for (String key in confirmationKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Language Support Validation', () {
      test('should support French and Arabic only', () {
        const supportedLocales = LocalizationService.supportedLocales;
        expect(supportedLocales.length, equals(2));
        
        final languageCodes = supportedLocales.map((l) => l.languageCode).toList();
        expect(languageCodes, contains('fr'));
        expect(languageCodes, contains('ar'));
        expect(languageCodes, isNot(contains('en'))); // English should be removed
      });

      test('should provide correct language information', () {
        final languages = localizationService.getAvailableLanguages();
        expect(languages.length, equals(2));
        
        final languageNames = languages.map((l) => l['name']).toList();
        expect(languageNames, contains('Français'));
        expect(languageNames, contains('Arabic'));
        expect(languageNames, isNot(contains('English'))); // English should be removed
      });
    });

    group('Translation Consistency', () {
      test('should have consistent translation structure for teachers and parents', () {
        final commonStructureKeys = [
          'page_title',
          'search_placeholder',
          'add_success',
          'edit_success',
          'delete_success',
          'delete_error',
          'loading_error',
        ];

        for (String structureKey in commonStructureKeys) {
          // Test that both teachers and parents have these keys
          expect(() => localizationService.translate('teachers.$structureKey'), returnsNormally);
          expect(() => localizationService.translate('parents.$structureKey'), returnsNormally);
        }
      });

      test('should handle missing translations gracefully', () {
        const missingKey = 'missing.section.key';
        final result = localizationService.translate(missingKey);
        expect(result, equals(missingKey));
      });
    });

    group('Specific Translation Content', () {
      test('should have meaningful French translations', () {
        // Test specific French translations
        expect(localizationService.translate('teachers.page_title'), equals('Gestion des Enseignants'));
        expect(localizationService.translate('parents.page_title'), equals('Gestion des Parents'));
        expect(localizationService.translate('teachers.add_teacher'), equals('Ajouter un enseignant'));
        expect(localizationService.translate('parents.add_parent'), equals('Ajouter un parent'));
      });

      test('should have proper phone field translations', () {
        // Both teachers and parents should have phone field translations
        expect(localizationService.translate('teachers.phone'), equals('Tél'));
        expect(localizationService.translate('parents.phone'), equals('Tél'));
      });

      test('should have proper confirmation messages', () {
        final teacherConfirmation = localizationService.translate('teachers.delete_confirmation');
        final parentConfirmation = localizationService.translate('parents.delete_confirmation');
        
        expect(teacherConfirmation, contains('enseignant'));
        expect(parentConfirmation, contains('parent'));
      });
    });

    group('RTL Support Validation', () {
      test('should support RTL for Arabic', () {
        expect(localizationService.isRTL, isFalse); // Default is French (LTR)
        
        // Test that Arabic locale exists
        const arabicLocale = Locale('ar', 'SA');
        expect(LocalizationService.supportedLocales, contains(arabicLocale));
      });
    });
  });
}
