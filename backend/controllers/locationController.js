const LocationUpdate = require('../models/LocationUpdate');
const User = require('../models/User');
const Delivery = require('../models/Delivery');

// Mettre à jour la position actuelle du chauffeur
exports.updateLocation = async (req, res) => {
  try {
    const { coordinates, accuracy, speed, heading, altitude, batteryLevel, isCharging } = req.body;
    const driverId = req.user.id;

    // Validation des coordonnées
    if (!coordinates || !Array.isArray(coordinates) || coordinates.length !== 2) {
      return res.status(400).json({ message: 'Coordonnées GPS invalides' });
    }

    const [longitude, latitude] = coordinates;
    
    // Validation des valeurs numériques
    if (isNaN(longitude) || isNaN(latitude) || 
        longitude < -180 || longitude > 180 || 
        latitude < -90 || latitude > 90) {
      return res.status(400).json({ message: 'Coordonnées GPS invalides' });
    }

    // Mettre à jour la position dans le modèle User
    await User.findByIdAndUpdate(driverId, {
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      lastLocationUpdate: new Date(),
      status: 'available' // Mettre à jour le statut si nécessaire
    });

    // Créer une nouvelle entrée dans l'historique
    const locationUpdate = new LocationUpdate({
      driverId,
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      accuracy,
      speed,
      heading,
      altitude,
      batteryLevel,
      isCharging,
      source: 'gps'
    });

    // Si le chauffeur a une livraison en cours, l'ajouter à l'historique
    const activeDelivery = await Delivery.findOne({
      driverId,
      status: { $in: ['assigned', 'picked', 'in_transit'] }
    }).sort({ createdAt: -1 });

    if (activeDelivery) {
      locationUpdate.deliveryId = activeDelivery._id;
    }

    await locationUpdate.save();

    res.status(200).json({
      message: 'Position mise à jour avec succès',
      location: {
        type: 'Point',
        coordinates: [longitude, latitude]
      },
      timestamp: new Date()
    });

  } catch (error) {
    console.error('Erreur lors de la mise à jour de la position:', error);
    res.status(500).json({ message: 'Erreur serveur lors de la mise à jour de la position' });
  }
};

// Obtenir la position actuelle d'un chauffeur
exports.getDriverLocation = async (req, res) => {
  try {
    const { driverId } = req.params;
    
    const driver = await User.findById(driverId)
      .select('name location lastLocationUpdate status vehicule')
      .lean();

    if (!driver) {
      return res.status(404).json({ message: 'Chauffeur non trouvé' });
    }

    if (!driver.location) {
      return res.status(404).json({ message: 'Aucune position disponible pour ce chauffeur' });
    }

    res.status(200).json({
      driverId,
      name: driver.name,
      status: driver.status,
      vehicule: driver.vehicule,
      location: driver.location,
      lastUpdate: driver.lastLocationUpdate
    });

  } catch (error) {
    console.error('Erreur lors de la récupération de la position:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Obtenir l'historique des positions d'un chauffeur
exports.getLocationHistory = async (req, res) => {
  try {
    const { driverId } = req.params;
    const { startDate, endDate, limit = 100 } = req.query;

    const query = { driverId };
    
    // Filtrer par période si spécifiée
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const history = await LocationUpdate.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .select('location.coordinates createdAt')
      .lean();

    // Formater la réponse en GeoJSON
    const geoJson = {
      type: 'FeatureCollection',
      features: history.map(update => ({
        type: 'Feature',
        properties: {
          timestamp: update.createdAt
        },
        geometry: update.location
      }))
    };

    res.status(200).json(geoJson);

  } catch (error) {
    console.error('Erreur lors de la récupération de l\'historique:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Trouver les chauffeurs à proximité
exports.findNearbyDrivers = async (req, res) => {
  try {
    const { longitude, latitude, maxDistance = 5000 } = req.query; // maxDistance en mètres

    if (!longitude || !latitude) {
      return res.status(400).json({ message: 'Les coordonnées sont requises' });
    }

    const point = {
      type: 'Point',
      coordinates: [parseFloat(longitude), parseFloat(latitude)]
    };

    const nearbyDrivers = await User.aggregate([
      {
        $geoNear: {
          near: point,
          distanceField: 'distance',
          maxDistance: parseFloat(maxDistance),
          spherical: true,
          query: { 
            role: 'driver',
            status: 'available',
            'location.coordinates': { $exists: true }
          }
        }
      },
      {
        $project: {
          name: 1,
          email: 1,
          phone: 1,
          vehicule: 1,
          'location.coordinates': 1,
          distance: { $round: ['$distance', 2] }, // Arrondir à 2 décimales
          lastLocationUpdate: 1
        }
      },
      { $sort: { distance: 1 } }, // Trier par distance croissante
      { $limit: 20 } // Limiter à 20 résultats
    ]);

    res.status(200).json({
      type: 'FeatureCollection',
      features: nearbyDrivers.map(driver => ({
        type: 'Feature',
        properties: {
          id: driver._id,
          name: driver.name,
          email: driver.email,
          phone: driver.phone,
          vehicule: driver.vehicule,
          distance: driver.distance,
          lastUpdate: driver.lastLocationUpdate
        },
        geometry: {
          type: 'Point',
          coordinates: driver.location.coordinates
        }
      }))
    });

  } catch (error) {
    console.error('Erreur lors de la recherche de chauffeurs à proximité:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

// Calculer l'itinéraire entre deux points
exports.calculateRoute = async (req, res) => {
  try {
    const { origin, destination } = req.query;
    
    // Ici, vous pourriez intégrer un service comme Google Maps Directions API
    // ou OSRM (Open Source Routing Machine) pour calculer l'itinéraire
    // Pour l'instant, on retourne simplement une ligne droite entre les points
    
    if (!origin || !destination) {
      return res.status(400).json({ message: 'Les points de départ et d\'arrivée sont requis' });
    }

    const [originLng, originLat] = origin.split(',').map(Number);
    const [destLng, destLat] = destination.split(',').map(Number);

    // Validation des coordonnées
    if (isNaN(originLng) || isNaN(originLat) || isNaN(destLng) || isNaN(destLat)) {
      return res.status(400).json({ message: 'Coordonnées invalides' });
    }

    // Dans une implémentation réelle, utilisez un service de routage comme OSRM ou Google Maps
    // Ceci est une simplification qui retourne une ligne droite
    const route = {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'LineString',
        coordinates: [
          [originLng, originLat],
          [destLng, destLat]
        ]
      }
    };

    res.status(200).json(route);

  } catch (error) {
    console.error('Erreur lors du calcul de l\'itinéraire:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
