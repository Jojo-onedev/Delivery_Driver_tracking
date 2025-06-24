const request = require('supertest');
const app = require('../../../index');
const User = require('../../../models/User');
const { connect, close, clear } = require('../../../test-utils');

beforeAll(async () => {
  await connect();
});

afterEach(async () => {
  await clear();
});

afterAll(async () => {
  await close();
});

describe('Auth API', () => {
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