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

/**
 * @swagger
 * tags:
 *   name: Livraisons
 *   description: Gestion des livraisons
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Delivery:
 *       type: object
 *       required:
 *         - orderId
 *         - customerName
 *         - address
 *         - phone
 *       properties:
 *         orderId:
 *           type: string
 *           description: Numéro de commande unique
 *         customerName:
 *           type: string
 *           description: Nom du client
 *         address:
 *           type: string
 *           description: Adresse de livraison
 *         phone:
 *           type: string
 *           description: Téléphone du client
 *         notes:
 *           type: string
 *           description: Notes supplémentaires
 *         status:
 *           type: string
 *           enum: [pending, in_transit, delivered, cancelled]
 *           default: pending
 *           description: Statut de la livraison
 *         driverId:
 *           type: string
 *           description: ID du chauffeur affecté
 */

// Routes publiques (authentification requise)
router.use(authenticate);

/**
 * @swagger
 * /api/deliveries:
 *   post:
 *     summary: Créer une nouvelle livraison (Admin uniquement)
 *     tags: [Livraisons]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Delivery'
 *     responses:
 *       201:
 *         description: Livraison créée avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé (admin uniquement)
 */
router.post('/', adminAuth, createDelivery);

/**
 * @swagger
 * /api/deliveries:
 *   get:
 *     summary: Obtenir la liste des livraisons
 *     tags: [Livraisons]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, in_transit, delivered, cancelled]
 *         description: Filtrer par statut
 *       - in: query
 *         name: driver
 *         schema:
 *           type: string
 *         description: Filtrer par ID de chauffeur
 *     responses:
 *       200:
 *         description: Liste des livraisons
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Delivery'
 */
router.get('/', getAllDeliveries);

/**
 * @swagger
 * /api/deliveries/{id}:
 *   get:
 *     summary: Obtenir une livraison par son ID
 *     tags: [Livraisons]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la livraison
 *     responses:
 *       200:
 *         description: Détails de la livraison
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Delivery'
 *       404:
 *         description: Livraison non trouvée
 */
router.get('/:id', getDeliveryById);

/**
 * @swagger
 * /api/deliveries/{id}/status:
 *   patch:
 *     summary: Mettre à jour le statut d'une livraison
 *     tags: [Livraisons]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la livraison
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, in_transit, delivered, cancelled]
 *     responses:
 *       200:
 *         description: Statut mis à jour
 *       400:
 *         description: Statut invalide
 *       404:
 *         description: Livraison non trouvée
 */
router.patch('/:id/status', updateStatus);

/**
 * @swagger
 * /api/deliveries/{id}/assign:
 *   patch:
 *     summary: Affecter un chauffeur à une livraison (Admin uniquement)
 *     tags: [Livraisons]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la livraison
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - driverId
 *             properties:
 *               driverId:
 *                 type: string
 *                 description: ID du chauffeur à affecter
 *     responses:
 *       200:
 *         description: Chauffeur affecté avec succès
 *       400:
 *         description: Données invalides
 *       403:
 *         description: Accès refusé (admin uniquement)
 *       404:
 *         description: Livraison ou chauffeur non trouvé
 */
router.patch('/:id/assign', adminAuth, assignDriver);

/**
 * @swagger
 * /api/deliveries/{id}:
 *   delete:
 *     summary: Supprimer une livraison (Admin uniquement)
 *     tags: [Livraisons]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la livraison à supprimer
 *     responses:
 *       200:
 *         description: Livraison supprimée
 *       403:
 *         description: Accès refusé (admin uniquement)
 *       404:
 *         description: Livraison non trouvée
 */
router.delete('/:id', adminAuth, deleteDelivery);

module.exports = router;