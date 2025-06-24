const { body } = require('express-validator');

// Validation pour l'inscription
exports.registerValidator = [
  body('name')
    .trim()
    .notEmpty().withMessage('Le nom est requis')
    .isLength({ min: 2, max: 30 }).withMessage('Le nom doit contenir entre 2 et 30 caractères'),
    
  body('email')
    .trim()
    .notEmpty().withMessage('L\'email est requis')
    .isEmail().withMessage('Veuillez fournir un email valide')
    .normalizeEmail(),
    
  body('password')
    .notEmpty().withMessage('Le mot de passe est requis')
    .isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
    .matches(/[0-9]/).withMessage('Le mot de passe doit contenir au moins un chiffre')
    .matches(/[a-zA-Z]/).withMessage('Le mot de passe doit contenir au moins une lettre')
];

// Validation pour la connexion
exports.loginValidator = [
  body('email')
    .trim()
    .notEmpty().withMessage('L\'email est requis')
    .isEmail().withMessage('Veuillez fournir un email valide')
    .normalizeEmail(),
    
  body('password')
    .notEmpty().withMessage('Le mot de passe est requis')
];

// Validation pour la mise à jour du profil
exports.updateProfileValidator = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 30 }).withMessage('Le nom doit contenir entre 2 et 30 caractères'),
    
  body('email')
    .optional()
    .trim()
    .isEmail().withMessage('Veuillez fournir un email valide')
    .normalizeEmail(),
    
  body('phone')
    .optional()
    .trim()
    .isMobilePhone().withMessage('Numéro de téléphone invalide')
];

// Validation pour le changement de mot de passe
exports.changePasswordValidator = [
  body('currentPassword')
    .notEmpty().withMessage('Le mot de passe actuel est requis'),
    
  body('newPassword')
    .notEmpty().withMessage('Le nouveau mot de passe est requis')
    .isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
    .matches(/[0-9]/).withMessage('Le mot de passe doit contenir au moins un chiffre')
    .matches(/[a-zA-Z]/).withMessage('Le mot de passe doit contenir au moins une lettre')
    .custom((value, { req }) => {
      if (value === req.body.currentPassword) {
        throw new Error('Le nouveau mot de passe doit être différent de l\'ancien');
      }
      return true;
    }),
    
  body('confirmPassword')
    .notEmpty().withMessage('Veuillez confirmer votre mot de passe')
    .custom((value, { req }) => {
      if (value !== req.body.newPassword) {
        throw new Error('Les mots de passe ne correspondent pas');
      }
      return true;
    })
];
