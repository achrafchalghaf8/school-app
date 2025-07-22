import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'selected_language';
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // Français
    Locale('ar', 'SA'), // Arabe
  ];

  Locale _currentLocale = const Locale('fr', 'FR');
  Map<String, dynamic> _localizedStrings = {};

  Locale get currentLocale => _currentLocale;
  bool get isRTL => _currentLocale.languageCode == 'ar';

  // Initialiser le service de localisation
  Future<void> initialize() async {
    await _loadSavedLanguage();
    await _loadTranslations();
  }

  // Charger la langue sauvegardée
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        _currentLocale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == languageCode,
          orElse: () => const Locale('fr', 'FR'),
        );
      }
    } catch (e) {
      print('Erreur lors du chargement de la langue: $e');
    }
  }

  // Charger les traductions depuis les fichiers JSON
  Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/${_currentLocale.languageCode}.json'
      );
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      print('Erreur lors du chargement des traductions: $e');
      // Charger les traductions par défaut (français) en cas d'erreur
      if (_currentLocale.languageCode != 'fr') {
        try {
          final String jsonString = await rootBundle.loadString(
            'assets/translations/fr.json'
          );
          _localizedStrings = json.decode(jsonString);
        } catch (e) {
          print('Erreur lors du chargement des traductions par défaut: $e');
        }
      }
    }
  }

  // Changer la langue
  Future<void> changeLanguage(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    
    _currentLocale = locale;
    await _loadTranslations();
    
    // Sauvegarder la langue sélectionnée
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la langue: $e');
    }
    
    notifyListeners();
  }

  // Obtenir une traduction par clé
  String translate(String key) {
    return _getNestedTranslation(_localizedStrings, key) ?? key;
  }

  // Obtenir une traduction imbriquée (ex: "login.title")
  String? _getNestedTranslation(Map<String, dynamic> map, String key) {
    final keys = key.split('.');
    dynamic current = map;
    
    for (String k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }
    
    return current is String ? current : null;
  }

  // Obtenir le nom de la langue actuelle
  String getCurrentLanguageName() {
    switch (_currentLocale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'Français';
    }
  }

  // Obtenir toutes les langues disponibles
  List<Map<String, dynamic>> getAvailableLanguages() {
    return [
      {
        'locale': const Locale('fr', 'FR'),
        'name': 'Français',
        'nativeName': 'Français',
        'flag': '🇫🇷'
      },
      {
        'locale': const Locale('ar', 'SA'),
        'name': 'Arabic',
        'nativeName': 'العربية',
        'flag': '🇸🇦'
      },
    ];
  }
}

// Extension pour faciliter l'utilisation des traductions
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return LocalizationService().translate(key);
  }
  
  bool get isRTL {
    return LocalizationService().isRTL;
  }
  
  Locale get currentLocale {
    return LocalizationService().currentLocale;
  }
}
