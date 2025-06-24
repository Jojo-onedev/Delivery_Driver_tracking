console.log('🚀 Initialisation de la configuration des tests...');

// Afficher des informations sur l'environnement
console.log('📋 Environnement de test:');
console.log(`- Node.js: ${process.version}`);
console.log(`- NODE_ENV: ${process.env.NODE_ENV}`);
console.log(`- Répertoire de travail: ${process.cwd()}`);

// Configuration de Jest
console.log('⚙️ Configuration de Jest...');

// Augmenter le timeout des tests (30 secondes par défaut)
const TEST_TIMEOUT = 30000;
jest.setTimeout(TEST_TIMEOUT);
console.log(`⏱  Timeout des tests configuré à ${TEST_TIMEOUT}ms`);

// Nettoyage après les tests
console.log('🧹 Configuration du nettoyage après les tests...');
afterAll(async () => {
  console.log('\n🧹 Début du nettoyage après les tests...');
  
  try {
    // Fermer les connexions MongoDB
    const { mongoose } = require('mongoose');
    console.log('🔌 Vérification de la connexion MongoDB...');
    
    if (mongoose.connection.readyState === 1) {
      console.log('🔌 Déconnexion de MongoDB...');
      await mongoose.disconnect();
      console.log('✅ Déconnexion de MongoDB réussie');
    } else {
      console.log('ℹ️  Aucune connexion MongoDB active à fermer');
    }
    
    // Arrêter le serveur Express s'il est en cours d'exécution
    if (global.__SERVER__) {
      console.log('🛑 Arrêt du serveur Express...');
      await new Promise((resolve, reject) => {
        global.__SERVER__.close((err) => {
          if (err) {
            console.error('❌ Erreur lors de la fermeture du serveur:', err);
            return reject(err);
          }
          console.log('✅ Serveur Express arrêté avec succès');
          resolve();
        });
      });
    } else {
      console.log('ℹ️  Aucun serveur Express à arrêter');
    }
    
    console.log('✅ Nettoyage terminé avec succès');
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage après les tests:', error);
    throw error;
  }
});

// Gestion des erreurs non capturées
console.log('⚠️ Configuration de la gestion des erreurs non capturées...');

process.on('unhandledRejection', (reason, promise) => {
  console.error('\n❌ UNHANDLED REJECTION ❌');
  console.error('Promise:', promise);
  console.error('Raison:', reason);
  // Ne pas arrêter le processus en mode test pour permettre à Jest de gérer l'erreur
  if (process.env.NODE_ENV !== 'test') {
    process.exit(1);
  }
});

process.on('uncaughtException', (error) => {
  console.error('\n❌ UNCAUGHT EXCEPTION ❌');
  console.error('Erreur:', error);
  // Ne pas arrêter le processus en mode test pour permettre à Jest de gérer l'erreur
  if (process.env.NODE_ENV !== 'test') {
    process.exit(1);
  }});
