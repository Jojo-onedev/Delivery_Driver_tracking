const mongoose = require('mongoose');

const deliverySchema = new mongoose.Schema({
  orderId: { type: String, required: true },
  customerName: { type: String, required: true },
  address: { type: String, required: true },
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  status: { type: String, enum: ['pending', 'picked', 'in_transit', 'delivered'], default: 'pending' },
  assignedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Delivery', deliverySchema);