const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// Charger les variables d'environnement
dotenv.config();

const app = express();

console.log('Initialisation du serveur Express...');

// Middleware de sécurité
app.use(helmet()); // Protège contre les vulnérabilités courantes
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
app.use(express.json({ limit: '10kb' })); // Limite la taille du corps des requêtes

// Limite le taux de requêtes
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limite chaque IP à 100 requêtes par fenêtre
  message: 'Trop de requêtes depuis cette adresse IP, veuillez réessayer plus tard.'
});
app.use('/api/', limiter); // Applique à toutes les routes /api/*

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/admin', require('./routes/admin'));
// Ajoutez d'autres routes ici...

// Gestion des erreurs globales
app.use((err, req, res, next) => {
  console.error('Erreur non gérée:', err);
  console.error(err.stack);
  
  // Ne pas exposer les détails d'erreur en production
  const errorResponse = process.env.NODE_ENV === 'development' 
    ? { message: err.message, stack: err.stack }
    : { message: 'Une erreur est survenue' };
    
  res.status(err.status || 500).json(errorResponse);
});

// Gestion des routes non trouvées (doit être la dernière route)
app.all('*', (req, res) => {
  res.status(404).json({ 
    status: 'error',
    message: `Impossible de trouver ${req.originalUrl} sur ce serveur` 
  });
});

// Démarrer le serveur
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
  console.log(`✅ Serveur en cours d'exécution sur http://localhost:${PORT}`);
  console.log('Environnement:', process.env.NODE_ENV || 'development');
});

// Gestion des erreurs de démarrage du serveur
server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.error(`❌ Le port ${PORT} est déjà utilisé.`);
  } else {
    console.error('Erreur lors du démarrage du serveur:', error);
  }
  process.exit(1);
});

// Gestion des signaux de terminaison
process.on('SIGTERM', () => {
  console.log('Reçu SIGTERM. Arrêt gracieux du serveur...');
  server.close(() => {
    console.log('Serveur arrêté');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\nReçu SIGINT. Arrêt gracieux du serveur...');
  server.close(() => {
    console.log('Serveur arrêté');
    process.exit(0);
  });
});

// Exporter l'application et le serveur pour les tests
module.exports = { app, server };