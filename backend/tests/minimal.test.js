// Test minimal pour vérifier que Jest fonctionne correctement
describe('Test minimal', () => {
  console.log('🚀 Exécution du test minimal...');
  
  it('devrait réussir un test simple', () => {
    console.log('✅ Exécution du test simple');
    expect(1 + 1).toBe(2);
  });
  
  it('devrait échouer intentionnellement', () => {
    console.log('⚠️ Test d\'échec intentionnel');
    // Ce test échouera intentionnellement
    expect(1 + 1).toBe(3);
  });
});
