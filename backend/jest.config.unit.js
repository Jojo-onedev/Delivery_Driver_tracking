const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig,
  testMatch: ['**/tests/unit/**/*.test.js'],
  testTimeout: 10000,
};
