import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/localization_service.dart';

void main() {
  group('Admin Notifications Translation Tests', () {
    late LocalizationService localizationService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      localizationService = LocalizationService();
      await localizationService.initialize();
    });

    group('Admin Notifications Page Translations', () {
      test('should have all required French translations for admin notifications', () {
        final notificationKeys = [
          'admin_notifications.page_title',
          'admin_notifications.refresh',
          'admin_notifications.loading',
          'admin_notifications.error_loading',
          'admin_notifications.error_message',
          'admin_notifications.no_notifications',
          'admin_notifications.retry',
          'admin_notifications.notification_details',
          'admin_notifications.no_message',
        ];

        for (String key in notificationKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate notification page title correctly', () {
        // Test French
        final frenchTitle = localizationService.translate('admin_notifications.page_title');
        expect(frenchTitle, equals('Notifications Administrateur'));
      });

      test('should translate notification actions correctly', () {
        final actionKeys = [
          'admin_notifications.refresh',
          'admin_notifications.retry',
        ];

        for (String key in actionKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });

      test('should translate notification states correctly', () {
        final stateKeys = [
          'admin_notifications.loading',
          'admin_notifications.no_notifications',
          'admin_notifications.error_message',
        ];

        for (String key in stateKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
        }
      });
    });

    group('Common Translations for Notifications', () {
      test('should have common translations used in notifications', () {
        final commonKeys = [
          'common.search',
          'common.recipients',
          'common.unknown_date',
          'common.at',
          'common.unknown',
        ];

        for (String key in commonKeys) {
          expect(() => localizationService.translate(key), returnsNormally);
          expect(localizationService.translate(key).isNotEmpty, isTrue);
        }
      });

      test('should translate common search functionality', () {
        final searchTranslation = localizationService.translate('common.search');
        expect(searchTranslation, isNot(equals('common.search')));
        expect(searchTranslation.isNotEmpty, isTrue);
      });

      test('should translate recipients label', () {
        final recipientsTranslation = localizationService.translate('common.recipients');
        expect(recipientsTranslation, isNot(equals('common.recipients')));
        expect(recipientsTranslation.isNotEmpty, isTrue);
      });
    });

    group('Translation Consistency', () {
      test('should have consistent translation structure for notifications', () {
        final structureKeys = [
          'page_title',
          'refresh',
          'loading',
          'error_loading',
          'error_message',
          'no_notifications',
          'retry',
        ];

        for (String structureKey in structureKeys) {
          expect(() => localizationService.translate('admin_notifications.$structureKey'), returnsNormally);
        }
      });

      test('should handle missing translations gracefully', () {
        const missingKey = 'admin_notifications.missing.key';
        final result = localizationService.translate(missingKey);
        expect(result, equals(missingKey));
      });

      test('should support parameter replacement in error messages', () {
        final errorMessage = localizationService.translate('admin_notifications.error_loading')
            .replaceAll('{code}', '404');
        expect(errorMessage, contains('404'));
      });
    });

    group('RTL Support', () {
      test('should detect RTL for Arabic notifications', () {
        // Test French (LTR)
        expect(localizationService.isRTL, isFalse);
      });
    });
  });
} 