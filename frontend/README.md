# DeliveryPro

Application Flutter de suivi et gestion des livraisons pour chauffeurs et administrateurs.

## Présentation
DeliveryPro permet :
- Aux chauffeurs de consulter et suivre leurs livraisons assignées
- Aux administrateurs de gérer l’ensemble des livraisons et des chauffeurs
- Un accès sécurisé par authentification (rôles driver/admin)
- Un affichage moderne et responsive (web, desktop, mobile)

## Fonctionnalités principales
- Connexion sécurisée (JWT)
- Filtrage des livraisons par chauffeur
- Rafraîchissement des données en temps réel
- Statistiques de livraisons (en cours, terminées, en attente)
- Interface d’administration (visualisation globale, gestion des chauffeurs)
- UI personnalisée (padding, animations, thèmes)

## Lancement du projet

1. **Pré-requis** :
   - Flutter SDK (>= 3.8)
   - Un backend Node.js compatible (voir dossier backend/)
2. **Installation des dépendances** :
   ```bash
   flutter pub get
   ```
3. **Lancement en mode debug** :
   ```bash
   flutter run
   ```
   (pour web : `flutter run -d chrome`)

## Structure du projet
- `lib/` : code source principal (screens, services, modèles)
- `web/` : fichiers pour la version web
- `test/` : tests Flutter

## Personnalisation
- Le nom de l’app et le thème sont configurables dans `main.dart` et `pubspec.yaml`
- Pour changer le logo/icône, voir les dossiers `assets/` et `web/`

## Liens utiles
- [Documentation Flutter](https://docs.flutter.dev/)
- [Cookbook Flutter](https://docs.flutter.dev/cookbook)
- [Démarrage Flutter Web](https://docs.flutter.dev/platform-integration/web)

---
