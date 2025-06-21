const mongoose = require('mongoose');

const locationUpdateSchema = new mongoose.Schema({
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  coordinates: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true } // [longitude, latitude]
  },
  timestamp: { type: Date, default: Date.now }
});

locationUpdateSchema.index({ coordinates: '2dsphere' });

module.exports = mongoose.model('LocationUpdate', locationUpdateSchema);