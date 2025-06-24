const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig,
  testMatch: ['**/tests/e2e/**/*.test.js'],
  testTimeout: 60000, // Temps d'attente plus long pour les tests E2E
  globalSetup: '<rootDir>/tests/setup.e2e.js',
  globalTeardown: '<rootDir>/tests/teardown.e2e.js',
};
