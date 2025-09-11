#!/usr/bin/env bash
# ==============================================================================
# new.sh ÃÂ¢ bootstrap multi-distros (console propre + logs dÃÃÂ©taillÃÃÂ©s + rÃÃÂ©cap par catÃÃÂ©gories)
#
# USAGE:
#   sudo ./new.sh [OPTIONS]
#
# OPTIONS:
#   --debug      Active le mode debug (bash -x) et les messages [DEBUG]
#   --dry-run    N'exÃÃÂ©cute pas les commandes (simule) ÃÂ¢ tout est logguÃÃÂ©, console propre
#   --quiet|-q   RÃÃÂ©duit la verbositÃÃÂ© console (n'affiche que WARN/ERROR, le log reste complet)
#
# COMPORTEMENT:
#   - DÃÃÂ©tecte la distribution / gestionnaire de paquets
#   - MAJ index + upgrade systÃÃÂ¨me
#   - Installe des paquets communs (curl, wget, htop, ÃÂ¢ÃÂ¦) + groupes spÃÃÂ©cifiques (gnupg, lm-sensors, dnsutilsÃÂ¢ÃÂ¦)
#   - Installe fastfetch depuis les dÃÃÂ©pÃÃÂ´ts si dispo, sinon via script externe
#   - Remplace le ~/.bashrc (sans rechargement)
#   - RÃÃÂ¨gle la timezone sur Europe/Paris
#   - Active avahi-daemon si prÃÃÂ©sent
#   - Console : statut dÃÂ¢ÃÃÂ©tapes uniquement ; Logs : dÃÃÂ©tails complets et lisibles (/var/log)
# ==============================================================================

set -euo pipefail

# ============================== CLI Flags ======================================
DEBUG=0; DRYRUN=0; QUIET=0
for arg in "$@"; do
  case "${arg:-}" in
    --debug) DEBUG=1 ;;
    --dry-run|--dryrun) DRYRUN=1 ;;
    --quiet|-q) QUIET=1 ;;
    *) ;;
  esac
done
[[ $DEBUG -eq 1 ]] && set -x

# ============================== Log setup ======================================
_start_ts=$(date +%s)
LOG_TS="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/new-basics-${LOG_TS}.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Couleurs console
BOLD="\e[1m"; DIM="\e[2m"; RED="\e[31m"; YEL="\e[33m"; GRN="\e[32m"; BLU="\e[34m"; C0="\e[0m"
_now()   { date "+%Y-%m-%d %H:%M:%S%z"; }
_since() { local s=$1; printf "%ds" $(( $(date +%s) - s )); }
_strip() { sed -E 's/\r//g; s/\x1B\[[0-9;]*[A-Za-z]//g'; }

_logfile()  { printf "%s\n" "$*" | _strip >> "$LOG_FILE"; }
log()       { [[ $QUIET -eq 0 ]] && printf "%b[%s] [INFO ]%b %s\n"  "$GRN" "$(_now)" "$C0" "$*"; _logfile "[$(_now)] [INFO ] $*"; }
warn()      { printf "%b[%s] [WARN ]%b %s\n"  "$YEL" "$(_now)" "$C0" "$*"; _logfile "[$(_now)] [WARN ] $*"; }
err()       { printf "%b[%s] [ERROR]%b %s\n"  "$RED" "$(_now)" "$C0" "$*"; _logfile "[$(_now)] [ERROR] $*"; }
debug()     { [[ $DEBUG -eq 1 ]] && { printf "%b[%s] [DEBUG]%b %s\n" "$BLU" "$(_now)" "$C0" "$*"; _logfile "[$(_now)] [DEBUG] $*"; } || true; }

# ============================== Steps reporting ================================
declare -a REPORT_OK=() REPORT_FAIL=() REPORT_SKIP=()

_step_log_block() {
  # $1 desc, $2 status, $3 dur_secs, $4 cmd, $5 tmpfile (stdout+stderr)
  {
    echo
    echo "============================== STEP ================================="
    echo "Time     : $(_now)"
    echo "Step     : $1"
    echo "Status   : $2"
    echo "Duration : ${3}s"
    echo "Command  : $4"
    echo "------------------------------ OUTPUT -------------------------------"
    [[ -f "$5" ]] && _strip < "$5" || echo "(no output)"
    echo "=========================== END OF STEP ============================="
  } >> "$LOG_FILE"
}

run() {
  local desc="$1"; shift
  local ts=$(date +%s)
  local cmd_str="$*"
  local tmp_out; tmp_out="$(mktemp)"
  if [[ $DRYRUN -eq 1 ]]; then
    printf "%b[%s] [EXEC ]%b %s\n" "$BOLD" "$(_now)" "$C0" "$desc"
    log "OK: (dry-run) $desc"
    REPORT_SKIP+=("$desc")
    _step_log_block "$desc" "SKIPPED (dry-run)" "0" "$cmd_str" /dev/null
    return 100  # code spÃÃÂ©cial "skip"
  fi
  printf "%b[%s] [EXEC ]%b %s\n" "$BOLD" "$(_now)" "$C0" "$desc"
  if "$@" >"$tmp_out" 2>&1; then
    local d=$(_since "$ts"); log "OK: $desc (durÃÃÂ©e $d)"
    REPORT_OK+=("$desc")
    _step_log_block "$desc" "OK" "${d%s}" "$cmd_str" "$tmp_out"
    rm -f "$tmp_out"
    return 0
  else
    local rc=$?; local d=$(_since "$ts")
    err "ECHEC: $desc (durÃÃÂ©e $d, rc=$rc)"
    REPORT_FAIL+=("$desc (rc=$rc)")
    _step_log_block "$desc" "FAIL (rc=$rc)" "${d%s}" "$cmd_str" "$tmp_out"
    rm -f "$tmp_out"
    return $rc
  fi
}

# ============================== CatÃÃÂ©gories =====================================
# Status: 0=UNKNOWN, 1=OK, 2=SKIP, 3=FAIL (plus grand = pire)
declare -A CAT
_set_cat() {
  local key="$1" ; local val="$2"
  local cur="${CAT[$key]:-0}"
  (( val > cur )) && CAT["$key"]="$val" || true
}
_status_str() {
  case "$1" in
    1) printf "%bÃÂ¢ OK%b"   "$GRN" "$C0" ;;
    2) printf "%bÃÂ¢ÃÂ­ SKIP%b" "$YEL" "$C0" ;;
    3) printf "%bÃÂ¢ FAIL%b" "$RED" "$C0" ;;
    *) printf "-" ;;
  esac
}

# ============================== Root & contexte ================================
if [[ $EUID -ne 0 ]]; then
  warn "Ce script doit ÃÃÂªtre exÃÃÂ©cutÃÃÂ© en root. Tentative avec sudoÃÂ¢ÃÂ¦"
  exec sudo -E "$0" "$@"
fi

trap 'err "Interruption ou erreur (code=$?) ÃÂ¢ voir '"$LOG_FILE"'"; exit 1' INT TERM

log "Journal complet: $LOG_FILE"
log "HÃÃÂ´te: $(hostname) | Kernel: $(uname -r) | Arch: $(uname -m)"
log "Shell: $SHELL | DEBUG=$DEBUG | DRYRUN=$DRYRUN | QUIET=$QUIET"

# ============================== DÃÃÂ©tection distro ===============================
DIST_ID=""; DIST_LIKE=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DIST_ID="${ID:-unknown}"
  DIST_LIKE="${ID_LIKE:-}"
else
  err "/etc/os-release introuvable ÃÂ¢ abandon."
  exit 1
fi
log "Distribution dÃÃÂ©tectÃÃÂ©e: ID=${DIST_ID} | ID_LIKE=${DIST_LIKE}"

# ============================== Gestionnaire paquets ===========================
PKG_MGR="" PKG_UPDATE="" PKG_UPGRADE="" PKG_INSTALL=""
case "$DIST_ID" in
  debian|ubuntu|linuxmint|pop|kali)
    export DEBIAN_FRONTEND=noninteractive
    PKG_MGR="apt"
    PKG_UPDATE="apt-get update -y"
    PKG_UPGRADE="apt-get -y full-upgrade --autoremove --purge"
    PKG_INSTALL="apt-get install -y --no-install-recommends -o Dpkg::Use-Pty=0"
    ;;
  fedora)
    PKG_MGR="dnf"
    PKG_UPDATE="dnf -y makecache"
    PKG_UPGRADE="dnf -y upgrade --refresh"
    PKG_INSTALL="dnf -y install"
    ;;
  rhel|centos|rocky|almalinux)
    if command -v dnf >/dev/null 2>&1; then
      PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"
    else
      PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"
    fi
    ;;
  arch|artix|manjaro)
    PKG_MGR="pacman"
    PKG_UPDATE="pacman -Sy --noconfirm"
    PKG_UPGRADE="pacman -Syu --noconfirm"
    PKG_INSTALL="pacman -S --noconfirm --needed"
    ;;
  opensuse*|sles)
    PKG_MGR="zypper"
    PKG_UPDATE="zypper --non-interactive refresh"
    PKG_UPGRADE="zypper --non-interactive update"
    PKG_INSTALL="zypper --non-interactive install --no-confirm"
    ;;
  alpine)
    PKG_MGR="apk"
    PKG_UPDATE="apk update"
    PKG_UPGRADE="apk upgrade"
    PKG_INSTALL="apk add --no-cache"
    ;;
  *)
    case "$DIST_LIKE" in
      *debian*) DIST_ID="debian"; export DEBIAN_FRONTEND=noninteractive
        PKG_MGR="apt"; PKG_UPDATE="apt-get update -y"; PKG_UPGRADE="apt-get -y full-upgrade --autoremove --purge"; PKG_INSTALL="apt-get install -y --no-install-recommends -o Dpkg::Use-Pty=0" ;;
      *rhel*|*fedora*)
        if command -v dnf >/dev/null 2>&1; then
          PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"
        else
          PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"
        fi ;;
      *) err "Distribution non gÃÃÂ©rÃÃÂ©e (ID=$DIST_ID ID_LIKE=$DIST_LIKE)"; exit 1 ;;
    esac
    ;;
esac
log "Gestionnaire de paquets: $PKG_MGR"
_set_cat "detect_pm" 1  # OK

# ============================== Helpers paquets ================================
pkg_available() {
  local pkg="$1"
  case "$PKG_MGR" in
    apt)
      local cand
      cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')"
      [[ -n "${cand:-}" && "${cand:-}" != "(none)" ]]
      ;;
    dnf|yum) $PKG_MGR -q info "$pkg" >/dev/null 2>&1 ;;
    pacman)  pacman -Si "$pkg" >/dev/null 2>&1 ;;
    zypper)  zypper info "$pkg" >/dev/null 2>&1 ;;
    apk)     apk info -e "$pkg" >/dev/null 2>&1 || apk search -x "$pkg" >/dev/null 2>&1 ;;
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
    if [[ $DRYRUN -eq 0 ]]; then
      # shellcheck disable=SC2086
      if run "Installer ($group)" $PKG_INSTALL ${ok[*]}; then
        return 0
      else
        return 1
      fi
    else
      run "Installer ($group) ÃÂ¢ dry-run" echo "$PKG_INSTALL ${ok[*]}" >/dev/null
      return 100
    fi
  else
    warn "Aucun paquet installable pour le lot: $group"
    return 100
  fi
}

# ============================== MAJ systÃÃÂ¨me ===================================
rc=$(run "MAJ index paquets" bash -lc "$PKG_UPDATE");  (( rc==0 )) && _set_cat "update_index" 1 || _set_cat "update_index" 3
rc=$(run "Upgrade systÃÃÂ¨me"    bash -lc "$PKG_UPGRADE"); (( rc==0 )) && _set_cat "upgrade_system" 1 || _set_cat "upgrade_system" 3

# ============================== Mapping paquets ===============================
PKG_GNUPG=(gnupg gnupg2)
PKG_LMSENS_DEB_RPM=(lm-sensors)
PKG_LMSENS_ARCH=(lm_sensors)
PKG_COMMON=(curl wget htop nload screen vim git ncdu rsync tree net-tools ripgrep)
PKG_MAN_DEB=(man-db manpages)
PKG_MAN_RPM=(man-db man-pages)
PKG_MAN_ARCH=(man-db man-pages)
PKG_DNS_DEB=(dnsutils)
PKG_DNS_RPM=(bind-utils)
PKG_DNS_ARCH=(bind)       # dig/nslookup
PKG_DNS_ALP=(bind-tools)
PKG_AVAHI_DEB=(avahi-daemon)
PKG_AVAHI_OTH=(avahi avahi-daemon)
PKG_BPY=(bpytop)
PKG_BTOP=(btop bashtop)

log "SÃÃÂ©lection des paquets selon famille: $DIST_ID ($PKG_MGR)"
# Paquets communs (mÃÃÂªme nom multi-distros)
case "$PKG_MGR" in
  apt)    rc=$(install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_DEB[@]}" "${PKG_DNS_DEB[@]}" "${PKG_AVAHI_DEB[@]}") ;;
  dnf|yum)rc=$(install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}" "${PKG_DNS_RPM[@]}" "${PKG_AVAHI_OTH[@]}") ;;
  pacman) rc=$(install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_ARCH[@]}" "${PKG_DNS_ARCH[@]}" "${PKG_AVAHI_OTH[@]}") ;;
  zypper) rc=$(install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}"  "${PKG_DNS_RPM[@]}"  "${PKG_AVAHI_OTH[@]}") ;;
  apk)    rc=$(install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}"  "${PKG_DNS_ALP[@]}"  "${PKG_AVAHI_OTH[@]}") ;;
esac
case "$rc" in
  0)   _set_cat "install_common" 1 ;;
  100) _set_cat "install_common" 2 ;;
  *)   _set_cat "install_common" 3 ;;
esac

# Groupes spÃÃÂ©cifiques
install_if_exists "gnupg"      "${PKG_GNUPG[@]}"      >/dev/null 2>&1 || true
if [[ "$PKG_MGR" == "pacman" ]]; then
  install_if_exists "lm-sensors" "${PKG_LMSENS_ARCH[@]}" >/dev/null 2>&1 || true
else
  install_if_exists "lm-sensors" "${PKG_LMSENS_DEB_RPM[@]}" >/dev/null 2>&1 || true
fi
if pkg_available "${PKG_BPY[0]}"; then
  install_if_exists "monitoring" "${PKG_BPY[@]}"  >/dev/null 2>&1 || true
else
  install_if_exists "monitoring" "${PKG_BTOP[@]}" >/dev/null 2>&1 || true
fi

# ============================== Fastfetch (repo > fallback) ====================
FASTFETCH_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh"
install_fastfetch() {
  if pkg_available fastfetch; then
    run "Installer (fastfetch via dÃÃÂ©pÃÃÂ´ts)" $PKG_INSTALL fastfetch
    return $?
  fi
  warn "fastfetch non dispo dans les dÃÃÂ©pÃÃÂ´ts ÃÂ¢ fallback script externe"
  if [[ $DRYRUN -eq 1 ]]; then
    run "Installer (fastfetch via script) ÃÂ¢ dry-run" echo "bash <(curl -fsSL $FASTFETCH_URL)" >/dev/null
    return 100
  fi
  if command -v curl >/dev/null 2>&1; then
    run "Installer (fastfetch via script)" bash -lc "bash <(curl -fsSL \"$FASTFETCH_URL\")"
    return $?
  elif command -v wget >/dev/null 2>&1; then
    run "Installer (fastfetch via script)" bash -lc "bash <(wget -qO- \"$FASTFETCH_URL\")"
    return $?
  else
    err "Ni curl ni wget disponibles ÃÂ¢ fastfetch non installÃÃÂ©."
    return 1
  fi
}
rc=$(install_fastfetch)
case "$rc" in
  0)   _set_cat "fastfetch" 1 ;;
  100) _set_cat "fastfetch" 2 ;;
  *)   _set_cat "fastfetch" 3 ;;
esac

# ============================== Timezone ======================================
if command -v timedatectl >/dev/null 2>&1; then
  rc=$(run "RÃÃÂ©glage timezone Europe/Paris" timedatectl set-timezone Europe/Paris); 
else
  warn "timedatectl indisponible ÃÂ¢ tentative via /etc/localtime"
  ZF="/usr/share/zoneinfo/Europe/Paris"
  if [[ -f "$ZF" ]]; then
    rc=$(run "Lien /etc/localtime ÃÂ¢ Europe/Paris" ln -sf "$ZF" /etc/localtime || true; echo)
    [[ -w /etc/timezone ]] && echo "Europe/Paris" >/etc/timezone || true
  else
    rc=1
    err "Zoneinfo non trouvÃÃÂ©e"
  fi
fi
(( rc==0 || rc==100 )) && _set_cat "timezone" $(( rc==100 ? 2 : 1 )) || _set_cat "timezone" 3

# ============================== .bashrc (sans reload) ==========================
BRC_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/.bashrc"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"
TARGET_RC="$TARGET_HOME/.bashrc"
BK="$TARGET_HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

BRC_RC=0
log "Remplacement du .bashrc pour $TARGET_USER ($TARGET_HOME)"
[[ -f "$TARGET_RC" ]] && { run "Backup $TARGET_RC" cp -a "$TARGET_RC" "$BK" || BRC_RC=1; } || true
if command -v curl >/dev/null 2>&1; then
  if ! run "TÃÃÂ©lÃÃÂ©charger .bashrc" curl -fsSL "$BRC_URL" -o "$TARGET_RC"; then BRC_RC=1; fi
elif command -v wget >/dev/null 2>&1; then
  if ! run "TÃÃÂ©lÃÃÂ©charger .bashrc" wget -q "$BRC_URL" -O "$TARGET_RC"; then BRC_RC=1; fi
else
  warn "Ni curl ni wget pour rÃÃÂ©cupÃÃÂ©rer le .bashrc"; BRC_RC=1
fi
[[ -f "$TARGET_RC" ]] && { run "Chown .bashrc" chown "$TARGET_USER":"$TARGET_USER" "$TARGET_RC" || BRC_RC=1; } || true
if [[ -d /etc/skel && -f "$TARGET_RC" ]]; then
  run "Copie .bashrc vers /etc/skel" cp -f "$TARGET_RC" /etc/skel/.bashrc || BRC_RC=1
fi
(( BRC_RC==0 )) && _set_cat "bashrc" 1 || _set_cat "bashrc" 3
# NOTE: rechargement du .bashrc volontairement dÃÃÂ©sactivÃÃÂ©

# ============================== Avahi (enable si prÃÃÂ©sent) =====================
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q '^avahi-daemon\.service'; then
    rc=$(run "Activer avahi-daemon" systemctl enable --now avahi-daemon)
    (( rc==0 || rc==100 )) && _set_cat "avahi" $(( rc==100 ? 2 : 1 )) || _set_cat "avahi" 3
  else
    debug "Service avahi-daemon non prÃÃÂ©sent ÃÂ¢ ignorÃÃÂ©."
    _set_cat "avahi" 2
  fi
else
  debug "systemctl indisponible ÃÂ¢ probablement sans systemd."
  _set_cat "avahi" 2
fi

# ============================== RÃÃÂ©capitulatif (catÃÃÂ©gories) =====================
echo
echo -e "${BOLD}============================= RÃCAPITULATIF =============================${C0}"
echo "  Journal : $LOG_FILE"
echo "  Distro  : ID=$DIST_ID | LIKE=$DIST_LIKE | PM=$PKG_MGR"
echo "  DurÃÃÂ©e   : $(_since "$_start_ts")"
echo
echo -e "${BOLD}CatÃÃÂ©gories:${C0}"
printf "  %-28s : %s\n" "DÃÃÂ©tection gestionnaire"       "$(_status_str "${CAT[detect_pm]:-0}")"
printf "  %-28s : %s\n" "MAJ index paquets"           "$(_status_str "${CAT[update_index]:-0}")"
printf "  %-28s : %s\n" "Upgrade systÃÃÂ¨me"              "$(_status_str "${CAT[upgrade_system]:-0}")"
printf "  %-28s : %s\n" "Paquets communs"              "$(_status_str "${CAT[install_common]:-0}")"
printf "  %-28s : %s\n" "Fastfetch"                     "$(_status_str "${CAT[fastfetch]:-0}")"
printf "  %-28s : %s\n" "Timezone (Europe/Paris)"       "$(_status_str "${CAT[timezone]:-0}")"
printf "  %-28s : %s\n" ".bashrc (dÃÃÂ©ploiement)"         "$(_status_str "${CAT[bashrc]:-0}")"
printf "  %-28s : %s\n" "Avahi (enable si prÃÃÂ©sent)"     "$(_status_str "${CAT[avahi]:-0}")"
echo
echo -e "${BOLD}DÃÃÂ©tail ÃÃÂ©tapes:${C0}"
echo "  Ãtapes OK   : ${#REPORT_OK[@]}"
for s in "${REPORT_OK[@]}";  do echo "    ${GRN}ÃÂ¢${C0} $s"; done
echo
echo "  Ãtapes FAIL : ${#REPORT_FAIL[@]}"
for s in "${REPORT_FAIL[@]}"; do echo "    ${RED}ÃÂ¢${C0} $s"; done
if [[ $DRYRUN -eq 1 || ${#REPORT_SKIP[@]} -gt 0 ]]; then
  echo
  echo "  Ãtapes SKIP : ${#REPORT_SKIP[@]}"
  for s in "${REPORT_SKIP[@]}"; do echo "    ${YEL}ÃÂ¢ÃÂ­${C0} $s"; done
fi
echo -e "${BOLD}=========================================================================${C0}"

log "Configuration terminÃÃÂ©e."
# Fin
