#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Assistent
#
# Ergebnis: Der Assistent bestimmt das Installationsziel, zeigt den
# Loeschumfang, holt die Freigabe und startet danach die Installation.
# Ohne Freigabe wird nichts geschrieben.
#
# Grundsaetze:
#   1. Das laufende Installationsmedium ist niemals Ziel.
#   2. Es wird keine Platte nach Groesse oder Nummer gewaehlt.
#   3. Nur eine stabile Kennung gilt als Ziel.
#   4. Die Kennung wird unmittelbar vor dem Schreiben erneut geprueft.
#   5. Bei unklarer Zuordnung haelt der Assistent an.
#
# Aufruf: sudo bash wizard.sh [--dry-run] [--no-color]

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"

DRY_RUN=0
while [ "$#" -gt 0 ]; do
	case "$1" in
		--dry-run)  DRY_RUN=1 ;;
		--no-color) NO_COLOR=1; export NO_COLOR ;;
		-h|--help)  sed -n '2,18p' "$0"; exit "$RC_OK" ;;
		*)          die "$RC_USAGE" "Unbekannte Option '$1'." "Erlaubt sind --dry-run und --no-color." ;;
	esac
	shift
done

MX_LOG=/var/log/maximus-t2-neuinstall.log
mx_log_init
mx_require_root

# ---------------------------------------------------------------------------
# Testnaht fuer den Prueflauf
# ---------------------------------------------------------------------------
# Doppelte Sperre, wie in MAXIMUS V4.2:
#   1. Auf der Kernelzeile muss maximus.test=1 stehen.
#   2. Auf dem Medium muss maximus/testantworten.txt liegen.
# Nur dann liest der Assistent die Antworten aus der Datei.
# JEDE Pruefung laeuft dabei unveraendert weiter: Medienausschluss,
# stabile Kennung, Freigabekennung und die erneute Pruefung vor dem
# Schreiben. Es wird nur die Eingabequelle ersetzt.
# Die Menueeintraege fuer die Installation setzen maximus.test NIEMALS.
MX_TEST=0
MX_ANSWERS=''
if grep -qw 'maximus.test=1' /proc/cmdline 2>/dev/null; then
	for d in /cdrom /opt/maximus /run/live/medium; do
		if [ -f "$d/testantworten.txt" ]; then MX_ANSWERS="$d/testantworten.txt"; break; fi
		if [ -f "$d/maximus/testantworten.txt" ]; then MX_ANSWERS="$d/maximus/testantworten.txt"; break; fi
	done
	if [ -n "$MX_ANSWERS" ]; then
		MX_TEST=1
		# Der Zaehler liegt in einer Datei, NICHT in einer Variablen.
		# Gemessen im Prueflauf: ask() laeuft in einer Befehlsersetzung.
		# Das ist eine Unterschale. Eine Variable darin geht verloren.
		# Jede Frage bekam deshalb dieselbe Zeile 1.
		MX_COUNTER="$(mktemp -t maximus-zaehler-XXXXXX)"
		printf '0\n' > "$MX_COUNTER"
	fi
fi

# mx_naechste_zeile - gibt die naechste Antwortzeile aus und zaehlt weiter.
mx_naechste_zeile() {
	local n
	n="$(cat "$MX_COUNTER" 2>/dev/null || echo 0)"
	n=$((n + 1))
	printf '%s\n' "$n" > "$MX_COUNTER"
	sed -n "${n}p" "$MX_ANSWERS"
	printf '%s' "$n" > "$MX_COUNTER.letzte"
}

# ask <frage> - liest eine Antwort. Im Prueflauf aus der Datei.
ask() {
	local a=''
	if [ "$MX_TEST" -eq 1 ]; then
		a="$(mx_naechste_zeile)"
		printf '%s[Prueflauf Zeile %s]%s %s\n' \
			"$C_Y" "$(cat "$MX_COUNTER" 2>/dev/null)" "$C_0" "$a" >&2
		printf '%s' "$a"
		return 0
	fi
	IFS= read -r a || a=''
	printf '%s' "$a"
}

# ask_secret <frage> - wie ask, aber ohne Anzeige
ask_secret() {
	local a=''
	if [ "$MX_TEST" -eq 1 ]; then
		a="$(mx_naechste_zeile)"
		printf '%s[Prueflauf Zeile %s]%s (verborgen)\n' \
			"$C_Y" "$(cat "$MX_COUNTER" 2>/dev/null)" "$C_0" >&2
		printf '%s' "$a"
		return 0
	fi
	IFS= read -rs a || a=''
	printf '\n' >&2
	printf '%s' "$a"
}
for t in lsblk findmnt blkid awk sed; do mx_require_tool "$t"; done

TMPD="$(mktemp -d -t maximus-wizard-XXXXXX)"
cleanup() { rm -rf "$TMPD"; [ -n "${MX_COUNTER:-}" ] && rm -f "$MX_COUNTER" "$MX_COUNTER.letzte"; }
trap cleanup EXIT

# mx_token_pruefen <erwartet> - verlangt die woertliche Eingabe.
# Auch im Prueflauf muss der Wert stimmen. Die Pruefung bleibt echt.
mx_token_pruefen() {
	local want="$1" got=''
	log ""
	log "${C_B}Gib zur Freigabe genau dies ein:${C_0} $want"
	printf 'Eingabe (oder ABBRUCH): '
	got="$(ask)"
	if [ "$got" = "ABBRUCH" ] || [ -z "$got" ]; then
		log_warn "Abbruch durch Benutzer."
		return 1
	fi
	if [ "$got" != "$want" ]; then
		log_err "Die Eingabe stimmt nicht. Erwartet war: $want"
		return 1
	fi
	log_ok "Die Freigabekennung stimmt."
	return 0
}

clear 2>/dev/null || true
log "============================================================"
log " MAXIMUS - Ubuntu mit T2-Unterstuetzung neu installieren"
log " Fassung $MX_VERSION"
log "============================================================"
if [ "$DRY_RUN" -eq 1 ]; then
	log_warn "Betriebsart SIMULATION. Es wird nichts geschrieben."
fi
if [ "$MX_TEST" -eq 1 ]; then
	log_warn "PRUEFLAUF. Die Antworten stammen aus $MX_ANSWERS."
	log_warn "Jede Sicherheitspruefung laeuft dabei unveraendert weiter."
fi

# ---------------------------------------------------------------------------
log_step "Schritt 1: Laufendes Installationsmedium bestimmen"
# ---------------------------------------------------------------------------
MEDIUM="$(mx_live_medium_disk 2>/dev/null)" || MEDIUM=''
if [ -n "$MEDIUM" ]; then
	MED_FACTS="$(mx_disk_facts "$MEDIUM")"
	MED_SIZE="$(printf '%s' "$MED_FACTS" | cut -f2)"
	MED_MODEL="$(printf '%s' "$MED_FACTS" | cut -f3)"
	log_ok "Medium: $MEDIUM ($MED_MODEL, $(mx_human_size "$MED_SIZE"))"
	log_info "Dieses Geraet ist von der Zielauswahl ausgeschlossen."
else
	log_warn "Das laufende Medium liess sich nicht bestimmen."
	log_warn "Der Assistent kann es dann nicht ausschliessen."
	die "$RC_TARGET_IS_MEDIUM" "Ohne bekanntes Medium ist keine sichere Zielauswahl moeglich." \
		"Starte vom Installationsmedium. Melde diesen Fall, wenn er bestehen bleibt."
fi

# ---------------------------------------------------------------------------
log_step "Schritt 2: Vorhandene Datentraeger und Partitionen ermitteln"
# ---------------------------------------------------------------------------
CAND="$TMPD/kandidaten.tsv"
: > "$CAND"
N=0
while read -r name type; do
	[ "$type" = "disk" ] || continue
	case "$name" in loop*|zram*|sr*|ram*|fd*) continue ;; esac
	dev="/dev/$name"
	[ -b "$dev" ] || continue
	# Das Medium und jedes Geraet darauf sind ausgeschlossen.
	if [ "$dev" = "$MEDIUM" ]; then
		log_info "ausgeschlossen (laufendes Medium): $dev"
		continue
	fi
	facts="$(mx_disk_facts "$dev")"
	sid="$(printf '%s' "$facts" | cut -f5)"
	if [ "$sid" = "KEINE" ]; then
		log_warn "uebersprungen: $dev hat keine stabile Kennung unter /dev/disk/by-id."
		log_warn "Ein Gerätename allein ist als Ziel nicht zulaessig."
		continue
	fi
	N=$((N + 1))
	printf '%s\t%s\n' "$N" "$facts" >> "$CAND"
done < <(lsblk -ndo NAME,TYPE)

if [ "$N" -eq 0 ]; then
	die "$RC_NO_TARGET" "Es ist kein Datentraeger mit stabiler Kennung als Ziel verfuegbar." \
		"Pruefe die Verkabelung. Der Assistent waehlt keinen Ersatz."
fi

log ""
log "Gefundene Datentraeger (ohne das laufende Medium):"
log ""
while IFS="$(printf '\t')" read -r n dev size model serial sid; do
	log "  [$n] $dev   $(mx_human_size "$size")"
	log "      Modell:   $model"
	log "      Seriennr: $serial"
	log "      Kennung:  $sid"
	# Partitionen und ihr Inhalt
	if lsblk -nlo NAME,SIZE,FSTYPE,LABEL,PARTLABEL "$dev" 2>/dev/null | tail -n +2 | grep -q .; then
		log "      Partitionen:"
		while read -r pn psize pfs plabel ppartlabel; do
			kind="unbekannt"
			case "$pfs" in
				apfs)      kind="macOS (APFS) - enthaelt moeglicherweise dein System und deine Daten" ;;
				hfsplus)   kind="macOS (HFS+) oder Wiederherstellung" ;;
				vfat)      kind="EFI-Startpartition oder FAT-Datenbereich" ;;
				ext4|ext3|btrfs|xfs) kind="Linux-Dateisystem" ;;
				swap)      kind="Linux-Auslagerung" ;;
				crypto_LUKS) kind="verschluesselt (LUKS)" ;;
				'')        kind="kein erkanntes Dateisystem" ;;
				*)         kind="$pfs" ;;
			esac
			log "        /dev/$pn  $psize  ${plabel:-${ppartlabel:-ohne Bezeichnung}}  -> $kind"
		done < <(lsblk -nlo NAME,SIZE,FSTYPE,LABEL,PARTLABEL "$dev" 2>/dev/null | tail -n +2)
	else
		log "      Partitionen: keine erkennbar"
	fi
	log ""
done < "$CAND"

# ---------------------------------------------------------------------------
log_step "Schritt 3: Ziel waehlen"
# ---------------------------------------------------------------------------
log "Gib die Nummer des Ziels ein. 'ABBRUCH' beendet ohne Aenderung."
printf 'Nummer: '
SEL="$(ask)"
[ "$SEL" = "ABBRUCH" ] && die "$RC_ABORT" "Abbruch durch Benutzer." "Es wurde nichts geaendert."
case "$SEL" in ''|*[!0-9]*) die "$RC_USAGE" "Das ist keine Nummer aus der Liste." "Starte den Assistenten erneut." ;; esac

ROW="$(awk -F'\t' -v n="$SEL" '$1==n {print; exit}' "$CAND")"
[ -n "$ROW" ] || die "$RC_NO_TARGET" "Die Nummer $SEL steht nicht in der Liste." "Starte den Assistenten erneut."

T_DEV="$(printf '%s' "$ROW"    | cut -f2)"
T_SIZE="$(printf '%s' "$ROW"   | cut -f3)"
T_MODEL="$(printf '%s' "$ROW"  | cut -f4)"
T_SERIAL="$(printf '%s' "$ROW" | cut -f5)"
T_SID="$(printf '%s' "$ROW"    | cut -f6)"

# Gegenprobe: Das Ziel darf unter keinen Umstaenden das Medium sein.
if [ "$(readlink -f "$T_SID")" = "$(readlink -f "$MEDIUM")" ]; then
	die "$RC_TARGET_IS_MEDIUM" "Das gewaehlte Ziel ist das laufende Installationsmedium." \
		"Das ist nicht zulaessig. Waehle ein anderes Geraet."
fi

log ""
log_ok "Gewaehlt: $T_DEV"
log "  Modell:   $T_MODEL"
log "  Seriennr: $T_SERIAL"
log "  Kennung:  $T_SID"
log "  Groesse:  $(mx_human_size "$T_SIZE")"

# ---------------------------------------------------------------------------
log_step "Schritt 4: Loeschumfang waehlen"
# ---------------------------------------------------------------------------
log "Zwei Betriebsarten stehen bereit:"
log ""
log "  [1] GANZE PLATTE neu aufteilen."
log "      Alle Partitionen auf $T_DEV werden geloescht."
log "      Diese Betriebsart laeuft nach der Freigabe selbsttaetig durch."
log ""
log "  [2] NUR EINE VORHANDENE PARTITION nutzen."
log "      Die anderen Partitionen bleiben erhalten, auch macOS."
log "      Diese Betriebsart fuehrt dich durch die Partitionswahl des"
log "      Installers. Sie laeuft nicht selbsttaetig durch."
log "      Grund: Eine selbsttaetige Wahl neben einem vorhandenen macOS"
log "      waere zu gefaehrlich. Das Projekt t2linux verlangt hier"
log "      ausdruecklich die Partitionswahl von Hand."
log ""
printf 'Betriebsart (1 oder 2, oder ABBRUCH): '
MODE="$(ask)"
[ "$MODE" = "ABBRUCH" ] && die "$RC_ABORT" "Abbruch durch Benutzer." "Es wurde nichts geaendert."
case "$MODE" in
	1|2) ;;
	*) die "$RC_USAGE" "Erlaubt sind nur 1 und 2." "Starte den Assistenten erneut." ;;
esac

log ""
log "============================================================"
log " LOESCHUMFANG"
log "============================================================"
if [ "$MODE" = "1" ]; then
	log "Geloescht wird: ALLES auf $T_DEV ($T_SID)"
	log ""
	log "Diese Partitionen und ihre Daten gehen verloren:"
	if lsblk -nlo NAME,SIZE,FSTYPE,LABEL "$T_DEV" 2>/dev/null | tail -n +2 | grep -q .; then
		lsblk -nlo NAME,SIZE,FSTYPE,LABEL "$T_DEV" 2>/dev/null | tail -n +2 \
			| while read -r l; do log "  - /dev/$l"; done
	else
		log "  (keine Partition erkennbar, die Platte ist leer oder unpartitioniert)"
	fi
	log ""
	log "Erhalten bleibt: nichts auf diesem Geraet."
	log "Andere Geraete werden nicht angefasst."
else
	log "Zu nutzende Partition: du waehlst sie im Installer."
	log "Erhalten bleiben: alle anderen Partitionen auf $T_DEV."
	log "Andere Geraete werden nicht angefasst."
fi
log "============================================================"

# Sonderfall macOS: Das Projekt t2linux warnt ausdruecklich davor, dass eine
# selbsttaetige Aufteilung macOS mit entfernt. Deshalb eine eigene Freigabe.
if [ "$MODE" = "1" ]; then
	MACOS_FS="$(lsblk -nlo FSTYPE "$T_DEV" 2>/dev/null | grep -cE '^(apfs|hfsplus)$')"
	if [ "${MACOS_FS:-0}" -gt 0 ]; then
		log ""
		log_warn "ACHTUNG: Auf $T_DEV liegen $MACOS_FS Partitionen mit macOS-Dateisystem."
		log_warn "Betriebsart 1 loescht macOS vollstaendig."
		log_warn "Danach ist auch die Apple-Firmware fuer WLAN und Bluetooth weg."
		log_warn "Touch ID braucht meist eine vorhandene macOS-Installation."
		log_warn "Sichere die Firmware VORHER. Siehe firmware/ANLEITUNG.md."
		log_warn "Willst du macOS behalten, dann brich ab und waehle Betriebsart 2."
		if ! mx_token_pruefen "MACOS-LOESCHEN"; then
			die "$RC_ABORT" "Abbruch. macOS bleibt erhalten." \
				"Waehle Betriebsart 2, um eine vorhandene Partition zu nutzen."
		fi
	else
		log_ok "Auf dem Ziel liegt kein macOS-Dateisystem."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Schritt 5: Schutz vor einer zweiten Loeschung"
# ---------------------------------------------------------------------------
# Eine fertige MAXIMUS-Installation auf dem Ziel wird erkannt.
# Ein erneuter Start vom Medium soll nicht versehentlich erneut loeschen.
ALREADY=0
MPROBE="$TMPD/probe"
mkdir -p "$MPROBE"
while read -r pn pfs; do
	case "$pfs" in ext4|ext3|btrfs|xfs) ;; *) continue ;; esac
	if mount -o ro,noexec,nosuid "/dev/$pn" "$MPROBE" 2>/dev/null; then
		if [ -f "$MPROBE/var/lib/maximus-t2/neuinstall-fertig" ]; then
			ALREADY=1
			log_warn "Auf /dev/$pn liegt bereits eine fertige MAXIMUS-Installation:"
			sed 's/^/           /' "$MPROBE/var/lib/maximus-t2/neuinstall-fertig" 2>/dev/null | head -5
		fi
		umount "$MPROBE" 2>/dev/null || true
	fi
done < <(lsblk -nlo NAME,FSTYPE "$T_DEV" 2>/dev/null | tail -n +2)

if [ "$ALREADY" -eq 1 ]; then
	log ""
	log_warn "Das Ziel traegt schon eine fertige Installation."
	log_warn "Eine zweite Installation loescht sie."
	if ! mx_token_pruefen "ERNEUT-INSTALLIEREN"; then
		die "$RC_ABORT" "Abbruch. Die vorhandene Installation bleibt erhalten." \
			"Starte ohne die Option 'neu installieren', um das System zu nutzen."
	fi
else
	log_ok "Auf dem Ziel liegt keine fertige MAXIMUS-Installation."
fi

# ---------------------------------------------------------------------------
log_step "Schritt 6: Freigabe"
# ---------------------------------------------------------------------------
# Die Freigabe verlangt einen Teil der stabilen Kennung.
# Ein blosses 'ja' genuegt nicht.
TOKEN="$(basename "$T_SID")"
TOKEN="${TOKEN##*-}"
TOKEN="$(printf '%s' "$TOKEN" | tail -c 9)"
[ -n "$TOKEN" ] || TOKEN="$(printf '%s' "$T_SERIAL" | tail -c 9)"
[ -n "$TOKEN" ] || die "$RC_APPROVAL" "Es liess sich keine Freigabekennung bilden." \
	"Ohne eindeutige Kennung wird nicht installiert."

log "Ziel:        $T_DEV"
log "Kennung:     $T_SID"
log "Betriebsart: $([ "$MODE" = 1 ] && echo 'ganze Platte loeschen' || echo 'eine Partition nutzen')"
if ! mx_token_pruefen "$TOKEN"; then
	die "$RC_APPROVAL" "Die Freigabe fehlt oder stimmt nicht." "Es wurde nichts geaendert."
fi
log_ok "Freigabe erteilt."

# ---------------------------------------------------------------------------
log_step "Schritt 7: Zugangsdaten einmal abfragen"
# ---------------------------------------------------------------------------
# Es gibt kein fest eingebautes Passwort. Nichts davon wird protokolliert.
printf 'Vollstaendiger Name: '; U_FULL="$(ask)"
[ -n "$U_FULL" ] || U_FULL="MAXIMUS Benutzer"
while :; do
	printf 'Benutzername (klein, ohne Leerzeichen): '; U_NAME="$(ask)"
	case "$U_NAME" in
		''|*[!a-z0-9_-]*) log_err "Erlaubt sind nur a-z, 0-9, Bindestrich und Unterstrich." ;;
		[0-9]*) log_err "Der Name darf nicht mit einer Ziffer beginnen." ;;
		*) break ;;
	esac
done
printf 'Rechnername [macbook-t2]: '; U_HOST="$(ask)"
[ -n "$U_HOST" ] || U_HOST="macbook-t2"

while :; do
	printf 'Passwort: '; U_PW1="$(ask_secret)"
	printf 'Passwort wiederholen: '; U_PW2="$(ask_secret)"
	if [ -z "$U_PW1" ]; then log_err "Ein leeres Passwort ist nicht zulaessig."; continue; fi
	if [ "${#U_PW1}" -lt 8 ]; then log_err "Das Passwort braucht mindestens 8 Zeichen."; continue; fi
	if [ "$U_PW1" != "$U_PW2" ]; then log_err "Die Eingaben stimmen nicht ueberein."; continue; fi
	break
done
log_ok "Zugangsdaten erfasst. Das Passwort wird nicht protokolliert."

# ---------------------------------------------------------------------------
log_step "Schritt 8: Stabile Kennung erneut pruefen"
# ---------------------------------------------------------------------------
# Zwischen Auswahl und Schreiben kann sich die Geraetezuordnung aendern.
NOW_DEV="$(readlink -f "$T_SID" 2>/dev/null)" || NOW_DEV=''
if [ -z "$NOW_DEV" ]; then
	die "$RC_ID_CHANGED" "Die Kennung $T_SID zeigt auf kein Geraet mehr." \
		"Der Assistent waehlt keinen Ersatz. Starte erneut."
fi
NOW_SERIAL="$(lsblk -ndo SERIAL "$NOW_DEV" 2>/dev/null | sed 's/[[:space:]]*$//')"
NOW_SIZE="$(lsblk -bndo SIZE "$NOW_DEV" 2>/dev/null)"
if [ "$NOW_SERIAL" != "$T_SERIAL" ] || [ "$NOW_SIZE" != "$T_SIZE" ]; then
	log_err "erwartet: Seriennr '$T_SERIAL', Groesse $T_SIZE"
	log_err "gemessen: Seriennr '$NOW_SERIAL', Groesse $NOW_SIZE"
	die "$RC_ID_CHANGED" "Das Geraet hinter der Kennung hat sich geaendert." \
		"Der Assistent bricht ab. Starte erneut und bestaetige neu."
fi
if [ "$(readlink -f "$T_SID")" = "$(readlink -f "$MEDIUM")" ]; then
	die "$RC_TARGET_IS_MEDIUM" "Die Kennung zeigt jetzt auf das laufende Medium." \
		"Der Assistent bricht ab."
fi
log_ok "Die Kennung zeigt unveraendert auf $NOW_DEV."

# ---------------------------------------------------------------------------
log_step "Schritt 9: Preseed zur Laufzeit erzeugen"
# ---------------------------------------------------------------------------
# Das Passwort wandert in eine Datei mit Modus 0600. Es steht nie in einer
# Befehlszeile und nie im Protokoll.
PASSFILE="$TMPD/pw"
umask 077
printf '%s' "$U_PW1" > "$PASSFILE"

SEED="$TMPD/laufzeit.seed"
if [ "$MODE" = "2" ]; then
	# Betriebsart 2 nutzt ubiquity mit Grafik. Dafuer wird die Preseed
	# gebraucht. Betriebsart 1 braucht sie nicht, siehe Schritt 10.
	{
		printf 'd-i debian-installer/locale string de_DE.UTF-8\n'
		printf 'd-i keyboard-configuration/xkb-keymap select de\n'
		printf 'd-i keyboard-configuration/layoutcode string de\n'
		printf 'd-i time/zone string Europe/Berlin\n'
		printf 'd-i clock-setup/utc boolean true\n'
		printf 'd-i netcfg/get_hostname string %s\n' "$U_HOST"
		printf 'd-i netcfg/hostname string %s\n' "$U_HOST"
		printf 'd-i passwd/user-fullname string %s\n' "$U_FULL"
		printf 'd-i passwd/username string %s\n' "$U_NAME"
		printf 'd-i passwd/user-password password %s\n' "$U_PW1"
		printf 'd-i passwd/user-password-again password %s\n' "$U_PW1"
		printf 'd-i user-setup/allow-password-weak boolean false\n'
		printf 'd-i user-setup/encrypt-home boolean false\n'
		printf 'd-i passwd/auto-login boolean false\n'
		printf 'ubiquity ubiquity/download_updates boolean false\n'
		printf 'ubiquity ubiquity/use_nonfree boolean false\n'
		printf 'ubiquity ubiquity/reboot boolean false\n'
		printf 'ubiquity ubiquity/poweroff boolean false\n'
		printf 'd-i grub-installer/only_debian boolean true\n'
		printf 'd-i grub-installer/bootdev string %s\n' "$NOW_DEV"
		printf 'ubiquity ubiquity/success_command string bash /opt/maximus/postinstall.sh %s\n' "$T_SID"
		printf 'ubiquity ubiquity/failure_command string bash /opt/maximus/onfailure.sh\n'
	} > "$SEED"
	log_ok "Laufzeit-Preseed erzeugt: $(grep -c . "$SEED") Zeilen (nicht auf dem Medium)"
else
	log_info "Betriebsart 1 braucht keine Preseed. Alle Werte werden unmittelbar gesetzt."
fi
umask 022
log_info "Bestaetigte Kennung: $T_SID"
log_info "Aufgeloester Pfad:   $NOW_DEV"
log_info "Sprache de_DE.UTF-8, Tastatur de, Zeitzone Europe/Berlin, Rechner $U_HOST"

if [ "$DRY_RUN" -eq 1 ]; then
	log_step "Simulation beendet"
	log_ok "Es wurde nichts geschrieben."
	if [ -f "$SEED" ]; then
		log "Die erzeugte Preseed ohne Passwortzeilen:"
		grep -v 'password' "$SEED" | sed 's/^/         /'
	fi
	log "Geplante Aufteilung von $NOW_DEV:"
	bash "$SELF_DIR/install-direct.sh" --device "$NOW_DEV" --user "$U_NAME" \
		--fullname "$U_FULL" --host "$U_HOST" --passfile "$PASSFILE" --dry-run
	exit "$RC_OK"
fi

# ---------------------------------------------------------------------------
log_step "Schritt 10: Installation starten"
# ---------------------------------------------------------------------------
if [ "$MODE" = "2" ] && [ -f "$SEED" ]; then
	mx_require_tool debconf-set-selections
	debconf-set-selections "$SEED" \
		|| die "$RC_INSTALL" "Die Preseed liess sich nicht in debconf laden." "Pruefe $MX_LOG."
	shred -u "$SEED" 2>/dev/null || rm -f "$SEED"
	log_ok "Preseed geladen. Die Passwortzeilen sind geloescht."
fi
U_PW1=''; U_PW2=''

if [ "$MODE" = "1" ]; then
	# Gemessen: ubiquitys Frontend 'noninteractive' kann keine gefuehrte
	# Partitionierung. Seine Klasse PageNoninteractive kennt die Methoden
	# set_autopartition_options und get_autopartition_choice nicht.
	# Im Prueflauf endete ubiquity in einer Schleife mit
	# "Kein Root-Dateisystem: Es wurde kein Root-Dateisystem festgelegt."
	# Deshalb teilt dieser Weg die Platte selbst auf und packt dasselbe
	# Live-Abbild aus, das ubiquity sonst kopiert.
	log_info "Betriebsart 1: Installation ohne Grafik und ohne Routinefragen."
	log_info "Quelle ist das Live-Abbild auf dem Medium. Es wird nichts geladen."
	log ""
	RC=0
	bash "$SELF_DIR/install-direct.sh" --device "$NOW_DEV" --user "$U_NAME" \
		--fullname "$U_FULL" --host "$U_HOST" --passfile "$PASSFILE" || RC=$?
	shred -u "$PASSFILE" 2>/dev/null || rm -f "$PASSFILE"
	if [ "$RC" -ne 0 ]; then
		log_err "Die Installation endete mit Rueckgabecode $RC."
		bash "$SELF_DIR/onfailure.sh" || true
		die "$RC_INSTALL" "Die Installation ist unvollstaendig." \
			"Lies $MX_LOG. Naechster Schritt: recovery/WIEDERHERSTELLUNG.md auf dem Medium."
	fi
	log_ok "Das Betriebssystem ist installiert."

	# Nachbereitung mit eingehaengtem Ziel.
	log ""
	RC2=0
	bash "$SELF_DIR/postinstall.sh" "$T_SID" || RC2=$?
	[ "$RC2" -eq 0 ] || log_warn "Die Nachbereitung meldete Rueckgabecode $RC2."

	log_step "Ziel wieder aushaengen"
	sync
	for d in /target/sys/firmware/efi/efivars /target/run /target/sys /target/proc \
	         /target/dev/pts /target/dev /target/boot/efi /target; do
		umount -l "$d" 2>/dev/null || true
	done
	log_ok "Das Ziel ist ausgehaengt. Die Daten sind geschrieben."
else
	log_info "Betriebsart 2: Der Installer startet mit Partitionswahl von Hand."
	log_info "Waehle dort genau die Partition, die du eben bestaetigt hast."
	log_info "Mounte die EFI-Partition auf /boot/efi und deine Partition auf /."
	log ""
	if command -v ubiquity >/dev/null 2>&1; then
		RC=0
		ubiquity 2>&1 | tee -a "$MX_LOG" || RC="${PIPESTATUS[0]}"
		[ "$RC" -eq 0 ] || die "$RC_INSTALL" "Der Installer endete mit Rueckgabecode $RC." \
			"Lies $MX_LOG."
	else
		die "$RC_TOOL" "ubiquity ist nicht auffindbar." "Pruefe das Live-System."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Schritt 11: Ergebnis"
# ---------------------------------------------------------------------------
log_ok "Die Installation ist abgeschlossen."
log ""
log "Naechste Schritte:"
log "  1. Fahre das Geraet herunter."
log "  2. Zieh das Installationsmedium ab."
log "  3. Starte mit gehaltener Wahltaste und waehle 'EFI Boot'."
log "  4. Nach dem ersten Start erscheint der Funktionsbericht."
log ""
log "Das Protokoll liegt in $MX_LOG."
exit "$RC_OK"
