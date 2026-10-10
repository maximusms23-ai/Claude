#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.2 - Paket auf die Samsung T7 uebertragen
#
# Ergebnis: Die Samsung T7 enthaelt danach den Ordner MAXIMUS_T2_INSTALLER_V4
# mit dem geprueften Installationspaket.
#
# Dieses Skript laeuft auf dem BAURECHNER.
#
# Sicherheitsregeln, die das Skript einhaelt:
#   1. Es formatiert nichts.
#   2. Es veraendert keine Partitionen.
#   3. Es loescht keine vorhandenen Dateien.
#   4. Es schreibt ausschliesslich in den Zielordner.
#   5. Es bricht ab, wenn die Samsung T7 nicht eindeutig erkannt wird.
#
# Aufruf:  sudo bash deploy-to-t7.sh [OPTIONEN]
#   --dry-run       Simuliert alles. Es wird nichts geschrieben.
#   --target PFAD   Nutzt diesen Einhaengepunkt. Die Pruefung laeuft trotzdem.
#   --list          Zeigt nur die erkannten Wechseldatentraeger.
#   --yes           Setzt die Freigabe voraus.
#   --no-color      Gibt keine Farbcodes aus.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

readonly FOLDER_NAME="MAXIMUS_T2_INSTALLER_V4"
readonly MIN_FREE_MIB=1024

DRY_RUN=0
LIST_ONLY=0
ASSUME_YES=0
TARGET=''

while [ "$#" -gt 0 ]; do
	case "$1" in
		--dry-run)  DRY_RUN=1 ;;
		--target)   mt2_opt_needs_value "$#" --target; TARGET="$2"; shift ;;
		--list)     LIST_ONLY=1 ;;
		--yes)      ASSUME_YES=1 ;;
		--no-color) NO_COLOR=1; export NO_COLOR ;;
		-h|--help)  sed -n '2,24p' "$0"; exit "$RC_OK" ;;
		*)          die "$RC_USAGE" "Unbekannte Option '$1'." "Rufe '$0 --help' auf." ;;
	esac
	shift
done

mt2_need_cmd lsblk
mt2_need_cmd find
# rsync ist bevorzugt. Fehlt es, nutzt das Skript tar.
COPY_TOOL='tar'
if command -v rsync >/dev/null 2>&1; then
	COPY_TOOL='rsync'
fi

log "MAXIMUS_T2_INSTALLER V$MT2_VERSION - Uebertragung auf die Samsung T7"
if [ "$DRY_RUN" -eq 1 ]; then
	log "Betriebsart: SIMULATION (es wird nichts geschrieben)"
fi

# ---------------------------------------------------------------------------
log_step "Wechseldatentraeger auflisten"
# ---------------------------------------------------------------------------
log "Alle erkannten Datentraeger:"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,VENDOR,MODEL,SERIAL,TRAN,RM 2>/dev/null | sed 's/^/  /'

if [ "$LIST_ONLY" -eq 1 ]; then
	log ""
	log_info "Es wurde nur aufgelistet. Es wurde nichts geschrieben."
	exit "$RC_OK"
fi

# ---------------------------------------------------------------------------
log_step "Samsung T7 eindeutig bestimmen"
# ---------------------------------------------------------------------------
# Suchkriterien: Modellbezeichnung enthaelt 'T7' UND der Hersteller ist Samsung
# ODER das Modell enthaelt 'Portable SSD T7'. Es wird kein Geraetename angenommen.
declare -a CANDIDATES=()
while IFS= read -r disk; do
	[ -n "$disk" ] || continue
	dev="/dev/$disk"
	model="$(lsblk -dno MODEL "$dev" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
	vendor="$(lsblk -dno VENDOR "$dev" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
	serial="$(lsblk -dno SERIAL "$dev" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
	tran="$(lsblk -dno TRAN "$dev" 2>/dev/null | sed 's/[[:space:]]*$//' || true)"
	idmodel=''
	if command -v udevadm >/dev/null 2>&1; then
		idmodel="$(udevadm info --query=property --name="$dev" 2>/dev/null \
			| sed -n 's/^ID_MODEL=//p' | head -1 || true)"
	fi
	haystack="$model $vendor $idmodel"
	if printf '%s' "$haystack" | grep -qiE 'T7' \
		&& printf '%s' "$haystack" | grep -qiE 'samsung|portable[_ ]ssd'; then
		CANDIDATES+=("$dev|$model|$vendor|$serial|$tran")
		log_info "Treffer: $dev  Modell='$model'  Hersteller='$vendor'  Seriennummer='$serial'  Anschluss='$tran'"
	fi
done < <(lsblk -dno NAME 2>/dev/null)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
	die "$RC_PKG_TREE" "Es wurde keine Samsung T7 gefunden." \
		"Schliesse die SSD an und starte erneut. Pruefe die Liste mit: $0 --list"
fi
if [ "${#CANDIDATES[@]}" -gt 1 ]; then
	log_err "Es wurden ${#CANDIDATES[@]} passende Datentraeger gefunden:"
	printf '         %s\n' "${CANDIDATES[@]}"
	die "$RC_PKG_TREE" "Die Samsung T7 ist nicht eindeutig bestimmbar." \
		"Trenne alle weiteren Samsung-Datentraeger ab und starte erneut."
fi

T7_DEV="$(printf '%s' "${CANDIDATES[0]}" | cut -d'|' -f1)"
T7_MODEL="$(printf '%s' "${CANDIDATES[0]}" | cut -d'|' -f2)"
T7_SERIAL="$(printf '%s' "${CANDIDATES[0]}" | cut -d'|' -f4)"
log_ok "Samsung T7 eindeutig bestimmt: $T7_DEV (Modell '$T7_MODEL', Seriennummer '$T7_SERIAL')"

# ---------------------------------------------------------------------------
log_step "Einhaengepunkt und Dateisystem pruefen"
# ---------------------------------------------------------------------------
if [ -n "$TARGET" ]; then
	MOUNT="$TARGET"
	log_warn "Der Einhaengepunkt wurde mit --target vorgegeben: $MOUNT"
else
	MOUNT="$(lsblk -nro MOUNTPOINT "$T7_DEV" 2>/dev/null | awk 'NF' | head -1 || true)"
fi
if [ -z "$MOUNT" ]; then
	die "$RC_PKG_TREE" "Die Samsung T7 ist nicht eingehaengt." \
		"Haenge die Partition ein, zum Beispiel ueber den Dateimanager. Starte danach erneut."
fi
[ -d "$MOUNT" ] || die "$RC_PKG_TREE" "Der Einhaengepunkt '$MOUNT' ist kein Verzeichnis." "Pruefe die Einbindung."

# Gegenprobe: Der Einhaengepunkt muss wirklich zur T7 gehoeren.
MOUNT_SRC="$(findmnt -nro SOURCE --target "$MOUNT" 2>/dev/null | head -1 || true)"
case "$MOUNT_SRC" in
	"$T7_DEV"*) log_ok "Der Einhaengepunkt '$MOUNT' liegt auf $MOUNT_SRC." ;;
	*) die "$RC_PKG_TREE" "Der Einhaengepunkt '$MOUNT' liegt auf '$MOUNT_SRC' und nicht auf $T7_DEV." \
		"Gib den richtigen Einhaengepunkt an oder haenge die T7 neu ein." ;;
esac

read -r FSTYPE FSEXEC <<EOF
$(mt2_fs_info "$MOUNT")
EOF
FREE_MIB="$(df -Pm "$MOUNT" 2>/dev/null | awk 'NR==2{print $4}')"
log_info "Dateisystem: $FSTYPE   Einhaengung: $FSEXEC   freier Speicher: ${FREE_MIB:-0} MiB"

# V4.1: exFAT ist bei der Samsung T7 die Werkseinstellung.
# exFAT speichert keine regulaeren Unix-Dateiberechtigungen.
# Das Ausfuehrungsbit der Skripte geht dabei verloren.
if mt2_fs_keeps_modes "$FSTYPE"; then
	log_ok "Das Dateisystem '$FSTYPE' speichert Unix-Rechte. Das Ausfuehrungsbit bleibt erhalten."
	MODES_KEPT=1
else
	log_warn "Das Dateisystem '$FSTYPE' speichert KEINE Unix-Rechte."
	log_warn "Das Ausfuehrungsbit der Skripte geht verloren. Das ist kein Fehler."
	log_warn "Rufe jedes Skript auf dem MacBook mit 'bash' auf."
	MODES_KEPT=0
fi
if [ "$FSEXEC" = "noexec" ]; then
	log_warn "Die Einhaengung traegt 'noexec'. Ein direkter Aufruf scheitert dort immer."
fi

# V4.1: exFAT, vfat und ntfs kennen keine symbolischen Verknuepfungen.
SYMLINKS="$(mt2_count_files "$ROOT" -type l ! -path '*/.git/*')"
if [ "$SYMLINKS" -eq 0 ]; then
	log_ok "Das Paket enthaelt keine symbolischen Verknuepfungen."
elif [ "$MODES_KEPT" -eq 0 ]; then
	log_err "Das Paket enthaelt $SYMLINKS symbolische Verknuepfungen:"
	find "$ROOT" -type l ! -path '*/.git/*' 2>/dev/null | head -5 | sed 's/^/         /'
	die "$RC_PKG_TREE" "Das Dateisystem '$FSTYPE' kann keine symbolischen Verknuepfungen speichern." \
		"Loese sie im Paket auf oder nutze ein Dateisystem wie ext4."
else
	log_info "Das Paket enthaelt $SYMLINKS symbolische Verknuepfungen. Das Dateisystem kann sie speichern."
fi

# V4.1: Ein Pfad mit Sonderzeichen wandert in eine apt-Quelle.
DEST_PREVIEW="$MOUNT/$FOLDER_NAME/packages"
if [ "$(mt2_url_encode_path "$DEST_PREVIEW")" != "$DEST_PREVIEW" ]; then
	log_warn "Der Zielpfad enthaelt Sonderzeichen: $DEST_PREVIEW"
	log_info "install.sh kodiert ihn fuer die apt-Quelle. Das ist geprueft."
else
	log_ok "Der Zielpfad enthaelt keine Sonderzeichen."
fi
case "$DEST_PREVIEW" in
	*$'\n'*|*$'\t'*)
		die "$RC_PKG_TREE" "Der Zielpfad enthaelt einen Zeilen- oder Tabulatorumbruch." \
			"Haenge die Samsung T7 unter einem einfachen Pfad ein." ;;
esac

NEED_MIB="$(du -sm "$ROOT" 2>/dev/null | cut -f1)"
if [ "${FREE_MIB:-0}" -lt $((NEED_MIB + MIN_FREE_MIB)) ]; then
	die "$RC_PKG_TREE" "Es sind ${FREE_MIB:-0} MiB frei. Benoetigt werden $((NEED_MIB + MIN_FREE_MIB)) MiB." \
		"Schaffe Speicherplatz auf der Samsung T7. Loesche dabei nichts ueber dieses Skript."
fi
log_ok "Der Speicherplatz reicht. Bedarf: ${NEED_MIB} MiB zuzueglich ${MIN_FREE_MIB} MiB Reserve."

DEST="$MOUNT/$FOLDER_NAME"
if [ -e "$DEST" ]; then
	log_warn "Der Zielordner '$DEST' ist vorhanden. Vorhandene Dateien werden ergaenzt oder ersetzt."
	log_warn "Es wird nichts ausserhalb von '$DEST' angetastet."
fi

# ---------------------------------------------------------------------------
log_step "Paket pruefen"
# ---------------------------------------------------------------------------
[ -f "$ROOT/packages/Packages" ] || \
	die "$RC_REPO" "packages/Packages fehlt." "Fuehre zuerst scripts/fetch-packages.sh aus."
[ -f "$ROOT/packages/SHA256SUMS.debs" ] || \
	die "$RC_CHECKSUM" "packages/SHA256SUMS.debs fehlt." "Fuehre zuerst scripts/fetch-packages.sh aus."
if mt2_verify_sha256 "$ROOT/packages/SHA256SUMS.debs" "$ROOT/packages"; then
	log_ok "Alle Paketdateien sind geprueft."
else
	die "$RC_CHECKSUM" "Mindestens eine Paketdatei ist beschaedigt." "Fuehre scripts/fetch-packages.sh erneut aus."
fi
if [ -f "$SELF_DIR/selftest.sh" ]; then
	if bash "$SELF_DIR/selftest.sh" --no-color; then
		log_ok "Die Eigenpruefung des Pakets ist bestanden."
	else
		die "$RC_PKG_TREE" "Die Eigenpruefung des Pakets ist fehlgeschlagen." "Behebe die Befunde und starte erneut."
	fi
fi
if [ -f "$SELF_DIR/regression.sh" ]; then
	if bash "$SELF_DIR/regression.sh" --no-color >/dev/null 2>&1; then
		log_ok "Die Regressionstests sind bestanden."
	else
		log_warn "Die Regressionstests melden Befunde. Einzelheiten: bash scripts/regression.sh"
	fi
fi

# ---------------------------------------------------------------------------
log_step "Freigabe"
# ---------------------------------------------------------------------------
log "Quelle: $ROOT"
log "Ziel:   $DEST"
log "Umfang: ${NEED_MIB} MiB"
if [ "$DRY_RUN" -eq 1 ]; then
	log_info "In der Simulation wird nichts geschrieben."
elif [ "$ASSUME_YES" -eq 1 ]; then
	log_warn "Die Freigabe wurde mit --yes vorausgesetzt."
else
	if ! mt2_confirm "Soll das Paket jetzt nach '$DEST' kopiert werden?"; then
		die "$RC_ABORT" "Die Freigabe wurde nicht erteilt." "Es wurde nichts geschrieben."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Uebertragen"
# ---------------------------------------------------------------------------
# Es wird nichts geloescht. rsync laeuft ohne --delete.
log_info "Kopierwerkzeug: $COPY_TOOL"
RSYNC_OPTS=(-rltD --no-perms --chmod=ugo=rwX --human-readable
	--exclude '.git' --exclude '*.part' --exclude 'SHA256SUMS.debs.previous')
TAR_OPTS=(--exclude=.git --exclude='*.part' --exclude='SHA256SUMS.debs.previous')

if [ "$DRY_RUN" -eq 1 ]; then
	printf '         [wuerde ausfuehren] mkdir -p %s\n' "$DEST"
	if [ "$COPY_TOOL" = "rsync" ]; then
		rsync -n "${RSYNC_OPTS[@]}" "$ROOT/" "$DEST/" 2>/dev/null | tail -5 | sed 's/^/         /' || true
	else
		printf '         [wuerde ausfuehren] tar -C %s -cf - . | tar -C %s -xf -\n' "$ROOT" "$DEST"
	fi
	printf '         [wuerde uebertragen] %s Dateien, %s MiB\n' \
		"$(mt2_count_files "$ROOT" -type f ! -path '*/.git/*')" "$NEED_MIB"
	log_info "Simulation beendet. Es wurde nichts geschrieben."
	exit "$RC_OK"
fi

mkdir -p "$DEST" || die "$RC_PKG_TREE" "Der Zielordner liess sich nicht anlegen." "Pruefe die Schreibrechte auf '$MOUNT'."
if [ "$COPY_TOOL" = "rsync" ]; then
	rsync "${RSYNC_OPTS[@]}" "$ROOT/" "$DEST/" \
		|| die "$RC_PKG_TREE" "Die Uebertragung schlug fehl." "Pruefe die Verbindung zur Samsung T7 und starte erneut."
else
	tar -C "$ROOT" "${TAR_OPTS[@]}" -cf - . | tar -C "$DEST" -xf - \
		|| die "$RC_PKG_TREE" "Die Uebertragung schlug fehl." "Pruefe die Verbindung zur Samsung T7 und starte erneut."
fi
sync
log_ok "Die Uebertragung ist abgeschlossen."

# ---------------------------------------------------------------------------
log_step "Uebertragung nachpruefen"
# ---------------------------------------------------------------------------
if ( cd "$DEST/packages" && sha256sum --quiet -c SHA256SUMS.debs ); then
	log_ok "Alle Paketdateien auf der Samsung T7 sind unverfaelscht."
else
	die "$RC_CHECKSUM" "Mindestens eine Datei auf der Samsung T7 ist beschaedigt." \
		"Starte die Uebertragung erneut. Pruefe das Kabel und den Anschluss."
fi
DEST_DEBS="$(mt2_count_files "$DEST/packages" -name '*.deb')"
SRC_DEBS="$(mt2_count_files "$ROOT/packages" -name '*.deb')"
if [ "$DEST_DEBS" -eq "$SRC_DEBS" ]; then
	log_ok "Es liegen $DEST_DEBS Paketdateien auf der Samsung T7."
else
	die "$RC_CHECKSUM" "Es wurden $DEST_DEBS von $SRC_DEBS Paketdateien uebertragen." "Starte die Uebertragung erneut."
fi

# V4.1: Pruefung, dass die Skripte auf dem Ziel wirklich startbar sind.
log_step "Startbarkeit auf dem Ziel pruefen"
if bash -n "$DEST/scripts/install.sh" 2>/dev/null; then
	log_ok "install.sh ist auf der Samsung T7 ueber 'bash' lesbar und syntaktisch gueltig."
else
	die "$RC_PKG_TREE" "install.sh ist auf der Samsung T7 nicht lesbar oder beschaedigt." "Starte die Uebertragung erneut."
fi
if [ -x "$DEST/scripts/install.sh" ]; then
	log_ok "Das Ausfuehrungsbit ist erhalten. Ein direkter Aufruf ist moeglich."
	CALL_PREFIX=''
else
	log_warn "Das Ausfuehrungsbit fehlt. Das ist auf '$FSTYPE' normal."
	log_warn "Rufe jedes Skript mit 'bash' auf."
	CALL_PREFIX='bash '
fi
if bash "$DEST/scripts/selftest.sh" --no-color --skip-debs >/dev/null 2>&1; then
	log_ok "Die Eigenpruefung laeuft auch von der Samsung T7."
else
	log_warn "Die Eigenpruefung von der Samsung T7 meldete Befunde. Pruefe sie auf dem MacBook."
fi

# Startblatt auf dem Datentraeger ablegen. Es nennt die richtigen Aufrufe.
{
	printf 'MAXIMUS_T2_INSTALLER V%s - Start auf dem MacBookPro16,1
' "$MT2_VERSION"
	printf '=========================================================

'
	printf 'Dateisystem dieses Datentraegers: %s
' "$FSTYPE"
	if [ -n "$CALL_PREFIX" ]; then
		printf 'Dieses Dateisystem speichert keine Ausfuehrungsrechte.
'
		printf 'Rufe deshalb JEDES Skript mit "bash" auf.

'
	else
		printf 'Dieses Dateisystem speichert Ausfuehrungsrechte.

'
	fi
	printf 'VOR dem ersten Neustart:
'
	printf '  1. USB-Tastatur anschliessen.
'
	printf '  2. recovery/GRUB-NOTSTART.txt ausdrucken.

'
	printf 'Arbeitsschritte:
'
	printf '  cd %s
' "$DEST"
	printf '  sudo %sscripts/preflight.sh
' "$CALL_PREFIX"
	printf '  sudo %sscripts/install.sh --dry-run
' "$CALL_PREFIX"
	printf '  sudo %sscripts/install.sh
' "$CALL_PREFIX"
	printf '  sudo reboot
'
	printf '  sudo %sscripts/verify.sh
' "$CALL_PREFIX"
	printf '  sudo get-apple-firmware

'
	printf 'Bei einem Fehler:
'
	printf '  sudo %sscripts/rollback.sh --dry-run
' "$CALL_PREFIX"
	printf '  sudo %sscripts/rollback.sh
' "$CALL_PREFIX"
	printf '
Erstellt am %s
' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$DEST/START-HIER.txt"
log_ok "Startblatt geschrieben: $DEST/START-HIER.txt"

log ""
log_ok "PACKAGE_READY: Das Paket liegt auf der Samsung T7 unter $DEST."
log ""
log "Naechste Schritte auf dem MacBook:"
log "  1. Samsung T7 anschliessen."
log "  2. cd $DEST"
log "  3. START-HIER.txt lesen."
log "  4. sudo ${CALL_PREFIX}scripts/preflight.sh"
log "  5. sudo ${CALL_PREFIX}scripts/install.sh --dry-run"
exit "$RC_OK"
