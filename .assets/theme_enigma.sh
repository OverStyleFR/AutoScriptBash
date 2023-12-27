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

######################################### DOWNLOAD & EXTRACT ############################################

### DOSSIER TEMPORAIRE ###

# Définir le chemin du dossier à vérifier
dossier="/tmp/pterodactylthemeinstaller"

# Vérifier si le dossier existe
if [ -d "$dossier" ]; then
    # Vérifier si le dossier est vide
    if [ -z "$(ls -A $dossier)" ]; then
        echo "Le dossier existe mais est vide."
    else
        # Supprimer le contenu du dossier s'il n'est pas vide
        rm -r "$dossier"/*
        echo "Le contenu du dossier a été supprimé avec succès."
    fi
else
    # Créer le dossier s'il n'existe pas
    mkdir -p "$dossier"
    echo "Le dossier a été créé avec succès."
fi

### DOWNLOAD ###

cd /tmp/pterodactylthemeinstaller
wget -O enigma-v39.zip https://files.catbox.moe/lqxk6x.zip
mv lqxk6x.zip enigma-v39.zip

### EXTRACT SELECTED FILE ###

unzip enigma-v39.zip
mv -f 'app' 'net' 'public' 'resources' 'tailwind.config.js' /var/www/pterodactyl

########################################## BUILD ########################################################

cd /var/www/pterodactyl

## Installation cross-env
yarn add cross-env

## NPX Installation
npx update-browserslist-db@latest

### APPLIQUER ###

cd /var/www/pterodactyl && php artisan view:clear && php artisan config:clear && chown -R www-data:www-data /var/www/pterodactyl/*

### BUILD ###

yarn build:production