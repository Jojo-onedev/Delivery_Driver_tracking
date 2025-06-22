const mongoose = require('mongoose');

const deliverySchema = new mongoose.Schema({
  orderId: { 
    type: String, 
    required: [true, 'L\'ID de commande est requis'],
    unique: true,
    trim: true
  },
  customerName: { 
    type: String, 
    required: [true, 'Le nom du client est requis'],
    trim: true
  },
  address: { 
    type: String, 
    required: [true, 'L\'adresse de livraison est requise'],
    trim: true
  },
  phone: {
    type: String,
    trim: true
  },
  driverId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    index: true
  },
  status: { 
    type: String, 
    enum: ['pending', 'assigned', 'picked', 'in_transit', 'delivered'], 
    default: 'pending',
    index: true
  },
  assignedAt: { 
    type: Date,
    default: null
  },
  pickedAt: {
    type: Date,
    default: null
  },
  deliveredAt: {
    type: Date,
    default: null
  },
  notes: {
    type: String,
    trim: true
  },
  estimatedDeliveryTime: {
    type: Date
  },
  actualDeliveryTime: {
    type: Date
  }
}, {
  timestamps: true
});

// Index pour les recherches fréquentes
deliverySchema.index({ orderId: 1 });
deliverySchema.index({ status: 1, driverId: 1 });

module.exports = mongoose.model('Delivery', deliverySchema);