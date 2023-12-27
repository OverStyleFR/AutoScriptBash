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
mv /var/www/pterodactyl/.env /tmp/pterodactylpanelreinstall/


## Supprésion du panel actuelle
echo ""
echo "${BLUE}${BOLD}Suppresion du panel actuelle${RESET}"
echo ""

cd ~
rm -r /var/www/pterodactyl

### Installation du panel Pterodactyl Vanilla
echo ""
echo "${BLUE}${BOLD}Installation du panel Vanilla${RESET}"
echo ""

mkdir /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
sudo chmod -R 755 storage/* bootstrap/cache/

## Backup .env File
echo ""
echo "${GREEN}${BOLD}Backup .env File${RESET}"
echo ""

mv /tmp/pterodactylpanelreinstall/.env /var/www/pterodactyl/

############################################ Build du panel pterodactyl ###################################

# Demander à l'utilisateur de faire l'action "save file"
read -p "Voulez vous build le panel Pterodactyl ? ${RED}${BOLD}NON REVERSIBLE ${RESET}(${GREEN}Yes/${RED}Non) > ${RESET}" response

# Liste des réponses acceptées, séparées par des espaces
accepted_responses=("oui" "o" "yes" "y")

# Vérifier si la réponse est dans la liste des réponses acceptées
if [[ " ${accepted_responses[@]} " =~ " ${response} " ]]; then
    echo "L'utilisateur a répondu 'oui'. Le script continue..."
else
    echo "Réponse incorrecte. Le script se termine."
    exit 1
fi

echo ""
echo "${VIOLET}${BOLD}Build du panel Pterodactyl${RESET}"
echo ""

composer install --no-dev --optimize-autoloader
chown -R www-data:www-data /var/www/pterodactyl/*

# FIN
echo ""
echo "${BLUE}${BOLD}Fin du script.${RESET}"
echo ""
echo "${BLUE}Pterodactyl Panel ${GREEN}Re-installer ${BOLD}Script ${BOLD}By ${VIOLET}OverStyleFR${RESET}"