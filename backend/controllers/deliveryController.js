const Delivery = require('../models/Delivery');

exports.updateStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  // Vérifier que le statut est valide
  const allowedStatus = ['pending', 'in_transit', 'delivered'];
  if (!allowedStatus.includes(status)) {
    return res.status(400).json({ message: 'Statut invalide.' });
  }

  try {
    const delivery = await Delivery.findByIdAndUpdate(
      id,
      { status },
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