#!/usr/bin/env bash
# ==============================================================================
# menu.sh — TUI whiptail/dialog avec fallback Bash (ASCII style OverStyleFR)
#
# USAGE :
#   bash <(curl -fsSL https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu.sh) --bash
#
# OPTIONS :
#   --bash   Force le menu Bash (ASCII), même si whiptail/dialog sont présents
# ==============================================================================

set -uo pipefail

# ------------------------------ CLI flags -------------------------------------
FORCE_BASH=0
for arg in "$@"; do
  case "$arg" in
    --bash) FORCE_BASH=1 ;;
  esac
done

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

# ----------------------------- URLs des scripts -------------------------------
DOCKER_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/dockerinstall.sh"
YARN_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/yarninstall.sh"
NEW_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/refs/heads/fix/script-new-interactive-mode/.assets/new.sh"
SPEED_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/speedtest.sh"
FASTFETCH_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh"
PANEL_REINSTALL_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/pterodactylpanelreinstall.sh"
PTERO_MENU_URL="https://raw.githubusercontent.com/OverStyleFR/Pterodactyl-Installer-Menu/main/PterodactylMenu.sh"
SSH_MENU_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/menu_id.sh"

# ------------------------------ Options new.sh --------------------------------
NEW_F_DEBUG=0
NEW_F_DRYRUN=0
NEW_F_QUIET=0
NEW_EXTRA_ARGS=""
declare -a NEW_FLAGS=()

build_new_flags() {
  NEW_FLAGS=()
  (( NEW_F_DEBUG ))  && NEW_FLAGS+=(--debug)
  (( NEW_F_DRYRUN )) && NEW_FLAGS+=(--dry-run)
  (( NEW_F_QUIET ))  && NEW_FLAGS+=(--quiet)
  if [[ -n "$NEW_EXTRA_ARGS" ]]; then
    # shellcheck disable=SC2206
    local extra=( $NEW_EXTRA_ARGS )
    NEW_FLAGS+=( "${extra[@]}" )
  fi
}
flags_inline_if_any() {
  build_new_flags
  ((${#NEW_FLAGS[@]})) && echo " [${NEW_FLAGS[*]}]" || echo ""
}

# ------------------------------- Helpers communs ------------------------------
download_to_tmp() {
  local url="$1" prefix="${2:-script}" tmp
  tmp="$(mktemp -p /tmp "${prefix}.XXXXXX")" || { echo "mktemp a échoué"; return 98; }
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 --retry-delay 1 "$url" -o "$tmp" || { rm -f "$tmp"; return 90; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$tmp" || { rm -f "$tmp"; return 90; }
  else
    rm -f "$tmp"; return 91
  fi
  chmod +x "$tmp"
  printf "%s" "$tmp"
}
run_remote() {
  local url="$1" label="${2:-script}"; shift 2 || true
  local args=( "$@" ) tmp rc
  echo -e "${YELLOW}${BOLD}Téléchargement de ${label}…${RESET}"
  if ! tmp="$(download_to_tmp "$url" "$label")"; then
    echo -e "${RED}${BOLD}Échec de téléchargement.${RESET}"; return 90
  fi
  echo -e "${YELLOW}${BOLD}Exécution de ${label}…${RESET}"
  bash "$tmp" "${args[@]}"; rc=$?
  rm -f "$tmp" 2>/dev/null || true
  if [[ $rc -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✔ ${label} terminé avec succès${RESET}"
  else
    echo -e "${RED}${BOLD}✘ ${label} a échoué (rc=$rc)${RESET}"
    ls -1 /var/log/new-basics-*.log 2>/dev/null | tail -n 1 | sed "s/^/Dernier log : /"
  fi
  return $rc
}

# =============================== UI: WHIPTAIL/DIALOG ==========================
DIALOG_BIN=""
if [[ $FORCE_BASH -eq 0 ]]; then
  if command -v whiptail >/dev/null 2>&1; then
    DIALOG_BIN="whiptail"
  elif command -v dialog >/dev/null 2>&1; then
    DIALOG_BIN="dialog"
  fi
fi

ui_menu() {
  local title="$1" prompt="$2" h="$3" w="$4" mh="$5"; shift 5
  local status out
  if [[ "$DIALOG_BIN" == "whiptail" ]]; then
    out=$(whiptail --title "$title" --ok-button "OK" --cancel-button "Cancel" \
          --menu "$prompt" "$h" "$w" "$mh" "$@" 3>&1 1>&2 2>&3)
    status=$?
  else
    out=$(dialog --title "$title" --ok-label "OK" --cancel-label "Cancel" \
          --menu "$prompt" "$h" "$w" "$mh" "$@" 3>&1 1>&2 2>&3)
    status=$?
  fi
  printf "%s" "$out"
  return $status
}
ui_msg() {
  local title="$1" msg="$2"
  if [[ "$DIALOG_BIN" == "whiptail" ]]; then
    whiptail --title "$title" --msgbox "$msg" 13 70
  else
    dialog --title "$title" --msgbox "$msg" 13 70
  fi
}
adv_menu_ui() {
  local dbg="OFF" dry="OFF" qui="OFF" sel status
  (( NEW_F_DEBUG ))  && dbg="ON"
  (( NEW_F_DRYRUN )) && dry="ON"
  (( NEW_F_QUIET ))  && qui="ON"
  if [[ "$DIALOG_BIN" == "whiptail" ]]; then
    sel=$(whiptail --title "Options avancées (new.sh)" \
          --checklist "Sélectionne les flags à activer :" 16 70 6 \
          DEBUG  "Activer --debug (bash -x + logs DEBUG)"  "$dbg" \
          DRYRUN "Activer --dry-run (simulation)"          "$dry" \
          QUIET  "Activer --quiet (console moins bavarde)" "$qui" \
          3>&1 1>&2 2>&3); status=$?
  else
    sel=$(dialog --title "Options avancées (new.sh)" \
          --checklist "Sélectionne les flags à activer :" 16 70 6 \
          DEBUG  "Activer --debug (bash -x + logs DEBUG)"  "$dbg" \
          DRYRUN "Activer --dry-run (simulation)"          "$dry" \
          QUIET  "Activer --quiet (console moins bavarde)" "$qui" \
          3>&1 1>&2 2>&3); status=$?
  fi
  [[ $status -ne 0 ]] && return 0
  NEW_F_DEBUG=0; NEW_F_DRYRUN=0; NEW_F_QUIET=0
  for t in $sel; do
    t="${t%\"}"; t="${t#\"}"
    case "$t" in
      DEBUG)  NEW_F_DEBUG=1 ;;
      DRYRUN) NEW_F_DRYRUN=1 ;;
      QUIET)  NEW_F_QUIET=1 ;;
    esac
  done
  local extra
  if [[ "$DIALOG_BIN" == "whiptail" ]]; then
    extra=$(whiptail --title "Arguments libres (new.sh)" \
            --inputbox "Autres arguments (ex: --log /tmp/x.log) :" 10 70 "$NEW_EXTRA_ARGS" \
            3>&1 1>&2 2>&3); status=$?
  else
    extra=$(dialog --title "Arguments libres (new.sh)" \
            --inputbox "Autres arguments (ex: --log /tmp/x.log) :" 10 70 "$NEW_EXTRA_ARGS" \
            3>&1 1>&2 2>&3); status=$?
  fi
  [[ $status -ne 0 ]] && return 0
  NEW_EXTRA_ARGS="$extra"
  ui_msg "Options mises à jour" "new.sh sera lancé avec : $(flags_inline_if_any)"
}
submenu_installation_ui() {
  while true; do
    local sel; sel=$(ui_menu "Installation" "Choisis une action :" 15 70 6 \
      1 "Installer docker" \
      2 "Installer yarn" \
      3 "Retour")
    case $? in 1|255) return 0 ;; esac
    case "$sel" in
      1) run_remote "$DOCKER_URL" "dockerinstall.sh" ;;
      2) run_remote "$YARN_URL" "yarninstall.sh" ;;
      3|"") return 0 ;;
    esac
  done
}
submenu_scripts_ui() {
  while true; do
    local flags; flags="$(flags_inline_if_any)"
    local sel; sel=$(ui_menu "Scripts" "Choisis un script à exécuter :" 20 78 8 \
      1 "Exécuter 'new.sh'${flags}" \
      2 "Exécuter 'speedtest.sh'" \
      3 "Exécuter 'fastfetch-install.sh'" \
      4 "Exécuter 'pterodactyl-panel-reinstaller'" \
      5 "Retour")
    case $? in 1|255) return 0 ;; esac
    case "$sel" in
      1) build_new_flags; run_remote "$NEW_URL" "new.sh" "${NEW_FLAGS[@]}" ;;
      2) run_remote "$SPEED_URL" "speedtest.sh" ;;
      3) run_remote "$FASTFETCH_URL" "fastfetch-install.sh" ;;
      4) run_remote "$PANEL_REINSTALL_URL" "pterodactylpanelreinstall.sh" ;;
      5|"") return 0 ;;
    esac
  done
}
submenu_autres_ui() {
  while true; do
    local sel; sel=$(ui_menu "Autres menus" "Choisis une action :" 15 70 6 \
      1 "Exécuter le Pterodactyl Menu" \
      2 "Menu SSH" \
      3 "Retour")
    case $? in 1|255) return 0 ;; esac
    case "$sel" in
      1) run_remote "$PTERO_MENU_URL" "PterodactylMenu.sh" ;;
      2) run_remote "$SSH_MENU_URL" "menu_id.sh" ;;
      3|"") return 0 ;;
    esac
  done
}
main_menu_ui() {
  while true; do
    local sel; sel=$(ui_menu "Menu principal" "Sélectionne une catégorie :" 16 60 6 \
      1 "Installation" \
      2 "Scripts" \
      3 "Autres menus" \
      4 "Options avancées (new.sh)")
    case $? in 1|255) exit 0 ;; esac
    case "$sel" in
      1) submenu_installation_ui ;;
      2) submenu_scripts_ui ;;
      3) submenu_autres_ui ;;
      4) adv_menu_ui ;;
    esac
  done
}

# =============================== UI: MENU BASH (ASCII) ========================
pause() { read -n 1 -s -r -p "Appuyez sur une touche pour retourner au menu..." ; echo; }

draw_ascii_menu() {
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
  echo "  | 4. Exécuter 'speedtest.sh'                 |"
  echo "  | 5. Exécuter 'fastfetch-install.sh'         |"
  echo "  | 6. Exécuter 'pterodactyl-panel-reinstaller'|"
  echo "  +--------------------------------------------+"
  echo "  | 7. ${BLUE}${BOLD}Exécuter le Pterodactyl Menu${RESET}            |"
  echo "  | └ ${YELLOW}${BOLD}OverStyleFR/Pterodactyl-Installer-Menu${RESET}   |"
  echo "  +--------------------------------------------+"
  echo "  | 8. ${BOLD}${VIOLET}Menu SSH ${RESET}                               |"
  echo "  | └ ${VIOLET}${BOLD}OverStyleFR/AutoScriptBash${RESET}               |"
  echo "  +-------------+------------+-----------------+"
  echo "                | ${RED}${BOLD}9. Quitter${RESET} |"
  echo "                +------------+"
  echo
}

main_menu_ascii() {
  while true; do
    draw_ascii_menu
    read -rp "Choisissez une option (1-9) : " choix
    case "${choix:-}" in
      1) echo "Installation de Docker."                        ; run_remote "$DOCKER_URL" "dockerinstall.sh" ; pause ;;
      2) echo "Installation de Yarn."                          ; run_remote "$YARN_URL"   "yarninstall.sh"  ; pause ;;
      3) echo "Exécution du script 'new.sh'."                  ; build_new_flags; run_remote "$NEW_URL" "new.sh" "${NEW_FLAGS[@]}"; pause ;;
      4) echo "Exécution du script 'speedtest.sh'."            ; run_remote "$SPEED_URL" "speedtest.sh"    ; pause ;;
      5) echo "Exécution du script 'fastfetch-install.sh'."    ; run_remote "$FASTFETCH_URL" "fastfetch-install.sh" ; pause ;;
      6) echo "Exécution du script 'pterodactyl-panel-reinstaller'." ; run_remote "$PANEL_REINSTALL_URL" "pterodactylpanelreinstall.sh" ; pause ;;
      7) echo -e "${BLUE}${BOLD}Exécuter le Pterodactyl Menu${RESET}" ; run_remote "$PTERO_MENU_URL" "PterodactylMenu.sh" ; pause ;;
      8) echo -e "${BOLD}${VIOLET}Menu SSH${RESET}"                    ; run_remote "$SSH_MENU_URL"  "menu_id.sh"         ; pause ;;
      9) echo "Au revoir !" ; exit 0 ;;
      *) echo -e "${RED}Choix non valide. Veuillez entrer un numéro entre 1 et 9.${RESET}"; sleep 1 ;;
    esac
  done
}

# =============================== Lancement ====================================
if [[ -n "$DIALOG_BIN" ]]; then
  main_menu_ui
else
  echo "(UI Bash : whiptail/dialog indisponibles ou --bash forcé)"
  main_menu_ascii
fi
