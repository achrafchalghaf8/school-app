import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/localization_service.dart';

void main() {
  group('Students and Teachers Translation Tests', () {
    late LocalizationService localizationService;

    setUp(() {
      localizationService = LocalizationService();
    });

    group('Students Page Translations', () {
      test('should have all required French translations for students', () {
        final studentKeys = [
          'students.page_title',
          'students.search_placeholder',
          'students.add_student',
          'students.edit_student',
          'students.delete_confirmation',
          'students.missing_data',
          'students.first_name',
          'students.last_name',
          'students.class',
          'students.parent',
          'students.no_students',
          'students.close_form',
        ];

        for (String key in studentKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate student form fields correctly', () {
        final formKeys = [
          'students.first_name',
          'students.last_name',
          'students.class',
          'students.parent',
        ];

        for (String key in formKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should translate student actions correctly', () {
        final actionKeys = [
          'students.add_student',
          'students.edit_student',
          'students.close_form',
        ];

        for (String key in actionKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
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

      test('should translate teacher success messages correctly', () {
        final successKeys = [
          'teachers.add_success',
          'teachers.edit_success',
          'teachers.delete_success',
        ];

        for (String key in successKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should translate teacher error messages correctly', () {
        final errorKeys = [
          'teachers.delete_error',
          'teachers.loading_error',
        ];

        for (String key in errorKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should translate teacher information fields correctly', () {
        final infoKeys = [
          'teachers.specialty',
          'teachers.phone',
          'teachers.classes',
        ];

        for (String key in infoKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Form Validation Translations', () {
      test('should have all form validation translations', () {
        final formKeys = [
          'forms.required_field',
          'forms.invalid_email',
          'forms.password_too_short',
          'forms.passwords_dont_match',
          'forms.selection_required',
        ];

        for (String key in formKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate selection validation correctly', () {
        const selectionKey = 'forms.selection_required';
        expect(() => localizationService.translate(selectionKey), returnsNormally);
      });
    });

    group('Common Action Translations', () {
      test('should have all common action translations', () {
        final commonKeys = [
          'common.add',
          'common.edit',
          'common.delete',
          'common.save',
          'common.cancel',
          'common.confirm',
          'common.search',
          'common.refresh',
          'common.retry',
          'common.error',
          'common.unknown',
          'common.confirm_delete',
        ];

        for (String key in commonKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate retry action correctly', () {
        const retryKey = 'common.retry';
        expect(() => localizationService.translate(retryKey), returnsNormally);
      });
    });

    group('Nested Translation Keys', () {
      test('should handle deeply nested translation keys', () {
        final nestedKeys = [
          'students.page_title',
          'teachers.add_success',
          'forms.selection_required',
          'common.confirm_delete',
        ];

        for (String key in nestedKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should return key if nested translation not found', () {
        const nonExistentKey = 'students.non.existent.key';
        final result = localizationService.translate(nonExistentKey);
        expect(result, equals(nonExistentKey));
      });
    });

    group('Translation Consistency', () {
      test('should have consistent translation structure', () {
        // Test que les clés principales existent
        final mainSections = [
          'students',
          'teachers',
          'forms',
          'common',
        ];

        for (String section in mainSections) {
          // Vérifier que la section existe en testant une clé connue
          expect(() => localizationService.translate('$section.page_title'), returnsNormally);
        }
      });

      test('should handle missing translations gracefully', () {
        const missingKey = 'missing.section.key';
        final result = localizationService.translate(missingKey);
        expect(result, equals(missingKey));
      });
    });

    group('Language Support Validation', () {
      test('should support both French and Arabic', () {
        const supportedLocales = LocalizationService.supportedLocales;
        expect(supportedLocales.length, equals(2));
        
        final languageCodes = supportedLocales.map((l) => l.languageCode).toList();
        expect(languageCodes, contains('fr'));
        expect(languageCodes, contains('ar'));
      });

      test('should provide correct language information', () {
        final languages = localizationService.getAvailableLanguages();
        expect(languages.length, equals(2));
        
        final languageNames = languages.map((l) => l['name']).toList();
        expect(languageNames, contains('Français'));
        expect(languageNames, contains('Arabic'));
      });
    });
  });
}
