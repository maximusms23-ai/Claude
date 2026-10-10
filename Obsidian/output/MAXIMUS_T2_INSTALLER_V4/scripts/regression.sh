#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.1 - Regressionstests
#
# Ergebnis: Das Skript prueft jeden in V4.1 behobenen Fehler einzeln.
# Jeder Test hat eine Erwartung. Die Rohdaten landen in einer Tabelle.
# Die Erfolgsquote wird aus diesen Rohdaten berechnet.
#
# Das Skript aendert keine Systemdatei.
# Es arbeitet in einem temporaeren Verzeichnis.
# Es nutzt zusaetzlich die eigenen Verzeichnisse unter /var/lib/maximus-t2
# und /var/backups/maximus-t2. Vorhandene Inhalte werden vorher gesichert
# und danach zurueckgelegt.
#
# Aufruf:  bash regression.sh [OPTIONEN]
#   --packages PFAD  Nutzt diese lokale Paketquelle fuer die Offline-Tests.
#                    Standard ist <Paketwurzel>/packages.
#   --out DATEI      Zielpfad der Rohdatentabelle.
#   --force          Laeuft auch, wenn eine echte Installation aufgezeichnet ist.
#   --no-color       Gibt keine Farbcodes aus.
#
# Rueckgabe: 0 wenn jeder Test seine Erwartung erfuellt, sonst 19.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
# shellcheck source=lib/grub-config.sh
. "$SELF_DIR/lib/grub-config.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

PKG_SRC="$ROOT/packages"
OUTFILE=''
FORCE=0
while [ "$#" -gt 0 ]; do
	case "$1" in
		--packages) mt2_opt_needs_value "$#" --packages; PKG_SRC="$2"; shift ;;
		--out)      mt2_opt_needs_value "$#" --out; OUTFILE="$2"; shift ;;
		--force)    FORCE=1 ;;
		--no-color) NO_COLOR=1; export NO_COLOR ;;
		-h|--help)  sed -n '2,22p' "$0"; exit "$RC_OK" ;;
		*)          die "$RC_USAGE" "Unbekannte Option '$1'." "Rufe 'bash $0 --help' auf." ;;
	esac
	shift
done

WORK="$(mktemp -d -t maximus-t2-regression-XXXXXX)"
[ -n "$OUTFILE" ] || OUTFILE="$WORK/regression-results.tsv"

N_TOTAL=0
N_PASS=0
N_FAIL=0
N_SKIP=0
GROUP='-'

# Sicherung der eigenen Zustandsverzeichnisse
SAVED_STATE=''
SAVED_BACKUPS=''

# shellcheck disable=SC2317  # Die Funktion ruft die EXIT-Falle ueber cleanup auf.
restore_state() {
	if [ -n "$SAVED_STATE" ] && [ -d "$SAVED_STATE" ]; then
		rm -rf "$MT2_STATE_DIR"
		mv "$SAVED_STATE" "$MT2_STATE_DIR" 2>/dev/null || true
	else
		rm -rf "$MT2_STATE_DIR" 2>/dev/null || true
	fi
	if [ -n "$SAVED_BACKUPS" ] && [ -d "$SAVED_BACKUPS" ]; then
		rm -rf "$MT2_BACKUP_ROOT"
		mv "$SAVED_BACKUPS" "$MT2_BACKUP_ROOT" 2>/dev/null || true
	else
		rm -rf "$MT2_BACKUP_ROOT" 2>/dev/null || true
	fi
}

# shellcheck disable=SC2317  # Die Funktion ruft die EXIT-Falle auf.
cleanup() {
	restore_state
	rm -rf "$WORK"
}
trap cleanup EXIT

group() { GROUP="$1"; printf '\n%s=== %s ===%s\n' "$C_B" "$1" "$C_0"; }

# record <name> <erwartet> <gemessen>
record() {
	local name="$1" want="$2" got="$3" verdict
	N_TOTAL=$((N_TOTAL + 1))
	if [ "$want" = "$got" ]; then
		verdict=PASS; N_PASS=$((N_PASS + 1))
		printf '%s[ PASS ]%s %-62s %s\n' "$C_G" "$C_0" "$name" "$got"
	else
		verdict=FAIL; N_FAIL=$((N_FAIL + 1))
		printf '%s[ FAIL ]%s %-62s erwartet=%s gemessen=%s\n' "$C_R" "$C_0" "$name" "$want" "$got"
	fi
	printf '%s\t%s\t%s\t%s\t%s\n' "$GROUP" "$name" "$want" "$got" "$verdict" >> "$OUTFILE"
}

skip() {
	N_TOTAL=$((N_TOTAL + 1)); N_SKIP=$((N_SKIP + 1))
	printf '%s[ SKIP ]%s %-62s %s\n' "$C_Y" "$C_0" "$1" "$2"
	printf '%s\t%s\t-\t-\tSKIP\n' "$GROUP" "$1" >> "$OUTFILE"
}

# rc_of <befehl...> - gibt den Rueckgabecode aus
rc_of() { "$@" >/dev/null 2>&1; printf '%s' "$?"; }

# V4.1: Die Rohdaten tragen ihre Umgebung. Ein Lauf ohne grub-script-check
# oder ohne Paketbestand liefert andere Zahlen. Das muss nachlesbar sein.
{
	printf '# MAXIMUS_T2_INSTALLER V%s - Rohdaten der Regressionstests\n' "$MT2_VERSION"
	printf '# zeitpunkt=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	printf '# rechner_kernel=%s\n' "$(uname -r)"
	printf '# betriebssystem=%s %s\n' "$(mt2_release_id || echo unbekannt)" "$(mt2_codename || echo unbekannt)"
	printf '# rootrechte=%s\n' "$([ "$(id -u)" -eq 0 ] && echo ja || echo nein)"
	printf '# grub_script_check=%s\n' "$(mt2_grub_check_tool 2>/dev/null || echo FEHLT)"
	printf '# shellcheck=%s\n' "$(command -v shellcheck 2>/dev/null || echo FEHLT)"
	printf '# paketquelle=%s\n' "$PKG_SRC"
	printf '# paketdateien=%s\n' "$(mt2_count_files "$PKG_SRC" -name '*.deb')"
	printf '# paketindex=%s\n' "$([ -f "$PKG_SRC/Packages" ] && echo vorhanden || echo FEHLT)"
	printf '#\n'
	printf '# Hinweis: Ohne grub-script-check werden R1.1 bis R1.4 uebersprungen.\n'
	printf '# Ohne Paketindex werden R2.* und R3.4 bis R3.5 uebersprungen.\n'
	printf '# Ohne Rootrechte werden R2.*, R3.4, R6.*, R7.*, R9.1, R9.2 und R10.1 uebersprungen.\n'
	printf '#\n'
	printf 'gruppe\ttest\terwartet\tgemessen\tergebnis\n'
} > "$OUTFILE"

log "MAXIMUS_T2_INSTALLER V$MT2_VERSION - Regressionstests"
log "Paketwurzel:   $ROOT"
log "Paketquelle:   $PKG_SRC"
log "Rohdaten:      $OUTFILE"

if [ -f "$MT2_STATE_DIR/install-state" ] && [ "$FORCE" -eq 0 ]; then
	PH="$(awk -F= '/^phase=/{print $2}' "$MT2_STATE_DIR/install-state" | tail -1)"
	if [ -n "$PH" ] && [ "$PH" != "test" ]; then
		die "$RC_ABORT" "Es ist eine Installation im Zustand '$PH' aufgezeichnet." \
			"Die Tests wuerden diese Aufzeichnung ueberschreiben. Nutze --force nur, wenn das gewollt ist."
	fi
fi

# Eigene Zustandsverzeichnisse beiseitelegen
if [ "$(id -u)" -eq 0 ]; then
	[ -d "$MT2_STATE_DIR" ] && SAVED_STATE="$WORK/saved-state" && mv "$MT2_STATE_DIR" "$SAVED_STATE"
	[ -d "$MT2_BACKUP_ROOT" ] && SAVED_BACKUPS="$WORK/saved-backups" && mv "$MT2_BACKUP_ROOT" "$SAVED_BACKUPS"
fi

# ===========================================================================
group "R1 - GRUB-Syntaxpruefung (Fehler 1)"
# ===========================================================================
G="$WORK/grub"; mkdir -p "$G"
cat > "$G/valid.cfg" <<'EOF'
set default="0"
if [ x"${feature_menuentry_id}" = xy ]; then
  menuentry_id_option="--id"
else
  menuentry_id_option=""
fi
function load_video {
  if [ x$feature_all_video_module = xy ]; then
    insmod all_video
  fi
}
menuentry 'Ubuntu' --class ubuntu $menuentry_id_option 'gnulinux-simple-UUID' {
	recordfail
	load_video
	insmod gzio
	if [ x$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
	search --no-floppy --fs-uuid --set=root UUID
	linux	/boot/vmlinuz-7.0.0-38-generic root=UUID=UUID ro quiet splash
	initrd	/boot/initrd.img-7.0.0-38-generic
}
EOF
sed '$d' "$G/valid.cfg" > "$G/unclosed.cfg"
printf "menuentry 'Ubuntu' {\n\tif [ x\$a = xy ]\n\t  insmod gzio\n\tfi\n}\n" > "$G/badif.cfg"

if mt2_grub_check_tool >/dev/null 2>&1; then
	record "R1.1 gueltige grub.cfg wird akzeptiert"            0 "$(rc_of mt2_grub_check_cfg "$G/valid.cfg")"
	record "R1.2 nicht geschlossener menuentry wird erkannt"   1 "$(rc_of mt2_grub_check_cfg "$G/unclosed.cfg")"
	record "R1.3 fehlerhaftes if wird erkannt"                 1 "$(rc_of mt2_grub_check_cfg "$G/badif.cfg")"
	record "R1.4 fehlende Datei wird gemeldet"                 1 "$(rc_of mt2_grub_check_cfg "$G/fehlt.cfg")"
	# Gegenprobe: Die alte Methode war in beide Richtungen falsch.
	record "R1.5 Gegenprobe: 'bash -n' meldet Fehlalarm"       2 "$(rc_of bash -n "$G/valid.cfg")"
	record "R1.6 Gegenprobe: 'bash -n' uebersieht den Fehler"  0 "$(rc_of bash -n "$G/unclosed.cfg")"
else
	skip "R1.1-R1.4 GRUB-Pruefung" "grub-script-check fehlt. Installiere grub-common."
	record "R1.5 Gegenprobe: 'bash -n' meldet Fehlalarm"       2 "$(rc_of bash -n "$G/valid.cfg")"
	record "R1.6 Gegenprobe: 'bash -n' uebersieht den Fehler"  0 "$(rc_of bash -n "$G/unclosed.cfg")"
fi

# Statische Gegenprobe: Kein Skript darf 'bash -n' auf grub.cfg anwenden.
# Die Pruefskripte selbst sind ausgenommen. Sie tragen das Muster als Suchtext.
# Gezaehlt wird nur ein echter Aufruf. Erklaerende Kommentare zaehlen nicht.
if grep -rn "bash -n" "$SELF_DIR" --include='*.sh' 2>/dev/null \
	| grep -v -e '/regression\.sh:' -e '/selftest\.sh:' \
	| grep -vE ':[[:space:]]*#' | grep -q 'grub\.cfg'; then
	record "R1.7 kein Skript prueft grub.cfg mit 'bash -n'" ja nein
else
	record "R1.7 kein Skript prueft grub.cfg mit 'bash -n'" ja ja
fi
if grep -rln 'mt2_grub_check_cfg' "$SELF_DIR" --include='*.sh' 2>/dev/null \
	| grep -qE 'install\.sh|preflight\.sh|rollback\.sh'; then
	record "R1.8 install, preflight und rollback nutzen grub-script-check" ja ja
else
	record "R1.8 install, preflight und rollback nutzen grub-script-check" ja nein
fi

# ===========================================================================
group "R2 - Gepinnte Offline-Paketquelle (Fehler 2)"
# ===========================================================================
if [ ! -f "$PKG_SRC/Packages" ]; then
	skip "R2.1-R2.8 Offline-Paketquelle" "Die Paketquelle '$PKG_SRC' hat keinen Index. Fuehre fetch-packages.sh aus."
elif [ "$(id -u)" -ne 0 ]; then
	skip "R2.1-R2.8 Offline-Paketquelle" "Die Tests brauchen Rootrechte. Starte: sudo bash $0"
else
	record "R2.1 gepinnte Konfiguration wird angelegt" 0 "$(rc_of mt2_apt_pin_create "$PKG_SRC")"
	record "R2.2 Quellenliste nennt nur file://" ja \
		"$(grep -qE '^deb .*file://' "$MT2_APT_LIST" && ! grep -qE 'https?://' "$MT2_APT_LIST" && echo ja || echo nein)"
	record "R2.3 Konfiguration schaltet sourceparts ab" ja \
		"$(grep -q 'Dir::Etc::sourceparts "/dev/null"' "$MT2_APT_CONF" && echo ja || echo nein)"
	record "R2.4 Konfiguration nutzt eigene Listen" ja \
		"$(grep -q "Dir::State::lists \"$MT2_APT_LISTS\"" "$MT2_APT_CONF" && echo ja || echo nein)"
	record "R2.5 Index wird gelesen" 0 "$(rc_of mt2_apt update -qq)"
	record "R2.6 nur die lokale Quelle ist sichtbar" 0 "$(rc_of mt2_apt_pin_verify)"
	# Gegenprobe: Mit einer Netzquelle muss die Pruefung anschlagen.
	printf 'deb [arch=amd64] https://archive.ubuntu.com/ubuntu noble main\n' >> "$MT2_APT_LIST"
	record "R2.7 Gegenprobe: Netzquelle wird erkannt" 1 "$(rc_of mt2_apt_pin_verify)"
	mt2_apt_pin_create "$PKG_SRC" >/dev/null 2>&1
	mt2_apt update -qq >/dev/null 2>&1
	# Aufloesung ohne jede Netzmoeglichkeit: unerreichbarer Vermittlungsrechner.
	if http_proxy='http://127.0.0.1:1' https_proxy='http://127.0.0.1:1' \
		mt2_apt install -s -y --no-install-recommends linux-t2-lts t2fanrd tiny-dfr >"$WORK/r2sim.txt" 2>&1; then
		record "R2.8 Aufloesung gelingt ohne Netzzugang" ja ja
	else
		record "R2.8 Aufloesung gelingt ohne Netzzugang" ja nein
		sed -n '1,8p' "$WORK/r2sim.txt" | sed 's/^/         /'
	fi
	record "R2.9 Simulation nennt keine Netzadresse" ja \
		"$(grep -qE 'https?://' "$WORK/r2sim.txt" && echo nein || echo ja)"
	record "R2.10 Simulation entfernt kein Paket" ja \
		"$(grep -qE '^Remv ' "$WORK/r2sim.txt" && echo nein || echo ja)"
	record "R2.11 Systemlisten bleiben unberuehrt" ja \
		"$(find "$MT2_APT_LISTS" -maxdepth 1 -name '*Packages*' 2>/dev/null | grep -q . && echo ja || echo nein)"
fi

# ===========================================================================
group "R3 - Pfade mit Sonderzeichen (Fehler 2b)"
# ===========================================================================
record "R3.1 Leerzeichen wird kodiert" "/media/a/My%20T7" "$(mt2_url_encode_path '/media/a/My T7')"
record "R3.2 Prozentzeichen wird kodiert" "/media/a/100%25" "$(mt2_url_encode_path '/media/a/100%')"
record "R3.3 Pfad ohne Sonderzeichen bleibt gleich" "/media/a/T7" "$(mt2_url_encode_path '/media/a/T7')"
if [ -f "$PKG_SRC/Packages" ] && [ "$(id -u)" -eq 0 ]; then
	SPACED="$WORK/My T7 Disk/packages"
	mkdir -p "$(dirname "$SPACED")"
	cp -r "$PKG_SRC" "$SPACED"
	mt2_apt_pin_create "$SPACED" >/dev/null 2>&1
	record "R3.4 Quelle mit Leerzeichen im Pfad wird gelesen" 0 "$(rc_of mt2_apt update -qq)"
	# Gegenprobe: ohne Kodierung scheitert es.
	printf 'deb [arch=amd64 trusted=yes] file://%s ./\n' "$SPACED" > "$MT2_APT_LIST"
	rm -rf "$MT2_APT_LISTS"; mkdir -p "$MT2_APT_LISTS/partial"
	if mt2_apt update >/dev/null 2>&1 && mt2_apt install -s -y linux-t2-lts >/dev/null 2>&1; then
		record "R3.5 Gegenprobe: ohne Kodierung scheitert die Quelle" nein ja
	else
		record "R3.5 Gegenprobe: ohne Kodierung scheitert die Quelle" nein nein
	fi
	rm -rf "$WORK/My T7 Disk"
else
	skip "R3.4-R3.5 Quelle mit Leerzeichen" "Rootrechte oder Paketindex fehlen."
fi

# V4.1: Eine Kommandosubstitution in einem case-Muster ist unwirksam.
# '$(printf "\n")' liefert eine leere Zeichenkette. Das Muster trifft dann
# jeden Pfad. Gefunden im eigenen Code-Review von V4.1.
# Dieses Pruefskript ist ausgenommen: Die Gegenprobe R3.7 nutzt die alte
# Form absichtlich, um ihr Fehlverhalten zu messen.
# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
BAD_CASE_FORM="$(grep -rln '\*"\$(printf' "$SELF_DIR" --include='*.sh' 2>/dev/null \
	| grep -v '/regression\.sh$' | tr '\n' ' ')"
if [ -n "${BAD_CASE_FORM// /}" ]; then
	record "R3.6 keine Kommandosubstitution in einem case-Muster" ja nein
	printf '         Befund in: %s\n' "$BAD_CASE_FORM"
else
	record "R3.6 keine Kommandosubstitution in einem case-Muster" ja ja
fi
# Gegenprobe: Die alte Form trifft jeden Pfad, die ANSI-C-Form nicht.
PROBE_PATH="/media/max/T7"
PROBE=nein
case "$PROBE_PATH" in
	*"$(printf '\n')"*) PROBE=ja ;;
esac
record "R3.7 Gegenprobe: die alte Form trifft jeden Pfad" ja "$PROBE"
PROBE2=nein
case "$PROBE_PATH" in
	*$'\n'*) PROBE2=ja ;;
esac
record "R3.8 die ANSI-C-Form trifft nur echte Umbrueche" nein "$PROBE2"
PROBE3=nein
case "$(printf 'a\nb')" in
	*$'\n'*) PROBE3=ja ;;
esac
record "R3.9 die ANSI-C-Form erkennt einen echten Umbruch" ja "$PROBE3"

# ===========================================================================
group "R4 - Pruefsummenverwaltung (Fehler 4)"
# ===========================================================================
# Die Liste darf bei Abweichung NICHT selbsttaetig ueberschrieben werden.
# shellcheck disable=SC2016  # Die Muster sind absichtlich woertlich.
if grep -q 'accept-new-checksums' "$SELF_DIR/fetch-packages.sh"; then
	record "R4.1 fetch-packages kennt die Freigabeoption" ja ja
else
	record "R4.1 fetch-packages kennt die Freigabeoption" ja nein
fi
# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
if awk '/Pruefsummenliste erzeugen/,/log_step "Abschluss"/' "$SELF_DIR/fetch-packages.sh" \
	| grep -q 'die "\$RC_CHECKSUM"'; then
	record "R4.2 Abweichung fuehrt zum Abbruch" ja ja
else
	record "R4.2 Abweichung fuehrt zum Abbruch" ja nein
fi
# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
if awk '/Pruefsummenliste erzeugen/,/log_step "Abschluss"/' "$SELF_DIR/fetch-packages.sh" \
	| grep -qE '^cp "\$NEWLIST" "\$EXPECTED"\s*$'; then
	record "R4.3 kein unbedingtes Ueberschreiben der Liste" ja nein
else
	record "R4.3 kein unbedingtes Ueberschreiben der Liste" ja ja
fi
if grep -q 'SHA256SUMS.debs.provenance' "$SELF_DIR/fetch-packages.sh"; then
	record "R4.3b Uebernahme wird mit Herkunftsvermerk belegt" ja ja
else
	record "R4.3b Uebernahme wird mit Herkunftsvermerk belegt" ja nein
fi
# Beschaedigte Paketdatei muss auffallen.
C="$WORK/corrupt"; mkdir -p "$C"
printf 'Inhalt A\n' > "$C/a.deb"; printf 'Inhalt B\n' > "$C/b.deb"
( cd "$C" && sha256sum ./*.deb > SHA256SUMS.debs )
record "R4.4 unverfaelschter Bestand wird bestaetigt" 0 "$(rc_of mt2_verify_sha256 "$C/SHA256SUMS.debs" "$C")"
printf 'Inhalt B manipuliert\n' > "$C/b.deb"
record "R4.5 beschaedigte Paketdatei wird erkannt" 1 "$(rc_of mt2_verify_sha256 "$C/SHA256SUMS.debs" "$C")"
rm -f "$C/b.deb"
record "R4.6 fehlende Paketdatei wird erkannt" 1 "$(rc_of mt2_verify_sha256 "$C/SHA256SUMS.debs" "$C")"
record "R4.7 fehlende Pruefsummenliste wird erkannt" 1 "$(rc_of mt2_verify_sha256 "$C/gibtsnicht" "$C")"

# ===========================================================================
group "R5 - Sicherung und Rueckfall (Fehler 3)"
# ===========================================================================
# Gesucht wird ein echter Aufruf, nicht ein Hinweistext in einer Meldung.
if grep -nE '^[[:space:]]*(act[[:space:]]+|run[[:space:]]+)?apt-get[[:space:]]+autoremove' \
	"$SELF_DIR/rollback.sh" >/dev/null 2>&1; then
	record "R5.1 rollback nutzt kein apt-get autoremove" ja nein
else
	record "R5.1 rollback nutzt kein apt-get autoremove" ja ja
fi
if grep -q "dpkg-query -W -f='\${Package} \${Status}' " "$SELF_DIR/rollback.sh" \
	&& ! grep -qE "dpkg-query .*'linux-t2\*'" "$SELF_DIR/rollback.sh"; then
	record "R5.2 rollback nutzt kein Paketnamensmuster" ja ja
elif grep -qE "'linux-t2\*'|'t2-apple-audio-dsp-\*'" "$SELF_DIR/rollback.sh"; then
	record "R5.2 rollback nutzt kein Paketnamensmuster" ja nein
else
	record "R5.2 rollback nutzt kein Paketnamensmuster" ja ja
fi
if grep -q 'mt2_backup_verify' "$SELF_DIR/rollback.sh"; then
	record "R5.3 rollback prueft die Sicherung" ja ja
else
	record "R5.3 rollback prueft die Sicherung" ja nein
fi
if grep -q 'files-written.txt' "$SELF_DIR/install.sh" && grep -q 'files-written.txt' "$SELF_DIR/rollback.sh"; then
	record "R5.4 jede Dateiaenderung wird aufgezeichnet" ja ja
else
	record "R5.4 jede Dateiaenderung wird aufgezeichnet" ja nein
fi
if grep -q 'mt2_pkg_diff' "$SELF_DIR/install.sh"; then
	record "R5.5 jede Paketaenderung wird aufgezeichnet" ja ja
else
	record "R5.5 jede Paketaenderung wird aufgezeichnet" ja nein
fi

# Siegel der Sicherung
B="$WORK/backup"; mkdir -p "$B"
printf 'GRUB_TIMEOUT=0\n' > "$B/etc-default-grub"
printf 'low_temp = 50\n' > "$B/t2fand.conf"
record "R5.6 Sicherung wird versiegelt" 0 "$(rc_of mt2_backup_seal "$B")"
record "R5.7 unveraenderte Sicherung wird bestaetigt" 0 "$(rc_of mt2_backup_verify "$B")"
printf 'veraendert\n' > "$B/t2fand.conf"
record "R5.8 veraenderte Sicherung wird erkannt" 1 "$(rc_of mt2_backup_verify "$B")"
rm -f "$B/SHA256SUMS"
record "R5.9 Sicherung ohne Siegel wird erkannt" 2 "$(rc_of mt2_backup_verify "$B")"

# ===========================================================================
group "R6 - Rueckfall gegen vorhandene Systemkonfiguration"
# ===========================================================================
if [ "$(id -u)" -ne 0 ]; then
	skip "R6.1-R6.7 Rueckfallverhalten" "Die Tests brauchen Rootrechte."
else
	mkdir -p "$MT2_STATE_DIR"
	STAMP_T="19700101T000000Z"
	BK="$MT2_BACKUP_ROOT/$STAMP_T"; mkdir -p "$BK"
	printf 'GRUB_TIMEOUT=0\nGRUB_CMDLINE_LINUX=""\n' > "$BK/etc-default-grub"
	printf 'low_temp = 50\n' > "$BK/t2fand.conf"
	printf '7.0.0-38-generic\n' > "$BK/running-kernel.txt"
	printf '4.1.0\n' > "$BK/installer-version.txt"
	printf 'vorhandenes-paket\t1.0\nzweites-paket\t2.0\n' > "$BK/pkg-before.txt"
	cp "$BK/pkg-before.txt" "$MT2_STATE_DIR/pkg-before.txt"
	mt2_backup_seal "$BK" >/dev/null 2>&1
	printf '%s\n' "$BK" > "$MT2_STATE_DIR/last-backup"
	printf 'version=4.1.0\nphase=done\n' > "$MT2_STATE_DIR/install-state"
	printf 'create\t/etc/modules-load.d/t2.conf\nreplace\t/etc/default/grub\n' > "$MT2_STATE_DIR/files-written.txt"
	: > "$MT2_STATE_DIR/held-by-maximus.txt"

	# 6.1 Simulation mit gueltiger Sicherung
	bash "$SELF_DIR/rollback.sh" --dry-run --no-color > "$WORK/rb1.txt" 2>&1
	record "R6.1 Simulation mit gueltiger Sicherung" 0 "$?"
	record "R6.2 Simulation aendert nichts" ja \
		"$(grep -q 'Es wurde nichts geaendert' "$WORK/rb1.txt" && echo ja || echo nein)"
	record "R6.3 Sicherung wird als unverfaelscht gemeldet" ja \
		"$(grep -q 'Die Sicherung ist unverfaelscht' "$WORK/rb1.txt" && echo ja || echo nein)"

	# 6.2 Veraenderte Sicherung muss zum Abbruch fuehren
	printf 'manipuliert\n' >> "$BK/t2fand.conf"
	record "R6.4 veraenderte Sicherung bricht ab" 13 \
		"$(rc_of bash "$SELF_DIR/rollback.sh" --dry-run --no-color)"
	record "R6.5 veraenderte Sicherung nur mit Freigabe nutzbar" 0 \
		"$(rc_of bash "$SELF_DIR/rollback.sh" --dry-run --no-color --force-unverified)"
	printf 'low_temp = 50\n' > "$BK/t2fand.conf"
	mt2_backup_seal "$BK" >/dev/null 2>&1

	# 6.3 Ein vorher vorhandenes Paket darf nicht entfernt werden
	printf 'vorhandenes-paket\t1.0\nneues-paket\t9.9\n' > "$MT2_STATE_DIR/packages-added.txt"
	: > "$MT2_STATE_DIR/packages-changed.txt"
	bash "$SELF_DIR/rollback.sh" --dry-run --no-color --remove-added > "$WORK/rb2.txt" 2>&1
	record "R6.6 vorher vorhandenes Paket wird geschont" ja \
		"$(grep -q "war schon vor der Installation vorhanden" "$WORK/rb2.txt" && echo ja || echo nein)"

	# 6.4 Ein Ubuntu-Kernel in der Aufzeichnung muss zum Abbruch fuehren
	printf 'linux-image-7.0.0-38-generic\t7.0.0-38\n' > "$MT2_STATE_DIR/packages-added.txt"
	record "R6.7 Ubuntu-Kernel in der Aufzeichnung bricht ab" 17 \
		"$(rc_of bash "$SELF_DIR/rollback.sh" --dry-run --no-color --remove-added)"

	# 6.5 Ohne Aufzeichnung wird kein Paket entfernt
	rm -f "$MT2_STATE_DIR/packages-added.txt"
	bash "$SELF_DIR/rollback.sh" --dry-run --no-color --remove-added > "$WORK/rb3.txt" 2>&1
	record "R6.8 ohne Aufzeichnung wird kein Paket entfernt" ja \
		"$(grep -q 'wird KEIN Paket entfernt' "$WORK/rb3.txt" && echo ja || echo nein)"

	# 6.6 Fehlende Sicherung
	rm -f "$MT2_STATE_DIR/last-backup"
	rm -rf "$MT2_BACKUP_ROOT"
	record "R6.9 fehlende Sicherung bricht ab" 17 \
		"$(rc_of bash "$SELF_DIR/rollback.sh" --dry-run --no-color)"
	rm -rf "$MT2_STATE_DIR"
fi

# ===========================================================================
group "R7 - Unterbrochene Installation"
# ===========================================================================
if [ "$(id -u)" -ne 0 ]; then
	skip "R7.1-R7.4 unterbrochene Installation" "Die Tests brauchen Rootrechte."
else
	if grep -q 'set_phase "' "$SELF_DIR/install.sh"; then
		record "R7.1 install.sh haelt den Fortschritt fest" ja ja
	else
		record "R7.1 install.sh haelt den Fortschritt fest" ja nein
	fi
	PHASES="$(grep -c 'set_phase "' "$SELF_DIR/install.sh")"
	record "R7.2 mindestens acht Phasen sind erfasst" ja \
		"$([ "$PHASES" -ge 8 ] && echo ja || echo nein)"
	mkdir -p "$MT2_STATE_DIR"
	BK2="$MT2_BACKUP_ROOT/19700101T000001Z"; mkdir -p "$BK2"
	printf 'GRUB_TIMEOUT=0\n' > "$BK2/etc-default-grub"
	mt2_backup_seal "$BK2" >/dev/null 2>&1
	printf '%s\n' "$BK2" > "$MT2_STATE_DIR/last-backup"
	printf 'version=4.1.0\nphase=packages\n' > "$MT2_STATE_DIR/install-state"
	printf 'create\t/etc/modules-load.d/t2.conf\n' > "$MT2_STATE_DIR/files-written.txt"
	bash "$SELF_DIR/rollback.sh" --dry-run --no-color > "$WORK/rb4.txt" 2>&1
	record "R7.3 Unterbrechung wird erkannt und benannt" ja \
		"$(grep -q "unterbrochen" "$WORK/rb4.txt" && echo ja || echo nein)"
	record "R7.4 Rueckfall nach Unterbrechung laeuft" 0 \
		"$(rc_of bash "$SELF_DIR/rollback.sh" --dry-run --no-color)"
	rm -rf "$MT2_STATE_DIR" "$MT2_BACKUP_ROOT"
fi

# ===========================================================================
group "R8 - Dateisystem ohne Unix-Rechte (Fehler 5)"
# ===========================================================================
record "R8.1 exfat speichert keine Rechte" 1 "$(rc_of mt2_fs_keeps_modes exfat)"
record "R8.2 vfat speichert keine Rechte" 1 "$(rc_of mt2_fs_keeps_modes vfat)"
record "R8.3 ntfs speichert keine Rechte" 1 "$(rc_of mt2_fs_keeps_modes ntfs)"
record "R8.4 ext4 speichert Rechte" 0 "$(rc_of mt2_fs_keeps_modes ext4)"
record "R8.5 btrfs speichert Rechte" 0 "$(rc_of mt2_fs_keeps_modes btrfs)"
FSOUT="$(mt2_fs_info "$ROOT")"
record "R8.6 Dateisystem der Paketwurzel ist bestimmbar" ja \
	"$(printf '%s' "$FSOUT" | grep -qE '^[a-z0-9]+ (exec|noexec)$' && echo ja || echo nein)"
record "R8.7 deploy-to-t7 prueft die Rechtefrage" ja \
	"$(grep -q 'mt2_fs_keeps_modes' "$SELF_DIR/deploy-to-t7.sh" && echo ja || echo nein)"
record "R8.8 deploy-to-t7 prueft symbolische Verknuepfungen" ja \
	"$(grep -q 'symbolische Verknuepfungen' "$SELF_DIR/deploy-to-t7.sh" && echo ja || echo nein)"
record "R8.9 Paket enthaelt keine symbolische Verknuepfung" 0 \
	"$(mt2_count_files "$ROOT" -type l ! -path '*/.git/*')"
# Jedes Skript muss ohne Ausfuehrungsbit startbar sein.
NOEXEC_OK=ja
for s in preflight.sh install.sh verify.sh rollback.sh selftest.sh regression.sh deploy-to-t7.sh fetch-packages.sh; do
	bash -n "$SELF_DIR/$s" 2>/dev/null || NOEXEC_OK=nein
done
record "R8.10 jedes Skript ist ueber bash startbar" ja "$NOEXEC_OK"
record "R8.11 Anleitungen nennen den Aufruf ueber bash" ja \
	"$(grep -q 'bash scripts/install.sh' "$ROOT/README.md" && echo ja || echo nein)"

# ===========================================================================
group "R9 - Samsung T7 fehlt"
# ===========================================================================
if [ "$(id -u)" -ne 0 ]; then
	skip "R9.1-R9.2 Samsung T7" "Die Tests brauchen Rootrechte."
elif lsblk -dno MODEL 2>/dev/null | grep -qi 't7'; then
	skip "R9.1-R9.2 Samsung T7" "Es ist ein Datentraeger mit 'T7' angeschlossen. Der Negativtest entfaellt."
else
	record "R9.1 fehlende Samsung T7 bricht ab" 4 \
		"$(rc_of bash "$SELF_DIR/deploy-to-t7.sh" --dry-run --no-color)"
	record "R9.2 Auflistung allein schreibt nichts" 0 \
		"$(rc_of bash "$SELF_DIR/deploy-to-t7.sh" --list --no-color)"
fi
record "R9.3 deploy-to-t7 formatiert nicht" ja \
	"$(grep -qE 'mkfs|parted|sgdisk|wipefs' "$SELF_DIR/deploy-to-t7.sh" && echo nein || echo ja)"
record "R9.4 deploy-to-t7 nutzt kein rsync --delete" ja \
	"$(grep -nE "^[[:space:]]*(RSYNC_OPTS|TAR_OPTS)=\(.*--delete|^[[:space:]]*rsync .*--delete" \
		"$SELF_DIR/deploy-to-t7.sh" >/dev/null 2>&1 && echo nein || echo ja)"

# ===========================================================================
group "R10 - Sperren des Installationsskripts"
# ===========================================================================
if [ "$(id -u)" -ne 0 ]; then
	skip "R10.1-R10.3 Sperren" "Die Tests brauchen Rootrechte."
else
	MODEL_NOW="$(mt2_model || true)"
	if [ "$MODEL_NOW" = "$MT2_SUPPORTED_MODEL" ]; then
		skip "R10.1 Modellsperre" "Dies ist das Zielgeraet. Der Negativtest entfaellt."
	else
		# V4.1: Die Modellsperre ist der erste Schritt. Sie greift auch dann,
		# wenn der Bauumgebung Werkzeuge wie update-grub fehlen.
		record "R10.1 falsches Modell bricht ab" 10 \
			"$(rc_of bash "$SELF_DIR/install.sh" --dry-run --skip-preflight --no-color)"
		record "R10.1b Modellsperre greift auch mit Vorpruefung" 10 \
			"$(rc_of bash "$SELF_DIR/install.sh" --dry-run --no-color)"
	fi
	record "R10.2 unbekannte Option bricht ab" 2 \
		"$(rc_of bash "$SELF_DIR/install.sh" --unbekannte-option)"
	# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
	record "R10.3 Konfliktpaket in der Liste wird erkannt" ja \
		"$(grep -q 'Das Paket .\$bad. steht in der Installationsliste' "$SELF_DIR/install.sh" && echo ja || echo nein)"
fi
record "R10.4 install.sh fordert grub-script-check" ja \
	"$(grep -q 'RC_TOOL' "$SELF_DIR/install.sh" && echo ja || echo nein)"
record "R10.5 install.sh schreibt nicht nach /etc/apt/sources.list.d" ja \
	"$(grep -q 'sources.list.d/maximus' "$SELF_DIR/install.sh" && echo nein || echo ja)"

# ===========================================================================
group "R11 - Fehlerklassen aus dem Code-Review"
# ===========================================================================
# Diese Pruefungen halten Fehlerklassen fern, die im Review von V4.1
# in den eigenen Korrekturen gefunden wurden.

# Klasse 1: 'set -e' beendet das Skript, wenn eine Funktion direkt vor
# 'case $?' einen Wert ungleich 0 liefert. Der Fehlerzweig wird nie erreicht.
BAD_CASE=0
for s in "$SELF_DIR"/*.sh "$SELF_DIR/lib"/*.sh; do
	case "$(basename "$s")" in regression.sh) continue ;; esac
	grep -q 'set -euo pipefail' "$s" || continue
	if grep -B1 'case "\$?"' "$s" 2>/dev/null | grep -qE '^[^#]*mt2_[a-z_]+( |$)'; then
		printf '         Befund in %s\n' "$(basename "$s")"
		BAD_CASE=1
	fi
done
record "R11.1 kein 'case \$?' direkt nach einem Funktionsaufruf" 0 "$BAD_CASE"
# Gegenprobe: Das Verhalten von 'set -e' wird gemessen, nicht angenommen.
SETE="$(bash -c 'set -euo pipefail; f(){ return 1; }; f; case "$?" in 1) echo erreicht ;; esac' 2>/dev/null || true)"
record "R11.2 Gegenprobe: 'set -e' bricht vor dem case ab" "" "$SETE"
SETE2="$(bash -c 'set -euo pipefail; f(){ return 1; }; r=0; f || r=$?; case "$r" in 1) echo erreicht ;; esac' 2>/dev/null || true)"
record "R11.3 die aufgefangene Form erreicht den Zweig" "erreicht" "$SETE2"

# Klasse 2: Ein Funktionsrueckgabewert wird in einer Zuweisung mit Pipe
# verschluckt. mt2_count_files faengt das ab.
record "R11.4 Zaehlfunktion liefert 0 bei fehlendem Verzeichnis" 0 \
	"$(mt2_count_files /gibt/es/nicht -name '*.deb')"
record "R11.5 Zaehlfunktion zaehlt vorhandene Dateien" 2 \
	"$(mkdir -p "$WORK/cnt" && : > "$WORK/cnt/a.deb" && : > "$WORK/cnt/b.deb" \
		&& mt2_count_files "$WORK/cnt" -name '*.deb')"

# Klasse 3: apt laesst die Rechte fallen und kann die Quelle nicht lesen.
record "R11.6 Sandkastenbetrieb wird bestimmt" ja \
	"$(grep -q 'MT2_APT_SANDBOX' "$SELF_DIR/lib/common.sh" && echo ja || echo nein)"
record "R11.7 Pin-Pruefung liest auch die Quellenliste" ja \
	"$(awk '/^mt2_apt_pin_verify/,/^}/' "$SELF_DIR/lib/common.sh" | grep -q 'MT2_APT_LIST' && echo ja || echo nein)"

# ===========================================================================
group "R12 - Befunde des unabhaengigen Code-Reviews"
# ===========================================================================

# 12.1 Anfuehrungszeichen in GRUB_CMDLINE_LINUX
GC="$WORK/grubcfg"; mkdir -p "$GC"
printf "GRUB_CMDLINE_LINUX='quiet splash'\n" > "$GC/single"
record "R12.1 einfache Anfuehrungszeichen werden entfernt" "quiet splash" \
	"$(mt2_grub_read_cmdline "$GC/single")"
printf 'GRUB_CMDLINE_LINUX="quiet splash"\n' > "$GC/double"
record "R12.2 doppelte Anfuehrungszeichen werden entfernt" "quiet splash" \
	"$(mt2_grub_read_cmdline "$GC/double")"

# 12.3 Maskierung der sed-Ersetzung
record "R12.3 kaufmaennisches Und wird maskiert" 'a\&b' "$(mt2_sed_escape_replacement 'a&b')"
printf 'GRUB_TEST=alt\n' > "$GC/amp"
printf 'GRUB_TEST=a&b\n' > "$GC/ampkey"
mt2_grub_set_keys "$GC/amp" "$GC/ampkey" >/dev/null
record "R12.4 Wert mit Und landet unveraendert in der Datei" "GRUB_TEST=a&b" \
	"$(grep GRUB_TEST "$GC/amp")"
printf 'GRUB_TEST=alt\n' > "$GC/pipe"
printf 'GRUB_TEST=x|y\n' > "$GC/pipekey"
mt2_grub_set_keys "$GC/pipe" "$GC/pipekey" >/dev/null 2>&1 || true
record "R12.5 Wert mit Trennzeichen landet unveraendert in der Datei" "GRUB_TEST=x|y" \
	"$(grep GRUB_TEST "$GC/pipe")"

# 12.6 Kodieren und Dekodieren muss umkehrbar sein
RT_OK=ja
for s in "/media/a/My T7" "/media/a/100% x" "/media/a/b#c?d" "/media/a/e[f]"; do
	[ "$(mt2_url_decode_path "$(mt2_url_encode_path "$s")")" = "$s" ] || RT_OK=nein
done
record "R12.6 Kodieren und Dekodieren ist umkehrbar" ja "$RT_OK"
record "R12.7 Dekodierung kennt mehr als nur das Leerzeichen" ja \
	"$(awk '/^mt2_url_decode_path/,/^}/' "$SELF_DIR/lib/common.sh" | grep -c '%' \
		| awk '{print ($1 >= 6) ? "ja" : "nein"}')"
record "R12.8 Dateipruefung nutzt die Dekodierung" ja \
	"$(grep -q 'mt2_apt_wanted_files' "$SELF_DIR/install.sh" \
		&& grep -q 'mt2_apt_wanted_files' "$SELF_DIR/preflight.sh" && echo ja || echo nein)"

# 12.9 Optionen ohne Wert melden verstaendlich
record "R12.9 rollback --backup ohne Wert meldet Code 2" 2 \
	"$(rc_of bash "$SELF_DIR/rollback.sh" --backup)"
BACKUP_MSG="$(bash "$SELF_DIR/rollback.sh" --backup 2>&1 || true)"
record "R12.10 die Meldung nennt die Option" ja \
	"$(printf '%s' "$BACKUP_MSG" | grep -q -- '--backup' && echo ja || echo nein)"
record "R12.11 deploy --target ohne Wert meldet Code 2" 2 \
	"$(rc_of bash "$SELF_DIR/deploy-to-t7.sh" --target)"
record "R12.12 fetch --out ohne Wert meldet Code 2" 2 \
	"$(rc_of bash "$SELF_DIR/fetch-packages.sh" --out)"
record "R12.13 verify --out ohne Wert meldet Code 2" 2 \
	"$(rc_of bash "$SELF_DIR/verify.sh" --out)"

# 12.14 Der Kernelschutz liegt nach der Freigabe
APPROVAL_LINE="$(grep -n 'log_step "Benutzerfreigabe"' "$SELF_DIR/install.sh" | cut -d: -f1)"
HOLD_LINE="$(grep -n 'log_step "Vorhandene Kernel schuetzen"' "$SELF_DIR/install.sh" | cut -d: -f1)"
record "R12.14 Kernelschutz liegt nach der Freigabe" ja \
	"$([ "${HOLD_LINE:-0}" -gt "${APPROVAL_LINE:-0}" ] && echo ja || echo nein)"

# 12.15 Zweiter Lauf wird abgefangen
record "R12.15 install.sh faengt einen zweiten Lauf ab" ja \
	"$(grep -q 'force-reinstall' "$SELF_DIR/install.sh" && echo ja || echo nein)"

# 12.16 Vorgabeeintrag wird ausdruecklich gesetzt
record "R12.16 install.sh setzt den Vorgabeeintrag" ja \
	"$(grep -q 'grub-set-default' "$SELF_DIR/install.sh" && echo ja || echo nein)"
record "R12.17 rollback.sh setzt den Vorgabeeintrag" ja \
	"$(grep -q 'grub-set-default' "$SELF_DIR/rollback.sh" && echo ja || echo nein)"
record "R12.18 rollback.sh hebt einen offenen Teststart auf" ja \
	"$(grep -q 'unset next_entry' "$SELF_DIR/rollback.sh" && echo ja || echo nein)"

# 12.19 Die Abnahmevorlage wird nicht ueberschrieben
# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
record "R12.19 verify.sh schreibt nicht auf die Vorlage" ja \
	"$(grep -q 'HARDWARE_TEST_REPORT-\$STAMP.md' "$SELF_DIR/verify.sh" && echo ja || echo nein)"
record "R12.20 verify.sh prueft das Modell vor der Kopie" ja \
	"$(awk '/Bericht schreiben/,0' "$SELF_DIR/verify.sh" | grep -q 'REPORT_MODEL' && echo ja || echo nein)"
record "R12.21 Tabellenzellen werden maskiert" ja \
	"$(grep -q 'md_cell' "$SELF_DIR/verify.sh" && echo ja || echo nein)"
record "R12.22 Maskierung ersetzt das Trennzeichen" 'a\|b' \
	"$(printf 'a|b' | sed -e 's/|/\\|/g')"

# 12.23 Harmlose ACPI-Meldungen werden nicht gewertet
record "R12.23 ACPI-BIOS-Meldungen sind ausgenommen" ja \
	"$(grep -q 'ACPI BIOS (Bug|Error)' "$SELF_DIR/verify.sh" && echo ja || echo nein)"
ACPI_PROBE="$(printf 'ACPI BIOS Bug: something\nnormal line\n' \
	| grep -E 'Kernel panic|BUG: |Oops|scheduling while atomic|NULL pointer dereference' \
	| grep -cvE 'ACPI BIOS (Bug|Error)|DEBUG|debug' || true)"
record "R12.24 Gegenprobe: ACPI-Meldung zaehlt nicht" 0 "$ACPI_PROBE"
OOPS_PROBE="$(printf 'kernel: BUG: scheduling while atomic\n' \
	| grep -E 'Kernel panic|BUG: |Oops|scheduling while atomic|NULL pointer dereference' \
	| grep -cvE 'ACPI BIOS (Bug|Error)|DEBUG|debug' || true)"
record "R12.25 Gegenprobe: echter Fehler zaehlt" 1 "$OOPS_PROBE"

# 12.26 selftest ruft Hilfsskripte ueber bash auf
# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
record "R12.26 selftest ruft grub-entry.sh ueber bash auf" ja \
	"$(grep -q 'bash "\$SELF_DIR/lib/grub-entry.sh"' "$SELF_DIR/selftest.sh" && echo ja || echo nein)"

# 12.27 Baupfad wird kodiert
# shellcheck disable=SC2016  # Das Muster ist absichtlich woertlich.
record "R12.27 fetch-packages kodiert den Baupfad" ja \
	"$(grep -q 'mt2_url_encode_path "\$OUT/t2linux"' "$SELF_DIR/fetch-packages.sh" && echo ja || echo nein)"

# 12.28 preflight benennt seine eigenen Arbeitsbereiche
record "R12.28 preflight nennt seine Schreibziele im Kopf" ja \
	"$(sed -n '1,25p' "$SELF_DIR/preflight.sh" | grep -q 'var/lib/maximus-t2' && echo ja || echo nein)"

# ===========================================================================
group "Ergebnis"
# ===========================================================================
RATE='0.0'
N_BEWERTET=$((N_PASS + N_FAIL))
if [ "$N_BEWERTET" -gt 0 ]; then
	RATE="$(awk -v p="$N_PASS" -v n="$N_BEWERTET" 'BEGIN{printf "%.1f", 100*p/n}')"
fi
log "Rohdaten:   $OUTFILE"
log "Tests:      $N_TOTAL"
log "Bestanden:  $N_PASS"
log "Fehler:     $N_FAIL"
log "Uebersprungen: $N_SKIP"
log "Bewertet:   $N_BEWERTET"
log "Erfolgsquote (bestanden / bewertet): ${RATE} Prozent"

if [ -n "${MT2_RESULT_COPY:-}" ]; then
	cp "$OUTFILE" "$MT2_RESULT_COPY" 2>/dev/null && log_info "Kopie: $MT2_RESULT_COPY"
fi

if [ "$N_FAIL" -gt 0 ]; then
	log_err "Die Regressionstests sind fehlgeschlagen."
	exit "$RC_HARDWARE"
fi
log_ok "Alle bewerteten Regressionstests sind bestanden."
exit "$RC_OK"
