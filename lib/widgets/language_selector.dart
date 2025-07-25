import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class LanguageSelector extends StatelessWidget {
  final bool showAsDialog;
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({
    Key? key,
    this.showAsDialog = false,
    this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) {
        final localizationService = LocalizationService();
        final availableLanguages = localizationService.getAvailableLanguages();
        
        if (showAsDialog) {
          return IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context, availableLanguages),
            tooltip: context.tr('navigation.language'),
          );
        }
        
        return PopupMenuButton<Locale>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 4),
              Text(
                localizationService.getCurrentLanguageName(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          onSelected: (Locale locale) async {
            await localizationService.changeLanguage(locale);
            onLanguageChanged?.call();
          },
          itemBuilder: (BuildContext context) {
            return availableLanguages.map((language) {
              final locale = language['locale'] as Locale;
              final isSelected = locale == localizationService.currentLocale;
              
              return PopupMenuItem<Locale>(
                value: locale,
                child: Row(
                  children: [
                    Text(
                      language['flag'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        language['nativeName'] as String,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, List<Map<String, dynamic>> availableLanguages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr('navigation.language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableLanguages.map((language) {
              final locale = language['locale'] as Locale;
              final localizationService = LocalizationService();
              final isSelected = locale == localizationService.currentLocale;
              
              return ListTile(
                leading: Text(
                  language['flag'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(language['nativeName'] as String),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  await localizationService.changeLanguage(locale);
                  onLanguageChanged?.call();
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('common.cancel')),
            ),
          ],
        );
      },
    );
  }
}

// Widget simple pour afficher la langue actuelle
class CurrentLanguageDisplay extends StatelessWidget {
  const CurrentLanguageDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) {
        final localizationService = LocalizationService();
        final currentLanguage = localizationService.getAvailableLanguages()
            .firstWhere((lang) => lang['locale'] == localizationService.currentLocale);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLanguage['flag'] as String,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              currentLanguage['nativeName'] as String,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}
