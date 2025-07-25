# Système de Notifications - Documentation

## Vue d'ensemble

Le système de notifications de l'application scolaire permet d'envoyer et de gérer des notifications en temps réel aux utilisateurs (parents, enseignants, concierges, administrateurs).

## Fonctionnalités

### ✅ Fonctionnalités Implémentées

1. **Enregistrement des notifications dans l'API backend**
   - Les notifications sont sauvegardées de manière persistante
   - API REST disponible sur `http://localhost:8004/api/notifications`

2. **Types de notifications supportés**
   - Notifications de demande de récupération d'enfants
   - Notifications de réponse aux demandes (approuvé/refusé)
   - Notifications générales personnalisées

3. **Interface utilisateur**
   - Widget de test des notifications (page parent)
   - Page d'administration des notifications
   - Icône de notification avec compteur
   - Page de visualisation des notifications

4. **Notifications push locales**
   - Notifications natives sur mobile/desktop
   - Intégration avec flutter_local_notifications

## Structure du Code

### Services

- **`NotificationService`** (`lib/services/notification_service.dart`)
  - Gestion des notifications via API backend
  - Fallback vers stockage local en cas d'échec
  - Méthodes pour créer, récupérer et marquer comme lues

- **`PushNotificationService`** (`lib/services/push_notification_service.dart`)
  - Gestion des notifications push natives
  - Support Android/iOS/Web

### Pages et Widgets

- **`AdminNotificationsPage`** (`lib/pages/admin_notifications_page.dart`)
  - Interface d'administration pour créer des notifications
  - Formulaire de saisie avec validation

- **`NotificationTestWidget`** (`lib/widgets/notification_test_widget.dart`)
  - Widget de test pour développeurs
  - Boutons pour tester différents types de notifications

- **`NotificationsPage`** (`lib/pages/notifications_page.dart`)
  - Affichage de toutes les notifications de l'utilisateur
  - Marquage comme lu/non lu

- **`NotificationIconWidget`** (`lib/widgets/notification_icon_widget.dart`)
  - Icône avec compteur de notifications non lues

## API Backend

### Endpoints

#### GET `/api/notifications`
Récupère toutes les notifications

**Réponse :**
```json
[
  {
    "id": 1,
    "contenu": "Votre demande a été approuvée",
    "date": "2025-01-25T15:30:00.000+00:00",
    "compteIds": [4]
  }
]
```

#### POST `/api/notifications`
Crée une nouvelle notification

**Corps de la requête :**
```json
{
  "contenu": "Message de la notification",
  "date": "2025-01-25T15:30:00.000+00:00",
  "compteIds": [1, 2, 3, 4]
}
```

**Réponse :**
```json
{
  "id": 6,
  "contenu": "Message de la notification",
  "date": "2025-01-25T15:30:00.000+00:00",
  "compteIds": [4]
}
```

## Utilisation

### 1. Créer une notification générale

```dart
final notificationService = NotificationService();

final success = await notificationService.createGeneralNotification(
  contenu: 'Réunion parents-professeurs le 15 février',
  compteIds: [1, 2, 3, 4], // IDs des utilisateurs destinataires
);
```

### 2. Envoyer une notification de récupération

```dart
final success = await notificationService.sendPickupRequestNotification(
  studentName: 'Jean Dupont',
  parentName: 'Marie Dupont',
  parentId: 4,
);
```

### 3. Récupérer les notifications d'un utilisateur

```dart
final notifications = await notificationService.getNotificationsForUser(userId);
```

## Test du Système

### Via l'Interface

1. **Page Parent** : Utilisez le widget "Test des Notifications"
2. **Page Admin** : Accédez à "Administration - Notifications"

### Via API (PowerShell)

```powershell
# Récupérer toutes les notifications
Invoke-WebRequest -Uri "http://localhost:8004/api/notifications" -Method GET

# Créer une notification
$body = @{
    contenu = "Test de notification"
    date = "2025-01-25T15:30:00.000+00:00"
    compteIds = @(1, 2, 3, 4)
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8004/api/notifications" -Method POST -ContentType "application/json" -Body $body
```

## Configuration

### Prérequis

1. **Backend API** : Serveur sur `http://localhost:8004`
2. **Permissions** : Notifications push activées sur l'appareil

### Variables de Configuration

Dans `NotificationService` :
```dart
final String baseUrl = 'http://localhost:8004/api/notifications';
```

## Améliorations Futures

- [ ] Notifications en temps réel via WebSocket
- [ ] Filtrage des notifications par type
- [ ] Notifications programmées
- [ ] Historique des notifications
- [ ] Notifications par email
- [ ] Interface de gestion avancée pour les administrateurs

## Dépannage

### Problèmes Courants

1. **Erreur 400 lors de la création** : Vérifiez le format de la date
2. **Notifications non reçues** : Vérifiez les permissions push
3. **API non accessible** : Vérifiez que le backend est démarré

### Logs de Debug

Les services utilisent des logs détaillés avec des préfixes :
- `📢 [NOTIFICATION]` : Opérations générales
- `💾 [NOTIFICATION API]` : Appels API
- `📱 [NOTIFICATION]` : Notifications push
- `🔔 [NOTIFICATION ICON]` : Widget d'icône

## Tests Effectués

✅ **API Backend** : Création et récupération de notifications  
✅ **Interface Flutter** : Widgets et pages fonctionnels  
✅ **Intégration** : Communication app ↔ API  
✅ **Notifications Push** : Affichage natif  

Le système de notifications est maintenant opérationnel et prêt pour la production !
