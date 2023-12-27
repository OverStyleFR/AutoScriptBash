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

# Vérifier si Yarn est installé
if command -v yarn &> /dev/null; then
    echo "Yarn est déjà installé sur votre machine."
else
    # Installer Yarn s'il n'est pas déjà installé
    echo "Yarn n'est pas installé. Installation en cours..."

    # Installer Yarn via le script (get.tomv.ovh)
    bash <(curl -s https://get.tomv.ovh/yarninstall.sh)

    # Vérifier à nouveau si l'installation a réussi
    if command -v yarn &> /dev/null; then
        echo "Yarn a été installé avec succès."
    else
        echo "Une erreur s'est produite lors de l'installation de Yarn. Veuillez vérifier votre configuration."
        exit 1
    fi
fi

### PHP ###

# Vérifier si PHP est installé
if command -v php &> /dev/null; then
    echo "PHP est déjà installé sur votre machine."
else
    # Installer PHP s'il n'est pas déjà installé
    echo "PHP n'est pas installé. Installation en cours..."
    
    # Vérifier le gestionnaire de paquets
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y php
    elif command -v yum &> /dev/null; then
        sudo yum install -y php
    elif command -v brew &> /dev/null; then
        brew install php
    else
        echo "Impossible de déterminer le gestionnaire de paquets. Veuillez installer PHP manuellement."
        exit 1
    fi

    # Vérifier à nouveau si l'installation a réussi
    if command -v php &> /dev/null; then
        echo "PHP a été installé avec succès."
    else
        echo "Une erreur s'est produite lors de l'installation de PHP. Veuillez vérifier votre configuration."
        exit 1
    fi
fi

### AUTRES ###






################ VERSIONS #################

### Node JS ### (16.20.2)

