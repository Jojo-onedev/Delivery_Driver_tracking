const jwt = require('jsonwebtoken');
const User = require('../models/User');

const adminAuth = async (req, res, next) => {
  try {
    // Vérifier le token dans le header Authorization
    const authHeader = req.header('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Accès non autorisé - Pas de token fourni' });
    }

    const token = authHeader.split(' ')[1];
    
    // Vérifier le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Vérifier si l'utilisateur existe et est admin
    const user = await User.findById(decoded.id).select('-password');
    if (!user) {
      return res.status(401).json({ message: 'Utilisateur non trouvé' });
    }
    
    if (user.role !== 'admin') {
      return res.status(403).json({ message: 'Accès refusé - Droits insuffisants' });
    }
    
    req.user = user;
    next();
  } catch (error) {
    console.error('Erreur d\'authentification admin:', error);
    res.status(401).json({ message: 'Token invalide ou expiré' });
  }
};

module.exports = adminAuth;
