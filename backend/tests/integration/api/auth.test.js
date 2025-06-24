console.log('Chargement des dépendances de test...');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

console.log('Chargement de l\'application...');
const { app, server } = require('../../../index');
const User = require('../../../models/User');

let mongoServer;

// Stocker le serveur Express dans une variable globale pour pouvoir le fermer
if (server) {
  global.__SERVER__ = server;
}

beforeAll(async () => {
  console.log('Démarrage du serveur MongoDB en mémoire...');
  try {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    console.log('MongoDB Memory Server démarré sur:', mongoUri);
    
    // Se connecter à la base de données de test
    console.log('Connexion à MongoDB...');
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connecté à MongoDB avec succès');
  } catch (error) {
    console.error('Erreur lors de la configuration des tests:', error);
    throw error;
  }
});

afterEach(async () => {
  // Nettoyer la base de données entre les tests
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});

afterAll(async () => {
  console.log('Nettoyage après les tests...');
  try {
    if (mongoose.connection.readyState === 1) {
      console.log('Fermeture de la connexion MongoDB...');
      await mongoose.disconnect();
      console.log('Connexion MongoDB fermée');
    }
    
    if (mongoServer) {
      console.log('Arrêt du serveur MongoDB en mémoire...');
      await mongoServer.stop();
      console.log('Serveur MongoDB arrêté');
    }
    
    console.log('Fermeture du serveur Express...');
    await new Promise(resolve => server.close(resolve));
    console.log('Serveur Express fermé');
  } catch (error) {
    console.error('Erreur lors du nettoyage après les tests:', error);
    throw error;
  }
});

console.log('Démarrage des tests d\'authentification...');

// Test de base en dehors de tout describe pour vérifier que Jest fonctionne
console.log('Définition du test de base...');

test('test de base de Jest', () => {
  console.log('Exécution du test de base de Jest');
  expect(true).toBe(true);
});

describe('Auth API', () => {
  console.log('Définition du describe Auth API');
  
  beforeAll(() => {
    console.log('Configuration avant tous les tests d\'authentification');
  });

  afterAll(() => {
    console.log('Nettoyage après tous les tests d\'authentification');
  });
  
  // Test de base pour vérifier que les tests s'exécutent
  it('devrait exécuter un test de base', () => {
    console.log('Exécution du test de base dans describe');
    expect(true).toBe(true);
  });
  describe('POST /api/auth/register', () => {
    it('devrait enregistrer un nouvel utilisateur avec succès', async () => {
      const userData = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        phone: '1234567890'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('user');
      expect(response.body.user.email).toBe(userData.email.toLowerCase());
      expect(response.body.user.role).toBe('driver'); // Vérifiez le rôle par défaut
    });

    it('ne devrait pas enregistrer un utilisateur avec un email existant', async () => {
      const userData = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        phone: '1234567890'
      };

      // Créer un utilisateur
      await User.create(userData);

      // Essayer de créer un utilisateur avec le même email
      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body).toHaveProperty('message');
    });

    it('devrait valider les champs requis', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('message');
    });
  });

  describe('POST /api/auth/login', () => {
    const testUser = {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      phone: '1234567890'
    };

    beforeEach(async () => {
      // Créer un utilisateur de test
      const user = new User(testUser);
      await user.save();
    });

    it('devrait connecter un utilisateur avec des identifiants valides', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password
        })
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('user');
      expect(response.body.user.email).toBe(testUser.email.toLowerCase());
    });

    it('ne devrait pas connecter avec un mot de passe incorrect', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email,
          password: 'wrongpassword'
        })
        .expect(401);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toContain('Email ou mot de passe incorrect');
    });

    it('devrait être insensible à la casse pour l\'email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.email.toUpperCase(),
          password: testUser.password
        })
        .expect(200);

      expect(response.body).toHaveProperty('token');
    });
  });
});