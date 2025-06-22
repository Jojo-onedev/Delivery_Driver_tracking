require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

async function resetAdminPassword() {
  try {
    // Connexion à MongoDB
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connecté à MongoDB');

    // Trouver l'utilisateur admin
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@delivery.com';
    const newPassword = process.env.ADMIN_PASSWORD || 'Motdepasse123!';
    
    console.log(`Recherche de l'admin avec l'email: ${adminEmail}`);
    
    // Mettre à jour le mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    const result = await User.findOneAndUpdate(
      { email: adminEmail },
      { $set: { password: hashedPassword } },
      { new: true, upsert: true }
    );

    if (result) {
      console.log('Mot de passe admin mis à jour avec succès!');
      console.log(`Email: ${adminEmail}`);
      console.log(`Nouveau mot de passe: ${newPassword}`);
    } else {
      console.log('Aucun admin trouvé, création d\'un nouvel admin...');
      // Créer un nouvel admin si aucun n'existe
      await User.create({
        name: 'Admin',
        email: adminEmail,
        password: hashedPassword,
        role: 'admin'
      });
      console.log('Nouvel admin créé avec succès!');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors de la réinitialisation du mot de passe admin:', error);
    process.exit(1);
  }
}

resetAdminPassword();
