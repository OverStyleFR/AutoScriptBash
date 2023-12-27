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

######################################### MENU ###########################################################

# Fonction pour le choix 1
choice_one() {

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
    wget https://files.catbox.moe/ldjbsz.zip

    ### EXTRACT SELECTED FILE ###
    unzip ldjbsz.zip pterodactyl/app database resources routes -d /var/www/pterodactyl/
    cd /var/www/pterodactyl/

    # Installer react-feather via Yarn
    yarn add react-feather

    # Installer cross-env via Yarn
    yarn add cross-env
    
    # Installer update-browserslist
    npx update-browserslist-db@latest

    # Exécuter les migrations
    php artisan migrate

    # Construire la version de production
    yarn build:production

    # Effacer le cache des vues
    php artisan view:clear
}

# Fonction pour le choix 2
choice_two() {
   # Selection du dossier d'installation
   cd /var/www/pterodactyl/

    # Construire la version de production
    yarn build:production

    # Effacer le cache des vues
    php artisan view:clear
}

# Affichage du menu de choix
echo "Choisissez une action :"
echo "1. Installer le thème et exécuter les étapes complètes."
echo "2. Re-Build le Panel."
read -p "Entrez votre choix (1 ou 2): " user_choice

# Logique pour les choix
case $user_choice in
    1)
        echo "Vous avez choisi d'installer le thème et d'exécuter les étapes complètes."
        choice_one  # Assurez-vous que la fonction est définie avant cet appel
        ;;
    2)
        echo "Vous avez choisi de seulement exécuter yarn build:production et php artisan view:clear."
        choice_two
        ;;
    *)
        echo "Choix invalide. Veuillez entrer 1 ou 2."
        exit 1
        ;;
esac