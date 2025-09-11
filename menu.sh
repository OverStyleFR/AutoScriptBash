#!/usr/bin/env bash
# ==============================================================================
# menu.sh â Lanceur interactif des scripts OverStyleFR
#
# USAGE :
#   sudo ./menu.sh
#
# CARACTÃRISTIQUES :
#   - Menu en boucle (1..9)
#   - VÃ©rifie root, relance via sudo si nÃ©cessaire
#   - Couleurs avec fallback si tput indisponible
#   - TÃ©lÃ©charge chaque script dans /tmp avec mktemp, exÃ©cute, affiche le statut
#   - Nettoyage auto des fichiers temporaires
# ==============================================================================

# Pas de "set -e" pour ne pas quitter le menu sur une simple erreur de sous-commande
set -uo pipefail

# ------------------------------- Couleurs -------------------------------------
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  GREEN="$(tput setaf 2)"; RED="$(tput setaf 1)"; BLUE="$(tput setaf 4)"
  VIOLET="$(tput setaf 5)"; YELLOW="$(tput setaf 3)"
  BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
  GREEN=""; RED=""; BLUE=""; VIOLET=""; YELLOW=""; BOLD=""; RESET=""
fi

# ------------------------------ VÃ©rif root ------------------------------------
if [[ ${EUID:-$UID} -ne 0 ]]; then
  echo -e "${RED}${BOLD}Ce script doit Ãªtre exÃ©cutÃ© en tant que root.${RESET}"
  exec sudo -E bash "$0" "$@"
fi

# ----------------------------- URLs des scripts --------------------------------
DOCKER_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/dockerinstall.sh"
YARN_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/yarninstall.sh"
NEW_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/refs/heads/fix/script-new-interactive-mode/.assets/new.sh"
SPEED_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/speedtest.sh"
FASTFETCH_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh"
PANEL_REINSTALL_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/pterodactylpanelreinstall.sh"
PTERO_MENU_URL="https://raw.githubusercontent.com/OverStyleFR/Pterodactyl-Installer-Menu/main/PterodactylMenu.sh"
SSH_MENU_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu_id.sh"

# ------------------------------- Helpers --------------------------------------
pause() { read -n 1 -s -r -p "Appuyez sur une touche pour retourner au menu..." ; echo; }

download_to_tmp() {
  # $1=url  $2=prefix (nom lisible)
  local url="$1" prefix="${2:-script}"
  local tmp
  tmp="$(mktemp -p /tmp "${prefix}.XXXXXX")" || { echo -e "${RED}${BOLD}mktemp a Ã©chouÃ©${RESET}"; return 98; }

  # Nettoyage automatique Ã  la sortie de la fonction:
  trap 'rm -f "$tmp" 2>/dev/null || true' RETURN

  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsSL --retry 3 --retry-delay 1 "$url" -o "$tmp"; then
      echo -e "${RED}${BOLD}TÃ©lÃ©chargement Ã©chouÃ© (curl)${RESET}"; return 90
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget -q "$url" -O "$tmp"; then
      echo -e "${RED}${BOLD}TÃ©lÃ©chargement Ã©chouÃ© (wget)${RESET}"; return 90
    fi
  else
    echo -e "${RED}${BOLD}Ni curl ni wget disponible pour tÃ©lÃ©charger${RESET}"; return 91
  fi

  chmod +x "$tmp"
  echo "$tmp"   # retourne le chemin
}

run_remote() {
  # $1=url  $2=nom_affichÃ©
  local url="$1" label="${2:-script}"
  echo -e "${YELLOW}${BOLD}TÃ©lÃ©chargement de ${label}â¦${RESET}"
  local tmp rc
  if ! tmp="$(download_to_tmp "$url" "$label")"; then
    echo -e "${RED}${BOLD}Ãchec de prÃ©paration pour ${label}${RESET}"
    return 90
  fi
  echo -e "${YELLOW}${BOLD}ExÃ©cution de ${label}â¦${RESET}"
  bash "$tmp"; rc=$?
  if [[ $rc -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}â ${label} terminÃ© avec succÃ¨s${RESET}"
  else
    echo -e "${RED}${BOLD}â ${label} a Ã©chouÃ© (rc=${rc})${RESET}"
    # indice utile pour new.sh
    ls -1 /var/log/new-basics-*.log 2>/dev/null | tail -n 1 | sed "s/^/Dernier log: /"
  fi
  return $rc
}

draw_menu() {
  clear
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
  echo "  | 3. ExÃ©cuter 'new.sh'                       |"
  echo "  |                                            |"
  echo "  | 4. ExÃ©cuter 'speedtest.sh'                 |"
  echo "  |                                            |"
  echo "  | 5. ExÃ©cuter 'fastfetch.sh'                 |"
  echo "  |                                            |"
  echo "  | 6. ExÃ©cuter 'pterodactyl-panel-reinstaller'|"
  echo "  +--------------------------------------------+"
  echo "  | 7. ${BLUE}${BOLD}ExÃ©cuter le Pterodactyl Menu${RESET}            |"
  echo "  | â ${YELLOW}${BOLD}OverStyleFR/Pterodactyl-Installer-Menu${RESET}   |"
  echo "  +--------------------------------------------+"
  echo "  | 8. ${BOLD}${VIOLET}M${GREEN}e${YELLOW}n${BLUE}u${RESET}${BOLD} SSH ${RESET}                               |"
  echo "  | â ${VIOLET}${BOLD}OverStyleFR/AutoScriptBash${RESET}               |"
  echo "  +-------------+------------+-----------------+"
  echo "                | ${RED}${BOLD}9. Quitter${RESET} |"
  echo "                +------------+"
  echo
}

# --------------------------------- Boucle -------------------------------------
while true; do
  draw_menu
  read -rp "Choisissez une option (1-9) : " choix
  case "${choix:-}" in
    1)
      echo "Installation de Docker."
      run_remote "$DOCKER_URL" "dockerinstall.sh"
      pause
      ;;
    2)
      echo "Installation de Yarn."
      run_remote "$YARN_URL" "yarninstall.sh"
      pause
      ;;
    3)
      echo "ExÃ©cution du script 'new.sh'."
      run_remote "$NEW_URL" "new.sh"
      pause
      ;;
    4)
      echo "ExÃ©cution du script 'speedtest.sh'."
      run_remote "$SPEED_URL" "speedtest.sh"
      pause
      ;;
    5)
      echo "ExÃ©cution du script 'fastfetch-install.sh'."
      run_remote "$FASTFETCH_URL" "fastfetch-install.sh"
      pause
      ;;
    6)
      echo "ExÃ©cution du script 'pterodactyl-panel-reinstaller'."
      run_remote "$PANEL_REINSTALL_URL" "pterodactylpanelreinstall.sh"
      pause
      ;;
    7)
      echo -e "${BLUE}${BOLD}ExÃ©cuter le Pterodactyl Menu${RESET}"
      run_remote "$PTERO_MENU_URL" "PterodactylMenu.sh"
      pause
      ;;
    8)
      echo -e "${BOLD}${VIOLET}Menu SSH${RESET}"
      run_remote "$SSH_MENU_URL" "menu_id.sh"
      pause
      ;;
    9)
      echo "Au revoir !"; exit 0 ;;
    *)
      echo -e "${RED}Choix non valide. Veuillez entrer un numÃ©ro entre 1 et 9.${RESET}"
      sleep 1
      ;;
  esac
done
