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

########################################## YARN INSTALL ##################################################

# Préparation #
apt-get remote cmdtest
apt-get remove yarn
##

# Ajout de la clé #
echo ""
echo "${GREEN}${BOLD}Ajout de la clé & du répertoire${RESET}"
echo ""

sleep 1

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
##

## INSTALLATION DOCKER | Last Version ##
echo ""
echo "${BLUE}${BOLD}Installation de la dernière version de yarn${RESET}"
echo ""

apt-get update
apt-get install yarn -y