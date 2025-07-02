
const express = require('express');
const router = express.Router();
const { register, login, getProfile, logout } = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Authentication
 *   description: Gestion de l'authentification des utilisateurs
 */

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Enregistre un nouvel utilisateur
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               phone:
 *                 type: string
 *     responses:
 *       201:
 *         description: Utilisateur enregistré avec succès
 *       400:
 *         description: Données invalides
 */
router.post('/register', register);

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Connecte un utilisateur
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Connexion réussie
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         description: Email ou mot de passe incorrect
 */
router.post('/login', login);

/**
 * @swagger
 * /auth/profile:
 *   get:
 *     summary: Récupère le profil de l'utilisateur connecté
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profil utilisateur récupéré avec succès
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       401:
 *         description: Non autorisé
 */
router.get('/profile', authenticate, getProfile);

/**
 * @swagger
 * /auth/logout:
 *   post:
 *     summary: Déconnecte l'utilisateur
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Déconnexion réussie
 *       401:
 *         description: Non autorisé
 */

router.post('/logout', authenticate, logout);

module.exports = router;