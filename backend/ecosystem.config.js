module.exports = {
  apps: [{
    name: 'delivery-api',
    script: './index.js',
    instances: 'max',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000,
      NODE_OPTIONS: '--max-http-header-size=16384'
    }
  }],

  deploy: {
    production: {
      user: 'node',
      host: 'localhost',
      ref: 'origin/main',
      repo: 'git@github.com:Jojoonedev/Delivery_Driver_tracking.git',
      path: 'C:\Users\batio\OneDrive\Documents\GitHub\Delivery_Driver_tracking\backend',
      'post-deploy': 'npm install --production && pm2 reload ecosystem.config.js --env production'
    }
  }
};
