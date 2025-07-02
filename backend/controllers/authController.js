const User = require('../models/User');
const jwt = require('jsonwebtoken');


const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

const register = async (req, res) => {
  try {
    const { name, email, password, phone, vehicule, licensePlate } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'A user with this email already exists.' });
    }

    // Créez un objet avec les données de base
    const userData = {
      name,
      email,
      password,
      role: 'driver'
    };

    // Ajoutez les champs optionnels s'ils sont fournis
    if (phone) userData.phone = phone;
    if (vehicule) userData.vehicule = vehicule;
    if (licensePlate) userData.licensePlate = licensePlate;

    // Créez l'utilisateur avec toutes les données
    const user = await User.create(userData);

    const token = generateToken(user._id);
    res.status(201).json({
      message: 'User successfully registered',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        vehicule: user.vehicule,
        licensePlate: user.licensePlate,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Erreur lors de l\'inscription:', error);
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
      return res.status(400).json({ message: 'Email and password required' });
    }
    
    // Recherche insensible à la casse pour l'email
    const user = await User.findOne({ email: { $regex: new RegExp('^' + email + '$', 'i') } });
    console.log('Utilisateur trouvé:', user ? 'Oui' : 'Non');
    
    if (!user) {
      console.log('Aucun utilisateur trouvé avec cet email');
      return res.status(401).json({ message: 'Incorrect email or password' });
    }
    
    console.log('Vérification du mot de passe...');
    const isPasswordValid = await user.comparePassword(password);
    console.log('Mot de passe valide:', isPasswordValid);
    
    if (!isPasswordValid) {
      console.log('Mot de passe incorrect');
      return res.status(401).json({ message: 'Incorrect email or password' });
    }
    const token = generateToken(user._id);
    res.json({
      message: 'Connexion successful',
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
      message: 'Server error during login',
      error: error.message
    });
  }
};

const logout = async (req, res) => {
  try {
    res.json({ message: 'Logout successful' });
  } catch (error) {
    res.status(500).json({
      message: 'Server error during logout',
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
      message: 'Server error while fetching profile',
      error: error.message
    });
  }
};

module.exports = { register, login, logout, getProfile };