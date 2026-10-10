#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.2 - T2-Kernel und Treiber installieren
#
# Ergebnis: Das Zielgeraet erhaelt den T2-Kernel, die T2-Treiberpakete und die
# passenden Konfigurationsdateien. Die vorhandenen Ubuntu-Kernel bleiben
# unveraendert und geschuetzt.
#
# Aufruf:  sudo bash install.sh [OPTIONEN]
#   --dry-run          Simuliert alle Schritte. Es wird nichts geaendert.
#   --yes              Setzt die Freigabe voraus. Fuer unbeaufsichtigte Laeufe.
#   --skip-preflight   Ueberspringt die Vorpruefung. Nur fuer Wiederholungen.
#   --force-reinstall  Laeuft, obwohl schon eine Installation aufgezeichnet ist.
#   --no-color         Gibt keine Farbcodes aus.
#
# Das Skript installiert kein Ubuntu neu. Es veraendert weder EFI noch NVRAM
# noch Partitionen. Es laedt keine Pakete aus dem Netz.
#
# V4.2: Mit --dry-run wird keine Datei ausserhalb eines temporaeren
# Verzeichnisses angelegt oder geaendert. Das Skript weist das selbst nach:
# Es nimmt vor und nach dem Lauf eine Momentaufnahme von /etc, /boot und
# den eigenen Verzeichnissen und vergleicht sie.
#
# Rufe das Skript mit 'bash' auf. Auf exFAT fehlt das Ausfuehrungsbit.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
# shellcheck source=lib/grub-config.sh
. "$SELF_DIR/lib/grub-config.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

DRY_RUN=0
ASSUME_YES=0
SKIP_PREFLIGHT=0
FORCE_REINSTALL=0
for arg in "$@"; do
	case "$arg" in
		--dry-run)         DRY_RUN=1 ;;
		--yes)             ASSUME_YES=1 ;;
		--skip-preflight)  SKIP_PREFLIGHT=1 ;;
		--force-reinstall) FORCE_REINSTALL=1 ;;
		--no-color)       NO_COLOR=1; export NO_COLOR ;;
		-h|--help)        sed -n '2,20p' "$0"; exit "$RC_OK" ;;
		*)                die "$RC_USAGE" "Unbekannte Option '$arg'." "Rufe 'bash $0 --help' auf." ;;
	esac
done

mt2_require_root "$@"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$MT2_BACKUP_ROOT/$STAMP"

if [ "$DRY_RUN" -eq 1 ]; then
	MODE_TEXT="SIMULATION (es wird nichts geaendert)"
else
	MODE_TEXT="ECHTE INSTALLATION"
	mt2_start_log install
fi

log "MAXIMUS_T2_INSTALLER V$MT2_VERSION - Installation"
log "Betriebsart: $MODE_TEXT"
log "Paketwurzel: $ROOT"
log "Zeitpunkt:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# write_file: Schreibt eine Datei. In der Simulation wird nur das Ziel genannt.
# Aufruf: write_file <Quelle> <Ziel> [anhaengen]
write_file() {
	local src="$1" dst="$2" append="${3:-0}"
	[ -f "$src" ] || die "$RC_PKG_TREE" "Quelldatei '$src' fehlt." "Pruefe die Vollstaendigkeit des Installationspakets."
	if [ "$DRY_RUN" -eq 1 ]; then
		if [ "$append" = "1" ]; then
			printf '         [wuerde anhaengen] %s -> %s\n' "${src#"$ROOT"/}" "$dst"
		else
			printf '         [wuerde schreiben] %s -> %s\n' "${src#"$ROOT"/}" "$dst"
		fi
		return 0
	fi
	mkdir -p "$(dirname "$dst")"
	if [ "$append" = "1" ]; then
		if ! grep -qF "MAXIMUS_T2_INSTALLER" "$dst" 2>/dev/null; then
			cat "$src" >> "$dst"
			log_ok "angehaengt: $dst"
			printf 'append\t%s\n' "$dst" >> "$MT2_STATE_DIR/files-written.txt"
		else
			log_info "bereits vorhanden, uebersprungen: $dst"
		fi
	else
		# Hatte die Datei vorher keinen Inhalt, merkt sich rollback.sh das.
		if [ -e "$dst" ]; then
			printf 'replace\t%s\n' "$dst" >> "$MT2_STATE_DIR/files-written.txt"
		else
			printf 'create\t%s\n' "$dst" >> "$MT2_STATE_DIR/files-written.txt"
		fi
		install -m 0644 "$src" "$dst"
		log_ok "geschrieben: $dst"
	fi
}

# ---------------------------------------------------------------------------
# V4.2: Pflicht- und Wahlsicherungen
# ---------------------------------------------------------------------------
# Gemessen in V4.1: 16 Kopierbefehle endeten auf '|| true'. Eine
# fehlgeschlagene Kopie von /etc/default/grub blieb unbemerkt. Das Siegel
# bewies nur Selbstkonsistenz, nicht Vollstaendigkeit.
#
# Regel in V4.2: Eine vorhandene Quelle MUSS erfolgreich kopiert werden.
# Nur eine FEHLENDE Quelle darf uebersprungen werden, und nur bei 'wahl'.
# Format je Zeile: <quellpfad>|<zielname>
readonly MT2_BACKUP_REQUIRED="/etc/default/grub|etc-default-grub
/boot/grub/grub.cfg|grub.cfg"

readonly MT2_BACKUP_OPTIONAL="/etc/apt/sources.list|sources.list
/etc/apt/sources.list.d|sources.list.d
/etc/modprobe.d|modprobe.d
/etc/modules-load.d|modules-load.d
/etc/initramfs-tools/modules|initramfs-modules
/etc/t2fand.conf|t2fand.conf
/etc/systemd/logind.conf.d|logind.conf.d
/etc/NetworkManager/conf.d|NetworkManager-conf.d
/etc/udev/rules.d|udev-rules.d
/proc/cmdline|cmdline-before.txt"

# backup_copy <quelle> <zielname> <pflicht|wahl>
backup_copy() {
	local src="$1" name="$2" kind="$3"
	if [ ! -e "$src" ]; then
		if [ "$kind" = "pflicht" ]; then
			die "$RC_BACKUP" "Die Pflichtdatei '$src' fehlt auf dem Zielgeraet." \
				"Ohne sie ist kein Rueckfall moeglich. Die Installation ist gesperrt."
		fi
		log_info "nicht vorhanden, uebersprungen: $src"
		printf 'fehlt\t%s\t%s\t-\n' "$kind" "$src" >> "$BACKUP_DIR/MANIFEST"
		return 0
	fi
	if ! cp -a "$src" "$BACKUP_DIR/$name" 2>"$TMP_WORK/cp-err.txt"; then
		log_err "Fehlermeldung: $(head -1 "$TMP_WORK/cp-err.txt" 2>/dev/null)"
		die "$RC_BACKUP" "Die Sicherung von '$src' schlug fehl." \
			"Pruefe den freien Speicherplatz unter /var. Die Installation ist gesperrt."
	fi
	printf 'gesichert\t%s\t%s\t%s\n' "$kind" "$src" "$name" >> "$BACKUP_DIR/MANIFEST"
	return 0
}

# backup_write <befehl...> > <zielname>: haelt eine erzeugte Datei fest.
# Auch hier gilt: Ein Fehler stoppt die Installation.
backup_generate() {
	local name="$1"; shift
	if ! "$@" > "$BACKUP_DIR/$name" 2>/dev/null; then
		die "$RC_BACKUP" "Die Sicherungsdatei '$name' liess sich nicht erzeugen." \
			"Befehl: $*. Pruefe den freien Speicherplatz unter /var."
	fi
	printf 'erzeugt\tpflicht\t%s\t%s\n' "$*" "$name" >> "$BACKUP_DIR/MANIFEST"
}

# Haelt den Fortschritt fest. Eine Unterbrechung ist danach erkennbar.
set_phase() {
	[ "$DRY_RUN" -eq 1 ] && return 0
	mkdir -p "$MT2_STATE_DIR"
	printf 'version=%s\nstamp=%s\nphase=%s\nbackup_dir=%s\npackage_root=%s\nupdated=%s\n' \
		"$MT2_VERSION" "$STAMP" "$1" "$BACKUP_DIR" "$ROOT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		> "$MT2_STATE_DIR/install-state"
}

# ---------------------------------------------------------------------------
log_step "Zielgeraet pruefen"
# ---------------------------------------------------------------------------
# V4.1: Diese Sperren greifen als erstes. Ein falsches Geraet wird abgewiesen,
# bevor das Skript irgendetwas anderes prueft oder anlegt.
# Sie gelten auch bei --skip-preflight.
# Harte Sperren. Sie gelten auch bei --skip-preflight.
MODEL="$(mt2_model || true)"
[ "$MODEL" = "$MT2_SUPPORTED_MODEL" ] || \
	die "$RC_MODEL" "Falsches Modell: '${MODEL:-unbekannt}'." "Dieses Paket gilt nur fuer $MT2_SUPPORTED_MODEL."
[ "$(mt2_release_id)" = "$MT2_SUPPORTED_RELEASE" ] || \
	die "$RC_RELEASE" "Nicht unterstuetzte Ubuntu-Version: '$(mt2_release_id)'." "Erwartet wird $MT2_SUPPORTED_RELEASE."
[ "$(dpkg --print-architecture)" = "amd64" ] || \
	die "$RC_RELEASE" "Falsche Architektur." "Erwartet wird amd64."
log_ok "Modell, Betriebssystemversion und Architektur sind bestaetigt."

# ---------------------------------------------------------------------------
log_step "Werkzeuge pruefen"
# ---------------------------------------------------------------------------
for c in apt-get dpkg dpkg-query apt-mark update-grub update-initramfs sha256sum findmnt; do
	mt2_need_cmd "$c"
done
if GRUB_TOOL="$(mt2_grub_check_tool)"; then
	log_ok "GRUB-Pruefprogramm: $GRUB_TOOL"
else
	die "$RC_TOOL" "Das Programm 'grub-script-check' fehlt." \
		"Installiere es mit: sudo apt install grub-common. Ohne dieses Programm ist die GRUB-Konfiguration nicht pruefbar."
fi
log_ok "Alle benoetigten Programme sind vorhanden."

# ---------------------------------------------------------------------------
log_step "Paketpfad pruefen"
# ---------------------------------------------------------------------------
# Der Pfad wandert in eine apt-Quelle. Sonderzeichen muessen kodiert werden.
PKG_DIR="$ROOT/packages"
PKG_DIR_ENC="$(mt2_url_encode_path "$PKG_DIR")"
if [ "$PKG_DIR_ENC" != "$PKG_DIR" ]; then
	log_warn "Der Paketpfad enthaelt Sonderzeichen: $PKG_DIR"
	log_ok "Fuer die apt-Quelle wird er kodiert: $PKG_DIR_ENC"
else
	log_ok "Paketpfad ohne Sonderzeichen: $PKG_DIR"
fi
case "$PKG_DIR" in
	*$'\n'*|*$'\t'*) die "$RC_PKG_TREE" "Der Paketpfad enthaelt einen Zeilen- oder Tabulatorumbruch." \
		"Haenge die Samsung T7 unter einem einfachen Pfad ein." ;;
esac

read -r FS_TYPE FS_EXEC <<EOF
$(mt2_fs_info "$ROOT")
EOF
log_info "Dateisystem der Paketwurzel: $FS_TYPE ($FS_EXEC)"
if ! mt2_fs_keeps_modes "$FS_TYPE"; then
	log_warn "Das Dateisystem '$FS_TYPE' speichert keine Unix-Rechte."
	log_warn "Rufe alle Skripte mit 'bash' auf, zum Beispiel: sudo bash scripts/verify.sh"
fi
if [ "$FS_EXEC" = "noexec" ]; then
	log_warn "Die Einhaengung traegt 'noexec'. Ein direkter Aufruf ist nicht moeglich."
	log_warn "Der Aufruf ueber 'bash' funktioniert trotzdem."
fi

# ---------------------------------------------------------------------------
log_step "Vorpruefung"
# ---------------------------------------------------------------------------
if [ "$SKIP_PREFLIGHT" -eq 1 ]; then
	log_warn "Die Vorpruefung wurde uebersprungen. Das Risiko traegt der Benutzer."
else
	if ! bash "$SELF_DIR/preflight.sh" --no-color; then
		die "$RC_DEPS" "Die Vorpruefung ist fehlgeschlagen." "Behebe die gemeldeten Fehler und starte erneut."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Pakete und Pruefsummen validieren"
# ---------------------------------------------------------------------------
[ -f "$PKG_DIR/Packages" ] || \
	die "$RC_REPO" "packages/Packages fehlt." "Fuehre 'bash scripts/fetch-packages.sh' auf dem Baurechner aus."
[ -f "$PKG_DIR/SHA256SUMS.debs" ] || \
	die "$RC_CHECKSUM" "packages/SHA256SUMS.debs fehlt." "Das Paket ist unvollstaendig. Baue es neu."
if mt2_verify_sha256 "$PKG_DIR/SHA256SUMS.debs" "$PKG_DIR"; then
	log_ok "Alle Paketdateien haben die erwartete SHA-256-Pruefsumme."
else
	die "$RC_CHECKSUM" "Mindestens eine Paketdatei ist beschaedigt oder veraendert." "Kopiere das Paket erneut von der Samsung T7."
fi

declare -a PKGLIST=()
mapfile -t PKGLIST < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
	"$ROOT/config/install-packages.list")
[ "${#PKGLIST[@]}" -gt 0 ] || \
	die "$RC_PKG_TREE" "config/install-packages.list ist leer." "Stelle die Datei aus dem Paket wieder her."
log_ok "${#PKGLIST[@]} Pakete sind zur Installation vorgesehen."

# Gegenprobe: keines der konfliktbehafteten Pakete darf in der Liste stehen.
for bad in apple-bce apple-touchbar applesmc-t2 bcm5974-t2 apfs-dkms broadcom-wl; do
	if printf '%s\n' "${PKGLIST[@]}" | grep -qx "$bad"; then
		die "$RC_PKG_TREE" "Das Paket '$bad' steht in der Installationsliste." \
			"Der Kernel $MT2_KERNEL_PACKAGE enthaelt diese Treiber bereits. Entferne den Eintrag."
	fi
done
log_ok "Es sind keine konfliktbehafteten Treiberpakete vorgesehen."

# ---------------------------------------------------------------------------
log_step "Arbeitsverzeichnis anlegen"
# ---------------------------------------------------------------------------
TMP_WORK="$(mktemp -d -t maximus-t2-install-XXXXXX)"
# shellcheck disable=SC2317  # Die Funktion ruft die EXIT-Falle auf.
cleanup_work() { rm -rf "$TMP_WORK"; }
trap cleanup_work EXIT
log_ok "Temporaeres Arbeitsverzeichnis: $TMP_WORK"
log_info "Die EXIT-Falle loescht es am Ende des Laufs."

# V4.2: In der Simulation wird vorher eine Momentaufnahme genommen.
# Am Ende beweist der Vergleich, dass nichts geaendert wurde.
FP_PATHS="/etc /boot $MT2_STATE_DIR $MT2_BACKUP_ROOT"
if [ "$DRY_RUN" -eq 1 ]; then
	# shellcheck disable=SC2086  # Die Pfadliste muss expandieren.
	mt2_fs_fingerprint "$TMP_WORK/fp-before.txt" $FP_PATHS
	log_ok "Momentaufnahme vor dem Lauf: $(wc -l < "$TMP_WORK/fp-before.txt") Eintraege"
fi

# ---------------------------------------------------------------------------
log_step "Gepinnte Offline-Paketquelle einrichten"
# ---------------------------------------------------------------------------
# V4.1: Simulation UND Installation nutzen genau diese eine Quelle.
# Fassung V4.0 richtete nur 'apt-get update' auf die lokale Quelle aus.
# Die Simulation und die Installation liefen danach gegen die Systemquellen.
# Ein Download aus dem Netz war damit moeglich.
# V4.2: In der Simulation liegt die Paketverwaltung im temporaeren
# Verzeichnis. Nur die echte Installation nutzt den festen Pfad.
# Fassung V4.1 schrieb auch im Dry-Run nach /var/lib/maximus-t2.
if [ "$DRY_RUN" -eq 1 ]; then
	APT_BASE="$TMP_WORK/apt"
	log_info "Betriebsart Simulation: Die Paketverwaltung liegt in $APT_BASE."
else
	APT_BASE="$MT2_APT_DIR"
	log_info "Betriebsart Installation: Die Paketverwaltung liegt in $APT_BASE."
fi
mt2_apt_pin_create "$PKG_DIR" "$APT_BASE" \
	|| die "$RC_REPO" "Die gepinnte Paketverwaltung liess sich nicht anlegen." "Pruefe die Schreibrechte."
log_ok "Konfiguration: $MT2_APT_CONF"
log_ok "Quellenliste:  $MT2_APT_LIST"
log_info "Eigene Listen: $MT2_APT_LISTS (die Systemlisten bleiben unberuehrt)"
if [ "$MT2_APT_SANDBOX" = "root" ]; then
	log_info "apt holt die Pakete als root. Der Benutzer '_apt' kann '$PKG_DIR' nicht lesen."
	log_info "Das ist bei einem Wechseldatentraeger der Normalfall. Jede Datei wurde vorher geprueft."
else
	log_ok "apt holt die Pakete im Sandkasten als Benutzer '_apt'."
fi

if ! mt2_apt update -qq >/dev/null 2>&1; then
	die "$RC_REPO" "Die lokale Paketquelle liess sich nicht lesen." \
		"Pruefe $PKG_DIR/Packages und den Pfad in $MT2_APT_LIST."
fi
log_ok "Die lokale Paketquelle ist eingelesen."

if mt2_apt_pin_verify; then
	log_ok "Es ist ausschliesslich die lokale Quelle sichtbar. Ein Netzdownload ist ausgeschlossen."
else
	die "$RC_REPO" "Die gepinnte Paketverwaltung sieht eine Netzquelle oder nicht die lokale Quelle." \
		"Brich ab. Pruefe $MT2_APT_CONF."
fi

# ---------------------------------------------------------------------------
log_step "Paketbestand des Zielsystems auswerten"
# ---------------------------------------------------------------------------
mt2_pkg_snapshot "$TMP_WORK/pkg-before.txt"
log_info "Auf dem Zielgeraet sind $(wc -l < "$TMP_WORK/pkg-before.txt") Pakete installiert."

ALREADY=0
MISSING=0
for p in "${PKGLIST[@]}"; do
	if cut -f1 "$TMP_WORK/pkg-before.txt" | grep -qx "$p"; then
		ALREADY=$((ALREADY + 1))
	else
		MISSING=$((MISSING + 1))
	fi
done
log_ok "Davon aus der Installationsliste bereits vorhanden: $ALREADY, fehlend: $MISSING"

# ---------------------------------------------------------------------------
log_step "Installation simulieren"
# ---------------------------------------------------------------------------
SIM_FILE="$TMP_WORK/sim.txt"
if mt2_apt install -s -y --no-install-recommends "${PKGLIST[@]}" > "$SIM_FILE" 2>&1; then
	log_ok "Die Simulation war erfolgreich."
	grep -E 'newly installed|upgraded,' "$SIM_FILE" | tail -1 | sed 's/^/         /'
	INST_TOTAL="$(grep -cE '^Inst ' "$SIM_FILE" || true)"
	log_info "Neu oder geaendert: ${INST_TOTAL} Pakete"
	grep -E '^Inst ' "$SIM_FILE" | awk '{print "         " $2 " " $3}' | head -40
	[ "${INST_TOTAL:-0}" -gt 40 ] && log_info "... weitere Eintraege stehen im Protokoll."
	if grep -qE '^Remv ' "$SIM_FILE"; then
		log_err "Die Simulation wuerde Pakete ENTFERNEN:"
		grep -E '^Remv ' "$SIM_FILE" | sed 's/^/         /'
		die "$RC_DEPS" "Die Installation wuerde Pakete entfernen." \
			"Das ist nicht zulaessig. Pruefe den Paketbestand des Zielgeraets."
	fi
	log_ok "Es wird kein Paket entfernt."
	# V4.1: Gegenprobe, dass kein Paket aus dem Netz kommen soll.
	if grep -qE '^(Get|Conf)?.*https?://' "$SIM_FILE"; then
		log_err "Die Simulation nennt eine Netzadresse:"
		grep -E 'https?://' "$SIM_FILE" | head -5 | sed 's/^/         /'
		die "$RC_REPO" "Die Simulation wuerde aus dem Netz laden." "Brich ab. Pruefe $MT2_APT_LIST."
	fi
	log_ok "Die Simulation nennt keine Netzadresse."
else
	log_err "Die Simulation ist fehlgeschlagen:"
	sed -n '1,30p' "$SIM_FILE" | sed 's/^/         /'
	die "$RC_DEPS" "Die Paketabhaengigkeiten sind nicht erfuellbar." \
		"Pruefe die Meldungen oben. Ergaenze fehlende Pakete im Installationspaket."
fi

# Gegenprobe: liegt jede benoetigte Datei wirklich lokal?
# V4.1: Die Pfade kommen prozentkodiert aus apt. mt2_apt_wanted_files
# dekodiert jede Kodierung, nicht nur das Leerzeichen.
MISSING_FILES=0
NET_URIS=0
while IFS= read -r deb; do
	[ -n "$deb" ] || continue
	case "$deb" in
		NETZ:*) log_err "apt wuerde aus dem Netz laden: ${deb#NETZ:}"; NET_URIS=$((NET_URIS + 1)); continue ;;
	esac
	[ -f "$deb" ] || { log_err "Paketdatei fehlt: $deb"; MISSING_FILES=$((MISSING_FILES + 1)); }
done < <(mt2_apt_wanted_files "${PKGLIST[@]}")
if [ "$NET_URIS" -gt 0 ]; then
	die "$RC_REPO" "$NET_URIS Pakete sollen aus dem Netz kommen." "Brich ab. Pruefe $MT2_APT_LIST."
fi
if [ "$MISSING_FILES" -gt 0 ]; then
	die "$RC_REPO" "$MISSING_FILES Paketdateien fehlen im lokalen Bestand." "Fuehre 'bash scripts/fetch-packages.sh' erneut aus."
fi
log_ok "Jede benoetigte Paketdatei liegt lokal vor. Keine Netzadresse."

if [ "$DRY_RUN" -eq 1 ]; then
	log_step "Vorschau der geplanten Aenderungen"
	log "Diese Dateien wuerden geschrieben:"
	write_file "$ROOT/config/modules/t2.conf"           /etc/modules-load.d/t2.conf
	write_file "$ROOT/config/modules/t2-touchbar.conf"  /etc/modprobe.d/t2-touchbar.conf
	write_file "$ROOT/config/modules/initramfs-modules.conf" /etc/initramfs-tools/modules 1
	write_file "$ROOT/config/network/99-network-t2-ncm.rules" /etc/udev/rules.d/99-network-t2-ncm.rules
	write_file "$ROOT/config/network/99-network-t2-ncm.conf"  /etc/NetworkManager/conf.d/99-network-t2-ncm.conf
	write_file "$ROOT/config/power/99-maximus-t2-sleep.conf"  /etc/systemd/logind.conf.d/99-maximus-t2-sleep.conf
	log ""
	log "So wuerde GRUB_CMDLINE_LINUX lauten (berechnet auf einer Kopie):"
	declare -a PREVIEW_PARAMS=()
	mapfile -t PREVIEW_PARAMS < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
		"$ROOT/config/grub/20-maximus-t2-cmdline.conf")
	if [ -f /etc/default/grub ] && [ "${#PREVIEW_PARAMS[@]}" -gt 0 ]; then
		cp /etc/default/grub "$TMP_WORK/grub.preview"
		printf '         %s\n' "$(mt2_grub_merge_cmdline "$TMP_WORK/grub.preview" "${PREVIEW_PARAMS[@]}")"
		log ""
		log "Diese Menueschluessel wuerden gesetzt:"
		mt2_grub_set_keys "$TMP_WORK/grub.preview" "$ROOT/config/grub/10-maximus-t2-grub.conf" \
			| sed 's/^/         /'
	else
		log_warn "/etc/default/grub fehlt. Die Vorschau ist nicht moeglich."
	fi
	log ""
	log "Weitere Schritte der echten Installation:"
	log "         Sicherung nach $MT2_BACKUP_ROOT/<Zeitstempel>, versiegelt mit SHA-256"
	log "         apt-mark hold auf die Ubuntu-Kernelpakete"
	log "         Dienst t2fanrd aktivieren, Luefterkurve 55 bis 80 Grad Celsius"
	log "         update-initramfs -u -k all"
	log "         update-grub und Pruefung mit grub-script-check"
	log "         grub-reboot fuer EINEN Teststart in den T2-Kernel"
	# -------------------------------------------------------------------
	log_step "Schreibfreiheit der Simulation nachweisen"
	# -------------------------------------------------------------------
	# V4.2: Der Vergleich beweist, dass der Dry-Run nichts geaendert hat.
	# shellcheck disable=SC2086  # Die Pfadliste muss expandieren.
	mt2_fs_fingerprint "$TMP_WORK/fp-after.txt" $FP_PATHS
	log_info "Momentaufnahme nach dem Lauf: $(wc -l < "$TMP_WORK/fp-after.txt") Eintraege"
	# V4.2: Fluechtige Pfade wie /etc/resolv.conf zaehlen nicht.
	# Das System schreibt sie von selbst. Sonst entstuende ein Fehlalarm.
	FP_CHANGES="$(mt2_fs_fingerprint_changes "$TMP_WORK/fp-before.txt" "$TMP_WORK/fp-after.txt")"
	FP_VOLATILE="$(mt2_fs_fingerprint_volatile_count "$TMP_WORK/fp-before.txt" "$TMP_WORK/fp-after.txt")"
	if [ -z "$FP_CHANGES" ]; then
		log_ok "Kein Unterschied. Die Simulation war schreibfrei."
		log_ok "Geprueft wurden: $FP_PATHS"
		[ "${FP_VOLATILE:-0}" -gt 0 ] && \
			log_info "${FP_VOLATILE} fluechtige Systempfade haben sich geaendert. Sie zaehlen nicht."
	else
		log_err "Die Simulation hat das Dateisystem veraendert:"
		printf '%s\n' "$FP_CHANGES" | head -20 | sed 's/^/         /'
		die "$RC_PKG_TREE" "Die Simulation ist nicht schreibfrei." \
			"Das ist ein Fehler im Installationspaket. Melde ihn. Installiere nicht."
	fi
	LEFT_PERSIST="$(mt2_count_files "$MT2_APT_DIR" -mindepth 1)"
	if [ "$LEFT_PERSIST" -eq 0 ]; then
		log_ok "Unter $MT2_APT_DIR liegt keine Datei."
	else
		log_err "Unter $MT2_APT_DIR liegen $LEFT_PERSIST Dateien."
		die "$RC_PKG_TREE" "Die Simulation hat eine dauerhafte Ablage angelegt." "Melde diesen Fehler."
	fi

	log_step "Simulation beendet"
	log_ok "Alle Pruefungen der Simulation sind bestanden."
	log ""
	log "Es wurde nichts geaendert. Das ist nachgewiesen, nicht behauptet."
	log "Starte die echte Installation mit:"
	log "  sudo bash $0"
	exit "$RC_OK"
fi

# ---------------------------------------------------------------------------
log_step "Frueheren Lauf pruefen"
# ---------------------------------------------------------------------------
# V4.1: Ein zweiter Lauf wuerde das bereits veraenderte System sichern und die
# Aufzeichnungen des ersten Laufs ueberschreiben. Der Rueckfall wuerde danach
# veraenderte Dateien einspielen und die Pakete des ersten Laufs uebersehen.
if [ -f "$MT2_STATE_DIR/install-state" ]; then
	PREV_PHASE="$(awk -F= '/^phase=/{print $2}' "$MT2_STATE_DIR/install-state" | tail -1)"
	case "$PREV_PHASE" in
		rolled-back|'')
			log_info "Ein frueherer Lauf wurde zurueckgenommen. Die Installation beginnt neu." ;;
		*)
			if [ "$FORCE_REINSTALL" -eq 0 ]; then
				log_err "Es ist bereits eine Installation im Zustand '$PREV_PHASE' aufgezeichnet."
				sed 's/^/         /' "$MT2_STATE_DIR/install-state"
				die "$RC_ABORT" "Ein zweiter Lauf wuerde die Aufzeichnungen des ersten ueberschreiben." \
					"Nimm den ersten Lauf zuerst zurueck: sudo bash scripts/rollback.sh. Nur wenn das nicht moeglich ist: --force-reinstall."
			fi
			log_warn "Ein frueherer Lauf im Zustand '$PREV_PHASE' wird auf Anweisung uebergangen."
			log_warn "Die Aufzeichnungen des ersten Laufs werden mitgefuehrt." ;;
	esac
fi

# ---------------------------------------------------------------------------
log_step "Boot-Konfiguration sichern"
# ---------------------------------------------------------------------------
mkdir -p "$BACKUP_DIR" || die "$RC_BACKUP" "Das Sicherungsverzeichnis liess sich nicht anlegen." "Pruefe den freien Speicherplatz unter /var."
mkdir -p "$MT2_STATE_DIR"
# Aufzeichnungen eines frueheren Laufs bleiben erhalten. Neue werden angehaengt.
if [ -f "$MT2_STATE_DIR/files-written.txt" ] && [ -s "$MT2_STATE_DIR/files-written.txt" ]; then
	cp "$MT2_STATE_DIR/files-written.txt" "$BACKUP_DIR/files-written-previous.txt"
	log_info "Die Dateiaufzeichnung des frueheren Laufs bleibt erhalten und wird ergaenzt."
else
	: > "$MT2_STATE_DIR/files-written.txt"
fi
set_phase "backup"

# V4.2: Pflichtdateien zuerst. Ein Fehler stoppt hier, nicht spaeter.
: > "$BACKUP_DIR/MANIFEST"
while IFS='|' read -r src name; do
	[ -n "$name" ] || continue
	backup_copy "$src" "$name" pflicht
done <<EOF
$MT2_BACKUP_REQUIRED
EOF
log_ok "Alle Pflichtdateien sind gesichert."

while IFS='|' read -r src name; do
	[ -n "$name" ] || continue
	backup_copy "$src" "$name" wahl
done <<EOF
$MT2_BACKUP_OPTIONAL
EOF
log_ok "Die Wahldateien sind abgearbeitet."

# Erzeugte Nachweise. Auch sie sind Pflicht.
cp "$TMP_WORK/pkg-before.txt" "$BACKUP_DIR/pkg-before.txt" \
	|| die "$RC_BACKUP" "Der Paketbestand liess sich nicht sichern." "Pruefe den freien Speicherplatz unter /var."
printf 'gesichert\tpflicht\t%s\t%s\n' "dpkg-Bestand" "pkg-before.txt" >> "$BACKUP_DIR/MANIFEST"
backup_generate dpkg-selections.txt dpkg --get-selections
backup_generate running-kernel.txt uname -r
backup_generate installer-version.txt printf '%s\n' "$MT2_VERSION"
backup_generate stamp.txt printf '%s\n' "$STAMP"

# Diese Nachweise sind nuetzlich, aber nicht zwingend.
apt-mark showhold > "$BACKUP_DIR/apt-holds-before.txt" 2>/dev/null || : > "$BACKUP_DIR/apt-holds-before.txt"
dpkg-query -W -f='${Package} ${Version}\n' 'linux-image-*' 'linux-headers-*' \
	> "$BACKUP_DIR/kernel-packages.txt" 2>/dev/null || : > "$BACKUP_DIR/kernel-packages.txt"
find /boot -maxdepth 1 \( -name 'vmlinuz-*' -o -name 'initrd.img-*' \) -printf '%f %s\n' \
	> "$BACKUP_DIR/boot-listing.txt" 2>/dev/null || : > "$BACKUP_DIR/boot-listing.txt"
find /lib/firmware/brcm -maxdepth 1 -type f -printf '%f %s\n' \
	> "$BACKUP_DIR/firmware-brcm.txt" 2>/dev/null || : > "$BACKUP_DIR/firmware-brcm.txt"

# V4.2: Vollstaendigkeit PRUEFEN, dann versiegeln. Nicht umgekehrt.
declare -a REQ_ENTRIES=()
mapfile -t REQ_ENTRIES <<EOF
$MT2_BACKUP_REQUIRED
EOF
REQ_ENTRIES+=("$TMP_WORK/pkg-before.txt|pkg-before.txt")
REQ_ENTRIES+=("|running-kernel.txt")
REQ_ENTRIES+=("|dpkg-selections.txt")
REQ_ENTRIES+=("|installer-version.txt")
if mt2_backup_check_complete "$BACKUP_DIR" "${REQ_ENTRIES[@]}"; then
	log_ok "Die Sicherung ist vollstaendig. Jede Pflichtdatei stimmt Byte fuer Byte."
else
	die "$RC_BACKUP" "Die Sicherung ist unvollstaendig oder weicht vom Original ab." \
		"Die Installation ist gesperrt. Pruefe den freien Speicherplatz unter /var."
fi

# V4.1: Die Pruefsummen liegen IN der Sicherung. rollback.sh prueft sie.
mt2_backup_seal "$BACKUP_DIR" \
	|| die "$RC_BACKUP" "Die Sicherung liess sich nicht versiegeln." "Pruefe den freien Speicherplatz unter /var."
if mt2_backup_verify "$BACKUP_DIR"; then
	log_ok "Sicherung liegt in $BACKUP_DIR und ist versiegelt ($(grep -c . "$BACKUP_DIR/SHA256SUMS") Dateien)."
	log_info "Das Verzeichnis traegt MANIFEST mit $(grep -c . "$BACKUP_DIR/MANIFEST") Eintraegen."
else
	die "$RC_BACKUP" "Die Sicherung ist nicht nachpruefbar." "Brich ab. Ohne gueltige Sicherung wird nichts geaendert."
fi
printf '%s\n' "$BACKUP_DIR" > "$MT2_STATE_DIR/last-backup"

# ---------------------------------------------------------------------------
log_step "Benutzerfreigabe"
# ---------------------------------------------------------------------------
log "Die folgenden dauerhaften Aenderungen stehen an:"
log "  1. Installation von ${INST_TOTAL} Paketen, darunter $MT2_KERNEL_PACKAGE $MT2_KERNEL_VERSION."
log "  2. Ergaenzung der Kernelparameter in /etc/default/grub."
log "  3. Neuerzeugung der Initialramdisk und des GRUB-Menues."
log "  4. Abschaltung des selbsttaetigen Ruhezustands."
log "  5. Einmaliger Teststart in den T2-Kernel beim naechsten Neustart."
log ""
log "Alle Pakete kommen aus $PKG_DIR. Es wird nichts aus dem Netz geladen."
log "Nicht angetastet werden: EFI, NVRAM, Partitionen, vorhandene Ubuntu-Kernel."
log "Die Sicherung liegt in $BACKUP_DIR."
if [ "$ASSUME_YES" -eq 1 ]; then
	log_warn "Die Freigabe wurde mit --yes vorausgesetzt."
else
	if ! mt2_confirm "Soll die Installation jetzt dauerhaft ausgefuehrt werden?"; then
		die "$RC_ABORT" "Die Freigabe wurde nicht erteilt." "Es wurde nichts installiert. Die Sicherung bleibt in $BACKUP_DIR."
	fi
	log_ok "Freigabe erteilt."
fi

# ---------------------------------------------------------------------------
log_step "Vorhandene Kernel schuetzen"
# ---------------------------------------------------------------------------
# V4.1: Dieser Schritt liegt NACH der Freigabe. In V4.0 lag er davor.
# Eine verweigerte Freigabe liess den Schutz zurueck, obwohl die Meldung
# sagte, es sei nichts geaendert worden.
set_phase "hold"
declare -a HOLDS=()
mapfile -t HOLDS < <(dpkg-query -W -f='${Package} ${Status}\n' 'linux-image-*-generic' 'linux-headers-*-generic' \
	'linux-modules-*-generic' 'linux-modules-extra-*-generic' 2>/dev/null \
	| awk '$NF=="installed"{print $1}' | sort -u || true)
if [ "${#HOLDS[@]}" -eq 0 ]; then
	log_warn "Es wurden keine Ubuntu-Kernelpakete zum Schutz gefunden."
	: > "$MT2_STATE_DIR/held-by-maximus.txt"
else
	# V4.1: Nur Pakete schuetzen, die noch nicht geschuetzt waren.
	declare -a NEWHOLDS=()
	while IFS= read -r h; do
		if ! apt-mark showhold 2>/dev/null | grep -qx "$h"; then
			NEWHOLDS+=("$h")
		fi
	done < <(printf '%s\n' "${HOLDS[@]}")
	if [ "${#NEWHOLDS[@]}" -gt 0 ]; then
		apt-mark hold "${NEWHOLDS[@]}" >/dev/null
		printf '%s\n' "${NEWHOLDS[@]}" > "$MT2_STATE_DIR/held-by-maximus.txt"
		log_ok "${#NEWHOLDS[@]} Ubuntu-Kernelpakete sind jetzt gegen Entfernung geschuetzt."
	else
		: > "$MT2_STATE_DIR/held-by-maximus.txt"
		log_info "Alle ${#HOLDS[@]} Ubuntu-Kernelpakete waren bereits geschuetzt."
	fi
fi

# ---------------------------------------------------------------------------
log_step "T2-Kernel und Treiber installieren"
# ---------------------------------------------------------------------------
set_phase "packages"
export DEBIAN_FRONTEND=noninteractive
if ! mt2_apt install -y --no-install-recommends "${PKGLIST[@]}"; then
	mt2_pkg_snapshot "$MT2_STATE_DIR/pkg-after.txt" || true
	mt2_pkg_diff "$TMP_WORK/pkg-before.txt" "$MT2_STATE_DIR/pkg-after.txt" "$MT2_STATE_DIR" || true
	set_phase "packages-failed"
	die "$RC_DEPS" "Die Paketinstallation ist fehlgeschlagen." \
		"Der Bestand wurde festgehalten. Setze zurueck mit: sudo bash scripts/rollback.sh"
fi
log_ok "Die Pakete sind installiert."

# V4.1: Jede Paketaenderung wird festgehalten. rollback.sh raet nicht mehr.
mt2_pkg_snapshot "$MT2_STATE_DIR/pkg-after.txt"
cp "$TMP_WORK/pkg-before.txt" "$MT2_STATE_DIR/pkg-before.txt"
mt2_pkg_diff "$MT2_STATE_DIR/pkg-before.txt" "$MT2_STATE_DIR/pkg-after.txt" "$MT2_STATE_DIR"
log_ok "Hinzugefuegt: $(wc -l < "$MT2_STATE_DIR/packages-added.txt") Pakete"
log_ok "Geaendert:    $(wc -l < "$MT2_STATE_DIR/packages-changed.txt") Pakete"
if [ -s "$MT2_STATE_DIR/packages-removed.txt" ]; then
	log_err "Entfernt:     $(wc -l < "$MT2_STATE_DIR/packages-removed.txt") Pakete"
	sed 's/^/         /' "$MT2_STATE_DIR/packages-removed.txt"
	log_warn "Das war nicht vorgesehen. Pruefe die Liste."
else
	log_ok "Entfernt:     0 Pakete"
fi

if [ ! -f "/boot/vmlinuz-$MT2_KERNEL_RELEASE" ]; then
	die "$RC_GRUB" "Das Kernelabbild /boot/vmlinuz-$MT2_KERNEL_RELEASE fehlt." \
		"Die Installation war unvollstaendig. Setze mit 'sudo bash scripts/rollback.sh' zurueck."
fi
log_ok "Kernelabbild gefunden: /boot/vmlinuz-$MT2_KERNEL_RELEASE"

# ---------------------------------------------------------------------------
log_step "Module und Konfiguration schreiben"
# ---------------------------------------------------------------------------
set_phase "config"
write_file "$ROOT/config/modules/t2.conf"           /etc/modules-load.d/t2.conf
write_file "$ROOT/config/modules/t2-touchbar.conf"  /etc/modprobe.d/t2-touchbar.conf
write_file "$ROOT/config/modules/initramfs-modules.conf" /etc/initramfs-tools/modules 1
write_file "$ROOT/config/network/99-network-t2-ncm.rules" /etc/udev/rules.d/99-network-t2-ncm.rules
write_file "$ROOT/config/network/99-network-t2-ncm.conf"  /etc/NetworkManager/conf.d/99-network-t2-ncm.conf
write_file "$ROOT/config/power/99-maximus-t2-sleep.conf"  /etc/systemd/logind.conf.d/99-maximus-t2-sleep.conf

# ---------------------------------------------------------------------------
log_step "Luefterdienst einrichten"
# ---------------------------------------------------------------------------
set_phase "fan"
if systemctl enable t2fanrd >/dev/null 2>&1; then
	log_ok "Der Dienst t2fanrd startet kuenftig selbsttaetig."
else
	log_warn "Der Dienst t2fanrd liess sich nicht aktivieren."
fi
if systemctl start t2fanrd 2>/dev/null; then
	log_ok "Der Dienst t2fanrd laeuft."
	sleep 2
else
	log_warn "Der Dienst t2fanrd startete nicht. Die Luefterwerte sind erst unter dem T2-Kernel lesbar."
fi

# t2fanrd erzeugt /etc/t2fand.conf selbst. Nur die Werte werden angepasst.
if [ -f /etc/t2fand.conf ]; then
	cp -a /etc/t2fand.conf "$BACKUP_DIR/t2fand.conf.generated"
	sed -i -e 's/^[[:space:]]*low_temp[[:space:]]*=.*/low_temp = 55/' \
	       -e 's/^[[:space:]]*high_temp[[:space:]]*=.*/high_temp = 80/' \
	       -e 's/^[[:space:]]*speed_curve[[:space:]]*=.*/speed_curve = linear/' \
	       /etc/t2fand.conf
	printf 'replace\t%s\n' /etc/t2fand.conf >> "$MT2_STATE_DIR/files-written.txt"
	log_ok "Die Luefterkurve ist auf 55 bis 80 Grad Celsius gesetzt."
	systemctl restart t2fanrd 2>/dev/null || log_warn "Der Dienst t2fanrd liess sich nicht neu starten."
else
	log_warn "/etc/t2fand.conf wurde noch nicht erzeugt. Pruefe die Werte nach dem Teststart."
	log_info "Referenzwerte stehen in config/fan/t2fand.conf.reference."
fi

# ---------------------------------------------------------------------------
log_step "Kernelparameter in GRUB ergaenzen"
# ---------------------------------------------------------------------------
set_phase "grub-cmdline"
declare -a CMDLINE_ADD=()
mapfile -t CMDLINE_ADD < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
	"$ROOT/config/grub/20-maximus-t2-cmdline.conf")
[ "${#CMDLINE_ADD[@]}" -gt 0 ] || die "$RC_PKG_TREE" "Die Kernelparameterliste ist leer." "Stelle config/grub/20-maximus-t2-cmdline.conf wieder her."

CMDLINE_BEFORE="$(mt2_grub_read_cmdline /etc/default/grub || true)"
log_info "GRUB_CMDLINE_LINUX vorher: ${CMDLINE_BEFORE:-<leer>}"
CMDLINE_AFTER="$(mt2_grub_merge_cmdline /etc/default/grub "${CMDLINE_ADD[@]}")" \
	|| die "$RC_GRUB" "/etc/default/grub liess sich nicht bearbeiten." "Pruefe die Datei und die Schreibrechte."
if [ "$CMDLINE_AFTER" = "$CMDLINE_BEFORE" ]; then
	log_info "GRUB_CMDLINE_LINUX war bereits vollstaendig."
else
	log_ok "GRUB_CMDLINE_LINUX lautet nun: $CMDLINE_AFTER"
fi

# Gegenprobe: Jeder geforderte Parameter muss jetzt enthalten sein.
for p in "${CMDLINE_ADD[@]}"; do
	key="${p%%=*}"
	printf '%s' " $CMDLINE_AFTER " | grep -q " ${key}[= ]" \
		|| die "$RC_GRUB" "Der Kernelparameter '$key' fehlt nach der Bearbeitung." "Pruefe /etc/default/grub von Hand."
done
log_ok "Alle ${#CMDLINE_ADD[@]} Kernelparameter sind gesetzt."

# Menueeinstellungen setzen. Das Menue muss sichtbar bleiben.
while IFS= read -r line; do
	[ -n "$line" ] && log_ok "gesetzt: $line"
done < <(mt2_grub_set_keys /etc/default/grub "$ROOT/config/grub/10-maximus-t2-grub.conf")
printf 'replace\t%s\n' /etc/default/grub >> "$MT2_STATE_DIR/files-written.txt"

# ---------------------------------------------------------------------------
log_step "Initialramdisk und GRUB-Menue neu erzeugen"
# ---------------------------------------------------------------------------
set_phase "initramfs"
if ! update-initramfs -u -k all; then
	die "$RC_GRUB" "Die Initialramdisk liess sich nicht erzeugen." \
		"Starte das Geraet NICHT neu. Fuehre 'sudo bash scripts/rollback.sh' aus."
fi
log_ok "Die Initialramdisk ist erzeugt."

set_phase "grub-menu"
if ! update-grub; then
	die "$RC_GRUB" "Das GRUB-Menue liess sich nicht erzeugen." \
		"Starte das Geraet NICHT neu. Fuehre 'sudo bash scripts/rollback.sh' aus."
fi
log_ok "Das GRUB-Menue ist erzeugt."

# V4.1: Pruefung mit grub-script-check, nicht mit 'bash -n'.
# Achtung: 'set -e' beendet das Skript, wenn eine Funktion direkt vor
# 'case $?' einen Wert ungleich 0 liefert. Der Rueckgabewert wird deshalb
# in einer Variablen aufgefangen.
GRUB_RC=0
mt2_grub_check_cfg /boot/grub/grub.cfg || GRUB_RC=$?
case "$GRUB_RC" in
	0) log_ok "grub-script-check bestaetigt die GRUB-Konfiguration." ;;
	6) die "$RC_TOOL" "Das Programm 'grub-script-check' ist verschwunden." "Installiere grub-common und pruefe von Hand." ;;
	*) die "$RC_GRUB" "grub-script-check meldet einen Fehler in /boot/grub/grub.cfg." \
		"Stelle sie sofort zurueck: sudo cp $BACKUP_DIR/grub.cfg /boot/grub/grub.cfg" ;;
esac

if ! grep -q "$MT2_KERNEL_RELEASE" /boot/grub/grub.cfg; then
	die "$RC_GRUB" "Im GRUB-Menue fehlt ein Eintrag fuer $MT2_KERNEL_RELEASE." \
		"Pruefe /boot und fuehre 'sudo update-grub' erneut aus."
fi
log_ok "Das GRUB-Menue enthaelt einen Eintrag fuer $MT2_KERNEL_RELEASE."

# V4.1: Der Vorgabeeintrag wird ausdruecklich auf den bisherigen
# Ubuntu-Kernel gesetzt. 'GRUB_DEFAULT=saved' allein genuegt nicht:
# Ohne gesetztes 'saved_entry' entscheidet GRUB selbst, meist Eintrag 0.
PREV_KERNEL="$(cat "$BACKUP_DIR/running-kernel.txt" 2>/dev/null || uname -r)"
PREV_ENTRY="$(bash "$SELF_DIR/lib/grub-entry.sh" "$PREV_KERNEL" || true)"
if [ -n "$PREV_ENTRY" ]; then
	if grub-set-default "$PREV_ENTRY" 2>/dev/null; then
		log_ok "Vorgabeeintrag gesetzt auf den bisherigen Kernel $PREV_KERNEL."
		printf '%s\n' "$PREV_ENTRY" > "$MT2_STATE_DIR/default-boot-entry"
	else
		log_warn "'grub-set-default' schlug fehl. Pruefe den Vorgabeeintrag im Menue."
	fi
else
	log_warn "Der Menueeintrag fuer $PREV_KERNEL war nicht ermittelbar."
	log_warn "Pruefe nach dem Teststart, welcher Kernel als Vorgabe startet."
fi

# ---------------------------------------------------------------------------
log_step "Einmaligen Teststart vorbereiten"
# ---------------------------------------------------------------------------
set_phase "test-boot"
ENTRY="$(bash "$SELF_DIR/lib/grub-entry.sh" "$MT2_KERNEL_RELEASE" || true)"
if [ -z "$ENTRY" ]; then
	log_warn "Der Menueeintrag war nicht automatisch ermittelbar."
	log_warn "Waehle den T2-Kernel beim naechsten Start manuell im GRUB-Menue."
	log_info "Pfad im Menue: 'Advanced options for Ubuntu' -> Linux $MT2_KERNEL_RELEASE"
else
	log_info "Menueeintrag: $ENTRY"
	if grub-reboot "$ENTRY"; then
		log_ok "Der naechste Start geht EINMALIG in den T2-Kernel."
		log_ok "Jeder weitere Start geht wieder in den bisherigen Ubuntu-Kernel."
		printf '%s\n' "$ENTRY" > "$MT2_STATE_DIR/test-boot-entry"
	else
		log_warn "'grub-reboot' schlug fehl. Waehle den Eintrag manuell im Menue."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Abschluss"
# ---------------------------------------------------------------------------
set_phase "done"
{
	printf 'version=%s\n' "$MT2_VERSION"
	printf 'stamp=%s\n' "$STAMP"
	printf 'phase=done\n'
	printf 'kernel_package=%s\n' "$MT2_KERNEL_PACKAGE"
	printf 'kernel_version=%s\n' "$MT2_KERNEL_VERSION"
	printf 'kernel_release=%s\n' "$MT2_KERNEL_RELEASE"
	printf 'backup_dir=%s\n' "$BACKUP_DIR"
	printf 'package_root=%s\n' "$ROOT"
	printf 'packages_added=%s\n' "$(wc -l < "$MT2_STATE_DIR/packages-added.txt")"
	printf 'packages_changed=%s\n' "$(wc -l < "$MT2_STATE_DIR/packages-changed.txt")"
	printf 'updated=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$MT2_STATE_DIR/install-state"

log_ok "PACKAGE_READY und INSTALLATION_READY sind erfuellt."
log_warn "HARDWARE_READY ist NICHT erteilt. Die Hardwaretests fehlen noch."
log ""
log "Naechste Schritte:"
log "  1. Lies recovery/GRUB-NOTSTART.txt. Lege das Blatt bereit."
log "  2. Schliesse eine USB-Tastatur an."
log "  3. Starte das Geraet neu: sudo reboot"
log "  4. Fuehre die Abnahme aus: sudo bash scripts/verify.sh"
log "  5. Hole die WLAN-Firmware nach firmware/README.md."
log ""
log "Bei einem Fehlstart: Waehle im GRUB-Menue den Kernel $(uname -r)."
log "Zum Zurueckrollen: sudo bash scripts/rollback.sh"
exit "$RC_OK"
