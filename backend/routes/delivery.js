const express = require('express');
const router = express.Router();
const { 
  createDelivery,
  getAllDeliveries,
  getDeliveryById,
  updateStatus,
  assignDriver,
  deleteDelivery
} = require('../controllers/deliveryController');
const { authenticate } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Routes publiques (authentification requise)
router.use(authenticate);

// Créer une livraison (Admin uniquement)
router.post('/', adminAuth, createDelivery);

// Obtenir toutes les livraisons (avec filtres optionnels)
router.get('/', getAllDeliveries);

// Obtenir une livraison spécifique
router.get('/:id', getDeliveryById);

// Mettre à jour le statut d'une livraison
router.patch('/:id/status', updateStatus);

// Affecter un chauffeur à une livraison (Admin uniquement)
router.patch('/:id/assign', adminAuth, assignDriver);

// Supprimer une livraison (Admin uniquement)
router.delete('/:id', adminAuth, deleteDelivery);

module.exports = router;