#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034  # Die Konstanten nutzen die einlesenden Skripte.
# shellcheck disable=SC1091  # /etc/os-release liegt erst auf dem Zielgeraet vor.
# MAXIMUS_T2_INSTALLER_V4 - gemeinsame Funktionen
# Diese Datei wird von allen Skripten eingelesen. Sie startet nichts selbst.

# ---------------------------------------------------------------------------
# Rueckgabecodes. Jeder Code hat genau eine Bedeutung.
# ---------------------------------------------------------------------------
readonly RC_OK=0              # Erfolg
readonly RC_USAGE=2           # Falscher Aufruf
readonly RC_NOT_ROOT=3        # Rootrechte fehlen
readonly RC_PKG_TREE=4        # Paketstruktur unvollstaendig
readonly RC_MODEL=10          # Falsches Mac-Modell
readonly RC_RELEASE=11        # Falsche Ubuntu-Version
readonly RC_DEPS=12           # Paketabhaengigkeiten fehlen
readonly RC_CHECKSUM=13       # Pruefsumme falsch
readonly RC_REPO=14           # Lokale Paketquelle fehlerhaft
readonly RC_APPROVAL=15       # Benutzerfreigabe fehlt
readonly RC_GRUB=16           # GRUB-Fehler
readonly RC_BACKUP=17         # Sicherung fehlgeschlagen
readonly RC_HARDWARE=19       # Hardwaretest fehlgeschlagen
readonly RC_ABORT=20          # Abbruch durch Benutzer

# ---------------------------------------------------------------------------
# Feste Pfade
# ---------------------------------------------------------------------------
readonly MT2_BACKUP_ROOT="/var/backups/maximus-t2"
readonly MT2_STATE_DIR="/var/lib/maximus-t2"
readonly MT2_LOG_DIR="/var/log/maximus-t2"
readonly MT2_APT_LIST="/etc/apt/sources.list.d/maximus-t2-offline.list"
readonly MT2_SUPPORTED_MODEL="MacBookPro16,1"
readonly MT2_SUPPORTED_RELEASE="24.04"
readonly MT2_SUPPORTED_CODENAME="noble"
readonly MT2_KERNEL_PACKAGE="linux-t2-lts"
readonly MT2_KERNEL_VERSION="6.18.54-1-noble"
readonly MT2_KERNEL_RELEASE="6.18.54-1-t2-noble"
readonly MT2_KERNEL_FALLBACK_RELEASE="6.18.53-1-t2-noble"

# Nur diese Verzeichnisse darf install.sh dauerhaft beschreiben.
readonly MT2_WRITE_ALLOWLIST="/etc/apt /etc/default /etc/modprobe.d /etc/modules-load.d /etc/initramfs-tools /etc/pipewire /etc/NetworkManager /etc/udev/rules.d /etc/systemd /etc/t2fand.conf /boot /var/backups/maximus-t2 /var/lib/maximus-t2 /var/log/maximus-t2 /var/lib/dpkg /var/cache/apt /usr /lib/modules"

# ---------------------------------------------------------------------------
# Ausgabe
# ---------------------------------------------------------------------------
MT2_STEP=0
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	C_R=$'\033[31m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_B=$'\033[36m'; C_0=$'\033[0m'
else
	C_R=''; C_G=''; C_Y=''; C_B=''; C_0=''
fi

log()      { printf '%s\n' "$*"; }
log_info() { printf '%s[ INFO ]%s %s\n' "$C_B" "$C_0" "$*"; }
log_ok()   { printf '%s[  OK  ]%s %s\n' "$C_G" "$C_0" "$*"; }
log_warn() { printf '%s[ WARN ]%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
log_err()  { printf '%s[FEHLER]%s %s\n' "$C_R" "$C_0" "$*" >&2; }

# Schrittzaehler. Jeder Arbeitsschritt wird nummeriert ausgegeben.
log_step() {
	MT2_STEP=$((MT2_STEP + 1))
	printf '\n%s=== Schritt %d: %s ===%s\n' "$C_B" "$MT2_STEP" "$*" "$C_0"
}

# Bricht mit Code und verstaendlicher Meldung ab.
# Aufruf: die <code> "<Ursache>" "<Abhilfe>"
die() {
	local code="$1"; shift
	log_err "$1"
	if [ -n "${2:-}" ]; then
		printf '         Abhilfe: %s\n' "$2" >&2
	fi
	printf '         Rueckgabecode: %s\n' "$code" >&2
	exit "$code"
}

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

# Gibt das Wurzelverzeichnis des Installationspakets aus.
mt2_package_root() {
	local here
	here="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
	# scripts/ -> Paketwurzel ist eine Ebene hoeher
	if [ -f "$here/../manifest.json" ]; then
		(cd "$here/.." && pwd)
	elif [ -f "$here/manifest.json" ]; then
		printf '%s\n' "$here"
	else
		printf '%s\n' "$here"
	fi
}

# Zaehlt gefundene Dateien robust.
# Fehlt das Verzeichnis, lautet das Ergebnis 0.
# Wichtig: 'find || true' verhindert, dass 'set -o pipefail' das Skript beendet.
mt2_count_files() {
	local out
	out="$( { find "$@" 2>/dev/null || true; } | wc -l )"
	printf '%s\n' "${out:-0}"
}

mt2_require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		die "$RC_NOT_ROOT" "Dieses Skript benoetigt Rootrechte." "Starte es erneut mit: sudo $0 $*"
	fi
}

mt2_need_cmd() {
	command -v "$1" >/dev/null 2>&1 || \
		die "$RC_DEPS" "Das Programm '$1' fehlt." "Installiere '$1' auf dem Zielgeraet."
}

# Liest das Mac-Modell. Gibt eine leere Zeichenkette aus, wenn es fehlt.
mt2_model() {
	local f
	for f in /sys/class/dmi/id/product_name /sys/devices/virtual/dmi/id/product_name; do
		if [ -r "$f" ]; then tr -d '\0\n' < "$f"; return 0; fi
	done
	return 1
}

mt2_release_id() { . /etc/os-release 2>/dev/null && printf '%s\n' "${VERSION_ID:-}"; }
mt2_codename()   { . /etc/os-release 2>/dev/null && printf '%s\n' "${VERSION_CODENAME:-}"; }

# Prueft eine SHA-256-Liste. Argument 1: Listendatei. Argument 2: Basisverzeichnis.
mt2_verify_sha256() {
	local list="$1" base="$2" rc=0
	[ -f "$list" ] || { log_err "Pruefsummenliste '$list' fehlt."; return 1; }
	( cd "$base" && sha256sum --quiet -c "$list" ) || rc=1
	return "$rc"
}

# Fragt eine Freigabe ab. Erwartet die genaue Eingabe JA.
mt2_confirm() {
	local prompt="$1" answer=''
	printf '\n%s%s%s\n' "$C_Y" "$prompt" "$C_0"
	printf 'Tippe JA und druecke Enter, um fortzufahren: '
	if ! IFS= read -r answer; then
		log_err "Keine Eingabe moeglich."
		return 1
	fi
	[ "$answer" = "JA" ]
}

# Legt die Protokolldatei an und leitet die Ausgabe zusaetzlich dorthin.
mt2_start_log() {
	local name="$1" ts
	ts="$(date -u +%Y%m%dT%H%M%SZ)"
	mkdir -p "$MT2_LOG_DIR" 2>/dev/null || true
	MT2_LOGFILE="$MT2_LOG_DIR/${name}-${ts}.log"
	if : > "$MT2_LOGFILE" 2>/dev/null; then
		exec > >(tee -a "$MT2_LOGFILE") 2>&1
		log_info "Protokoll: $MT2_LOGFILE"
	else
		MT2_LOGFILE=''
		log_warn "Protokolldatei nicht beschreibbar. Die Ausgabe erfolgt nur auf dem Bildschirm."
	fi
}
