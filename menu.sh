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
clear
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
    echo "  | 5. Exécuter 'fastfetch.sh'                 |"
    echo "  |                                            |"
    echo "  | 6. Exécuter 'pterodactyl-panel-reinstaller'|"
    echo "  +--------------------------------------------+"
    echo "  | 7. ${BLUE}${BOLD}Exécuter le Pterodactyl Menu${RESET}            |"
    echo "  | └ ${YELLOW}${BOLD}OverStyleFR/Pterodactyl-Installer-Menu${RESET}   |"
    echo "  +--------------------------------------------+"
    echo "  | 8. ${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${BOLD} SSH ${RESET}                               |"
    echo "  | └ ${VIOLET}${BOLD}OverStyleFR/AutoScriptBash${RESET}               |"
    echo "  +-------------+------------+-----------------+"
    echo "                | ${RED}${BOLD}9. Quitter${RESET} |"
    echo "                +------------+"
    
    # Lecture du choix de l'utilisateur
    read -p "Choisissez une option (1-9) : " choix
    
    # Traitement du choix
    case $choix in
        1)
            echo "Installation de Docker."
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/dockerinstall.sh)
            ;;
        2)
            echo "Installation de Yarn."
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/yarninstall.sh)
            ;;
        3)
            echo "Exécution du script 'new.sh'."
            if bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/new.sh); then
                echo "Script 'new.sh' exécuté avec succès."
            else
                echo "Erreur lors de l'exécution du script 'new.sh'."
            fi
            read -n 1 -s -r -p "Appuyez sur une touche pour retourner au menu..."
            ;;
        4)
            echo "Exécution du script 'speedtest.sh'."
            if bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/speedtest.sh); then
                echo "Script 'speedtest.sh' exécuté avec succès."
            else
                echo "Erreur lors de l'exécution du script 'speedtest.sh'."
            fi
            read -n 1 -s -r -p "Appuyez sur une touche pour retourner au menu..."
            ;;
        5)
            echo "Exécution du script 'fastfetch.sh'."
            if bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/refs/heads/main/.assets/fastfetch-install.sh); then
                echo "Script 'fastfetch.sh' exécuté avec succès."
            else
                echo "Erreur lors de l'exécution du script 'fastfetch.sh'."
            fi
            read -n 1 -s -r -p "Appuyez sur une touche pour retourner au menu..."
            ;;
        6)
            echo "Exécuter 'pterodactyl-panel-reinstaller'"
            if bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/pterodactylpanelreinstall.sh); then
                echo "Script 'pterodactyl-panel-reinstaller' exécuté avec succès."
            else
                echo "Erreur lors de l'exécution du script 'pterodactyl-panel-reinstaller'."
            fi
            read -n 1 -s -r -p "Appuyez sur une touche pour retourner au menu..."
            ;;
        7)
            echo "${BLUE}${BOLD}Exécuter le Pterodactyl Menu${RESET}"
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/Pterodactyl-Installer-Menu/main/PterodactylMenu.sh)
            ;;
        8)
            echo "${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${BOLD} SSH ${RESET}"
            bash <(curl -s https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu_id.sh)
            ;;
        9)
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo "Choix non valide. Veuillez entrer un numéro entre 1 et 9."
            ;;
    esac
done
