#!/bin/bash

# Définir les couleurs
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
VIOLET=$(tput setaf 5)
BOLD=$(tput bold)
RESET=$(tput sgr0)
########################################## INITIALISATION ROOT ##########################################

# Vérifier si l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
   echo "${RED}${BOLD}Ce script doit être exécuté en tant que root${RESET}" 
   # Demander le mot de passe
   sudo "$0" "$@"
   exit 1
fi

# Le reste du script ici

########################################## AUTO-SAVE .env FILE ##########################################

echo ""
echo "${GREEN}${BOLD}Auto-Save .env File${RESET}"
echo ""

mkdir /tmp/pterodactylpanelreinstall
mv /var/wwww/pterodactyl/.env /tmp/pterodactylpanelreinstall/







COPY .env file in /var/www/pterodactyl/

cd ~
sudo rm -r /var/www/pterodactyl
sudo mkdir /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
sudo chmod -R 755 storage/* bootstrap/cache/

Add back the .env

composer install --no-dev --optimize-autoloader
chown -R www-data:www-data /var/www/pterodactyl/*