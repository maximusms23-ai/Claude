#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Abbild auf die Samsung T7 schreiben
#
# Ergebnis: Die bestaetigte Samsung T7 traegt das geprueefte Abbild.
#
# Grundsaetze:
#   1. Die T7 wird ueber Modell, Groesse und stabile Kennung erkannt.
#   2. Ein Geraetename wie /dev/sdb gilt NICHT als Erkennung.
#   3. Aus dem Namen 'Samsung T7' folgt KEINE Erlaubnis fuer andere Platten.
#   4. Ist die Zuordnung nicht eindeutig, haelt das Skript an.
#   5. Vor dem Schreiben wird die Kennung erneut geprueft.
#   6. Nach dem Schreiben werden Daten und Partitionen geprueft.
#
# Aufruf: sudo bash 04-write-to-t7.sh --iso ISO [--dry-run] [--device KENNUNG]

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SELF_DIR/.." && pwd)"
# shellcheck source=../iso-overlay/maximus/lib/common.sh
. "$ROOT/iso-overlay/maximus/lib/common.sh"

ISO=''; DRY_RUN=0; WANT_DEV=''
while [ "$#" -gt 0 ]; do
	case "$1" in
		--iso)     ISO="${2:?}"; shift ;;
		--device)  WANT_DEV="${2:?}"; shift ;;
		--dry-run) DRY_RUN=1 ;;
		--no-color) NO_COLOR=1; export NO_COLOR ;;
		-h|--help) sed -n '2,16p' "$0"; exit 0 ;;
		*) die "$RC_USAGE" "Unbekannte Option '$1'." "Erlaubt sind --iso, --device und --dry-run." ;;
	esac
	shift
done

MX_LOG=/var/log/maximus-t7-schreiben.log
mx_log_init
mx_require_root
for t in lsblk sha256sum dd blockdev; do mx_require_tool "$t"; done
[ -n "$ISO" ] && [ -f "$ISO" ] || die "$RC_USAGE" "--iso fehlt oder ist keine Datei." "Baue es zuerst mit 03-remaster-iso.sh."

log "============================================================"
log " MAXIMUS - Abbild auf die Samsung T7 schreiben"
log "============================================================"
[ "$DRY_RUN" -eq 1 ] && log_warn "Betriebsart SIMULATION. Es wird nichts geschrieben."

log_step "1. Abbild pruefen"
ISO_SIZE="$(stat -c%s "$ISO")"
ISO_SHA="$(sha256sum "$ISO" | cut -d' ' -f1)"
log_info "Datei:   $ISO"
log_info "Groesse: $(mx_human_size "$ISO_SIZE")"
log_info "SHA256:  $ISO_SHA"
if [ -f "$ISO.sha256" ]; then
	SOLL="$(cut -d' ' -f1 < "$ISO.sha256")"
	[ "$SOLL" = "$ISO_SHA" ] || die "$RC_CHECKSUM" "Das Abbild weicht von seiner Pruefsummendatei ab." \
		"Baue es neu. Es wird nichts geschrieben."
	log_ok "Die Pruefsumme stimmt mit $ISO.sha256 ueberein."
else
	log_warn "Es gibt keine Pruefsummendatei neben dem Abbild."
fi
if command -v xorriso >/dev/null 2>&1; then
	if xorriso -indev "$ISO" -report_system_area plain 2>/dev/null | grep -q 'APM partition name'; then
		log_ok "Das Abbild traegt eine Apple-Partition-Map."
	else
		die "$RC_CHECKSUM" "Dem Abbild fehlt die Apple-Partition-Map." \
			"Der Mac-Startmanager zeigt es dann moeglicherweise nicht. Baue es neu."
	fi
fi

log_step "2. Datentraeger suchen"
# Das laufende System darf niemals Ziel sein.
ROOTDEV="$(findmnt -no SOURCE / 2>/dev/null)"
ROOTDISK="$(lsblk -no PKNAME "$ROOTDEV" 2>/dev/null | head -1)"
[ -n "$ROOTDISK" ] && ROOTDISK="/dev/$ROOTDISK"
log_info "Systemplatte: ${ROOTDISK:-unbekannt} (ausgeschlossen)"

TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT
CAND="$TMPD/kandidaten.tsv"; : > "$CAND"
N=0
while read -r name type; do
	[ "$type" = "disk" ] || continue
	case "$name" in loop*|zram*|sr*|ram*|fd*) continue ;; esac
	dev="/dev/$name"
	[ -b "$dev" ] || continue
	[ "$dev" = "${ROOTDISK:-}" ] && { log_info "ausgeschlossen (Systemplatte): $dev"; continue; }
	facts="$(mx_disk_facts "$dev")"
	sid="$(printf '%s' "$facts" | cut -f5)"
	[ "$sid" = "KEINE" ] && { log_warn "ohne stabile Kennung, uebersprungen: $dev"; continue; }
	N=$((N + 1))
	printf '%s\t%s\n' "$N" "$facts" >> "$CAND"
done < <(lsblk -ndo NAME,TYPE)

[ "$N" -gt 0 ] || die "$RC_NO_TARGET" "Es ist kein Wechseldatentraeger mit stabiler Kennung sichtbar." \
	"Schliesse die Samsung T7 an. Das Skript waehlt keinen Ersatz."

log ""
log "Gefundene Datentraeger:"
while IFS="$(printf '\t')" read -r n dev size model serial sid; do
	t7hinweis=''
	case "$model" in *[Pp]ortable*SSD*|*T7*|*Samsung*) t7hinweis='  <- koennte die Samsung T7 sein' ;; esac
	log ""
	log "  [$n] $dev   $(mx_human_size "$size")$t7hinweis"
	log "      Modell:   $model"
	log "      Seriennr: $serial"
	log "      Kennung:  $sid"
	lsblk -nlo NAME,SIZE,FSTYPE,LABEL "$dev" 2>/dev/null | tail -n +2 \
		| while read -r l; do log "      Partition: /dev/$l"; done
done < "$CAND"
log ""
log_warn "Der Modellname allein ist KEINE Erlaubnis. Pruefe die Seriennummer."

log_step "3. Ziel bestaetigen"
if [ -n "$WANT_DEV" ]; then
	ROW="$(awk -F'\t' -v s="$WANT_DEV" '$6==s {print; exit}' "$CAND")"
	[ -n "$ROW" ] || die "$RC_NO_TARGET" "Die Kennung '$WANT_DEV' ist nicht in der Liste." \
		"Pruefe sie mit: ls -l /dev/disk/by-id/"
else
	log "Gib die Nummer des Ziels ein. 'ABBRUCH' beendet ohne Aenderung."
	printf 'Nummer: '
	IFS= read -r SEL || SEL=''
	[ "$SEL" = "ABBRUCH" ] && die "$RC_ABORT" "Abbruch durch Benutzer." "Es wurde nichts geaendert."
	case "$SEL" in ''|*[!0-9]*) die "$RC_USAGE" "Das ist keine Nummer." "Starte erneut." ;; esac
	ROW="$(awk -F'\t' -v n="$SEL" '$1==n {print; exit}' "$CAND")"
	[ -n "$ROW" ] || die "$RC_NO_TARGET" "Die Nummer steht nicht in der Liste." "Starte erneut."
fi
T_DEV="$(printf '%s' "$ROW" | cut -f2)"
T_SIZE="$(printf '%s' "$ROW" | cut -f3)"
T_MODEL="$(printf '%s' "$ROW" | cut -f4)"
T_SERIAL="$(printf '%s' "$ROW" | cut -f5)"
T_SID="$(printf '%s' "$ROW" | cut -f6)"

log ""
log "============================================================"
log " LOESCHUMFANG"
log "============================================================"
log "Geraet:   $T_DEV"
log "Modell:   $T_MODEL"
log "Seriennr: $T_SERIAL"
log "Kennung:  $T_SID"
log "Groesse:  $(mx_human_size "$T_SIZE")"
log ""
log "Geschrieben werden die ersten $(mx_human_size "$ISO_SIZE") des Geraets."
log "Die vorhandene Partitionstabelle wird dabei ueberschrieben."
log ""
log "Diese Partitionen und ihre Daten gehen verloren:"
if lsblk -nlo NAME,SIZE,FSTYPE,LABEL "$T_DEV" 2>/dev/null | tail -n +2 | grep -q .; then
	lsblk -nlo NAME,SIZE,FSTYPE,LABEL "$T_DEV" 2>/dev/null | tail -n +2 \
		| while read -r l; do log "  - /dev/$l"; done
else
	log "  (keine Partition erkennbar)"
fi
log "============================================================"

if [ "$T_SIZE" -lt "$ISO_SIZE" ]; then
	die "$RC_USAGE" "Das Geraet ist kleiner als das Abbild." "Nutze einen groesseren Datentraeger."
fi

TOKEN="$(printf '%s' "$T_SERIAL" | tail -c 9)"
[ -n "$TOKEN" ] && [ "$TOKEN" != "unbekannt" ] || TOKEN="$(basename "$T_SID" | tail -c 9)"
log ""
log "${C_B}Gib zur Freigabe genau dies ein:${C_0} $TOKEN"
printf 'Eingabe (oder ABBRUCH): '
IFS= read -r GOT || GOT=''
[ "$GOT" = "$TOKEN" ] || die "$RC_APPROVAL" "Die Freigabe fehlt oder stimmt nicht." "Es wurde nichts geschrieben."
log_ok "Freigabe erteilt."

log_step "4. Kennung unmittelbar vor dem Schreiben erneut pruefen"
NOW_DEV="$(readlink -f "$T_SID" 2>/dev/null)" || NOW_DEV=''
[ -n "$NOW_DEV" ] || die "$RC_ID_CHANGED" "Die Kennung zeigt auf kein Geraet mehr." "Starte erneut."
NOW_SERIAL="$(lsblk -ndo SERIAL "$NOW_DEV" 2>/dev/null | sed 's/[[:space:]]*$//')"
NOW_SIZE="$(lsblk -bndo SIZE "$NOW_DEV" 2>/dev/null)"
if [ "$NOW_SERIAL" != "$T_SERIAL" ] || [ "$NOW_SIZE" != "$T_SIZE" ]; then
	log_err "erwartet: '$T_SERIAL', $T_SIZE"
	log_err "gemessen: '$NOW_SERIAL', $NOW_SIZE"
	die "$RC_ID_CHANGED" "Das Geraet hinter der Kennung hat sich geaendert." "Es wurde nichts geschrieben."
fi
[ "$NOW_DEV" = "${ROOTDISK:-}" ] && die "$RC_TARGET_IS_MEDIUM" "Die Kennung zeigt auf die Systemplatte." "Abbruch."
log_ok "Die Kennung zeigt unveraendert auf $NOW_DEV."

log_step "5. Einhaengungen loesen"
while read -r part mp; do
	[ -n "$mp" ] || continue
	if [ "$DRY_RUN" -eq 1 ]; then
		log "         [wuerde aushaengen] /dev/$part von $mp"
	else
		umount "/dev/$part" 2>/dev/null && log_ok "ausgehaengt: /dev/$part" \
			|| log_warn "konnte nicht aushaengen: /dev/$part"
	fi
done < <(lsblk -nlo NAME,MOUNTPOINT "$NOW_DEV" 2>/dev/null | tail -n +2)

log_step "6. Schreiben"
if [ "$DRY_RUN" -eq 1 ]; then
	log "         [wuerde schreiben] dd if=$ISO of=$NOW_DEV bs=4M conv=fsync"
	log_ok "Simulation beendet. Es wurde nichts geschrieben."
	exit "$RC_OK"
fi
log_info "Das dauert je nach Anschluss einige Minuten."
if ! dd if="$ISO" of="$NOW_DEV" bs=4M conv=fsync status=progress; then
	die "$RC_INSTALL" "Das Schreiben schlug fehl." "Pruefe das Kabel und den Anschluss."
fi
sync; blockdev --flushbufs "$NOW_DEV" 2>/dev/null || true
log_ok "Das Abbild ist geschrieben."

log_step "7. Geschriebene Daten pruefen"
# Ein erfolgreicher Schreibbefehl allein genuegt nicht als Nachweis.
log_info "Es werden $(mx_human_size "$ISO_SIZE") zurueckgelesen und verglichen."
BACK_SHA="$(dd if="$NOW_DEV" bs=4M count=$(( (ISO_SIZE + 4194303) / 4194304 )) \
	iflag=fullblock status=none 2>/dev/null | head -c "$ISO_SIZE" | sha256sum | cut -d' ' -f1)"
log_info "Abbild:        $ISO_SHA"
log_info "Zurueckgelesen: $BACK_SHA"
if [ "$ISO_SHA" != "$BACK_SHA" ]; then
	die "$RC_CHECKSUM" "Die zurueckgelesenen Daten weichen vom Abbild ab." \
		"Das Medium ist NICHT startfaehig. Schreibe erneut."
fi
log_ok "Die zurueckgelesenen Daten stimmen Byte fuer Byte."

log_step "8. Partitionsstruktur pruefen"
partprobe "$NOW_DEV" 2>/dev/null || true
sleep 2
log "Struktur nach dem Schreiben:"
lsblk -no NAME,SIZE,FSTYPE,LABEL,PARTTYPENAME "$NOW_DEV" 2>/dev/null | sed 's/^/  /' | tee -a "$MX_LOG"
FEHLER=0
if lsblk -nlo FSTYPE "$NOW_DEV" 2>/dev/null | grep -qi 'iso9660'; then
	log_ok "Eine iso9660-Struktur ist erkennbar."
else
	log_warn "Es ist keine iso9660-Struktur erkennbar."
	FEHLER=$((FEHLER + 1))
fi
if lsblk -nlo FSTYPE "$NOW_DEV" 2>/dev/null | grep -qi 'vfat'; then
	log_ok "Die EFI-Partition (vfat) ist erkennbar."
else
	log_warn "Es ist keine vfat-Partition erkennbar."
	FEHLER=$((FEHLER + 1))
fi

log_step "9. Ergebnis"
if [ "$FEHLER" -gt 0 ]; then
	log_warn "Die Struktur weicht ab ($FEHLER Punkte). Pruefe das Medium von Hand."
	log_warn "Melde NICHT 'T7 vorbereitet', bevor das geklaert ist."
	exit "$RC_HARDWARE"
fi
log_ok "T7 VORBEREITET."
log ""
log "Geraet:   $NOW_DEV"
log "Kennung:  $T_SID"
log "Abbild:   $(basename "$ISO")"
log "SHA256:   $ISO_SHA"
log ""
log "Naechster Schritt: recovery/T2-STARTEINSTELLUNGEN.md lesen und umsetzen."
log "Danach am Mac mit gehaltener Wahltaste starten und 'EFI Boot' waehlen."
exit "$RC_OK"
