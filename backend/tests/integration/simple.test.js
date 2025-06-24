// Test minimal pour vérifier que Jest fonctionne
describe('Test minimal', () => {
  console.log('Démarrage du test minimal...');

  test('addition simple', () => {
    console.log('Exécution du test d\'addition');
    expect(1 + 1).toBe(2);
  });

  test('soustraction simple', () => {
    console.log('Exécution du test de soustraction');
    expect(3 - 1).toBe(2);
  });

  test('échec intentionnel', () => {
    console.log('Test d\'échec intentionnel');
    expect(1).toBe(2); // Ce test échouera intentionnellement
  });
});
