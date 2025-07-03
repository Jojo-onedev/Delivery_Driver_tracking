# Delivery_Driver_tracking

Application complète de gestion de livraisons : application mobile Flutter (DeliveryPro) et backend Node.js/Express/MongoDB.

## Objectif du projet
Concevoir une solution permettant :
- Aux livreurs (chauffeurs) de consulter leurs livraisons, mettre à jour leurs statuts, et partager leur position GPS en temps réel
- Aux administrateurs de gérer les livraisons, les chauffeurs, et de suivre l’activité via une interface dédiée
- Une communication sécurisée entre le mobile et le backend via API REST et authentification JWT

## Architecture
- **Frontend** : Flutter (mobile, web, desktop)
- **Backend** : Node.js/Express avec base de données MongoDB
- **API** : RESTful, sécurisée par JWT

## Fonctionnalités principales
- Authentification sécurisée (rôles chauffeur/admin)
- Filtrage et gestion des livraisons par utilisateur
- Suivi de position GPS (en temps réel pour les chauffeurs)
- Statistiques et visualisation pour l’admin
- Interface responsive et moderne

## Structure du projet
- `frontend/` : application Flutter DeliveryPro ([voir le README dédié](frontend/README.md))
- `backend/`  : serveur Node.js/Express ([voir le README dédié](backend/README.md) si présent)
- `README.md` (racine) : vue d’ensemble du projet

## Démarrage rapide
1. **Cloner le projet**
   ```bash
   git clone <repo-url>
   cd Delivery_Driver_tracking
   ```
2. **Installer le backend**
   - Aller dans `backend/`, installer les dépendances (`npm install`)
   - Configurer `.env` (voir exemple dans le dossier)
   - Lancer le serveur : `npm start` ou `node server.js`
3. **Installer le frontend**
   - Aller dans `frontend/`, installer les dépendances (`flutter pub get`)
   - Lancer l’app : `flutter run` (ou `flutter run -d chrome` pour le web)

## Ressources utiles
- [Flutter documentation](https://docs.flutter.dev/)
- [Express.js documentation](https://expressjs.com/)
- [MongoDB documentation](https://www.mongodb.com/docs/)

---

Pour plus de détails, voir les README dans chaque sous-dossier.
