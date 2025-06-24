# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-06-24

### Ajouté
- Système d'authentification sécurisé avec JWT
- Validation des entrées utilisateur avec express-validator
- Protection contre les attaques par force brute
- Rate limiting (100 requêtes/15 minutes)
- En-têtes de sécurité HTTP avec Helmet
- Configuration CORS stricte
- Gestion centralisée des erreurs
- Documentation complète de l'API
- Tests automatisés
- Fichier .env.example pour la configuration
- Documentation de sécurité (SECURITY.md)
- Amélioration de la structure du projet
- Gestion des rôles utilisateurs (admin, driver)
- Mise à jour du README avec les instructions d'installation et d'utilisation
- Scripts npm pour le développement et la production

### Modifié
- Refonte complète du système d'authentification
- Amélioration de la sécurité des mots de passe
- Optimisation des performances
- Mise à jour des dépendances
- Restructuration des dossiers du projet

### Corrigé
- Problèmes de sécurité potentiels
- Bugs dans la validation des données
- Problèmes de performances
- Problèmes de compatibilité

## [1.0.0] - 2024-01-01

### Ajouté
- Version initiale du projet
- Configuration de base de l'API
- Modèles de données utilisateurs et localisations
- Routes d'API de base
- Authentification simple
- Gestion des erreurs de base
