const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');


const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'A user with this email already exists.' });
    }
    const user = await User.create({
      name,
      email,
      password,
      role: 'driver'  // Toujours définir comme driver
    });
    const token = generateToken(user._id);
    res.status(201).json({
      message: 'User successfully registered',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
      
  } catch (error) {
    res.status(400).json({
      message: 'Erreur lors de l\'inscription',
      error: error.message
    });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log('Tentative de connexion avec:', { email });
    
    if (!email || !password) {
      console.log('Email ou mot de passe manquant');
      return res.status(400).json({ message: 'Email et mot de passe requis' });
    }
    
    // Recherche insensible à la casse pour l'email
    const user = await User.findOne({ email: { $regex: new RegExp('^' + email + '$', 'i') } });
    console.log('Utilisateur trouvé:', user ? 'Oui' : 'Non');
    
    if (!user) {
      console.log('Aucun utilisateur trouvé avec cet email');
      return res.status(401).json({ message: 'Incorrect email ou mot de passe' });
    }
    
    console.log('Vérification du mot de passe...');
    const isPasswordValid = await user.comparePassword(password);
    console.log('Mot de passe valide:', isPasswordValid);
    
    if (!isPasswordValid) {
      console.log('Mot de passe incorrect');
      return res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }
    const token = generateToken(user._id);
    res.json({
      message: 'Connexion réussie',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({
      message: 'Erreur serveur lors de la connexion',
      error: error.message
    });
  }
};

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json({ user });
  } catch (error) {
    res.status(500).json({
      message: 'Erreur serveur lors de la récupération du profil',
      error: error.message
    });
  }
};

// Mettre à jour le profil utilisateur
const updateProfile = async (req, res) => {
  try {
    const updates = Object.keys(req.body);
    const allowedUpdates = ['name', 'email', 'phone'];
    const isValidOperation = updates.every(update => allowedUpdates.includes(update));

    if (!isValidOperation) {
      return res.status(400).json({ 
        status: 'error',
        message: 'Mise à jour non autorisée' 
      });
    }

    updates.forEach(update => req.user[update] = req.body[update]);
    await req.user.save();

    res.json({
      status: 'success',
      message: 'Profil mis à jour avec succès',
      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        phone: req.user.phone,
        role: req.user.role
      }
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        status: 'error',
        message: 'Cet email est déjà utilisé par un autre compte'
      });
    }
    res.status(500).json({
      status: 'error',
      message: 'Erreur lors de la mise à jour du profil',
      error: error.message
    });
  }
};

// Changer le mot de passe
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    
    // Vérifier l'ancien mot de passe
    const isMatch = await bcrypt.compare(currentPassword, req.user.password);
    if (!isMatch) {
      return res.status(400).json({
        status: 'error',
        message: 'Le mot de passe actuel est incorrect'
      });
    }

    // Mettre à jour le mot de passe
    req.user.password = newPassword;
    await req.user.save();

    res.json({
      status: 'success',
      message: 'Mot de passe mis à jour avec succès'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Erreur lors du changement de mot de passe',
      error: error.message
    });
  }
};

module.exports = { 
  register, 
  login, 
  getProfile, 
  updateProfile, 
  changePassword 
};