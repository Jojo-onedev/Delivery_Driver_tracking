const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Middleware pour vérifier l'authentification
 * Vérifie la présence et la validité du token JWT
 * Ajoute l'utilisateur à l'objet req si authentifié
 */
const authenticate = async (req, res, next) => {
  try {
    // 1) Vérifier si le token existe
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ 
        status: 'error',
        message: 'Veuillez vous connecter pour accéder à cette ressource' 
      });
    }

    // 2) Vérifier et décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 3) Vérifier si l'utilisateur existe toujours
    const user = await User.findById(decoded.id).select('-password');
    if (!user) {
      return res.status(401).json({ 
        status: 'error',
        message: 'Le compte associé à ce token n\'existe plus' 
      });
    }

    // 4) Vérifier si le mot de passe n'a pas été modifié après la création du token
    if (user.changedPasswordAfter && user.changedPasswordAfter(decoded.iat)) {
      return res.status(401).json({
        status: 'error',
        message: 'Mot de passe récemment modifié. Veuillez vous reconnecter.'
      });
    }

    // 5) Ajouter l'utilisateur à la requête
    req.user = user;
    next();
  } catch (error) {
    // Gestion spécifique des erreurs JWT
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        status: 'error',
        message: 'Token invalide. Veuillez vous reconnecter.'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        status: 'error',
        message: 'Votre session a expiré. Veuillez vous reconnecter.'
      });
    }
    
    // Pour les autres types d'erreurs
    console.error('Erreur d\'authentification:', error);
    res.status(500).json({
      status: 'error',
      message: 'Une erreur est survenue lors de l\'authentification'
    });
  }
};

/**
 * Middleware pour vérifier les rôles utilisateur
 * @param  {...String} roles - Les rôles autorisés
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    // Vérifier si l'utilisateur est connecté
    if (!req.user) {
      return res.status(401).json({
        status: 'error',
        message: 'Non autorisé. Veuillez vous connecter.'
      });
    }

    // Vérifier si l'utilisateur a le bon rôle
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        status: 'error',
        message: 'Vous n\'avez pas les droits nécessaires pour effectuer cette action.'
      });
    }
    
    next();
  };
};

module.exports = { authenticate, authorize };