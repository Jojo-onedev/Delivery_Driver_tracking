const { validationResult } = require('express-validator');

/**
 * Middleware pour gérer les erreurs de validation
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (errors.isEmpty()) {
    return next();
  }
  
  // Formater les erreurs pour une meilleure lisibilité
  const extractedErrors = [];
  errors.array().map(err => extractedErrors.push({ [err.path]: err.msg }));
  
  return res.status(422).json({
    status: 'error',
    message: 'Erreur de validation',
    errors: extractedErrors
  });
};

module.exports = { validate };
