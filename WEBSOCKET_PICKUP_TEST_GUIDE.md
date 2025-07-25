# Guide de Test - Système de Notifications WebSocket pour Récupération d'Enfants

## Prérequis

1. **Backend en cours d'exécution** : Assurez-vous que le serveur Spring Boot est démarré sur `http://localhost:8004`
2. **Base de données** : Vérifiez que la base de données contient :
   - Au moins un compte parent
   - Au moins un compte concierge
   - Au moins un étudiant associé au parent

## Étapes de Test

### 1. Préparation des Comptes

#### Créer un compte Concierge (si nécessaire)
```sql
-- Dans la base de données, insérer un compte concierge
INSERT INTO compte (email, nom, password, role) 
VALUES ('concierge@ecole.com', 'Jean Concierge', '$2a$10$...', 'CONCIERGE');
```

#### Vérifier les comptes existants
- Parent : `parent@ecole.com`
- Concierge : `concierge@ecole.com`

### 2. Test de Connexion WebSocket

#### Côté Parent
1. Connectez-vous avec un compte parent
2. Naviguez vers la page des détails d'un étudiant
3. Vérifiez que l'icône WebSocket dans l'AppBar indique une connexion (vert)

#### Côté Concierge
1. Connectez-vous avec un compte concierge
2. Accédez à la page d'accueil concierge
3. Vérifiez que l'icône WebSocket indique une connexion (vert)

### 3. Test d'Envoi de Demande de Récupération

#### Depuis le compte Parent
1. Allez sur la page de détails d'un étudiant
2. Cliquez sur le bouton "Récupération d'enfant"
3. Vérifiez qu'un message de succès s'affiche
4. La demande doit être envoyée via WebSocket

#### Vérification côté Concierge
1. Sur la page concierge, une notification doit apparaître
2. La demande doit s'afficher dans la liste
3. Le statut doit être "En attente"

### 4. Test de Réponse à la Demande

#### Côté Concierge
1. Cliquez sur "Approuver" ou "Refuser" pour une demande
2. Vérifiez qu'un message de succès s'affiche
3. Le statut de la demande doit changer

#### Vérification côté Parent
1. Le parent devrait recevoir une notification de réponse
2. (Note: L'affichage de la réponse côté parent peut nécessiter une implémentation supplémentaire)

## Messages d'Erreur Possibles

### Erreurs de Connexion WebSocket
- **"WebSocket non connecté"** : Vérifiez que le backend est démarré
- **"Informations d'authentification manquantes"** : Reconnectez-vous

### Erreurs d'Envoi
- **"Erreur lors de l'envoi de la demande"** : Vérifiez la connexion réseau
- **"Erreur lors de l'envoi de la réponse"** : Vérifiez que la demande existe

## Structure des Messages WebSocket

### Demande de Récupération (Parent → Concierges)
```json
{
  "type": "PICKUP_REQUEST",
  "studentId": 123,
  "studentName": "Jean Dupont",
  "parentId": 456,
  "parentName": "Marie Dupont",
  "reason": "Demande de récupération d'enfant",
  "timestamp": "2024-01-15T14:30:00Z"
}
```

### Réponse de Récupération (Concierge → Parent)
```json
{
  "type": "PICKUP_RESPONSE",
  "requestId": "req_123",
  "response": "APPROVED",
  "conciergeId": 789,
  "conciergeName": "Jean Concierge",
  "timestamp": "2024-01-15T14:35:00Z"
}
```

## Canaux WebSocket Utilisés

- **`/topic/pickup-requests`** : Diffusion des demandes vers tous les concierges
- **`/user/queue/pickup-responses`** : Réponses privées vers le parent demandeur
- **`/app/pickup/request`** : Endpoint pour envoyer une demande
- **`/app/pickup/response`** : Endpoint pour envoyer une réponse

## Dépannage

### Si les notifications ne fonctionnent pas
1. Vérifiez les logs de la console du navigateur
2. Assurez-vous que le WebSocket est connecté (icône verte)
3. Vérifiez que les rôles des utilisateurs sont corrects
4. Redémarrez l'application si nécessaire

### Si les messages ne s'affichent pas
1. Vérifiez que les callbacks sont bien définis
2. Assurez-vous que les destinations WebSocket sont correctes
3. Vérifiez que le backend traite les messages

## Améliorations Futures

1. **Persistance des demandes** : Sauvegarder les demandes en base de données
2. **Historique** : Afficher l'historique des demandes pour les parents
3. **Notifications push** : Ajouter des notifications système
4. **Statuts avancés** : Ajouter plus de statuts (en cours, terminé, etc.)
