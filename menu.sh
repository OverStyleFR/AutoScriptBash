#!/usr/bin/env bash
# ==============================================================================
# menu.sh — Lanceur interactif des scripts OverStyleFR
#
# USAGE :
#   sudo ./menu.sh
# ==============================================================================

set -uo pipefail

# ------------------------------- Couleurs -------------------------------------
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  GREEN="$(tput setaf 2)"; RED="$(tput setaf 1)"; BLUE="$(tput setaf 4)"
  VIOLET="$(tput setaf 5)"; YELLOW="$(tput setaf 3)"
  BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
  GREEN=""; RED=""; BLUE=""; VIOLET=""; YELLOW=""; BOLD=""; RESET=""
fi

# ------------------------------ Vérif root ------------------------------------
if [[ ${EUID:-$UID} -ne 0 ]]; then
  echo -e "${RED}${BOLD}Ce script doit être exécuté en tant que root.${RESET}"
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
  tmp="$(mktemp -p /tmp "${prefix}.XXXXXX")" || { echo -e "${RED}${BOLD}mktemp a échoué${RESET}"; return 98; }

  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsSL --retry 3 --retry-delay 1 "$url" -o "$tmp"; then
      echo -e "${RED}${BOLD}Téléchargement échoué (curl)${RESET}"; rm -f "$tmp"; return 90
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget -q "$url" -O "$tmp"; then
      echo -e "${RED}${BOLD}Téléchargement échoué (wget)${RESET}"; rm -f "$tmp"; return 90
    fi
  else
    echo -e "${RED}${BOLD}Ni curl ni wget disponible pour télécharger${RESET}"; rm -f "$tmp"; return 91
  fi

  chmod +x "$tmp"
  printf "%s" "$tmp"   # retourne le chemin
}

run_remote() {
  # $1=url  $2=nom_affiché
  local url="$1" label="${2:-script}" tmp rc
  echo -e "${YELLOW}${BOLD}Téléchargement de ${label}…${RESET}"
  if ! tmp="$(download_to_tmp "$url" "$label")"; then
    echo -e "${RED}${BOLD}Échec de préparation pour ${label}${RESET}"
    return 90
  fi
  echo -e "${YELLOW}${BOLD}Exécution de ${label}…${RESET}"
  bash "$tmp"; rc=$?
  rm -f "$tmp" 2>/dev/null || true
  if [[ $rc -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✔ ${label} terminé avec succès${RESET}"
  else
    echo -e "${RED}${BOLD}✘ ${label} a échoué (rc=${rc})${RESET}"
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
  echo
}

# --------------------------------- Boucle -------------------------------------
while true; do
  draw_menu
  read -rp "Choisissez une option (1-9) : " choix
  case "${choix:-}" in
    1) echo "Installation de Docker." ; run_remote "$DOCKER_URL" "dockerinstall.sh" ; pause ;;
    2) echo "Installation de Yarn."   ; run_remote "$YARN_URL"   "yarninstall.sh"    ; pause ;;
    3) echo "Exécution du script 'new.sh'."                     ; run_remote "$NEW_URL"   "new.sh"            ; pause ;;
    4) echo "Exécution du script 'speedtest.sh'."               ; run_remote "$SPEED_URL" "speedtest.sh"      ; pause ;;
    5) echo "Exécution du script 'fastfetch-install.sh'."       ; run_remote "$FASTFETCH_URL" "fastfetch-install.sh" ; pause ;;
    6) echo "Exécution du script 'pterodactyl-panel-reinstaller'."; run_remote "$PANEL_REINSTALL_URL" "pterodactylpanelreinstall.sh" ; pause ;;
    7) echo -e "${BLUE}${BOLD}Exécuter le Pterodactyl Menu${RESET}" ; run_remote "$PTERO_MENU_URL" "PterodactylMenu.sh" ; pause ;;
    8) echo -e "${BOLD}${VIOLET}Menu SSH${RESET}"                   ; run_remote "$SSH_MENU_URL"  "menu_id.sh"          ; pause ;;
    9) echo "Au revoir !" ; exit 0 ;;
    *) echo -e "${RED}Choix non valide. Veuillez entrer un numéro entre 1 et 9.${RESET}" ; sleep 1 ;;
  esac
done
