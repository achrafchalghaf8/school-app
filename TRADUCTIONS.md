# Guide des Traductions - Application Scolaire

## 📋 Vue d'ensemble

Cette application scolaire supporte maintenant **deux langues** :
- 🇫🇷 **Français** (langue par défaut)
- 🇸🇦 **Arabe** (avec support RTL)

## 🚀 Fonctionnalités

### ✅ Pages traduites
- **Page Cours** (`courses_page.dart`) - Affichage des cours et exercices
- **Page Emploi du temps** (`emploi_du_temps_page.dart`) - Consultation des horaires

### ✅ Fonctionnalités de localisation
- Changement de langue en temps réel
- Support RTL (Right-to-Left) pour l'arabe
- Sauvegarde automatique de la préférence linguistique
- Interface adaptée selon la langue sélectionnée

## 🛠️ Structure technique

### Fichiers de traduction
```
assets/translations/
├── fr.json    # Traductions françaises
└── ar.json    # Traductions arabes
```

### Services
- `LocalizationService` : Gestion des langues et traductions
- `LanguageSelector` : Widget de sélection de langue

## 📱 Utilisation

### Changer de langue
1. Cliquez sur le sélecteur de langue dans la barre d'application
2. Sélectionnez la langue souhaitée
3. L'interface se met à jour automatiquement

### Dans le code
```dart
// Utiliser une traduction
Text(context.tr('parents.courses.page_title'))

// Avec paramètres
Text(context.tr('parents.courses.published_on').replaceAll('{date}', date))

// Vérifier la direction du texte
if (context.isRTL) {
  // Interface RTL pour l'arabe
}
```

## 🔧 Configuration

### Langue par défaut
Le français est défini comme langue par défaut dans `LocalizationService` :
```dart
Locale _currentLocale = const Locale('fr', 'FR');
```

### Langues supportées
```dart
static const List<Locale> supportedLocales = [
  Locale('fr', 'FR'), // Français
  Locale('ar', 'SA'), // Arabe
];
```

## 📝 Clés de traduction principales

### Page Cours
- `parents.courses.page_title` - Titre de la page
- `parents.courses.no_courses_available` - Aucun cours disponible
- `parents.courses.exercises_label` - Label des exercices
- `parents.courses.download` - Bouton télécharger
- `parents.courses.published_on` - Date de publication

### Page Emploi du temps
- `parents.schedule.page_title` - Titre de la page
- `parents.schedule.most_recent_schedule` - Emploi du temps récent
- `parents.schedule.loading_file` - Chargement du fichier
- `parents.schedule.no_schedule_available` - Aucun emploi disponible
- `parents.schedule.download` - Bouton télécharger

### Éléments communs
- `common.loading` - Chargement
- `common.error` - Erreur
- `common.save` - Enregistrer
- `common.cancel` - Annuler
- `navigation.language` - Langue

## 🧪 Test des traductions

Un script de test est disponible pour vérifier les traductions :
```bash
dart test_translations.dart
```

## 🎨 Interface utilisateur

### Support RTL
- L'interface s'adapte automatiquement pour l'arabe
- Les textes s'alignent de droite à gauche
- Les icônes et boutons sont repositionnés

### Sélecteur de langue
- Disponible dans la barre d'application
- Affiche le drapeau et le nom de la langue
- Menu déroulant avec toutes les langues disponibles

## 📋 Checklist de vérification

- [x] Traductions françaises complètes
- [x] Traductions arabes complètes
- [x] Support RTL pour l'arabe
- [x] Sélecteur de langue fonctionnel
- [x] Sauvegarde des préférences
- [x] Interface adaptée aux deux langues
- [x] Test des traductions

## 🔄 Ajout de nouvelles traductions

1. Ajouter la clé dans `fr.json` et `ar.json`
2. Utiliser `context.tr('nouvelle.cle')` dans le code
3. Tester avec le script de vérification
4. Vérifier l'affichage dans les deux langues

## 🐛 Dépannage

### Traduction manquante
Si une traduction n'apparaît pas :
1. Vérifier que la clé existe dans les deux fichiers JSON
2. Redémarrer l'application
3. Vérifier la syntaxe JSON

### Problème RTL
Si l'interface RTL ne fonctionne pas :
1. Vérifier que `Directionality` est utilisé
2. S'assurer que `isRTL` retourne la bonne valeur
3. Tester le changement de langue

## 📞 Support

Pour toute question concernant les traductions, consultez :
- Le service `LocalizationService`
- Les fichiers de traduction dans `assets/translations/`
- La page de démonstration `LanguageDemoPage`
