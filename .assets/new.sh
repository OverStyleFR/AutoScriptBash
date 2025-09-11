#!/usr/bin/env bash
# new-basics.sh â version verbose pour techniciens
# Objectif :
#   - DÃ©tecte la distro et installe : gnupg{,2} lm-sensors curl wget htop nload screen vim git ncdu bpytop rsync man avahi-daemon tree dnsutils net-tools ripgrep
#   - fastfetch : depuis les dÃ©pÃ´ts si dispo, sinon script externe (GitHub)
#   - Remplace le .bashrc de lâutilisateur appelant (SUDO_USER le cas Ã©chÃ©ant)
#   - Timezone -> Europe/Paris
#   - Logs dÃ©taillÃ©s dans /var/log + affichage verbeux, options --debug --dry-run --quiet

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
LOG_FILE="${LOG_DIR}/new-basics-${LOG_TS}.log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

BOLD="\e[1m"; DIM="\e[2m"; RED="\e[31m"; YEL="\e[33m"; GRN="\e[32m"; BLU="\e[34m"; C0="\e[0m"
_now() { date "+%Y-%m-%d %H:%M:%S%z"; }
_since() { local s=$1; printf "%ds" $(( $(date +%s) - s )); }

log()   { printf "%b[%s] [INFO ]%b %s\n"  "$GRN" "$(_now)" "$C0" "$*"; }
warn()  { printf "%b[%s] [WARN ]%b %s\n"  "$YEL" "$(_now)" "$C0" "$*"; }
err()   { printf "%b[%s] [ERROR]%b %s\n"  "$RED" "$(_now)" "$C0" "$*"; }
debug() { [[ $DEBUG -eq 1 ]] && printf "%b[%s] [DEBUG]%b %s\n" "$BLU" "$(_now)" "$C0" "$*"; }
logq()  { [[ $QUIET -eq 0 ]] && log "$@" || true; }

run() {
  local desc="$1"; shift
  local ts=$(date +%s)
  if [[ $DRYRUN -eq 1 ]]; then
    printf "%b[%s] [DRYRN]%b %s â %s\n" "$DIM" "$(_now)" "$C0" "$desc" "$*"
    return 0
  fi
  printf "%b[%s] [EXEC ]%b %s\n" "$BOLD" "$(_now)" "$C0" "$desc"
  debug "Commande: $*"
  if "$@"; then
    log "OK: $desc (durÃ©e $(_since "$ts"))"
    return 0
  else
    err "ECHEC: $desc (durÃ©e $(_since "$ts"))"
    return 1
  fi
}

# ============================== Root & contexte ================================
if [[ $EUID -ne 0 ]]; then
  warn "Ce script doit Ãªtre exÃ©cutÃ© en root. Tentative avec sudoâ¦"
  exec sudo -E "$0" "$@"
fi

trap 'err "Interruption ou erreur (code=$?) â voir $LOG_FILE"; exit 1' INT TERM

log "Journal complet: $LOG_FILE"
log "HÃ´te: $(hostname) | Kernel: $(uname -r) | Arch: $(uname -m)"
log "Shell: $SHELL | DEBUG=$DEBUG | DRYRUN=$DRYRUN | QUIET=$QUIET"

# ============================== DÃ©tection distro ===============================
DIST_ID=""; DIST_LIKE=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DIST_ID="${ID:-unknown}"
  DIST_LIKE="${ID_LIKE:-}"
else
  err "/etc/os-release introuvable â abandon."
  exit 1
fi
log "Distribution dÃ©tectÃ©e: ID=${DIST_ID} | ID_LIKE=${DIST_LIKE}"

# ============================== Gestionnaire paquets ===========================
PKG_MGR="" PKG_UPDATE="" PKG_UPGRADE="" PKG_INSTALL="" PKG_Q_AVAIL=""
case "$DIST_ID" in
  debian|ubuntu|linuxmint|pop|kali)
    export DEBIAN_FRONTEND=noninteractive
    PKG_MGR="apt"
    PKG_UPDATE="apt-get update -y"
    PKG_UPGRADE="apt-get -y full-upgrade --autoremove --purge"
    PKG_INSTALL="apt-get install -y"
    # 0 si dispo (Candidate != (none))
    PKG_Q_AVAIL='sh -c "[[ \$(apt-cache policy \"$1\" 2>/dev/null | awk '\''/Candidate:/ {print \$2}'\'' ) != \"(none)\" ]]" _'
    ;;
  fedora)
    PKG_MGR="dnf"
    PKG_UPDATE="dnf -y makecache"
    PKG_UPGRADE="dnf -y upgrade --refresh"
    PKG_INSTALL="dnf -y install"
    PKG_Q_AVAIL="dnf -q info"
    ;;
  rhel|centos|rocky|almalinux)
    if command -v dnf >/dev/null 2>&1; then
      PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"; PKG_Q_AVAIL="dnf -q info"
    else
      PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"; PKG_Q_AVAIL="yum -q info"
    fi
    ;;
  arch|artix|manjaro)
    PKG_MGR="pacman"
    PKG_UPDATE="pacman -Sy --noconfirm"
    PKG_UPGRADE="pacman -Syu --noconfirm"
    PKG_INSTALL="pacman -S --noconfirm --needed"
    PKG_Q_AVAIL="pacman -Si"
    ;;
  opensuse*|sles)
    PKG_MGR="zypper"
    PKG_UPDATE="zypper --non-interactive refresh"
    PKG_UPGRADE="zypper --non-interactive update"
    PKG_INSTALL="zypper --non-interactive install --no-confirm"
    PKG_Q_AVAIL="zypper info"
    ;;
  alpine)
    PKG_MGR="apk"
    PKG_UPDATE="apk update"
    PKG_UPGRADE="apk upgrade"
    PKG_INSTALL="apk add --no-cache"
    # 0 si apk search -x renvoie un match exact
    PKG_Q_AVAIL='sh -c "apk search -x \"$1\" >/dev/null 2>&1" _'
    ;;
  *)
    case "$DIST_LIKE" in
      *debian*) DIST_ID="debian"; export DEBIAN_FRONTEND=noninteractive
        PKG_MGR="apt"; PKG_UPDATE="apt-get update -y"; PKG_UPGRADE="apt-get -y full-upgrade --autoremove --purge"; PKG_INSTALL="apt-get install -y"
        PKG_Q_AVAIL='sh -c "[[ \$(apt-cache policy \"$1\" 2>/dev/null | awk '\''/Candidate:/ {print \$2}'\'' ) != \"(none)\" ]]" _'
        ;;
      *rhel*|*fedora*)
        if command -v dnf >/dev/null 2>&1; then
          PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"; PKG_Q_AVAIL="dnf -q info"
        else
          PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"; PKG_Q_AVAIL="yum -q info"
        fi ;;
      *)
        err "Distribution non gÃ©rÃ©e (ID=$DIST_ID ID_LIKE=$DIST_LIKE)"; exit 1 ;;
    esac
    ;;
esac
log "Gestionnaire de paquets: $PKG_MGR"

pkg_available() {
  local pkg="$1"
  case "$PKG_MGR" in
    apt)     eval "$PKG_Q_AVAIL" -- "$pkg" ;;
    dnf|yum) $PKG_Q_AVAIL "$pkg" >/dev/null 2>&1 ;;
    pacman)  $PKG_Q_AVAIL "$pkg" >/dev/null 2>&1 ;;
    zypper)  $PKG_Q_AVAIL "$pkg" >/dev/null 2>&1 ;;
    apk)     eval "$PKG_Q_AVAIL" -- "$pkg" ;;
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

# ============================== MAJ systÃ¨me ===================================
ts_update=$(date +%s)
run "MAJ index paquets" bash -c "$PKG_UPDATE" || warn "Update partielle/Ã©chouÃ©e"
run "Upgrade systÃ¨me"  bash -c "$PKG_UPGRADE" || warn "Upgrade partielle/Ã©chouÃ©e"
log "Section MAJ terminÃ©e (durÃ©e $(_since "$ts_update"))"

# ============================== Mapping paquets ===============================
# Liste demandÃ©e : gnupg{,2} lm-sensors curl wget htop nload screen vim git ncdu bpytop rsync man avahi-daemon tree dnsutils net-tools ripgrep
PKG_GNUPG=(gnupg gnupg2)
PKG_LMSENS_DEB_RPM=(lm-sensors)
PKG_LMSENS_ARCH=(lm_sensors)
PKG_COMMON=(curl wget htop nload screen vim git ncdu rsync tree net-tools ripgrep)
PKG_MAN_DEB=(man-db manpages)
PKG_MAN_RPM=(man-db man-pages)
PKG_MAN_ARCH=(man-db man-pages)
PKG_DNS_DEB=(dnsutils)
PKG_DNS_RPM=(bind-utils)
PKG_DNS_ARCH=(bind)            # Arch fournit dig/nslookup via 'bind'
PKG_DNS_ALP=(bind-tools)
PKG_AVAHI_DEB=(avahi-daemon)
PKG_AVAHI_OTH=(avahi avahi-daemon)  # RPM/Arch/openSUSE/Alpine (selon cas)
PKG_BPY=(bpytop)
PKG_BTOP=(btop bashtop)        # fallback si bpytop indispo

log "SÃ©lection des paquets selon famille: $DIST_ID ($PKG_MGR)"
case "$PKG_MGR" in
  apt)
    install_if_exists "gnupg"        "${PKG_GNUPG[@]}"
    install_if_exists "lm-sensors"   "${PKG_LMSENS_DEB_RPM[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_MAN_DEB[@]}" "${PKG_DNS_DEB[@]}" "${PKG_AVAHI_DEB[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  dnf|yum)
    install_if_exists "gnupg"        gnupg
    install_if_exists "lm-sensors"   "${PKG_LMSENS_DEB_RPM[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}" "${PKG_DNS_RPM[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  pacman)
    install_if_exists "gnupg"        gnupg
    install_if_exists "lm-sensors"   "${PKG_LMSENS_ARCH[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_MAN_ARCH[@]}" "${PKG_DNS_ARCH[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  zypper)
    install_if_exists "gnupg"        gpg2 gnupg
    install_if_exists "lm-sensors"   "${PKG_LMSENS_DEB_RPM[@]}"
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}" "${PKG_DNS_RPM[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
  apk)
    install_if_exists "gnupg"        gnupg
    install_if_exists "lm-sensors"   lm-sensors
    install_if_exists "commun"       "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}" "${PKG_DNS_ALP[@]}" "${PKG_AVAHI_OTH[@]}"
    if pkg_available "${PKG_BPY[0]}"; then install_if_exists "monitoring" "${PKG_BPY[@]}"; else install_if_exists "monitoring" "${PKG_BTOP[@]}"; fi
    ;;
esac

# ============================== Fastfetch (repo > fallback) ====================
FASTFETCH_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh"
install_fastfetch() {
  local ts=$(date +%s)
  if pkg_available fastfetch; then
    log "fastfetch disponible dans les dÃ©pÃ´ts: installation via $PKG_MGR"
    install_if_exists "fastfetch" fastfetch
    log "fastfetch installÃ© via dÃ©pÃ´ts (durÃ©e $(_since "$ts"))"
    return 0
  fi
  warn "fastfetch non dispo dans les dÃ©pÃ´ts â fallback script externe"
  if [[ $DRYRUN -eq 1 ]]; then
    printf "[DRYRUN] bash <(curl -fsSL %s)\n" "$FASTFETCH_URL"
    return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    run "Installer fastfetch (script)" bash -c "bash <(curl -fsSL \"$FASTFETCH_URL\")"
  elif command -v wget >/dev/null 2>&1; then
    run "Installer fastfetch (script)" bash -c "bash <(wget -qO- \"$FASTFETCH_URL\")"
  else
    err "Ni curl ni wget disponibles â fastfetch non installÃ©."
    return 1
  fi
  log "fastfetch via script terminÃ© (durÃ©e $(_since "$ts"))"
}
install_fastfetch || warn "Installation fastfetch Ã©chouÃ©e (script)."

# ============================== Timezone ======================================
if command -v timedatectl >/dev/null 2>&1; then
  run "RÃ©glage timezone Europe/Paris" timedatectl set-timezone Europe/Paris || warn "Echec rÃ©glage timezone"
else
  warn "timedatectl indisponible â tentative via /etc/localtime"
  ZF="/usr/share/zoneinfo/Europe/Paris"
  [[ -f "$ZF" ]] && run "Lien /etc/localtime â Europe/Paris" ln -sf "$ZF" /etc/localtime || warn "Zoneinfo non trouvÃ©e"
  [[ -w /etc/timezone ]] && echo "Europe/Paris" >/etc/timezone || true
fi

# ============================== .bashrc perso =================================
BRC_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/.bashrc"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"
TARGET_RC="$TARGET_HOME/.bashrc"
BK="$TARGET_HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

log "Remplacement du .bashrc pour $TARGET_USER ($TARGET_HOME)"
if [[ -f "$TARGET_RC" ]]; then
  run "Backup $TARGET_RC" cp -a "$TARGET_RC" "$BK" || true
fi
if command -v curl >/dev/null 2>&1; then
  [[ $DRYRUN -eq 1 ]] && echo "[DRYRUN] curl -fsSL $BRC_URL -o $TARGET_RC" \
                      || run "TÃ©lÃ©charger .bashrc" curl -fsSL "$BRC_URL" -o "$TARGET_RC"
elif command -v wget >/dev/null 2>&1; then
  [[ $DRYRUN -eq 1 ]] && echo "[DRYRUN] wget -q $BRC_URL -O $TARGET_RC" \
                      || run "TÃ©lÃ©charger .bashrc" wget -q "$BRC_URL" -O "$TARGET_RC"
else
  warn "Ni curl ni wget pour rÃ©cupÃ©rer le .bashrc"
fi
# Permissions
if [[ $DRYRUN -eq 0 && -f "$TARGET_RC" ]]; then
  run "Chown .bashrc" chown "$TARGET_USER":"$TARGET_USER" "$TARGET_RC" || true
fi
# Optionnel: copie pour /etc/skel
if [[ -d /etc/skel && -f "$TARGET_RC" ]]; then
  run "Copie .bashrc vers /etc/skel" cp -f "$TARGET_RC" /etc/skel/.bashrc || true
fi
# Recharge si session bash interactive
if [[ -n "${PS1:-}" && -n "${BASH_VERSION:-}" && $DRYRUN -eq 0 && "$TARGET_HOME" == "$HOME" ]]; then
  # shellcheck disable=SC1090
  run "Recharger ~/.bashrc" bash -lc "source \"$HOME/.bashrc\"" || true
fi

# ============================== Avahi (enable si prÃ©sent) =====================
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q '^avahi-daemon\.service'; then
    run "Activer avahi-daemon" systemctl enable --now avahi-daemon || warn "Impossible d'activer avahi-daemon"
  else
    debug "Service avahi-daemon non prÃ©sent â ignorÃ©."
  fi
else
  debug "systemctl indisponible â probablement sans systemd."
fi

# ============================== RÃ©capitulatif =================================
echo
echo -e "${BOLD}============================= RÃCAPITULATIF =============================${C0}"
echo "  - Journal complet : $LOG_FILE"
echo "  - Distro          : ID=$DIST_ID | LIKE=$DIST_LIKE | PKG_MGR=$PKG_MGR"
echo "  - DEBUG           : $DEBUG | DRYRUN=$DRYRUN | QUIET=$QUIET"
echo "  - DurÃ©e totale    : $(_since "$_start_ts")"
echo -e "${BOLD}=========================================================================${C0}"

log "Configuration terminÃ©e."
# Fin
