#!/bin/bash

# Définir les couleurs
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
VIOLET=$(tput setaf 5)
YELLOW=$(tput setaf 3)
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
    echo "                +------------+"
    echo "                |   ${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${BOLD} :${RESET}   |"
    echo "       +--------+------------+----------+"
    echo "       |         ${VIOLET}${BOLD}Installation${RESET}${BOLD} :${RESET}         |"
    echo "+------+--------------------------------+------+"
    echo "|  1. Installer docker                         |"
    echo "|  2. Installer yarn                           |"
    echo "+----------------------------------------------+"
    echo ""
    echo "                +-------------+"
    echo "                |  ${GREEN}${BOLD}Script${RESET}${BOLD} :${RESET}   |"
    echo "  +-------------+-------------+----------------+"
    echo "  | 3. Exécuter 'new.sh'                       |"
    echo "  |                                            |"
    echo "  | 4. Exécuter 'speedtest.sh'                 |"
    echo "  |                                            |"
    echo "  | 5. Exécuter 'pterodactyl-panel-reinstaller'|"
    echo "  +---------------------------+----------------+"
    echo "  | 6. ${BLUE}${BOLD}Exécuter le Pterodactyl Menu${RESET}            |"
    echo "  | └ ${YELLOW}${BOLD}OverStyleFR/Pterodactyl-Installer-Menu${RESET}   |"
    echo "  +-------------+------------+-----------------+"
    echo "                | ${RED}${BOLD}7. Quitter${RESET} |"
    echo "                +------------+"


    # Lecture du choix de l'utilisateur
    read -p "Choisissez une option (1-6) : " choix

    # Traitement du choix
    case $choix in
        
        1)
            echo "Installation de Docker."
            # Ajoutez le code correspondant à l'Option 1 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/dockerinstall.sh)
            ;;
        2)
            echo "Installation de Yarn."
            # Ajoutez le code correspondant à l'Option 2 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/yarninstall.sh)
            ;;
        3)
            echo "Exécution du script 'new.sh'."
            # Ajoutez le code correspondant à l'Option 3 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/new.sh)
            ;;
        4)
            echo "Exécution du script 'speedtest.sh'."
            # Ajoutez le code correspondant à l'Option 4 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/speedtest.sh)
            ;;
        5)
            echo "Exécution du script 'massgrave.cmd'."
            # Ajoutez le code correspondant à l'Option 4 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/pterodactylpanelreinstall.sh)
            ;;
        6)
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo "Choix non valide. Veuillez entrer un numéro entre 1 et 5."
            ;;
    esac
done