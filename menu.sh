#!/usr/bin/env bash
# ==============================================================================
# menu.sh — TUI façon raspi-config (whiptail/dialog) avec sous-menus + options
# - Cancel fonctionne partout (main + sous-menus)
# - Les flags de new.sh n'apparaissent que s'il y en a
# USAGE :
#   sudo ./menu.sh
# ==============================================================================

set -uo pipefail

# ------------------------------ Vérif root ------------------------------------
if [[ ${EUID:-$UID} -ne 0 ]]; then
  echo "Ce script doit être exécuté en root."
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

# ------------------------------ Backend UI ------------------------------------
DIALOG_BIN=""
if command -v whiptail >/dev/null 2>&1; then
  DIALOG_BIN="whiptail"
elif command -v dialog >/dev/null 2>&1; then
  DIALOG_BIN="dialog"
else
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y whiptail >/dev/null 2>&1 || true
    command -v whiptail >/dev/null 2>&1 && DIALOG_BIN="whiptail"
  fi
fi

if [[ -z "$DIALOG_BIN" ]]; then
  echo "Ni 'whiptail' ni 'dialog' détecté. Installe 'whiptail' (apt install -y whiptail) puis relance."
  exit 1
fi

# Wrapper uniforme pour --menu (retourne le choix sur stdout, et code:
# 0=OK, 1=Cancel, 255=ESC)
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
  if ((${#NEW_FLAGS[@]}==0)); then
    echo ""         # rien si aucun flag (demande)
  else
    echo " [${NEW_FLAGS[*]}]"
  fi
}

adv_menu() {
  local dbg="OFF" dry="OFF" qui="OFF"
  (( NEW_F_DEBUG ))  && dbg="ON"
  (( NEW_F_DRYRUN )) && dry="ON"
  (( NEW_F_QUIET ))  && qui="ON"

  local sel status
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

# ------------------------------- Helpers exec ---------------------------------
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
  tmp="$(download_to_tmp "$url" "$label")" || { ui_msg "Erreur" "Échec de téléchargement de ${label}."; return 90; }
  clear; echo "=== Exécution de ${label} ==="
  bash "$tmp" "${args[@]}"; rc=$?
  rm -f "$tmp" 2>/dev/null || true
  if [[ $rc -eq 0 ]]; then
    ui_msg "Terminé" "✔ ${label} s'est terminé avec succès."
  else
    local hint; hint="$(ls -1 /var/log/new-basics-*.log 2>/dev/null | tail -n 1)"
    ui_msg "Échec" "✘ ${label} a échoué (rc=$rc).${hint:+\nDernier log : $hint}"
  fi
  return $rc
}

# ------------------------------- Sous-menus ------------------------------------
submenu_installation() {
  while true; do
    local sel
    sel=$(ui_menu "Installation" "Choisis une action :" 15 70 6 \
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
submenu_scripts() {
  while true; do
    local flags; flags="$(flags_inline_if_any)"
    local sel
    sel=$(ui_menu "Scripts" "Choisis un script à exécuter :" 20 78 8 \
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
submenu_autres() {
  while true; do
    local sel
    sel=$(ui_menu "Autres menus" "Choisis une action :" 15 70 6 \
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

# ------------------------------- Menu principal --------------------------------
main_menu() {
  while true; do
    local sel
    sel=$(ui_menu "Menu principal" "Sélectionne une catégorie :" 16 60 6 \
      1 "Installation" \
      2 "Scripts" \
      3 "Autres menus" \
      4 "Options avancées (new.sh)")
    case $? in 1|255) exit 0 ;; esac
    case "$sel" in
      1) submenu_installation ;;
      2) submenu_scripts ;;
      3) submenu_autres ;;
      4) adv_menu ;;
      *) : ;;
    esac
  done
}

main_menu
