#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - gemeinsame Bibliothek
#
# Ergebnis: Diese Datei liefert Rueckgabecodes, Protokollfunktionen und die
# Geraeteerkennung. Sie veraendert nichts von sich aus.
#
# Rufe jedes Skript mit 'bash' auf.

readonly MX_VERSION="1.0.0"

# --- Rueckgabecodes -------------------------------------------------------
readonly RC_OK=0
readonly RC_USAGE=2
readonly RC_NOT_ROOT=3
readonly RC_TOOL=6
readonly RC_NO_TARGET=10        # Kein eindeutiges Ziel bestimmbar
readonly RC_TARGET_AMBIGUOUS=11 # Mehrere Treffer, keine Entscheidung
readonly RC_TARGET_IS_MEDIUM=12 # Das Ziel ist das laufende Medium
readonly RC_CHECKSUM=13
readonly RC_APPROVAL=15         # Freigabe fehlt oder stimmt nicht
readonly RC_ID_CHANGED=16       # Stabile Kennung hat sich geaendert
readonly RC_BACKUP=17
readonly RC_INSTALL=18          # Installationsschritt fehlgeschlagen
readonly RC_HARDWARE=19
readonly RC_ABORT=20

# --- Protokoll ------------------------------------------------------------
MX_LOG="${MX_LOG:-/var/log/maximus-t2-neuinstall.log}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_B=$'\033[1m'; C_0=$'\033[0m'
else
	C_G=''; C_Y=''; C_R=''; C_B=''; C_0=''
fi

mx_log_init() {
	mkdir -p "$(dirname "$MX_LOG")" 2>/dev/null || true
	{
		printf '=== MAXIMUS T2 Neuinstallation V%s ===\n' "$MX_VERSION"
		printf 'Zeitpunkt: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
		printf 'Kernel:    %s\n' "$(uname -r)"
	} >> "$MX_LOG" 2>/dev/null || true
}

# Im Prueflauf und im Selbsttest wird zusaetzlich auf die Konsole
# geschrieben. Nur so sammelt ein Starttest die Ausgabe ein.
MX_MIRROR=0
# Das Muster nutzt [.] statt \. Gemessen im Prueflauf: Ein doppelter
# Rueckstrich trifft einen echten Rueckstrich, nicht den Punkt.
if grep -qE 'maximus[.](test|selftest)=1' /proc/cmdline 2>/dev/null; then MX_MIRROR=1; fi
log() {
	printf '%s\n' "$*"
	printf '%s\n' "$*" >> "$MX_LOG" 2>/dev/null || true
	[ "$MX_MIRROR" -eq 1 ] && printf 'WIZ| %s\n' "$*" > /dev/console 2>/dev/null
	return 0
}
log_ok()   { log "${C_G}[  OK  ]${C_0} $*"; }
log_info() { log "[ INFO ] $*"; }
log_warn() { log "${C_Y}[ WARN ]${C_0} $*"; }
log_err()  { log "${C_R}[FEHLER]${C_0} $*"; }
log_step() { log ""; log "${C_B}=== $* ===${C_0}"; }

# die <code> <satz> [abhilfe]
die() {
	local code="$1" msg="$2" hint="${3:-}"
	log_err "$msg"
	[ -n "$hint" ] && log "         Abhilfe: $hint"
	log "         Rueckgabecode: $code"
	exit "$code"
}

mx_require_root() {
	[ "$(id -u)" -eq 0 ] || die "$RC_NOT_ROOT" "Dieses Skript braucht Rootrechte." \
		"Starte es mit 'sudo bash $0'."
}

mx_require_tool() {
	command -v "$1" >/dev/null 2>&1 || die "$RC_TOOL" "Das Programm '$1' fehlt." \
		"Ohne dieses Programm ist der Schritt nicht pruefbar."
}

# --- Geraeteerkennung -----------------------------------------------------
# Ergebnis: Pfad des laufenden Installationsmediums, oder leer.
# Das Medium wird ueber den Einhaengepunkt des Live-Systems gefunden.
# Es wird NICHT ueber den Namen 'Samsung T7' geraten.
mx_live_medium_disk() {
	local src disk
	for mp in /cdrom /run/live/medium /isodevice /media/cdrom; do
		[ -d "$mp" ] || continue
		src="$(findmnt -no SOURCE --target "$mp" 2>/dev/null)" || continue
		[ -n "$src" ] || continue
		case "$src" in /dev/*) ;; *) continue ;; esac
		disk="$(lsblk -no PKNAME "$src" 2>/dev/null | head -1)"
		if [ -n "$disk" ]; then printf '/dev/%s\n' "$disk"; return 0; fi
		printf '%s\n' "$src"; return 0
	done
	return 1
}

# mx_stable_id <geraet> - gibt die stabilste Kennung aus, die es gibt.
# Reihenfolge: WWN, dann by-id, dann Modell+Seriennummer.
# Ein Gerätename wie /dev/sda gilt NICHT als stabile Kennung.
mx_stable_id() {
	local dev="$1" link best=''
    [ -b "$dev" ] || return 1
	for link in /dev/disk/by-id/*; do
		[ -e "$link" ] || continue
		case "$(basename "$link")" in *-part[0-9]*) continue ;; esac
		[ "$(readlink -f "$link")" = "$(readlink -f "$dev")" ] || continue
		case "$(basename "$link")" in
			wwn-*)  printf '%s\n' "$link"; return 0 ;;
			nvme-eui*) [ -n "$best" ] || best="$link" ;;
			*)      [ -n "$best" ] || best="$link" ;;
		esac
	done
	if [ -n "$best" ]; then printf '%s\n' "$best"; return 0; fi
	return 1
}

# mx_disk_facts <geraet> - gibt eine Zeile mit Tabulatoren aus:
# geraet<TAB>groesse<TAB>modell<TAB>seriennummer<TAB>stabile_kennung
mx_disk_facts() {
	local dev="$1" size model serial sid
	size="$(lsblk -bndo SIZE "$dev" 2>/dev/null)"
	model="$(lsblk -ndo MODEL "$dev" 2>/dev/null | sed 's/[[:space:]]*$//')"
	serial="$(lsblk -ndo SERIAL "$dev" 2>/dev/null | sed 's/[[:space:]]*$//')"
	sid="$(mx_stable_id "$dev" 2>/dev/null)" || sid=''
	printf '%s\t%s\t%s\t%s\t%s\n' "$dev" "${size:-0}" "${model:-unbekannt}" \
		"${serial:-unbekannt}" "${sid:-KEINE}"
}

mx_human_size() {
	awk -v b="${1:-0}" 'BEGIN{
		split("Byte KiB MiB GiB TiB PiB", u, " ");
		i=1; while (b>=1024 && i<6) { b/=1024; i++ }
		printf (i==1) ? "%d %s\n" : "%.1f %s\n", b, u[i]
	}'
}

# mx_confirm_token <erwartet> - verlangt die wörtliche Eingabe.
# Ein blosses 'ja' genuegt nicht. Das verhindert ein versehentliches Loeschen.
mx_confirm_token() {
	local want="$1" got=''
	printf '\n%sGib zur Freigabe genau dies ein:%s %s\n' "$C_B" "$C_0" "$want"
	printf 'Eingabe (oder ABBRUCH): '
	IFS= read -r got || got=''
	if [ "$got" = "ABBRUCH" ] || [ -z "$got" ]; then
		log_warn "Abbruch durch Benutzer."
		return 1
	fi
	if [ "$got" != "$want" ]; then
		log_err "Die Eingabe stimmt nicht. Erwartet war: $want"
		return 1
	fi
	return 0
}
