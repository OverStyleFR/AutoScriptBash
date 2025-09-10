#!/usr/bin/env bash
# new.sh — version verbose pour techniciens

################################################################################
# Options opérateur
#   --debug     : active bash -x et logs DEBUG
#   --dry-run   : n'exécute rien (affiche uniquement)
#   --quiet     : réduit la verbosité à WARN/ERROR
################################################################################

set -euo pipefail

# ============================== CLI Flags ======================================
DEBUG=0
DRYRUN=0
QUIET=0
for arg in "$@"; do
  case "${arg:-}" in
    --debug) DEBUG=1 ;;
    --dry-run|--dryrun) DRYRUN=1 ;;
    --quiet|-q) QUIET=1 ;;
    *) ;;
  esac
done
[[ $DEBUG -eq 1 ]] && set -x

# ============================== Logging ========================================
_start_ts=$(date +%s)
LOG_TS="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/new.sh-${LOG_TS}.log"
mkdir -p "$LOG_DIR"
# Redirige TOUT vers tee (stdout + fichier)
exec > >(tee -a "$LOG_FILE") 2>&1

# Couleurs
BOLD="\e[1m"; DIM="\e[2m"; RED="\e[31m"; YEL="\e[33m"; GRN="\e[32m"; BLU="\e[34m"; C0="\e[0m"

_now() { date "+%Y-%m-%d %H:%M:%S%z"; }
_since() { local s=$1; printf "%ds" $(( $(date +%s) - s )); }

log()       { printf "%b[%s] [INFO ]%b %s\n" "$GRN" "$(_now)" "$C0" "$*"; }
warn()      { printf "%b[%s] [WARN ]%b %s\n" "$YEL" "$(_now)" "$C0" "$*"; }
err()       { printf "%b[%s] [ERROR]%b %s\n" "$RED" "$(_now)" "$C0" "$*"; }
debug()     { [[ $DEBUG -eq 1 ]] && printf "%b[%s] [DEBUG]%b %s\n" "$BLU" "$(_now)" "$C0" "$*"; }
logq()      { [[ $QUIET -eq 0 ]] && log "$@" || true; }

# Affiche et exécute une commande (ou simule en dry-run)
run() {
  local desc="$1"; shift
  local ts=$(date +%s)
  if [[ $DRYRUN -eq 1 ]]; then
    printf "%b[%s] [DRYRN]%b %s → %s\n" "$DIM" "$(_now)" "$C0" "$desc" "$*"
    return 0
  fi
  printf "%b[%s] [EXEC ]%b %s\n" "$BOLD" "$(_now)" "$C0" "$desc"
  debug "Commande: $*"
  if "$@"; then
    log "OK: $desc (durée $(_since "$ts"))"
    return 0
  else
    err "ECHEC: $desc (durée $(_since "$ts"))"
    return 1
  fi
}

# ============================== Root & contexte ================================
if [[ $EUID -ne 0 ]]; then
  warn "Ce script doit être exécuté en root. Tentative avec sudo…"
  exec sudo -E "$0" "$@"
fi

trap 'err "Interruption ou erreur (code=$?) — voir $LOG_FILE"; exit 1' INT TERM

log "Journal complet: $LOG_FILE"
log "Hôte: $(hostname) | Kernel: $(uname -r) | Arch: $(uname -m)"
log "Shell: $SHELL | DEBUG=$DEBUG | DRYRUN=$DRYRUN | QUIET=$QUIET"

# ============================== Détection distro ===============================
DIST_ID=""; DIST_LIKE=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DIST_ID="${ID:-unknown}"
  DIST_LIKE="${ID_LIKE:-}"
else
  err "/etc/os-release introuvable — abandon."
  exit 1
fi
log "Distribution détectée: ID=${DIST_ID} | ID_LIKE=${DIST_LIKE}"

# ============================== Gestionnaire paquets ===========================
PKG_MGR="" PKG_UPDATE="" PKG_UPGRADE="" PKG_INSTALL="" PKG_QUERY=""
case "$DIST_ID" in
  debian|ubuntu|linuxmint|pop)
    export DEBIAN_FRONTEND=noninteractive
    PKG_MGR="apt"
    PKG_UPDATE="apt-get update -y"
    PKG_UPGRADE="apt-get -y full-upgrade --autoremove --purge"
    PKG_INSTALL="apt-get install -y"
    PKG_QUERY="apt-cache policy"
    ;;
  fedora)
    PKG_MGR="dnf"
    PKG_UPDATE="dnf -y makecache"
    PKG_UPGRADE="dnf -y upgrade --refresh"
    PKG_INSTALL="dnf -y install"
    PKG_QUERY="dnf info"
    ;;
  rhel|centos|rocky|almalinux)
    if command -v dnf >/dev/null 2>&1; then
      PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"; PKG_QUERY="dnf info"
    else
      PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"; PKG_QUERY="yum info"
    fi
    ;;
  arch|artix|manjaro)
    PKG_MGR="pacman"
    PKG_UPDATE="pacman -Sy --noconfirm"
    PKG_UPGRADE="pacman -Syu --noconfirm"
    PKG_INSTALL="pacman -S --noconfirm --needed"
    PKG_QUERY="pacman -Si"
    ;;
  opensuse*|sles)
    PKG_MGR="zypper"
    PKG_UPDATE="zypper --non-interactive refresh"
    PKG_UPGRADE="zypper --non-interactive update"
    PKG_INSTALL="zypper --non-interactive install --no-confirm"
    PKG_QUERY="zypper info"
    ;;
  alpine)
    PKG_MGR="apk"
    PKG_UPDATE="apk update"
    PKG_UPGRADE="apk upgrade"
    PKG_INSTALL="apk add --no-cache"
    PKG_QUERY="apk info -e"
    ;;
  *)
    case "$DIST_LIKE" in
      *debian*) DIST_ID="debian"; export DEBIAN_FRONTEND=noninteractive
        PKG_MGR="apt"; PKG_UPDATE="apt-get update -y"; PKG_UPGRADE="apt-get -y full-upgrade --autoremove --purge"; PKG_INSTALL="apt-get install -y"; PKG_QUERY="apt-cache policy" ;;
      *rhel*|*fedora*) DIST_ID="rhel"
        if command -v dnf >/dev/null 2>&1; then
          PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"; PKG_QUERY="dnf info"
        else
          PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"; PKG_QUERY="yum info"
        fi ;;
      *)
        err "Distribution non gérée (ID=$DIST_ID ID_LIKE=$DIST_LIKE)"; exit 1 ;;
    esac
    ;;
esac
log "Gestionnaire de paquets: $PKG_MGR"
debug "CMD update='$PKG_UPDATE' upgrade='$PKG_UPGRADE' install='$PKG_INSTALL' query='$PKG_QUERY'"

# ============================== Helpers paquets ================================
pkg_available() {
  local pkg="$1"
  case "$PKG_MGR" in
    apt)     $PKG_QUERY "$pkg" >/dev/null 2>&1 ;;
    dnf|yum) $PKG_QUERY "$pkg" >/dev/null 2>&1 ;;
    pacman)  $PKG_QUERY "$pkg" >/dev/null 2>&1 ;;
    zypper)  $PKG_QUERY "$pkg" >/dev/null 2>&1 ;;
    apk)     $PKG_QUERY "$pkg" >/dev/null 2>&1 ;;
    *)       return 1 ;;
  esac
}

install_if_exists() {
  local group="$1"; shift
  local wanted=("$@")
  local ok=() skip=()
  for p in "${wanted[@]}"; do
    if pkg_available "$p"; then ok+=("$p"); else skip+=("$p"); fi
  done
  if ((${#ok[@]})); then
    logq "Installation ($group): ${ok[*]}"
    if [[ $DRYRUN -eq 0 ]]; then
      # shellcheck disable=SC2086
      run "Installer ($group)" $PKG_INSTALL ${ok[*]} || warn "Erreur installation ($group)"
    else
      printf "[DRYRUN] %s %s\n" "$PKG_INSTALL" "${ok[*]}"
    fi
  else
    warn "Aucun paquet installable pour le lot: $group"
  fi
  if ((${#skip[@]})); then
    warn "Indisponibles ($group): ${skip[*]}"
  fi
}

# ============================== MAJ système ===================================
ts_update=$(date +%s)
run "MAJ index paquets" bash -c "$PKG_UPDATE" || warn "Update partielle/échouée"
run "Upgrade système"  bash -c "$PKG_UPGRADE" || warn "Upgrade partielle/échouée"
log "Section MAJ terminée (durée $(_since "$ts_update"))"

# ============================== Mapping paquets ===============================
# Paquets communs (mappés selon distro)
PKG_GNUPG=(gnupg gnupg2)      # apt gère les deux; autres distros n'installeront que celui dispo
PKG_LMSENS=(lm-sensors)
PKG_COMMON=(curl wget htop nload screen vim git ncdu rsync tree net-tools ripgrep)
PKG_MAN_DEB=(man-db)
PKG_DNS_DEB=(dnsutils)
PKG_DNS_RPM=(bind-utils)
PKG_DNS_ARCH_ALP=(bind-tools)
PKG_AVAHI_DEB=(avahi-daemon)
PKG_AVAHI_OTH=(avahi)         # Arch/RPM/openSUSE/Alpine
PKG_BPY=(bpytop)
PKG_BTOP=(btop)

log "Sélection des paquets selon famille: $DIST_ID ($PKG_MGR)"

case "$PKG_MGR" in
  apt)
    install_if_exists "gnupg"        "${PKG_GNUPG[@]}"
    install_if_exists "lm-sensors"   "${PKG_LMSENS[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_MAN_DEB[@]}" "${PKG_DNS_DEB[@]}" "${PKG_AVAHI_DEB[@]}"
    # bpytop ou btop
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  dnf|yum)
    install_if_exists "gnupg"        gnupg
    install_if_exists "lm-sensors"   "${PKG_LMSENS[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_DNS_RPM[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  pacman)
    install_if_exists "gnupg"        gnupg
    install_if_exists "lm-sensors"   lm_sensors
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_DNS_ARCH_ALP[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  zypper)
    install_if_exists "gnupg"        gpg2
    install_if_exists "lm-sensors"   "${PKG_LMSENS[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_DNS_RPM[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  apk)
    install_if_exists "gnupg"        gnupg
    install_if_exists "lm-sensors"   lm-sensors
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_DNS_ARCH_ALP[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
esac

# ============================== Fastfetch (repo > fallback) ====================
install_fastfetch() {
  local ts=$(date +%s)
  if pkg_available fastfetch; then
    log "fastfetch disponible dans les dépôts: installation via $PKG_MGR"
    install_if_exists "fastfetch" fastfetch
    log "fastfetch installé via dépôts (durée $(_since "$ts"))"
    return 0
  fi
  warn "fastfetch non dispo dans les dépôts — fallback script externe"
  local URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh"
  if [[ $DRYRUN -eq 1 ]]; then
    printf "[DRYRUN] bash <(curl -fsSL %s)\n" "$URL"
    return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    run "Installer fastfetch (script)" bash -c "bash <(curl -fsSL \"$URL\")"
  elif command -v wget >/dev/null 2>&1; then
    run "Installer fastfetch (script)" bash -c "bash <(wget -qO- \"$URL\")"
  else
    err "Ni curl ni wget disponibles — fastfetch non installé."
    return 1
  fi
  log "fastfetch via script terminé (durée $(_since "$ts"))"
}
install_fastfetch || warn "Installation fastfetch échouée (script)."

# ============================== Timezone ======================================
if command -v timedatectl >/dev/null 2>&1; then
  run "Réglage timezone Europe/Paris" timedatectl set-timezone Europe/Paris || warn "Echec réglage timezone"
else
  warn "timedatectl indisponible — saut du réglage timezone."
fi

# ============================== Cron @reboot ===================================
if command -v crontab >/dev/null 2>&1; then
  log "Ajout cron @reboot (ping court vers 1.1.1.1)"
  if [[ $DRYRUN -eq 0 ]]; then
    (crontab -l 2>/dev/null | grep -v "ping -c 5 1\.1\.1\.1" 2>/dev/null; echo '@reboot /bin/ping -c 5 1.1.1.1 >/dev/null 2>&1 || true') | crontab -
  else
    echo "[DRYRUN] crontab append: @reboot /bin/ping -c 5 1.1.1.1 >/dev/null 2>&1 || true"
  fi
else
  warn "crontab indisponible (cron non installé ?)"
fi

# ============================== .bashrc perso =================================
BRC_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/.bashrc"
if [[ -f "$HOME/.bashrc" ]]; then
  run "Backup ~/.bashrc" cp -a "$HOME/.bashrc" "$HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)" || true
fi
if command -v curl >/dev/null 2>&1; then
  [[ $DRYRUN -eq 1 ]] && echo "[DRYRUN] curl -fsSL $BRC_URL -o $HOME/.bashrc" || run "Télécharger .bashrc" curl -fsSL "$BRC_URL" -o "$HOME/.bashrc"
elif command -v wget >/dev/null 2>&1; then
  [[ $DRYRUN -eq 1 ]] && echo "[DRYRUN] wget -q $BRC_URL -O $HOME/.bashrc" || run "Télécharger .bashrc" wget -q "$BRC_URL" -O "$HOME/.bashrc"
else
  warn "Ni curl ni wget pour récupérer le .bashrc"
fi

# Recharge seulement en shell interactif bash
if [[ -n "${PS1:-}" && -n "${BASH_VERSION:-}" && $DRYRUN -eq 0 ]]; then
  # shellcheck disable=SC1090
  run "Recharger ~/.bashrc" bash -lc "source \"$HOME/.bashrc\"" || true
fi

# ============================== Avahi =========================================
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q '^avahi-daemon\.service'; then
    run "Activer avahi-daemon" systemctl enable --now avahi-daemon || warn "Impossible d'activer avahi-daemon"
  else
    debug "Service avahi-daemon non présent — ignoré."
  fi
else
  debug "systemctl indisponible — probablement sans systemd."
fi

# ============================== Récapitulatif =================================
echo
echo -e "${BOLD}============================= RÉCAPITULATIF =============================${C0}"
echo "  - Journal complet : $LOG_FILE"
echo "  - Distro          : ID=$DIST_ID | LIKE=$DIST_LIKE | PKG_MGR=$PKG_MGR"
echo "  - DEBUG           : $DEBUG | DRYRUN=$DRYRUN | QUIET=$QUIET"
echo "  - Durée totale    : $(_since "$_start_ts")"
echo -e "${BOLD}=========================================================================${C0}"

log "Configuration terminée."

# Fin
