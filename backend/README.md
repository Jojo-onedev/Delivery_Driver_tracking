# 🚚 API de Suivi des Chauffeurs Livreurs

API sécurisée pour le suivi en temps réel des chauffeurs livreurs avec gestion des livraisons et authentification avancée.

## 📋 Table des matières
- [Fonctionnalités](#-fonctionnalités)
- [Sécurité](#-sécurité)
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Démarrage](#-démarrage)
- [API Endpoints](#-api-endpoints)
- [Tests](#-tests)
- [Documentation technique](#-documentation-technique)
- [Déploiement](#-déploiement)
- [Maintenance](#-maintenance)
- [Contribuer](#-contribuer)

## ✨ Fonctionnalités

- 🔒 Authentification sécurisée avec JWT
- 🛣️ Suivi en temps réel des chauffeurs
- 📍 Gestion des livraisons
- 👨‍💻 Interface d'administration
- 📱 API RESTful complète
- 🚀 Performances optimisées
- 🛡️ Protection contre les attaques courantes

## 🔒 Sécurité

- Validation des entrées utilisateur
- Protection contre les attaques XSS et CSRF
- Rate limiting (100 requêtes/15 minutes)
- En-têtes de sécurité HTTP
- Mots de passe hachés avec bcrypt
- Tokens JWT sécurisés
- Protection contre les attaques par force brute

## 🛠 Prérequis

- Node.js (v16+)
- MongoDB (v5.0+)
- npm (v8+) ou yarn (v1.22+)

## ⚙️ Installation

1. Cloner le dépôt :
   ```bash
   git clone <url-du-repo>
   cd Delivery_Driver_tracking/backend
   ```

2. Installer les dépendances :
   ```bash
   npm install
   ```
   ou
   ```bash
   yarn
   ```

## 🔧 Configuration

1. Copier le fichier d'exemple :
   ```bash
   cp .env.example .env
   ```

2. Configurer les variables dans `.env` :
   ```env
   # Configuration du serveur
   PORT=5000
   NODE_ENV=development
   
   # Base de données
   MONGO_URI=mongodb://localhost:27017/delivery_tracking
   
   # JWT
   JWT_SECRET=votre_secret_jwt_tres_long_et_complexe
   JWT_EXPIRES_IN=30d
   
   # Configuration Admin
   ADMIN_EMAIL=admin@delivery.com
   ADMIN_PASSWORD=Motdepasse123!
   
   # URL du frontend
   FRONTEND_URL=http://localhost:3000
   ```

### Variables d'environnement importantes

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `PORT` | Port d'écoute du serveur | 5000 |
| `MONGO_URI` | URI de connexion MongoDB | - |
| `JWT_SECRET` | Clé secrète pour les JWT | - |
| `JWT_EXPIRES_IN` | Durée de validité des tokens | 30d |
| `NODE_ENV` | Environnement d'exécution | development |
| `FRONTEND_URL` | URL du frontend pour CORS | http://localhost:3000 |

## 🚀 Démarrage

### Mode développement
```bash
npm run dev
```

### Mode production
```bash
npm start
```

## 🌐 API Endpoints

### Authentification
- `POST /api/auth/register` - Créer un nouveau compte
- `POST /api/auth/login` - Se connecter

### Gestion des utilisateurs (Admin)
- `GET /api/admin/users` - Lister tous les utilisateurs
- `GET /api/admin/users/:id` - Obtenir un utilisateur
- `PUT /api/admin/users/:id` - Mettre à jour un utilisateur
- `DELETE /api/admin/users/:id` - Supprimer un utilisateur

### Géolocalisation
- `POST /api/location/update` - Mettre à jour la position (Driver)
- `GET /api/location/driver/:driverId` - Obtenir la position d'un chauffeur
- `GET /api/location/history/:driverId` - Historique des positions
- `GET /api/location/nearby` - Chauffeurs à proximité
- `GET /api/location/route` - Calculer un itinéraire

## 📊 État d'avancement

### ✅ Terminé
- [x] Authentification JWT
- [x] Gestion des utilisateurs (CRUD)
- [x] Modèles de données (User, LocationUpdate)
- [x] Mise à jour de la position en temps réel
- [x] Historique des positions
- [x] Recherche de chauffeurs à proximité

### 🚧 En cours/À faire
- [ ] Documentation Swagger/OpenAPI
- [ ] Tests unitaires et d'intégration
- [ ] Intégration avec un service de cartographie (Google Maps/OSRM)
- [ ] Notifications en temps réel (WebSocket)
- [ ] Système de géofencing
- [ ] Optimisation des requêtes géospatiales

## 🧪 Tests

### Lancer les tests
```bash
npm test
```

### Couverture de code
```bash
npm run test:coverage
```

## 📚 Documentation technique

### Structure du projet
```
backend/
├── config/           # Fichiers de configuration
├── controllers/       # Contrôleurs de l'API
├── middleware/        # Middlewares personnalisés
│   ├── auth.js       # Authentification
│   ├── validate.js   # Validation des données
│   └── error.js      # Gestion des erreurs
├── models/           # Modèles Mongoose
├── routes/           # Définition des routes
├── tests/            # Tests automatisés
│   ├── unit/         # Tests unitaires
│   └── integration/  # Tests d'intégration
├── validators/       # Validation des données
├── .env.example      # Exemple de variables d'environnement
├── .gitignore        # Fichiers à ignorer par git
├── index.js          # Point d'entrée de l'application
├── package.json      # Dépendances et scripts
└── SECURITY.md       # Documentation de sécurité
```

### Architecture
- **MVC** : Modèle-Vue-Contrôleur
- **RESTful** : API conforme aux principes REST
- **JWT** : Authentification sans état
- **MongoDB** : Base de données NoSQL
- **Mongoose** : ODM pour MongoDB

### Bonnes pratiques
- Code modulaire
- Gestion centralisée des erreurs
- Validation des entrées
- Logging approprié
- Documentation claire
- Tests automatisés
- Protection contre les attaques XSS et CSRF
- Rate limiting (100 requêtes/15 minutes)
- En-têtes de sécurité HTTP
- Mots de passe hachés avec bcrypt
- Tokens JWT sécurisés

## 🔧 Maintenance

### Réinitialisation du mot de passe admin
1. Arrêter le serveur
2. Se connecter à MongoDB
3. Mettre à jour le mot de passe haché pour l'utilisateur admin
4. Redémarrer le serveur

### Nettoyage de la base de données
Pour nettoyer les anciennes entrées de localisation :
```bash
node scripts/cleanupLocationHistory.js
```

## 👥 Contribution

1. Créer une branche : `git checkout -b feature/nouvelle-fonctionnalite`
2. Committer vos modifications : `git commit -m 'Ajout d\'une nouvelle fonctionnalité'`
3. Pousser la branche : `git push origin feature/nouvelle-fonctionnalite`
4. Créer une Pull Request

## 📝 Licence

[À définir]
