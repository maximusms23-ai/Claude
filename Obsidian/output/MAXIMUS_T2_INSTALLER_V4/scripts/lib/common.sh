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
readonly RC_TOOL=6            # Ein benoetigtes Programm fehlt
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
readonly MT2_VERSION="4.1.0"
readonly MT2_BACKUP_ROOT="/var/backups/maximus-t2"
readonly MT2_STATE_DIR="/var/lib/maximus-t2"
readonly MT2_LOG_DIR="/var/log/maximus-t2"
# Die Offline-Paketquelle liegt NICHT in /etc/apt/sources.list.d.
# Grund: Ein Eintrag dort gilt fuer jeden spaeteren apt-Aufruf des Systems.
# Nach dem Abziehen der Samsung T7 wuerde 'apt update' dann scheitern.
readonly MT2_APT_DIR="/var/lib/maximus-t2/apt"
readonly MT2_APT_LIST="$MT2_APT_DIR/offline.list"
readonly MT2_APT_CONF="$MT2_APT_DIR/apt.conf"
readonly MT2_APT_LISTS="$MT2_APT_DIR/lists"
# Wird von mt2_apt_pin_create gesetzt: '_apt' oder 'root'.
MT2_APT_SANDBOX='_apt' 
# Fassung V4.0 legte die Quelle hier ab. rollback.sh entfernt die Altlast.
readonly MT2_APT_LIST_LEGACY="/etc/apt/sources.list.d/maximus-t2-offline.list"
readonly MT2_SUPPORTED_MODEL="MacBookPro16,1"
readonly MT2_SUPPORTED_RELEASE="24.04"
readonly MT2_SUPPORTED_CODENAME="noble"
readonly MT2_KERNEL_PACKAGE="linux-t2-lts"
readonly MT2_KERNEL_VERSION="6.18.54-1-noble"
readonly MT2_KERNEL_RELEASE="6.18.54-1-t2-noble"
readonly MT2_KERNEL_FALLBACK_RELEASE="6.18.53-1-t2-noble"

# Nur diese Verzeichnisse darf install.sh dauerhaft beschreiben.
readonly MT2_WRITE_ALLOWLIST="/etc/default /etc/modprobe.d /etc/modules-load.d /etc/initramfs-tools /etc/pipewire /etc/NetworkManager /etc/udev/rules.d /etc/systemd /etc/t2fand.conf /boot /var/backups/maximus-t2 /var/lib/maximus-t2 /var/log/maximus-t2 /var/lib/dpkg /var/cache/apt /usr /lib/modules"

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

# ---------------------------------------------------------------------------
# V4.1: GRUB-Konfiguration pruefen
# ---------------------------------------------------------------------------
# WICHTIG: 'bash -n' ist fuer grub.cfg FALSCH.
# Gemessen in V4.1: 'bash -n' meldete bei einer gueltigen grub.cfg einen
# Syntaxfehler (Fehlalarm) und bei einer nicht geschlossenen menuentry-Klammer
# keinen Fehler (uebersehener Fehler). Nur grub-script-check ist zustaendig.

# Gibt den Pfad des Pruefprogramms aus. Rueckgabe 1, wenn keines vorhanden ist.
mt2_grub_check_tool() {
	local c
	for c in grub-script-check grub2-script-check; do
		if command -v "$c" >/dev/null 2>&1; then
			command -v "$c"
			return 0
		fi
	done
	return 1
}

# Prueft eine GRUB-Konfiguration.
# Rueckgabe: 0 gueltig, 1 ungueltig, 6 Pruefprogramm fehlt.
mt2_grub_check_cfg() {
	local f="$1" tool
	[ -f "$f" ] || return 1
	if ! tool="$(mt2_grub_check_tool)"; then
		return 6
	fi
	if "$tool" "$f" >/dev/null 2>&1; then
		return 0
	fi
	return 1
}

# ---------------------------------------------------------------------------
# V4.1: Optionen mit Wert pruefen
# ---------------------------------------------------------------------------
# Ergebnis: Eine Option ohne Wert fuehrt zu einer verstaendlichen Meldung.
# Gemessen in V4.1: Ohne diese Pruefung scheiterte das nachfolgende 'shift'
# unter 'set -e'. Das Skript endete mit Code 1 und ohne jede Ausgabe.
#
# Aufruf: mt2_opt_needs_value "$#" --option
mt2_opt_needs_value() {
	if [ "${1:-0}" -lt 2 ]; then
		die "$RC_USAGE" "Die Option '$2' erwartet einen Wert." "Beispiel: $2 <wert>"
	fi
}

# ---------------------------------------------------------------------------
# V4.1: Pfade fuer apt-Quellen kodieren
# ---------------------------------------------------------------------------
# Gemessen in V4.1: Ein Leerzeichen im Pfad zerlegt die file://-Quelle.
# apt sucht dann in einem falschen Verzeichnis und meldet "File not found".
# Die Samsung T7 wird oft unter /media/<benutzer>/<bezeichnung> eingehaengt.
# Eine Bezeichnung mit Leerzeichen ist dort der Normalfall.
mt2_url_encode_path() {
	printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/#/%23/g' 		-e 's/?/%3F/g' -e 's/\[/%5B/g' -e 's/\]/%5D/g'
}

# Dekodiert einen prozentkodierten Pfad, wie apt ihn ausgibt.
# Die Reihenfolge ist wichtig: '%25' zuletzt, damit ein daraus entstandenes
# Prozentzeichen nicht erneut als Einleitung gelesen wird.
mt2_url_decode_path() {
	local s="$1"
	s="${s//%20/ }"
	s="${s//%23/#}"
	s="${s//%3F/?}"
	s="${s//%5B/[}"
	s="${s//%5D/]}"
	s="${s//%25/%}"
	printf '%s' "$s"
}

# Gibt die Dateipfade aus, die apt fuer eine Installation holen wuerde.
# Nur file://-Quellen werden beruecksichtigt. Eine andere Quelle ist ein
# Fehler und wird mit dem Vorsatz 'NETZ:' ausgegeben.
# Aufruf: mt2_apt_wanted_files <paket>...
mt2_apt_wanted_files() {
	local line uri
	while IFS= read -r line; do
		case "$line" in
			"'file:"*)
				uri="${line#\'}"
				uri="${uri%%\'*}"
				uri="${uri#file:}"
				mt2_url_decode_path "$uri"
				printf '\n'
				;;
			"'http"*|"'ftp"*)
				printf 'NETZ:%s\n' "$line"
				;;
		esac
	done < <(mt2_apt install -y --no-install-recommends --print-uris "$@" 2>/dev/null)
}

# ---------------------------------------------------------------------------
# V4.1: Gepinnte Paketverwaltung
# ---------------------------------------------------------------------------
# Ergebnis: Jeder apt-Aufruf sieht genau eine Paketquelle, die lokale.
# Simulation und echte Installation nutzen damit denselben Bestand.
# Ein unbeabsichtigter Download aus dem Netz ist ausgeschlossen.
#
# Der dpkg-Status bleibt der echte Status des Zielgeraets.
# Die Aufloesung beruecksichtigt deshalb die bereits installierten Pakete.
#
# Aufruf: mt2_apt_pin_create <paketverzeichnis>
mt2_apt_pin_create() {
	local pkgdir="$1" enc sandbox=''
	mkdir -p "$MT2_APT_DIR" "$MT2_APT_LISTS/partial" "$MT2_APT_DIR/log" \
		|| return 1
	# apt laesst beim Holen die Rechte auf den Benutzer '_apt' fallen.
	# Zwei Dinge muessen dann stimmen:
	#   1. '_apt' braucht Schreibrecht auf die eigene Teilablage.
	#   2. '_apt' braucht Leserecht auf das Paketverzeichnis.
	#
	# Punkt 2 ist auf einem Wechseldatentraeger meist NICHT erfuellt.
	# Der Dienst udisks2 haengt Wechselmedien unter /media/<benutzer>/ ein.
	# Dieses Elternverzeichnis hat den Modus 0700 und gehoert dem Benutzer.
	# '_apt' kann es deshalb nicht durchlaufen.
	# Gemessen: 'apt-get update' bricht dann mit Rueckgabe 100 ab.
	#
	# In diesem Fall laeuft das Holen als root. Das ist hier vertretbar:
	# Die Quelle ist ein lokales Verzeichnis, und jede Paketdatei wurde
	# vorher gegen packages/SHA256SUMS.debs geprueft.
	if id -u _apt >/dev/null 2>&1; then
		chown -R _apt:root "$MT2_APT_LISTS" 2>/dev/null || sandbox='root'
		chmod 0700 "$MT2_APT_LISTS/partial" 2>/dev/null || true
		if [ -z "$sandbox" ]; then
			if command -v runuser >/dev/null 2>&1; then
				runuser -u _apt -- test -r "$pkgdir/Packages" 2>/dev/null || sandbox='root'
			elif command -v setpriv >/dev/null 2>&1; then
				setpriv --reuid=_apt --regid=root --clear-groups \
					test -r "$pkgdir/Packages" 2>/dev/null || sandbox='root'
			else
				sandbox='root'
			fi
		fi
	else
		sandbox='root'
	fi
	MT2_APT_SANDBOX="${sandbox:-_apt}"
	enc="$(mt2_url_encode_path "$pkgdir")"
	printf '# MAXIMUS_T2_INSTALLER V%s - lokale Offline-Paketquelle\n' "$MT2_VERSION" > "$MT2_APT_LIST"
	printf '# Diese Datei liegt bewusst NICHT in /etc/apt/sources.list.d.\n' >> "$MT2_APT_LIST"
	printf 'deb [arch=amd64 trusted=yes] file://%s ./\n' "$enc" >> "$MT2_APT_LIST"
	{
		printf '// MAXIMUS_T2_INSTALLER V%s - gepinnte Paketverwaltung\n' "$MT2_VERSION"
		printf 'Dir::Etc::sourcelist "%s";\n' "$MT2_APT_LIST"
		printf 'Dir::Etc::sourceparts "/dev/null";\n'
		printf 'Dir::State::lists "%s";\n' "$MT2_APT_LISTS"
		printf 'Dir::Log "%s/log";\n' "$MT2_APT_DIR"
		printf 'APT::Architecture "amd64";\n'
		printf 'APT::Architectures "amd64";\n'
		printf 'Acquire::Languages "none";\n'
		printf 'APT::Install-Recommends "false";\n'
		printf 'APT::Install-Suggests "false";\n'
		printf 'APT::Get::AllowUnauthenticated "false";\n'
		printf 'Acquire::http::Timeout "3";\n'
		printf 'Acquire::https::Timeout "3";\n'
		printf 'Acquire::Retries "0";\n'
		if [ -n "$sandbox" ]; then
			# Der Benutzer '_apt' fehlt oder die Rechte liessen sich nicht setzen.
			printf 'APT::Sandbox::User "%s";\n' "$sandbox"
		fi
	} > "$MT2_APT_CONF"
	return 0
}

# Fuehrt apt-get mit der gepinnten Konfiguration aus.
mt2_apt() {
	APT_CONFIG="$MT2_APT_CONF" apt-get "$@"
}

# Prueft, dass die gepinnte Konfiguration nur die lokale Quelle kennt.
# Die Pruefung umfasst drei Stufen:
#   1. Die Quellenliste selbst. Sie darf nur file://-Zeilen tragen.
#   2. Die Konfiguration. Sie muss sourceparts abschalten.
#   3. Der geladene Zustand von apt. Er darf keine Netzquelle nennen.
# Stufe 1 ist wichtig: Stufe 3 zeigt eine neue Netzquelle erst nach
# 'apt-get update'. Eine Pruefung allein ueber apt-cache policy waere blind.
# Rueckgabe: 0 in Ordnung, 1 es ist eine Netzquelle moeglich oder sichtbar.
mt2_apt_pin_verify() {
	local pol line
	[ -f "$MT2_APT_LIST" ] || return 1
	[ -f "$MT2_APT_CONF" ] || return 1
	# Stufe 1
	while IFS= read -r line; do
		case "$line" in
			''|\#*) continue ;;
			deb*)	# deckt auch deb-src ab
				printf '%s' "$line" | grep -q 'file://' || return 1
				printf '%s' "$line" | grep -qE '(https?|ftp|tor|mirror)[+:]' && return 1
				;;
		esac
	done < "$MT2_APT_LIST"
	# Stufe 2
	grep -q 'Dir::Etc::sourceparts "/dev/null"' "$MT2_APT_CONF" || return 1
	# Stufe 3
	pol="$(APT_CONFIG="$MT2_APT_CONF" apt-cache policy 2>/dev/null || true)"
	printf '%s' "$pol" | grep -qE '(https?|ftp)://' && return 1
	printf '%s' "$pol" | grep -q 'MAXIMUS-T2-OFFLINE' || return 1
	return 0
}

# ---------------------------------------------------------------------------
# V4.1: Paketbestand festhalten und vergleichen
# ---------------------------------------------------------------------------
# Ergebnis: rollback.sh weiss genau, welche Pakete install.sh hinzugefuegt
# und welche es veraendert hat. Es raet nicht mehr ueber Namensmuster.

# Schreibt den Bestand als "name<TAB>version" nach <datei>.
mt2_pkg_snapshot() {
	local out="$1"
	dpkg-query -W -f='${Package}\t${Version}\t${Status}\n' 2>/dev/null \
		| awk -F'\t' '$3 ~ /ok installed/ {print $1 "\t" $2}' | sort > "$out"
}

# Vergleicht zwei Bestaende.
# Schreibt <ziel>/packages-added.txt und <ziel>/packages-changed.txt.
mt2_pkg_diff() {
	local before="$1" after="$2" dest="$3"
	join -t "$(printf '\t')" -v2 -o 2.1,2.2 "$before" "$after" > "$dest/packages-added.txt"
	join -t "$(printf '\t')" -o 1.1,1.2,2.2 "$before" "$after" \
		| awk -F'\t' '$2 != $3 {print $1 "\t" $2 "\t" $3}' > "$dest/packages-changed.txt"
	join -t "$(printf '\t')" -v1 -o 1.1,1.2 "$before" "$after" > "$dest/packages-removed.txt"
}

# ---------------------------------------------------------------------------
# V4.1: Sicherung schreiben und pruefen
# ---------------------------------------------------------------------------
# Schreibt die Pruefsummen IN das Sicherungsverzeichnis.
mt2_backup_seal() {
	local dir="$1"
	( cd "$dir" && find . -type f ! -name 'SHA256SUMS' -print0 | sort -z \
		| xargs -0 -r sha256sum > SHA256SUMS ) || return 1
	return 0
}

# Prueft eine Sicherung gegen ihre eigene Pruefsummenliste.
# Rueckgabe: 0 unverfaelscht, 1 veraendert, 2 keine Liste vorhanden.
mt2_backup_verify() {
	local dir="$1"
	[ -f "$dir/SHA256SUMS" ] || return 2
	( cd "$dir" && sha256sum --quiet -c SHA256SUMS >/dev/null 2>&1 ) || return 1
	return 0
}

# ---------------------------------------------------------------------------
# V4.1: Dateisystem des Paketverzeichnisses bewerten
# ---------------------------------------------------------------------------
# exFAT, vfat und ntfs speichern keine Unix-Rechte.
# Das Ausfuehrungsbit der Skripte geht dort verloren.
# Gibt "<dateisystem> <exec|noexec>" aus.
mt2_fs_info() {
	local path="$1" fs opts
	fs="$(findmnt -nro FSTYPE --target "$path" 2>/dev/null | head -1 || true)"
	opts="$(findmnt -nro OPTIONS --target "$path" 2>/dev/null | head -1 || true)"
	case ",$opts," in
		*,noexec,*) printf '%s noexec\n' "${fs:-unbekannt}" ;;
		*)          printf '%s exec\n'   "${fs:-unbekannt}" ;;
	esac
}

# Prueft, ob Unix-Rechte auf diesem Dateisystem gespeichert werden.
# Rueckgabe: 0 ja, 1 nein.
mt2_fs_keeps_modes() {
	case "$1" in
		exfat|vfat|msdos|ntfs|ntfs3|fuseblk|iso9660|udf) return 1 ;;
		*) return 0 ;;
	esac
}
