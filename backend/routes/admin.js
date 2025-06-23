const express = require('express');
const router = express.Router();
const { getAllUsers, getUser, updateUser, deleteUser } = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Routes protégées par authentification admin
router.get('/users', adminAuth, getAllUsers);
router.get('/users/:id', adminAuth, getUser);
router.put('/users/:id', adminAuth, updateUser);
router.delete('/users/:id', adminAuth, deleteUser);

module.exports = router;
