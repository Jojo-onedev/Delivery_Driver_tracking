const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔧 Configuration d\'Insomnia...');

try {
  // Vérifier si le fichier de collection existe
  const collectionPath = path.join(__dirname, '../backend/docs/insomnia/Delivery_Driver_tracker_API.json');
  
  if (!fs.existsSync(collectionPath)) {
    console.log('Aucun fichier de collection trouvé.');
    console.log(`   Veuillez placer votre fichier d'export Insomnia dans: ${collectionPath}`);
    process.exit(0);
  }

  console.log('Fichier de collection trouvé');
  console.log('\nPour importer la collection dans Insomnia:');
  console.log('1. Ouvrez Insomnia');
  console.log('2. Cliquez sur "Application" > "Import/Export" > "Import Data"');
  console.log('3. Sélectionnez "From File"');
  console.log(`4. Choisissez le fichier: ${collectionPath}`);
  console.log('\nPour plus d\'informations, consultez docs/README.md');

} catch (error) {
  console.error('Erreur lors de la configuration Insomnia:', error.message);
  process.exit(1);
}
