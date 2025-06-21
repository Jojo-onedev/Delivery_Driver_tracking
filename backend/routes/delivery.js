const express = require('express');
const router = express.Router();
const { updateStatus } = require('../controllers/deliveryController');
const { authenticate } = require('../middleware/auth');

// Route pour mettre à jour le statut d'une livraison
router.patch('/:id/status', authenticate, updateStatus);

module.exports = router;