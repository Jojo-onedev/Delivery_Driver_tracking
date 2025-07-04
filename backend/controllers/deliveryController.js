const Delivery = require('../models/Delivery');
const { validationResult } = require('express-validator');

// Créer une nouvelle livraison (Admin)
exports.createDelivery = async (req, res) => {
  try {
    const { orderId, customerName, address, driverId, phone, notes } = req.body;
    
    const delivery = new Delivery({
      orderId,
      customerName,
      address,
      phone,
      notes,
      driverId: driverId || null,
      status: driverId ? 'assigned' : 'pending'
    });

    await delivery.save();
    res.status(201).json(delivery);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la création de la livraison', error: error.message });
  }
};

// Obtenir toutes les livraisons
exports.getAllDeliveries = async (req, res) => {
  try {
    const { status, driver } = req.query;
    const filter = {};
    
    if (status) filter.status = status;
    if (driver) filter.driverId = driver;
    
    const deliveries = await Delivery.find(filter)
      .sort({ createdAt: -1 });
      
    res.json(deliveries);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// Obtenir une livraison par ID
exports.getDeliveryById = async (req, res) => {
  try {
    const delivery = await Delivery.findById(req.params.id);
    if (!delivery) {
      return res.status(404).json({ message: 'Livraison non trouvée' });
    }
    res.json(delivery);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// Mettre à jour le statut d'une livraison
exports.updateStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const allowedStatus = ['pending', 'picked', 'in_transit', 'delivered', 'assigned', 'cancelled','in_progress'];
    if (!allowedStatus.includes(status)) {
      return res.status(400).json({ message: 'Statut invalide.' });
    }

    const delivery = await Delivery.findByIdAndUpdate(
      id,
      { 
        status,
        ...(status === 'in_progress' && { pickedAt: new Date() }),
        ...(status === 'delivered' && { deliveredAt: new Date() })
      },
      { new: true }
    );

    if (!delivery) {
      return res.status(404).json({ message: 'Livraison non trouvée.' });
    }
    
    res.json(delivery);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// Affecter un chauffeur à une livraison (Admin)
exports.assignDriver = async (req, res) => {
  try {
    const { driverId } = req.body;
    
    const delivery = await Delivery.findByIdAndUpdate(
      req.params.id,
      { 
        driverId,
        status: 'assigned',
        assignedAt: new Date()
      },
      { new: true }
    );

    if (!delivery) {
      return res.status(404).json({ message: 'Livraison non trouvée' });
    }

    res.json(delivery);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// Supprimer une livraison (Admin)
exports.deleteDelivery = async (req, res) => {
  try {
    const delivery = await Delivery.findByIdAndDelete(req.params.id);
    
    if (!delivery) {
      return res.status(404).json({ message: 'Livraison non trouvée' });
    }
    
    res.json({ message: 'Livraison supprimée avec succès' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};