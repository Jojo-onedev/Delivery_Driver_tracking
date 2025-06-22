# Guide d'Administration - Delivery Driver Tracking

Ce document explique comment gérer les fonctionnalités d'administration de l'application Delivery Driver Tracking.

## Configuration Initiale

1. **Variables d'environnement**
   - Copiez le fichier `.env.example` vers `.env`
   - Modifiez les variables selon votre configuration
   - Spécifiez un mot de passe fort pour le compte admin

2. **Initialisation du compte admin**
   Le compte admin est automatiquement créé au démarrage du serveur avec les identifiants suivants :
   - Email: `admin@delivery.com` (configurable via `ADMIN_EMAIL`)
   - Mot de passe: Celui défini dans `ADMIN_PASSWORD`

## Points de Terminaison d'Administration

Toutes les routes d'administration sont préfixées par `/api/admin` et nécessitent un jeton JWT valide avec le rôle 'admin'.

### Authentification

1. **Connexion**
   ```
   POST /api/auth/login
   {
     "email": "admin@delivery.com",
     "password": "votre_mot_de_passe"
   }
   ```

### Gestion des Utilisateurs

1. **Lister tous les utilisateurs**
   ```
   GET /api/admin/users
   Headers: { "Authorization": "Bearer <votre_jwt>" }
   ```

2. **Supprimer un utilisateur**
   ```
   DELETE /api/admin/users/:id
   Headers: { "Authorization": "Bearer <votre_jwt>" }
   ```

## Sécurité

- Changez le `JWT_SECRET` en production
- Utilisez toujours HTTPS en production
- Limitez les tentatives de connexion
- Maintenez les dépendances à jour

## Dépannage

- **Problème de connexion admin** : Vérifiez les logs du serveur
- **Erreurs de base de données** : Vérifiez que MongoDB est en cours d'exécution
- **Problèmes de JWT** : Vérifiez que le `JWT_SECRET` est le même entre les redémarrages

## Maintenance

Pour réinitialiser le mot de passe admin :

1. Arrêtez le serveur
2. Connectez-vous à MongoDB
3. Mettez à jour le mot de passe haché pour l'utilisateur admin
4. Redémarrez le serveur
