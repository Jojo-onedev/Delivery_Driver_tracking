const express = require('express');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');

// Configuration de l'environnement
dotenv.config();

const app = express();

// Middleware
app.use(cors()); // Autorise toutes les origines pour le développement
app.use(express.json());

// Log des requêtes
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.originalUrl}`);
  next();
});

// Route de test (à placer AVANT la gestion des erreurs)
app.get('/api/test', (req, res) => {
  console.log('Test route called');
  res.json({ message: 'Test route works!' });
});

// Route d'accueil API
app.get('/', (req, res) => {
  res.status(200).json({ 
    application: 'Delivery Driver Tracking API',
    status: 'En ligne',
    environnement: process.env.NODE_ENV || 'développement',
    documentation: '/api-docs'
  });
});

// Configuration Swagger
const setupSwagger = require('./config/swagger');
setupSwagger(app);

// Routes publiques
app.use('/api/auth', require('./routes/auth'));

// Routes protégées
app.use('/api/deliveries', require('./routes/delivery'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/location', require('./routes/location'));

// Connexion MongoDB
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connecté avec succès');
    // Initialiser le compte admin après la connexion à la base de données
    if (process.env.NODE_ENV !== 'test') {
      const { exec } = require('child_process');
      exec('node scripts/initAdmin.js', (error, stdout, stderr) => {
        if (error) {
          console.error('Erreur lors de l\'initialisation admin:', error);
          return;
        }
        console.log('Initialisation admin terminée:', stdout);
      });
    }
  })
  .catch((err) => console.error('Erreur de connexion à MongoDB:', err));

// Gestion des erreurs 404
app.use((req, res) => {
  res.status(404).json({ message: 'Route non trouvée' });
});

// Gestion des erreurs globales
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Une erreur est survenue',
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Serveur en cours d'exécution sur le port ${PORT}`);  
});

// Gestion des erreurs non capturées
process.on('unhandledRejection', (err) => {
  console.error('Rejet non géré:', err);
  server.close(() => process.exit(1));
});