// Test simple pour vérifier que Node fonctionne correctement
console.log('✅ Test simple avec Node.js');
console.log(`Node.js version: ${process.version}`);
console.log(`NODE_ENV: ${process.env.NODE_ENV || 'non défini'}`);

// Sortie avec un code d'erreur pour indiquer que le test a réussi
process.exit(0);
