const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig,
  testMatch: ['**/tests/integration/**/*.test.js'],
  testTimeout: 30000,
};
