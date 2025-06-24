
const express = require('express');
const router = express.Router();
const { register, login, getProfile, updateProfile, changePassword } = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { 
  registerValidator, 
  loginValidator, 
  updateProfileValidator, 
  changePasswordValidator 
} = require('../validators/authValidator');
const { validate } = require('../middleware/validate');

// Routes d'authentification
router.post('/register', registerValidator, validate, register);
router.post('/login', loginValidator, validate, login);

// Routes protégées
router.use(authenticate);
router.get('/profile', getProfile);
router.put('/profile', updateProfileValidator, validate, updateProfile);
router.put('/change-password', changePasswordValidator, validate, changePassword);

module.exports = router;