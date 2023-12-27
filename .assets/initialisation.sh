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

########################################### INITIALISATION / PREPARATION ################################

################ PACKAGES #################

### UNZIP ###

# Vérifier si le package unzip est installé
if ! dpkg -s unzip >/dev/null 2>&1; then
    # Afficher le texte en rouge et en gras
    echo "${BOLD}Le package unzip n'est pas installé. Installation en cours...${RESET}"
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install -y unzip >/dev/null 2>&1
else
    # Afficher le texte en vert et en gras
    echo "${BOLD}Le package unzip est déjà installé.${RESET}"
fi

### YARN ### (Ré-installation de celui ci)

### PHP ###









################ VERSIONS #################

### Node JS ### (16.20.2)

