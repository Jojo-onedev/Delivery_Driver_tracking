# API de Suivi des Chauffeurs Livreurs

## 📋 Table des matières
- [Prérequis](#-prérequis)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Démarrage](#-démarrage)
- [API Endpoints](#-api-endpoints)
- [État d'avancement](#-état-davancement)
- [Tests](#-tests)
- [Documentation technique](#-documentation-technique)
- [Maintenance](#-maintenance)

## 🛠 Prérequis

- Node.js (v14+)
- MongoDB (v4.4+)
- npm ou yarn

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

1. Créer un fichier `.env` à la racine du backend :
   ```
   PORT=5000
   MONGO_URI=mongodb://localhost:27017/delivery_tracking
   JWT_SECRET=votre_secret_jwt
   NODE_ENV=development
   ```

2. Variables d'environnement optionnelles :
   - `JWT_EXPIRE=30d` - Durée de validité du token JWT
   - `ADMIN_EMAIL=admin@delivery.com` - Email admin par défaut
   - `ADMIN_PASSWORD=Motdepasse123!` - Mot de passe admin par défaut

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

### Modèles de données

#### User
```javascript
{
  name: String,
  email: { type: String, unique: true },
  password: String,
  role: { type: String, enum: ['admin', 'driver', 'user'] },
  location: {
    type: { type: String, default: 'Point' },
    coordinates: [Number] // [longitude, latitude]
  },
  lastLocationUpdate: Date,
  status: { type: String, enum: ['offline', 'available', 'on_delivery'] },
  vehicule: String,
  licensePlate: String,
  rating: Number
}
```

#### LocationUpdate
```javascript
{
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  deliveryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Delivery' },
  location: {
    type: { type: String, default: 'Point' },
    coordinates: [Number] // [longitude, latitude]
  },
  accuracy: Number,
  speed: Number,
  heading: Number,
  altitude: Number,
  source: String,
  batteryLevel: Number,
  isCharging: Boolean,
  rawData: Object
}
```

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
