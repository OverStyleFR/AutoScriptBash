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
    echo "                | ${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${BOLD} SSH :${RESET} |"
    echo "       +--------+------------+----------+"
    echo "       |            ${VIOLET}${BOLD}Menus${RESET}${BOLD} :${RESET}             |"
    echo "+------+--------------------------------+------+"
    echo "|  1. Exécuter le ${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${GREEN}${BOLD}.sh${RESET}                      |"
    echo "|  2. Exécuter le ${BLUE}${BOLD}Pterodactyl Menu${RESET}             |"
    echo "+----------------------------------------------+"
    echo ""
    echo "                +-------------+"
    echo "                |  ${GREEN}${BOLD}SSH ID${RESET}${BOLD} :${RESET}   |"
    echo "  +-------------+-------------+----+-----------+"
    echo "  | 3. Ajouter '${VIOLET}${BOLD}id_ed25519${RESET}'        |   ${VIOLET}${BOLD}Main${RESET}    |"
    echo "  |                                |           |"
    echo "  | 4. Ajouter '${VIOLET}${BOLD}id_ed25519${RESET}_${YELLOW}${BOLD}sk${RESET}'     | ${VIOLET}${BOLD}Main ${YELLOW}${BOLD}Yubi${RESET} |"
    echo "  +-------------+------------+-----+-----------+"
    echo "                | ${RED}${BOLD}5. Quitter${RESET} |"
    echo "                +------------+"


    # Lecture du choix de l'utilisateur
    read -p "Choisissez une option (1-7) : " choix

    # Traitement du choix
    case $choix in
        
        1)
            echo "Exécuter le ${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${GREEN}${BOLD}.sh${RESET}"
            # Ajoutez le code correspondant à l'Option 1 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/dockerinstall.sh)
            ;;
        2)
            echo "Exécuter le ${BLUE}${BOLD}Pterodactyl Menu${RESET}"
            # Ajoutez le code correspondant à l'Option 2 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/yarninstall.sh)
            ;;
        3)
            echo "Ajouter '${VIOLET}${BOLD}id_ed25519${RESET}'        |   ${VIOLET}${BOLD}Main${RESET}    |"
            # Ajoutez le code correspondant à l'Option 3 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/new.sh)
            ;;
        4)
            echo "Ajouter '${VIOLET}${BOLD}id_ed25519${RESET}_${YELLOW}${BOLD}sk${RESET}'     | ${VIOLET}${BOLD}Main ${YELLOW}${BOLD}Yubi${RESET} |"
            # Ajoutez le code correspondant à l'Option 4 ici
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/speedtest.sh)
            ;;
        5)
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo "Choix non valide. Veuillez entrer un numéro entre 1 et 5."
            ;;
    esac
done