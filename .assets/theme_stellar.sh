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

# Fonction pour le choix 1
choice_one() {
    # Télécharger le fichier ZIP
    wget -O theme.zip https://anonymfile.com/Wg94/stellar-v33.zip

    # Vérifier si le téléchargement a réussi
    if [ -f "theme.zip" ]; then
        # Extraire le contenu du ZIP
        unzip theme.zip

        # Supprimer le fichier ZIP après l'extraction (si nécessaire)
        rm theme.zip
    else
        echo "Échec du téléchargement du fichier ZIP."
        exit 1
    fi

    # Installer react-feather via Yarn
    yarn add react-feather

    # Exécuter les migrations
    php artisan migrate <<< "yes"

    # Construire la version de production
    yarn build:production

    # Effacer le cache des vues
    php artisan view:clear
}

# Fonction pour le choix 2
choice_two() {
    # Construire la version de production
    yarn build:production

    # Effacer le cache des vues
    php artisan view:clear
}

# Affichage du menu de choix
echo "Choisissez une action :"
echo "1. Installer le thème et exécuter les étapes complètes."
echo "2. Seulement yarn build:production et php artisan view:clear."
read -p "Entrez votre choix (1 ou 2): " user_choice

# Logique pour les choix
case $user_choice in
    1)
        echo "Vous avez choisi d'installer le thème et d'exécuter les étapes complètes."
        choice_one
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
