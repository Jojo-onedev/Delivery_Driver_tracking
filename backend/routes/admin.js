const express = require('express');
const router = express.Router();
const { getAllUsers, deleteUser } = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Routes protégées par authentification admin
router.get('/users', adminAuth, getAllUsers);
router.delete('/users/:id', adminAuth, deleteUser);

module.exports = router;
