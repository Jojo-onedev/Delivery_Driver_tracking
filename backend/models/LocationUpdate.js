const mongoose = require('mongoose');

const pointSchema = new mongoose.Schema({
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

const locationUpdateSchema = new mongoose.Schema({
  driverId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: [true, 'L\'ID du chauffeur est requis'],
    index: true
  },
  // Référence à la livraison en cours (optionnel)
  deliveryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Delivery',
    index: true
  },
  // Position géographique
  location: {
    type: pointSchema,
    required: [true, 'La position est requise'],
    index: '2dsphere'
  },
  // Précision en mètres (si disponible)
  accuracy: {
    type: Number,
    min: 0
  },
  // Vitesse en m/s (si disponible)
  speed: {
    type: Number,
    min: 0
  },
  // Direction en degrés (0-360)
  heading: {
    type: Number,
    min: 0,
    max: 360
  },
  // Altitude en mètres (si disponible)
  altitude: Number,
  // Source de la localisation (GPS, réseau, etc.)
  source: {
    type: String,
    enum: ['gps', 'network', 'manual', 'other'],
    default: 'gps'
  },
  // Niveau de batterie (0-100)
  batteryLevel: {
    type: Number,
    min: 0,
    max: 100
  },
  // L'appareil est-il en charge ?
  isCharging: {
    type: Boolean,
    default: false
  },
  // Données brutes supplémentaires (si disponibles)
  rawData: {
    type: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true,
  // Crée automatiquement un index sur le champ createdAt
  // pour des requêtes chronologiques plus rapides
  autoIndex: true
});

// Index composé pour les requêtes fréquentes
locationUpdateSchema.index({ driverId: 1, createdAt: -1 });
locationUpdateSchema.index({ deliveryId: 1, createdAt: -1 });

// Méthode pour obtenir les données au format GeoJSON
locationUpdateSchema.methods.toGeoJSON = function() {
  return {
    type: 'Feature',
    properties: {
      id: this._id,
      driverId: this.driverId,
      deliveryId: this.deliveryId,
      timestamp: this.createdAt,
      speed: this.speed,
      heading: this.heading,
      accuracy: this.accuracy,
      batteryLevel: this.batteryLevel,
      isCharging: this.isCharging
    },
    geometry: this.location
  };
};

// Méthode statique pour obtenir le dernier point d'un chauffeur
locationUpdateSchema.statics.findLastByDriver = function(driverId, limit = 1) {
  return this.find({ driverId })
    .sort({ createdAt: -1 })
    .limit(limit);
};

// Méthode statique pour obtenir l'historique des positions d'une livraison
locationUpdateSchema.statics.getDeliveryPath = function(deliveryId) {
  return this.find({ deliveryId })
    .sort({ createdAt: 1 })
    .select('location.coordinates createdAt')
    .lean();
};

// Middleware pour nettoyer les anciennes entrées (garder 1000 points max par chauffeur)
locationUpdateSchema.post('save', async function() {
  try {
    // Compter le nombre total d'entrées pour ce chauffeur
    const count = await this.constructor.countDocuments({ driverId: this.driverId });
    
    // Si plus de 1000 entrées, supprimer les plus anciennes
    if (count > 1000) {
      const docsToDelete = await this.constructor
        .find({ driverId: this.driverId })
        .sort({ createdAt: 1 })
        .limit(count - 1000)
        .select('_id');
      
      if (docsToDelete.length > 0) {
        await this.constructor.deleteMany({ 
          _id: { $in: docsToDelete.map(doc => doc._id) } 
        });
      }
    }
  } catch (error) {
    console.error('Erreur lors du nettoyage des anciennes positions:', error);
  }
});

module.exports = mongoose.model('LocationUpdate', locationUpdateSchema);