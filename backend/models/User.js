const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

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
  passwordChangedAt: {
    type: Date,
    select: false
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
  vehicle: {
    type: String,
    enum: ['car', 'motorbike', 'bicycle', 'on_foot', null],
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

// Hachage du mot de passe avant la sauvegarde
userSchema.pre('save', async function(next) {
  // Ne rien faire si le mot de passe n'est pas modifié
  if (!this.isModified('password')) return next();
  
  // Hacher le mot de passe
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  
  // Mettre à jour la date de modification du mot de passe
  if (this.isModified('password') && !this.isNew) {
    this.passwordChangedAt = Date.now() - 1000; // -1s pour s'assurer que le token est émis après
  }
  
  next();
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
      vehicle: this.vehicle,
      lastUpdate: this.lastLocationUpdate
    },
    geometry: this.location || null
  };
};

// Vérifie si le mot de passe a été modifié après l'émission du token
userSchema.methods.changedPasswordAfter = function(JWTTimestamp) {
  if (this.passwordChangedAt) {
    const changedTimestamp = parseInt(
      this.passwordChangedAt.getTime() / 1000,
      10
    );
    return JWTTimestamp < changedTimestamp;
  }
  // False signifie que le mot de passe n'a pas été modifié
  return false;
};

userSchema.index({location: '2dsphere'});

module.exports = mongoose.model('User', userSchema);