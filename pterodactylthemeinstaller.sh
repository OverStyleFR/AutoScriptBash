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

while true; do
    # Affichage du menu
    echo "Menu:"
    echo "1. Installer Pterodactyl (Dernière Version)"
    echo "2. Installer Stellar 1.11.x"
    echo "3. Installer Enigma 1.11.x"
    echo "4. Re-installer le thème du panel (RESET UI)"
    echo "5. Quitter"

    # Lecture du choix de l'utilisateur
    read -p "Choisissez une option (1-4) : " choix

    # Traitement du choix
    case $choix in
        1)
            echo "Installation du thème Stellar."
            # Ajoutez le code correspondant à l'Option 1 ici
            ;;
        2)
            echo "Installation du thème Enigma."
            # Ajoutez le code correspondant à l'Option 2 ici
            ;;
        3)
            echo "Ré-installer le thème de Pterodactyl. (RESET UI), (N'affecte pas les machines déjà installer)"
            # Ajoutez le code correspondant à l'Option 3 ici
            ;;
        4)
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo "Choix non valide. Veuillez entrer un numéro entre 1 et 4."
            ;;
    esac
done