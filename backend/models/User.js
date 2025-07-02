const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - name
 *         - email
 *         - password
 *         - role
 *       properties:
 *         id:
 *           type: string
 *           description: L'ID unique de l'utilisateur
 *         name:
 *           type: string
 *           description: Le nom complet de l'utilisateur
 *         email:
 *           type: string
 *           format: email
 *           description: L'email de l'utilisateur (unique)
 *         password:
 *           type: string
 *           format: password
 *           description: Le mot de passe haché
 *         phone:
 *           type: string
 *           description: Le numéro de téléphone de l'utilisateur
 *         role:
 *           type: string
 *           enum: [driver, admin]
 *           default: driver
 *           description: Le rôle de l'utilisateur
 *         status:
 *           type: string
 *           enum: [offline, available, on_delivery]
 *           default: offline
 *           description: Le statut actuel du chauffeur
 *         location:
 *           type: object
 *           properties:
 *             type:
 *               type: string
 *               enum: [Point]
 *               default: Point
 *             coordinates:
 *               type: array
 *               items:
 *                 type: number
 *               description: [longitude, latitude]
 *           description: La position géographique actuelle
 *         lastLocationUpdate:
 *           type: string
 *           format: date-time
 *           description: Date de la dernière mise à jour de position
 *         vehicule:
 *           type: string
 *           enum: [car, motorbike]
 *           nullable: true
 *           description: Le type de véhicule utilisé
 *         licensePlate:
 *           type: string
 *           description: La plaque d'immatriculation du véhicule
 *         rating:
 *           type: number
 *           minimum: 0
 *           maximum: 5
 *           default: 0
 *           description: La note moyenne de l'utilisateur
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: La date de création du compte
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: La date de dernière mise à jour du compte
 */

const locationSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['Point'],
    default: 'Point',
    required: true
  },
  coordinates: {
    type: [Number], // [longitude, latitude]
    required: true,
    validate: {
      validator: function(v) {
        return v.length === 2 && 
               v[0] >= -180 && v[0] <= 180 && 
               v[1] >= -90 && v[1] <= 90;
      },
      message: props => `${props.value} n'est pas une position géographique valide!`
    }
  }
});

const userSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: [true, 'Le nom est requis'],
    trim: true
  },
  email: { 
    type: String, 
    required: [true, 'L\'email est requis'],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\S+@\S+\.\S+$/, 'Veuillez entrer un email valide']
  },
  password: { 
    type: String, 
    required: [true, 'Le mot de passe est requis'],
    minlength: [6, 'Le mot de passe doit contenir au moins 6 caractères']
  },
  phone: {
    type: String,
    trim: true
  },
  role: { 
    type: String, 
    enum: ['driver', 'admin'], 
    default: 'driver' 
  },
  // Dernière position connue du chauffeur
  location: {
    type: locationSchema,
    sparse: true
  },
  // Statut du chauffeur (hors service, disponible, en livraison)
  status: {
    type: String,
    enum: ['offline', 'available', 'on_delivery'],
    default: 'offline'
  },
  // Dernière mise à jour de position
  lastLocationUpdate: {
    type: Date
  },
  // Véhicule du chauffeur (optionnel)
  vehicule: {
    type: String,
    enum: ['car', 'motorbike'],
    default: null
  },
  // Numéro de plaque d'immatriculation (si véhicule)
  licensePlate: {
    type: String,
    trim: true,
    uppercase: true
  },
  // Note moyenne du chauffeur
  rating: {
    type: Number,
    min: 0,
    max: 5,
    default: 0
  }
}, {
  timestamps: true
});

// Index pour les recherches géospatiales
userSchema.index({ location: '2dsphere' });

// Hash le mot de passe avant sauvegarde
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Méthode pour comparer les mots de passe
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Méthode pour mettre à jour la localisation
userSchema.methods.updateLocation = async function(coordinates) {
  this.location = {
    type: 'Point',
    coordinates: coordinates
  };
  this.lastLocationUpdate = new Date();
  return this.save();
};

// Méthode pour calculer la distance avec un autre point (en mètres)
userSchema.methods.calculateDistance = function(coordinates) {
  if (!this.location) return null;
  
  const R = 6371e3; // Rayon de la Terre en mètres
  const φ1 = this.location.coordinates[1] * Math.PI/180; // φ, λ en radians
  const φ2 = coordinates[1] * Math.PI/180;
  const Δφ = (coordinates[1] - this.location.coordinates[1]) * Math.PI/180;
  const Δλ = (coordinates[0] - this.location.coordinates[0]) * Math.PI/180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // en mètres
};

// Méthode pour obtenir la position au format GeoJSON
userSchema.methods.toGeoJSON = function() {
  return {
    type: 'Feature',
    properties: {
      id: this._id,
      name: this.name,
      status: this.status,
      vehicule: this.vehicule,
      lastUpdate: this.lastLocationUpdate
    },
    geometry: this.location || null
  };
};

module.exports = mongoose.model('User', userSchema);