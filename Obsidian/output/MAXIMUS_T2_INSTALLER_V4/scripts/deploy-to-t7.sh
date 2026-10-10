#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - Paket auf die Samsung T7 uebertragen
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
# Aufruf:  sudo ./deploy-to-t7.sh [OPTIONEN]
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
		--target)   shift; TARGET="${1:-}" ;;
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

log "MAXIMUS_T2_INSTALLER_V4 - Uebertragung auf die Samsung T7"
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

FSTYPE="$(findmnt -nro FSTYPE --target "$MOUNT" 2>/dev/null | head -1 || echo unbekannt)"
FREE_MIB="$(df -Pm "$MOUNT" 2>/dev/null | awk 'NR==2{print $4}')"
log_info "Dateisystem: $FSTYPE   freier Speicher: ${FREE_MIB:-0} MiB"
case "$FSTYPE" in
	ext4|exfat|xfs|btrfs) log_ok "Das Dateisystem '$FSTYPE' erhaelt die Ausfuehrungsrechte der Skripte." ;;
	vfat|ntfs|ntfs3|fuseblk)
		log_warn "Das Dateisystem '$FSTYPE' speichert keine Ausfuehrungsrechte."
		log_warn "Rufe die Skripte auf dem MacBook so auf: bash scripts/install.sh" ;;
	*) log_warn "Unbekanntes Dateisystem '$FSTYPE'. Pruefe die Rechte nach der Uebertragung." ;;
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
if [ -x "$SELF_DIR/selftest.sh" ]; then
	if "$SELF_DIR/selftest.sh" --no-color; then
		log_ok "Die Eigenpruefung des Pakets ist bestanden."
	else
		die "$RC_PKG_TREE" "Die Eigenpruefung des Pakets ist fehlgeschlagen." "Behebe die Befunde und starte erneut."
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

log ""
log_ok "PACKAGE_READY: Das Paket liegt auf der Samsung T7 unter $DEST."
log ""
log "Naechste Schritte auf dem MacBook:"
log "  1. Samsung T7 anschliessen."
log "  2. cd <Einhaengepunkt>/$FOLDER_NAME"
log "  3. sudo bash scripts/preflight.sh"
log "  4. sudo bash scripts/install.sh --dry-run"
exit "$RC_OK"
