# Système de Traduction - Guide d'utilisation

## Vue d'ensemble

Ce système de traduction permet de supporter plusieurs langues dans l'application Flutter. Actuellement configuré pour le français et l'arabe avec support RTL.

## Langues supportées

- **Français (fr)** - Langue par défaut
- **Arabe (ar)** - Avec support RTL (Right-to-Left)

## Structure des fichiers

```
assets/
  translations/
    fr.json     # Traductions françaises
    ar.json     # Traductions arabes
lib/
  services/
    localization_service.dart    # Service principal de localisation
  widgets/
    language_selector.dart       # Widget sélecteur de langue
```

## Utilisation

### 1. Initialisation

Le service est automatiquement initialisé dans `main.dart` :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService().initialize();
  runApp(const MyApp());
}
```

### 2. Utilisation dans les widgets

```dart
import '../services/localization_service.dart';

// Dans votre widget
Text(context.tr('login.title'))

// Ou directement
Text(LocalizationService().translate('login.title'))
```

### 3. Ajouter le sélecteur de langue

```dart
import '../widgets/language_selector.dart';

// Dans votre AppBar
AppBar(
  actions: [
    const LanguageSelector(),
  ],
)

// Ou comme dialog
LanguageSelector(showAsDialog: true)
```

### 4. Vérifier la direction du texte

```dart
// Vérifier si la langue actuelle est RTL
if (context.isRTL) {
  // Logique pour RTL
}

// Ou directement
if (LocalizationService().isRTL) {
  // Logique pour RTL
}
```

## Structure des traductions JSON

### Exemple de structure dans `fr.json` :

```json
{
  "app_title": "Application Scolaire",
  "login": {
    "title": "Connectez-vous à votre compte",
    "email": "Email",
    "password": "Mot de passe",
    "login_button": "Se connecter"
  },
  "admin": {
    "welcome": "Bienvenue Administrateur",
    "classes": "Classes",
    "students": "Étudiants"
  },
  "common": {
    "save": "Enregistrer",
    "cancel": "Annuler",
    "delete": "Supprimer"
  }
}
```

## Ajouter une nouvelle langue

### 1. Créer le fichier de traduction

Créez un nouveau fichier JSON dans `assets/translations/` (ex: `es.json` pour l'espagnol).

### 2. Mettre à jour le service

Dans `localization_service.dart`, ajoutez la nouvelle locale :

```dart
static const List<Locale> supportedLocales = [
  Locale('fr', 'FR'),
  Locale('ar', 'SA'),
  Locale('es', 'ES'), // Nouvelle langue
];
```

### 3. Mettre à jour la liste des langues disponibles

```dart
List<Map<String, dynamic>> getAvailableLanguages() {
  return [
    // ... langues existantes
    {
      'locale': const Locale('es', 'ES'),
      'name': 'Spanish',
      'nativeName': 'Español',
      'flag': '🇪🇸'
    },
  ];
}
```

## Ajouter de nouvelles traductions

### 1. Ajouter dans les fichiers JSON

Ajoutez vos nouvelles clés dans tous les fichiers de traduction :

```json
{
  "new_section": {
    "title": "Nouveau titre",
    "description": "Nouvelle description"
  }
}
```

### 2. Utiliser dans le code

```dart
Text(context.tr('new_section.title'))
```

## Bonnes pratiques

### 1. Organisation des clés

- Utilisez une structure hiérarchique logique
- Groupez les traductions par fonctionnalité
- Utilisez des noms de clés descriptifs

### 2. Gestion des traductions manquantes

Le service retourne la clé elle-même si la traduction n'est pas trouvée.

### 3. Support RTL

- Testez votre interface avec l'arabe pour vérifier le support RTL
- Utilisez `context.isRTL` pour adapter la logique si nécessaire

### 4. Performance

- Les traductions sont chargées une seule fois au démarrage
- Le changement de langue recharge automatiquement les traductions

## Dépannage

### Traduction non trouvée

Si une traduction n'apparaît pas :
1. Vérifiez que la clé existe dans le fichier JSON
2. Vérifiez la syntaxe JSON (pas de virgules en trop)
3. Redémarrez l'application après modification des assets

### Problèmes RTL

Si l'interface RTL ne fonctionne pas correctement :
1. Vérifiez que `Directionality` est bien configuré dans `main.dart`
2. Utilisez `context.isRTL` pour adapter les widgets si nécessaire

### Langue non sauvegardée

Si la langue sélectionnée n'est pas persistante :
1. Vérifiez les permissions de stockage
2. Vérifiez que `SharedPreferences` fonctionne correctement
