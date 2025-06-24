#!/bin/bash

# Script de déploiement pour l'API de suivi des chauffeurs

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher un message d'information
info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

# Fonction pour afficher un message de succès
success() {
  echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

# Fonction pour afficher un message d'erreur et quitter
error() {
  echo -e "${RED}[ERREUR]${NC} $1"
  exit 1
}

# Vérifier que le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then 
  error "Ce script doit être exécuté en tant que root"
fi

# Mettre à jour les paquets système
info "Mise à jour des paquets système..."
apt-get update && apt-get upgrade -y

# Installer les dépendances système
info "Installation des dépendances système..."
apt-get install -y git curl wget build-essential

# Installer Node.js (si non installé)
if ! command -v node &> /dev/null; then
  info "Installation de Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
  apt-get install -y nodejs
fi

# Installer PM2 (si non installé)
if ! command -v pm2 &> /dev/null; then
  info "Installation de PM2..."
  npm install -g pm2@latest
  
  # Configurer PM2 pour le démarrage automatique
  pm2 startup
  pm2 save
fi

# Installer MongoDB (si non installé)
if ! command -v mongod &> /dev/null; then
  info "Installation de MongoDB..."
  wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
  apt-get update
  apt-get install -y mongodb-org
  
  # Démarrer et activer MongoDB
  systemctl start mongod
  systemctl enable mongod
fi

# Créer un utilisateur dédié (si nécessaire)
if ! id -u api >/dev/null 2>&1; then
  info "Création de l'utilisateur 'api'..."
  useradd -m -s /bin/bash api
  usermod -aG sudo api
  
  # Configurer l'authentification sans mot de passe pour sudo
  echo "api ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/api
fi

# Cloner le dépôt (si nécessaire)
if [ ! -d "/opt/delivery-api" ]; then
  info "Clonage du dépôt..."
  git clone https://github.com/votre_compte/Delivery_Driver_tracking.git /opt/delivery-api
  chown -R api:api /opt/delivery-api
fi

# Passer à l'utilisateur api pour les étapes suivantes
su - api << 'EOF'
cd /opt/delivery-api/backend

# Installer les dépendances
info "Installation des dépendances Node.js..."
npm install --production

# Créer le fichier .env s'il n'existe pas
if [ ! -f ".env" ]; then
  info "Création du fichier .env..."
  cp .env.example .env
  
  # Générer un secret JWT sécurisé
  JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")
  sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
  
  # Demander les informations de configuration
  read -p "Entrez l'URL de connexion MongoDB (par défaut: mongodb://localhost:27017/delivery_tracking): " MONGO_URI
  read -p "Entrez le port d'écoute (par défaut: 5000): " PORT
  read -p "Entrez l'URL du frontend (par défaut: http://localhost:3000): " FRONTEND_URL
  
  # Mettre à jour les valeurs dans .env
  [ ! -z "$MONGO_URI" ] && sed -i "s|MONGO_URI=.*|MONGO_URI=$MONGO_URI|" .env
  [ ! -z "$PORT" ] && sed -i "s/PORT=.*/PORT=$PORT/" .env
  [ ! -z "$FRONTEND_URL" ] && sed -i "s|FRONTEND_URL=.*|FRONTEND_URL=$FRONTEND_URL|" .env
  
  echo -e "\nConfiguration terminée. N'oubliez de vérifier le fichier .env avant de démarrer l'application."
fi

# Démarrer l'application avec PM2
info "Démarrage de l'application avec PM2..."
if pm2 list | grep -q "delivery-api"; then
  pm2 restart delivery-api --update-env
else
  NODE_ENV=production pm2 start ecosystem.config.js --env production
  pm2 save
fi

# Afficher les informations de déploiement
success "Déploiement terminé avec succès !"
echo -e "\nInformations de déploiement :"
echo "- URL de l'API : http://$(curl -s ifconfig.me):$(grep -oP 'PORT=\K.*' .env || echo 5000)"
echo "- Gestion des processus : pm2 monit"
echo "- Journaux : pm2 logs delivery-api"
echo "- Redémarrage : pm2 restart delivery-api"
EOF

echo -e "\n${GREEN}Déploiement terminé avec succès !${NC}"
echo "Pour accéder à l'application, visitez : http://$(curl -s ifconfig.me):$(grep -oP 'PORT=\K.*' /opt/delivery-api/backend/.env 2>/dev/null || echo 5000)"
