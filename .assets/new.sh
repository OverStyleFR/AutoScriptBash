#!/usr/bin/env bash
# ==============================================================================
# new.sh — bootstrap multi-distros (console propre + logs détaillés + récap par catégories)
#
# USAGE:
#   sudo ./new.sh [OPTIONS]
#
# OPTIONS:
#   --debug      Active le mode debug (bash -x) et les messages [DEBUG]
#   --dry-run    N'exécute pas les commandes (simule) — tout est loggué, console propre
#   --quiet|-q   Réduit la verbosité console (n'affiche que WARN/ERROR, le log reste complet)
#
# COMPORTEMENT:
#   - Détecte la distribution / gestionnaire de paquets
#   - MAJ index + upgrade système
#   - Installe des paquets communs + groupes spécifiques (gnupg, lm-sensors…)
#   - fastfetch via dépôts si dispo, sinon script externe
#   - Remplace ~/.bashrc (sans rechargement)
#   - Timezone Europe/Paris
#   - Active avahi-daemon si présent
#   - Console : statut d’étapes uniquement ; Logs : détails complets et lisibles (/var/log)
=============================================================================

set -euo pipefail
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

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
mkdir -p "$LOG_DIR"; : > "$LOG_FILE"

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
    return 100
  fi
  printf "%b[%s] [EXEC ]%b %s\n" "$BOLD" "$(_now)" "$C0" "$desc"
  if "$@" >"$tmp_out" 2>&1; then
    local d=$(_since "$ts"); log "OK: $desc (durée $d)"
    REPORT_OK+=("$desc")
    _step_log_block "$desc" "OK" "${d%s}" "$cmd_str" "$tmp_out"
    rm -f "$tmp_out"; return 0
  else
    local rc=$?; local d=$(_since "$ts")
    err "ECHEC: $desc (durée $d, rc=$rc)"
    REPORT_FAIL+=("$desc (rc=$rc)")
    _step_log_block "$desc" "FAIL (rc=$rc)" "${d%s}" "$cmd_str" "$tmp_out"
    rm -f "$tmp_out"; return $rc
  fi
}

# --- Wrappers sûrs (ne quittent pas sous set -e) ---
safe_run() { set +e; run "$@"; local rc=$?; set -e; return $rc; }
safe_call() { set +e; "$@"; local rc=$?; set -e; return $rc; }

# ============================== Catégories =====================================
# 0=UNKNOWN, 1=OK, 2=SKIP, 3=FAIL
declare -A CAT
_set_cat() {
  local k v cur
  k="$1"; v="${2:-0}"
  cur="${CAT[$k]:-0}"
  [[ "$v" -gt "$cur" ]] && CAT["$k"]="$v" || true
}
print_cat_line() {
  local label="$1" code="${2:-0}" val="-"
  case "$code" in
    1) val="${GRN}✓ OK${C0}" ;;
    2) val="${YEL}⏭ SKIP${C0}" ;;
    3) val="${RED}✗ FAIL${C0}" ;;
  esac
  printf "  %-28s : %b\n" "$label" "$val"
}

# ============================== Root & contexte ================================
if [[ $EUID -ne 0 ]]; then
  warn "Ce script doit ÃÃÃÂªtre exÃÃÃÂ©cutÃÃÃÂ© en root. Tentative avec sudoÃÃÂ¢ÃÃÂ¦"
  exec sudo -E "$0" "$@"
fi
trap 'err "Interruption ou erreur (code=$?) — voir '"$LOG_FILE"'"; exit 1' INT TERM

log "Journal complet: $LOG_FILE"
log "HÃÃÃÂ´te: $(hostname) | Kernel: $(uname -r) | Arch: $(uname -m)"
log "Shell: $SHELL | DEBUG=$DEBUG | DRYRUN=$DRYRUN | QUIET=$QUIET"

# ============================== DÃÃÃÂ©tection distro ===============================
DIST_ID=""; DIST_LIKE=""
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DIST_ID="${ID:-unknown}"; DIST_LIKE="${ID_LIKE:-}"
else
  err "/etc/os-release introuvable — abandon."; exit 1
fi
log "Distribution dÃÃÃÂ©tectÃÃÃÂ©e: ID=${DIST_ID} | ID_LIKE=${DIST_LIKE}"

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
    PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install" ;;
  rhel|centos|rocky|almalinux)
    if command -v dnf >/dev/null 2>&1; then
      PKG_MGR="dnf"; PKG_UPDATE="dnf -y makecache"; PKG_UPGRADE="dnf -y upgrade --refresh"; PKG_INSTALL="dnf -y install"
    else
      PKG_MGR="yum"; PKG_UPDATE="yum -y makecache"; PKG_UPGRADE="yum -y update"; PKG_INSTALL="yum -y install"
    fi ;;
  arch|artix|manjaro)
    PKG_MGR="pacman"; PKG_UPDATE="pacman -Sy --noconfirm"; PKG_UPGRADE="pacman -Syu --noconfirm"; PKG_INSTALL="pacman -S --noconfirm --needed" ;;
  opensuse*|sles)
    PKG_MGR="zypper"; PKG_UPDATE="zypper --non-interactive refresh"; PKG_UPGRADE="zypper --non-interactive update"; PKG_INSTALL="zypper --non-interactive install --no-confirm" ;;
  alpine)
    PKG_MGR="apk"; PKG_UPDATE="apk update"; PKG_UPGRADE="apk upgrade"; PKG_INSTALL="apk add --no-cache" ;;
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
      *) err "Distribution non gérée (ID=$DIST_ID ID_LIKE=$DIST_LIKE)"; exit 1 ;;
    esac
    ;;
esac
log "Gestionnaire de paquets: $PKG_MGR"; _set_cat "detect_pm" 1

# ============================== Helpers paquets ================================
pkg_available() {
  local pkg="$1"
  case "$PKG_MGR" in
    apt)   local cand; cand="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')"; [[ -n "${cand:-}" && "${cand:-}" != "(none)" ]] ;;
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
      run "Installer ($group)" $PKG_INSTALL ${ok[*]}; return $?
    else
      run "Installer ($group) — dry-run" echo "$PKG_INSTALL ${ok[*]}" >/dev/null; return 100
    fi
  else
    warn "Aucun paquet installable pour le lot: $group"; return 100
  fi
}

# ============================== MAJ système ===================================
safe_run "MAJ index paquets" bash -lc "$PKG_UPDATE"; rc=$?
case "$rc" in 0) _set_cat "update_index" 1 ;; 100) _set_cat "update_index" 2 ;; *) _set_cat "update_index" 3 ;; esac

safe_run "Upgrade système"  bash -lc "$PKG_UPGRADE"; rc=$?
case "$rc" in 0) _set_cat "upgrade_system" 1 ;; 100) _set_cat "upgrade_system" 2 ;; *) _set_cat "upgrade_system" 3 ;; esac

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
PKG_DNS_ARCH=(bind)
PKG_DNS_ALP=(bind-tools)
PKG_AVAHI_DEB=(avahi-daemon)
PKG_AVAHI_OTH=(avahi avahi-daemon)
PKG_BPY=(bpytop)
PKG_BTOP=(btop bashtop)

log "Sélection des paquets selon famille: $DIST_ID ($PKG_MGR)"
case "$PKG_MGR" in
  apt)    safe_call install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_DEB[@]}"  "${PKG_DNS_DEB[@]}"  "${PKG_AVAHI_DEB[@]}"; rc=$? ;;
  dnf|yum)safe_call install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}"  "${PKG_DNS_RPM[@]}"  "${PKG_AVAHI_OTH[@]}"; rc=$? ;;
  pacman) safe_call install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_ARCH[@]}" "${PKG_DNS_ARCH[@]}" "${PKG_AVAHI_OTH[@]}"; rc=$? ;;
  zypper) safe_call install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}"  "${PKG_DNS_RPM[@]}"  "${PKG_AVAHI_OTH[@]}"; rc=$? ;;
  apk)    safe_call install_if_exists "commun" "${PKG_COMMON[@]}" "${PKG_MAN_RPM[@]}"  "${PKG_DNS_ALP[@]}"  "${PKG_AVAHI_OTH[@]}"; rc=$? ;;
esac
case "$rc" in 0) _set_cat "install_common" 1 ;; 100) _set_cat "install_common" 2 ;; *) _set_cat "install_common" 3 ;; esac

# Spécifiques (best effort)
if [[ "$PKG_MGR" == "pacman" ]]; then
  safe_call install_if_exists "lm-sensors" "${PKG_LMSENS_ARCH[@]}"   >/dev/null 2>&1 || true
else
  safe_call install_if_exists "lm-sensors" "${PKG_LMSENS_DEB_RPM[@]}" >/dev/null 2>&1 || true
fi
safe_call install_if_exists "gnupg"      "${PKG_GNUPG[@]}"            >/dev/null 2>&1 || true
if pkg_available "${PKG_BPY[0]}"; then
  safe_call install_if_exists "monitoring" "${PKG_BPY[@]}"            >/dev/null 2>&1 || true
else
  safe_call install_if_exists "monitoring" "${PKG_BTOP[@]}"           >/dev/null 2>&1 || true
fi

# ============================== Fastfetch ======================================
FASTFETCH_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/fastfetch-install.sh"
install_fastfetch() {
  if pkg_available fastfetch; then
    run "Installer (fastfetch via dépôts)" $PKG_INSTALL fastfetch; return $?
  fi
  warn "fastfetch non dispo dans les dépôts — fallback script externe"
  if [[ $DRYRUN -eq 1 ]]; then
    run "Installer (fastfetch via script) — dry-run" echo "bash <(curl -fsSL $FASTFETCH_URL)" >/dev/null; return 100
  fi
  if command -v curl >/dev/null 2>&1; then
    run "Installer (fastfetch via script)" bash -lc "bash <(curl -fsSL \"$FASTFETCH_URL\")"; return $?
  elif command -v wget >/dev/null 2>&1; then
    run "Installer (fastfetch via script)" bash -lc "bash <(wget -qO- \"$FASTFETCH_URL\")"; return $?
  else
    err "Ni curl ni wget disponibles — fastfetch non installé."; return 1
  fi
}
safe_call install_fastfetch; rc=$?
case "$rc" in 0) _set_cat "fastfetch" 1 ;; 100) _set_cat "fastfetch" 2 ;; *) _set_cat "fastfetch" 3 ;; esac

# ============================== Timezone ======================================
if command -v timedatectl >/dev/null 2>&1; then
  safe_run "Réglage timezone Europe/Paris" timedatectl set-timezone Europe/Paris; rc=$?
else
  warn "timedatectl indisponible — tentative via /etc/localtime"
  ZF="/usr/share/zoneinfo/Europe/Paris"
  if [[ -f "$ZF" ]]; then
    safe_run "Lien /etc/localtime → Europe/Paris" ln -sf "$ZF" /etc/localtime; rc=$?
    [[ -w /etc/timezone ]] && echo "Europe/Paris" >/etc/timezone || true
  else
    rc=1; err "Zoneinfo non trouvée"
  fi
fi
case "$rc" in 0) _set_cat "timezone" 1 ;; 100) _set_cat "timezone" 2 ;; *) _set_cat "timezone" 3 ;; esac

# ============================== .bashrc (sans reload) ==========================
BRC_URL="https://raw.githubusercontent.com/OverStyleFR/AutoScriptBash/main/.assets/.bashrc"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"
TARGET_RC="$TARGET_HOME/.bashrc"
BK="$TARGET_HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"

BRC_RC=0
log "Remplacement du .bashrc pour $TARGET_USER ($TARGET_HOME)"
[[ -f "$TARGET_RC" ]] && { safe_run "Backup $TARGET_RC" cp -a "$TARGET_RC" "$BK" || BRC_RC=1; } || true
if command -v curl >/dev/null 2>&1; then
  safe_run "Télécharger .bashrc" curl -fsSL "$BRC_URL" -o "$TARGET_RC" || BRC_RC=1
elif command -v wget >/dev/null 2>&1; then
  safe_run "Télécharger .bashrc" wget -q "$BRC_URL" -O "$TARGET_RC" || BRC_RC=1
else
  warn "Ni curl ni wget pour récupérer le .bashrc"; BRC_RC=1
fi
[[ -f "$TARGET_RC" ]] && safe_run "Chown .bashrc" chown "$TARGET_USER":"$TARGET_USER" "$TARGET_RC" || true
if [[ -d /etc/skel && -f "$TARGET_RC" ]]; then
  safe_run "Copie .bashrc vers /etc/skel" cp -f "$TARGET_RC" /etc/skel/.bashrc || BRC_RC=1
fi
if [[ "$BRC_RC" -eq 0 ]]; then _set_cat "bashrc" 1; else _set_cat "bashrc" 3; fi

# ============================== Avahi (enable si présent) =====================
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q '^avahi-daemon\.service'; then
    safe_run "Activer avahi-daemon" systemctl enable --now avahi-daemon; rc=$?
    case "$rc" in 0) _set_cat "avahi" 1 ;; 100) _set_cat "avahi" 2 ;; *) _set_cat "avahi" 3 ;; esac
  else
    debug "Service avahi-daemon non présent — ignoré."; _set_cat "avahi" 2
  fi
else
  debug "systemctl indisponible — probablement sans systemd."; _set_cat "avahi" 2
fi

# ============================== Récapitulatif (catégories) =====================
echo
printf "%b============================= RÉCAPITULATIF =============================%b\n" "$BOLD" "$C0"
echo "  Journal : $LOG_FILE"
echo "  Distro  : ID=$DIST_ID | LIKE=$DIST_LIKE | PM=$PKG_MGR"
echo "  Durée   : $(_since "$_start_ts")"
echo
echo -e "${BOLD}Catégories:${C0}"
print_cat_line "Détection gestionnaire"     "${CAT[detect_pm]:-0}"
print_cat_line "MAJ index paquets"          "${CAT[update_index]:-0}"
print_cat_line "Upgrade système"            "${CAT[upgrade_system]:-0}"
print_cat_line "Paquets communs"            "${CAT[install_common]:-0}"
print_cat_line "Fastfetch"                   "${CAT[fastfetch]:-0}"
print_cat_line "Timezone (Europe/Paris)"     "${CAT[timezone]:-0}"
print_cat_line ".bashrc (déploiement)"       "${CAT[bashrc]:-0}"
print_cat_line "Avahi (enable si présent)"   "${CAT[avahi]:-0}"
echo
echo -e "${BOLD}Détail étapes:${C0}"
echo "  Étapes OK   : ${#REPORT_OK[@]}"
for s in "${REPORT_OK[@]}";  do printf "    %b✓%b %s\n" "$GRN" "$C0" "$s"; done
echo
echo "  Étapes FAIL : ${#REPORT_FAIL[@]}"
for s in "${REPORT_FAIL[@]}"; do printf "    %b✗%b %s\n" "$RED" "$C0" "$s"; done
if [[ $DRYRUN -eq 1 || ${#REPORT_SKIP[@]} -gt 0 ]]; then
  echo
  echo "  Étapes SKIP : ${#REPORT_SKIP[@]}"
  for s in "${REPORT_SKIP[@]}"; do printf "    %b⏭%b %s\n" "$YEL" "$C0" "$s"; done
fi
printf "%b=========================================================================%b\n" "$BOLD" "$C0"

log "Configuration terminée."
# Fin
