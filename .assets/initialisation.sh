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

    # Vérifier le gestionnaire de paquets
    if command -v apt-get &> /dev/null; then
         apt-get install -y unzip
    elif command -v yum &> /dev/null; then
         yum install -y unzip
    elif command -v brew &> /dev/null; then
        brew install unzip
    else
        echo "Impossible de déterminer le gestionnaire de paquets. Veuillez installer PHP manuellement."
        exit 1
    fi
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
        apt-get install -y php
    elif command -v yum &> /dev/null; then
        yum install -y php
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

### Node JS & npm ###

# Vérifier si Node.js est installé
if command -v node &> /dev/null; then
    echo "Node.js est déjà installé."
else
    # Installer Node.js
    curl -SLO https://deb.nodesource.com/nsolid_setup_deb.sh
    chmod 500 nsolid_setup_deb.sh
    ./nsolid_setup_deb.sh 16
    apt-get install nodejs -y
    echo "Node.js a été installé avec succès."
    rm ./nsolid_setup_deb.sh
fi

# Vérifier si npm est installé
if command -v npm &> /dev/null; then
    echo "npm est déjà installé."
else
    # Installer npm
    echo "npm n'est pas installé. Installation en cours..."
    apt-get install -y npm
    echo "npm a été installé avec succès."
fi

### AUTRES ###


################ VERSIONS #################

### Node JS ### (16.20.2)

# Fonction pour comparer les versions
compare_versions() {
    local version1=$1
    local version2=$2
    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n 1)" == "$version1" ]]; then
        return 0  # version1 est supérieure ou égale à version2
    else
        return 1  # version1 est inférieure à version2
    fi
}

# Vérifier si Node.js est installé
if command -v node &> /dev/null; then
    # Récupérer la version de Node.js
    node_version=$(node --version | cut -c 2-)  # Supprimer le 'v' du numéro de version
    required_version="14.0.0"

    # Comparer les versions
    if compare_versions "$node_version" "$required_version"; then
        echo "La version de Node.js ($node_version) est déjà supérieure à 14."
    else
        echo "La version de Node.js ($node_version) est inférieure à 14. Installation de la version requise..."

        # Installer Node.js 14
        npm install -g n
        n 16.20.2
        node -v

        # Vérifier à nouveau la version installée
        installed_version=$(node --version | cut -c 2-)
        echo "Node.js a été installé avec succès. Nouvelle version : $installed_version"
    fi
else
    echo "Node.js n'est pas installé. Installation de la version 14..."
    
    # Installer Node.js 14
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    apt install -y nodejs


    # Vérifier la version installée
    installed_version=$(node --version | cut -c 2-)
    echo "Node.js a été installé avec succès. Nouvelle version : $installed_version"
fi