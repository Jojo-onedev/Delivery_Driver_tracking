const express = require('express');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const cors = require('cors');

// Configuration de l'environnement
dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.originalUrl}`);
  next();
});

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

// Route de test
app.get('/', (req, res) => {
  res.status(200).json({ 
    application: 'Delivery Driver Tracking API',
    status: 'En ligne',
    environnement: process.env.NODE_ENV || 'développement',
    documentation: '/api-docs' // À implémenter avec Swagger si nécessaire
  });
});

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

// Test route - à ajouter avant app.listen
app.get('/api/test', (req, res) => {
  console.log('Test route called');
  res.json({ message: 'Test route works!' });
});

const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
  console.log(`Serveur en cours d'exécution sur le port ${PORT}`);  
});

// Gestion des erreurs non capturées
process.on('unhandledRejection', (err) => {
  console.error('Rejet non géré:', err);
  server.close(() => process.exit(1));
});