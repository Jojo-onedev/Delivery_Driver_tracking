const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const { authenticate } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Localisation
 *   description: Gestion des positions GPS et géolocalisation
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     LocationUpdate:
 *       type: object
 *       required:
 *         - coordinates
 *       properties:
 *         coordinates:
 *           type: array
 *           items:
 *             type: number
 *           example: [2.3522, 48.8566]
 *           description: [longitude, latitude]
 *         accuracy:
 *           type: number
 *           description: Précision en mètres
 *         speed:
 *           type: number
 *           description: Vitesse en m/s
 *         heading:
 *           type: number
 *           description: Direction en degrés (0-360)
 *         altitude:
 *           type: number
 *           description: Altitude en mètres
 *         deliveryId:
 *           type: string
 *           description: ID de la livraison en cours (optionnel)
 *         source:
 *           type: string
 *           enum: [gps, network, manual, other]
 *           default: gps
 *         batteryLevel:
 *           type: number
 *           minimum: 0
 *           maximum: 100
 *         isCharging:
 *           type: boolean
 *           default: false
 * 
 *     NearbyDriversQuery:
 *       type: object
 *       properties:
 *         longitude:
 *           type: number
 *           required: true
 *           example: 2.3522
 *         latitude:
 *           type: number
 *           required: true
 *           example: 48.8566
 *         maxDistance:
 *           type: number
 *           default: 5000
 *           description: Distance maximale en mètres
 *         limit:
 *           type: number
 *           default: 10
 * 
 *     RouteQuery:
 *       type: object
 *       required:
 *         - origin
 *         - destination
 *       properties:
 *         origin:
 *           type: string
 *           example: "2.3522,48.8566"
 *         destination:
 *           type: string
 *           example: "2.2945,48.8584"
 *         mode:
 *           type: string
 *           enum: [driving, walking, cycling]
 *           default: driving
 */

// Middleware pour vérifier si l'utilisateur est un chauffeur
const isDriver = (req, res, next) => {
  if (req.user.role !== 'driver') {
    return res.status(403).json({ message: 'Accès refusé. Réservé aux chauffeurs.' });
  }
  next();
};

/**
 * @swagger
 * /api/location/update:
 *   post:
 *     summary: Mettre à jour la position GPS actuelle (chauffeurs uniquement)
 *     tags: [Localisation]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/LocationUpdate'
 *     responses:
 *       200:
 *         description: Position mise à jour avec succès
 *       400:
 *         description: Données de localisation invalides
 *       403:
 *         description: Accès refusé (chauffeurs uniquement)
 */
router.post('/update', authenticate, isDriver, locationController.updateLocation);

/**
 * @swagger
 * /api/location/driver/{driverId}:
 *   get:
 *     summary: Obtenir la dernière position connue d'un chauffeur
 *     tags: [Localisation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: driverId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du chauffeur
 *     responses:
 *       200:
 *         description: Dernière position du chauffeur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/LocationUpdate'
 *       404:
 *         description: Aucune position trouvée pour ce chauffeur
 */
router.get('/driver/:driverId', authenticate, locationController.getDriverLocation);

/**
 * @swagger
 * /api/location/history/{driverId}:
 *   get:
 *     summary: Obtenir l'historique des positions d'un chauffeur
 *     tags: [Localisation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: driverId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID du chauffeur
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de début (ISO 8601)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Date de fin (ISO 8601)
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 100
 *         description: Nombre maximum de points à retourner
 *     responses:
 *       200:
 *         description: Historique des positions
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/LocationUpdate'
 */
router.get('/history/:driverId', authenticate, locationController.getLocationHistory);

/**
 * @swagger
 * /api/location/nearby:
 *   get:
 *     summary: Trouver les chauffeurs à proximité
 *     tags: [Localisation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *         example: 2.3522
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *         example: 48.8566
 *       - in: query
 *         name: maxDistance
 *         schema:
 *           type: number
 *           default: 5000
 *         description: Distance maximale en mètres
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *     responses:
 *       200:
 *         description: Liste des chauffeurs à proximité
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   driverId:
 *                     type: string
 *                   distance:
 *                     type: number
 *                     description: Distance en mètres
 *                   location:
 *                     $ref: '#/components/schemas/LocationUpdate'
 */
router.get('/nearby', authenticate, locationController.findNearbyDrivers);

/**
 * @swagger
 * /api/location/route:
 *   get:
 *     summary: Calculer un itinéraire entre deux points
 *     tags: [Localisation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: origin
 *         required: true
 *         schema:
 *           type: string
 *         example: "2.3522,48.8566"
 *         description: Coordonnées d'origine (longitude,latitude)
 *       - in: query
 *         name: destination
 *         required: true
 *         schema:
 *           type: string
 *         example: "2.2945,48.8584"
 *         description: Coordonnées de destination (longitude,latitude)
 *       - in: query
 *         name: mode
 *         schema:
 *           type: string
 *           enum: [driving, walking, cycling]
 *           default: driving
 *     responses:
 *       200:
 *         description: Itinéraire calculé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 distance:
 *                   type: number
 *                   description: Distance en mètres
 *                 duration:
 *                   type: number
 *                   description: Durée en secondes
 *                 polyline:
 *                   type: string
 *                   description: Polyligne encodée pour l'affichage sur carte
 */
router.get('/route', authenticate, locationController.calculateRoute);

module.exports = router;
