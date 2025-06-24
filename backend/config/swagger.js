const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const path = require('path');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API de Suivi des Chauffeurs-Livreurs',
      version: '1.0.0',
      description: 'Documentation de l\'API pour le suivi des chauffeurs-livreurs',
      contact: {
        name: 'Support',
        email: 'support@delivery.com'
      },
    },
    servers: [
      {
        url: 'http://localhost:5000/api',
        description: 'Serveur de développement',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: [
    path.join(__dirname, '../routes/*.js'),
    path.join(__dirname, '../models/*.js')
  ],
};

const specs = swaggerJsdoc(options);

module.exports = (app) => {
  // Route pour la documentation Swagger UI
  app.use('/api-docs', 
    swaggerUi.serve, 
    swaggerUi.setup(specs, { explorer: true })
  );

  // Route pour le fichier JSON de la spécification
  app.get('/api-docs.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.send(specs);
  });

  console.log('Documentation Swagger disponible à http://localhost:5000/api-docs');
};
