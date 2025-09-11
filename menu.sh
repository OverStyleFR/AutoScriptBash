#!/usr/bin/env bash
# ==============================================================================
# menu.sh — TUI façon raspi-config (whiptail/dialog) pour lancer les scripts
#
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

# ------------------------------ UI backend ------------------------------------
DIALOG_BIN=""
if command -v whiptail >/dev/null 2>&1; then
  DIALOG_BIN="whiptail"
elif command -v dialog >/dev/null 2>&1; then
  DIALOG_BIN="dialog"
else
  # petit essai d’installation silencieuse côté apt ; sinon fallback texte
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y whiptail >/dev/null 2>&1 || true
    command -v whiptail >/dev/null 2>&1 && DIALOG_BIN="whiptail"
  fi
fi

msg_box() {
  # $1 titre, $2 message
  if [[ -n "$DIALOG_BIN" ]]; then
    $DIALOG_BIN --title "$1" --msgbox "$2" 13 70
  else
    echo -e "\n==== $1 ====\n$2\n(Entrée pour continuer)"; read -r _
  fi
}

# ------------------------------- Helpers --------------------------------------
download_to_tmp() {
  # $1=url  $2=prefix (nom lisible)
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
  # $1=url  $2=nom_affiché
  local url="$1" label="${2:-script}" tmp rc
  tmp="$(download_to_tmp "$url" "$label")" || {
    msg_box "Erreur" "Échec de téléchargement de ${label}.\nVérifie la connexion réseau."
    return 90
  }

  clear
  echo "=== Exécution de ${label} ==="
  bash "$tmp"; rc=$?
  rm -f "$tmp" 2>/dev/null || true

  if [[ $rc -eq 0 ]]; then
    msg_box "Terminé" "✔ ${label} s'est terminé avec succès."
  else
    local hint
    hint="$(ls -1 /var/log/new-basics-*.log 2>/dev/null | tail -n 1)"
    msg_box "Échec" "✘ ${label} a échoué (rc=$rc).\n${hint:+Dernier log : $hint}"
  fi
  return $rc
}

# ------------------------------- Menu loop ------------------------------------
text_menu() {
  while true; do
    clear
    cat <<'TXT'
+-------------------------------+
|           MENU (texte)        |
+-------------------------------+
 1) Installer docker
 2) Installer yarn
 3) Exécuter 'new.sh'
 4) Exécuter 'speedtest.sh'
 5) Exécuter 'fastfetch-install.sh'
 6) Exécuter 'pterodactyl-panel-reinstaller'
 7) Lancer PterodactylMenu.sh
 8) Menu SSH
 9) Quitter
TXT
    read -rp "Choix (1-9) : " choix
    case "${choix:-}" in
      1) run_remote "$DOCKER_URL" "dockerinstall.sh" ;;
      2) run_remote "$YARN_URL" "yarninstall.sh" ;;
      3) run_remote "$NEW_URL" "new.sh" ;;
      4) run_remote "$SPEED_URL" "speedtest.sh" ;;
      5) run_remote "$FASTFETCH_URL" "fastfetch-install.sh" ;;
      6) run_remote "$PANEL_REINSTALL_URL" "pterodactylpanelreinstall.sh" ;;
      7) run_remote "$PTERO_MENU_URL" "PterodactylMenu.sh" ;;
      8) run_remote "$SSH_MENU_URL" "menu_id.sh" ;;
      9) exit 0 ;;
      *) ;;
    esac
  done
}

whip_menu() {
  local choice ret
  while true; do
    choice=$($DIALOG_BIN --backtitle "OverStyleFR • AutoScriptBash" \
      --title "Menu principal" \
      --menu "Sélectionne une action :" 20 74 10 \
      1 "Installer docker" \
      2 "Installer yarn" \
      3 "Exécuter 'new.sh'" \
      4 "Exécuter 'speedtest.sh'" \
      5 "Exécuter 'fastfetch-install.sh'" \
      6 "Exécuter 'pterodactyl-panel-reinstaller'" \
      7 "Exécuter le Pterodactyl Menu" \
      8 "Menu SSH" \
      9 "Quitter" \
      3>&1 1>&2 2>&3)
    ret=$?
    [[ $ret -ne 0 ]] && exit 0

    case "$choice" in
      1) run_remote "$DOCKER_URL" "dockerinstall.sh" ;;
      2) run_remote "$YARN_URL" "yarninstall.sh" ;;
      3) run_remote "$NEW_URL" "new.sh" ;;
      4) run_remote "$SPEED_URL" "speedtest.sh" ;;
      5) run_remote "$FASTFETCH_URL" "fastfetch-install.sh" ;;
      6) run_remote "$PANEL_REINSTALL_URL" "pterodactylpanelreinstall.sh" ;;
      7) run_remote "$PTERO_MENU_URL" "PterodactylMenu.sh" ;;
      8) run_remote "$SSH_MENU_URL" "menu_id.sh" ;;
      9) exit 0 ;;
    esac
  done
}

# Lancer le bon menu selon disponibilité
if [[ -n "$DIALOG_BIN" ]]; then
  whip_menu
else
  echo "Ni 'whiptail' ni 'dialog' détecté — menu texte simple."
  echo "Conseil (Debian/Ubuntu) : apt-get install -y whiptail"
  text_menu
fi
