const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const { authenticate } = require('../middleware/auth');

// Middleware pour vérifier si l'utilisateur est un chauffeur
const isDriver = (req, res, next) => {
  if (req.user.role !== 'driver') {
    return res.status(403).json({ message: 'Accès refusé. Réservé aux chauffeurs.' });
  }
  next();
};

// Mettre à jour la position actuelle (pour les chauffeurs)
router.post('/update', authenticate, isDriver, locationController.updateLocation);

// Obtenir la position actuelle d'un chauffeur
router.get('/driver/:driverId', authenticate, locationController.getDriverLocation);

// Obtenir l'historique des positions d'un chauffeur
router.get('/history/:driverId', authenticate, locationController.getLocationHistory);

// Trouver les chauffeurs à proximité
router.get('/nearby', authenticate, locationController.findNearbyDrivers);

// Calculer un itinéraire
router.get('/route', authenticate, locationController.calculateRoute);

module.exports = router;
