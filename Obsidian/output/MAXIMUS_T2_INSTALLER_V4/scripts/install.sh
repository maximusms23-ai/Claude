#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - T2-Kernel und Treiber installieren
#
# Ergebnis: Das Zielgeraet erhaelt den T2-Kernel, die T2-Treiberpakete und die
# passenden Konfigurationsdateien. Die vorhandenen Ubuntu-Kernel bleiben
# unveraendert und geschuetzt.
#
# Aufruf:  sudo ./install.sh [OPTIONEN]
#   --dry-run          Simuliert alle Schritte. Es wird nichts geaendert.
#   --yes              Setzt die Freigabe voraus. Fuer unbeaufsichtigte Laeufe.
#   --skip-preflight   Ueberspringt die Vorpruefung. Nur fuer Wiederholungen.
#   --no-color         Gibt keine Farbcodes aus.
#
# Das Skript installiert kein Ubuntu neu. Es veraendert weder EFI noch NVRAM
# noch Partitionen.

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
for arg in "$@"; do
	case "$arg" in
		--dry-run)        DRY_RUN=1 ;;
		--yes)            ASSUME_YES=1 ;;
		--skip-preflight) SKIP_PREFLIGHT=1 ;;
		--no-color)       NO_COLOR=1; export NO_COLOR ;;
		-h|--help)        sed -n '2,17p' "$0"; exit "$RC_OK" ;;
		*)                die "$RC_USAGE" "Unbekannte Option '$arg'." "Rufe '$0 --help' auf." ;;
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

log "MAXIMUS_T2_INSTALLER_V4 - Installation"
log "Betriebsart: $MODE_TEXT"
log "Paketwurzel: $ROOT"
log "Zeitpunkt:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---------------------------------------------------------------------------
# run: Fuehrt einen Befehl aus. In der Simulation wird er nur angezeigt.
# ---------------------------------------------------------------------------
run() {
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde ausfuehren] %s\n' "$*"
		return 0
	fi
	log_info "fuehre aus: $*"
	"$@"
}

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
		if ! grep -qF "MAXIMUS_T2_INSTALLER_V4" "$dst" 2>/dev/null; then
			cat "$src" >> "$dst"
			log_ok "angehaengt: $dst"
		else
			log_info "bereits vorhanden, uebersprungen: $dst"
		fi
	else
		install -m 0644 "$src" "$dst"
		log_ok "geschrieben: $dst"
	fi
}

# ---------------------------------------------------------------------------
log_step "Vorpruefung"
# ---------------------------------------------------------------------------
if [ "$SKIP_PREFLIGHT" -eq 1 ]; then
	log_warn "Die Vorpruefung wurde uebersprungen. Das Risiko traegt der Benutzer."
else
	if ! "$SELF_DIR/preflight.sh" --no-color; then
		die "$RC_DEPS" "Die Vorpruefung ist fehlgeschlagen." "Behebe die gemeldeten Fehler und starte erneut."
	fi
fi

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
log_step "Pakete und Pruefsummen validieren"
# ---------------------------------------------------------------------------
[ -f "$ROOT/packages/Packages" ] || \
	die "$RC_REPO" "packages/Packages fehlt." "Fuehre scripts/fetch-packages.sh auf dem Baurechner aus."
[ -f "$ROOT/packages/SHA256SUMS.debs" ] || \
	die "$RC_CHECKSUM" "packages/SHA256SUMS.debs fehlt." "Das Paket ist unvollstaendig. Baue es neu."
if mt2_verify_sha256 "$ROOT/packages/SHA256SUMS.debs" "$ROOT/packages"; then
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
log_step "Boot-Konfiguration sichern"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
	printf '         [wuerde sichern] nach %s\n' "$BACKUP_DIR"
else
	mkdir -p "$BACKUP_DIR" || die "$RC_BACKUP" "Das Sicherungsverzeichnis liess sich nicht anlegen." "Pruefe den freien Speicherplatz unter /var."
	{
		cp -a /etc/default/grub            "$BACKUP_DIR/etc-default-grub" 2>/dev/null || true
		cp -a /boot/grub/grub.cfg          "$BACKUP_DIR/grub.cfg" 2>/dev/null || true
		cp -a /etc/apt/sources.list        "$BACKUP_DIR/sources.list" 2>/dev/null || true
		cp -a /etc/apt/sources.list.d      "$BACKUP_DIR/sources.list.d" 2>/dev/null || true
		cp -a /etc/modprobe.d              "$BACKUP_DIR/modprobe.d" 2>/dev/null || true
		cp -a /etc/modules-load.d          "$BACKUP_DIR/modules-load.d" 2>/dev/null || true
		cp -a /etc/initramfs-tools/modules "$BACKUP_DIR/initramfs-modules" 2>/dev/null || true
		cp -a /etc/t2fand.conf             "$BACKUP_DIR/t2fand.conf" 2>/dev/null || true
	}
	dpkg --get-selections > "$BACKUP_DIR/dpkg-selections.txt"
	apt-mark showhold    > "$BACKUP_DIR/apt-holds-before.txt" 2>/dev/null || true
	dpkg-query -W -f='${Package} ${Version}\n' 'linux-image-*' 'linux-headers-*' \
		> "$BACKUP_DIR/kernel-packages.txt" 2>/dev/null || true
	find /boot -maxdepth 1 \( -name 'vmlinuz-*' -o -name 'initrd.img-*' \) -printf '%f %s\n' \
		> "$BACKUP_DIR/boot-listing.txt" 2>/dev/null || true
	cp /proc/cmdline "$BACKUP_DIR/cmdline-before.txt" 2>/dev/null || true
	find /lib/firmware/brcm -maxdepth 1 -type f -printf '%f %s\n' \
		> "$BACKUP_DIR/firmware-brcm.txt" 2>/dev/null || true
	uname -r > "$BACKUP_DIR/running-kernel.txt"
	printf '%s\n' "$STAMP" > "$BACKUP_DIR/stamp.txt"
	( cd "$BACKUP_DIR" && find . -type f -print0 | sort -z | xargs -0 sha256sum > ../"SHA256SUMS-$STAMP" ) 2>/dev/null || true
	log_ok "Sicherung liegt in $BACKUP_DIR"
	mkdir -p "$MT2_STATE_DIR"
	printf '%s\n' "$BACKUP_DIR" > "$MT2_STATE_DIR/last-backup"
fi

# ---------------------------------------------------------------------------
log_step "Vorhandene Kernel schuetzen"
# ---------------------------------------------------------------------------
declare -a HOLDS=()
mapfile -t HOLDS < <(dpkg-query -W -f='${Package} ${Status}\n' 'linux-image-*-generic' 'linux-headers-*-generic' \
	'linux-modules-*-generic' 'linux-modules-extra-*-generic' 2>/dev/null \
	| awk '$NF=="installed"{print $1}' | sort -u || true)
if [ "${#HOLDS[@]}" -eq 0 ]; then
	log_warn "Es wurden keine Ubuntu-Kernelpakete zum Schutz gefunden."
else
	log_info "${#HOLDS[@]} Ubuntu-Kernelpakete werden gegen automatische Entfernung geschuetzt."
	run apt-mark hold "${HOLDS[@]}"
	if [ "$DRY_RUN" -eq 0 ]; then
		printf '%s\n' "${HOLDS[@]}" > "$MT2_STATE_DIR/held-by-maximus.txt"
	fi
fi

# ---------------------------------------------------------------------------
log_step "Lokale Paketquelle einrichten"
# ---------------------------------------------------------------------------
APT_LINE="deb [arch=amd64 trusted=yes] file://$ROOT/packages ./"
if [ "$DRY_RUN" -eq 1 ]; then
	printf '         [wuerde schreiben] %s\n' "$MT2_APT_LIST"
	printf '         Inhalt: %s\n' "$APT_LINE"
else
	printf '# MAXIMUS_T2_INSTALLER_V4 - lokale Offline-Paketquelle\n# Entfernt durch scripts/rollback.sh\n%s\n' \
		"$APT_LINE" > "$MT2_APT_LIST"
	log_ok "geschrieben: $MT2_APT_LIST"
fi

if [ "$DRY_RUN" -eq 1 ]; then
	printf '         [wuerde ausfuehren] apt-get update\n'
else
	apt-get update -o Dir::Etc::sourcelist="$MT2_APT_LIST" -o Dir::Etc::sourceparts="-" \
		-o APT::Get::List-Cleanup="0" >/dev/null 2>&1 \
		|| die "$RC_REPO" "Die lokale Paketquelle liess sich nicht lesen." "Pruefe die Datei $ROOT/packages/Packages."
	log_ok "Die lokale Paketquelle ist eingelesen."
fi

# ---------------------------------------------------------------------------
log_step "Installation simulieren"
# ---------------------------------------------------------------------------
SIM_FILE="$(mktemp -t maximus-t2-sim-XXXXXX)"
# shellcheck disable=SC2317  # Die Funktion ruft die EXIT-Falle auf.
cleanup_sim() { rm -f "$SIM_FILE"; }
trap cleanup_sim EXIT

if apt-get install -s -y --no-install-recommends "${PKGLIST[@]}" > "$SIM_FILE" 2>&1; then
	log_ok "Die Simulation war erfolgreich."
	grep -E 'newly installed|upgraded,' "$SIM_FILE" | tail -1 | sed 's/^/         /'
	log_info "Neu installierte Pakete:"
	grep -E '^Inst ' "$SIM_FILE" | awk '{print "         " $2 " " $3}' | head -40
	INST_TOTAL="$(grep -cE '^Inst ' "$SIM_FILE" || true)"
	log_info "Gesamtzahl: ${INST_TOTAL} Pakete"
	if grep -qE '^Remv ' "$SIM_FILE"; then
		log_err "Die Simulation wuerde Pakete ENTFERNEN:"
		grep -E '^Remv ' "$SIM_FILE" | sed 's/^/         /'
		die "$RC_DEPS" "Die Installation wuerde Pakete entfernen." \
			"Das ist nicht zulaessig. Pruefe den Paketbestand des Zielgeraets."
	fi
	log_ok "Es wird kein Paket entfernt."
else
	log_err "Die Simulation ist fehlgeschlagen:"
	sed -n '1,30p' "$SIM_FILE" | sed 's/^/         /'
	die "$RC_DEPS" "Die Paketabhaengigkeiten sind nicht erfuellbar." \
		"Pruefe die Meldungen oben. Ergaenze fehlende Pakete im Installationspaket."
fi

if [ "$DRY_RUN" -eq 1 ]; then
	log_step "Simulation beendet"
	log_ok "Alle Pruefungen der Simulation sind bestanden."
	log ""
	log "Es wurde nichts geaendert."
	log "Starte die echte Installation mit:"
	log "  sudo $0"
	exit "$RC_OK"
fi

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
log "Nicht angetastet werden: EFI, NVRAM, Partitionen, vorhandene Ubuntu-Kernel."
if [ "$ASSUME_YES" -eq 1 ]; then
	log_warn "Die Freigabe wurde mit --yes vorausgesetzt."
else
	if ! mt2_confirm "Soll die Installation jetzt dauerhaft ausgefuehrt werden?"; then
		die "$RC_ABORT" "Die Freigabe wurde nicht erteilt." "Es wurde nichts installiert. Die Sicherung bleibt in $BACKUP_DIR."
	fi
	log_ok "Freigabe erteilt."
fi

# ---------------------------------------------------------------------------
log_step "T2-Kernel und Treiber installieren"
# ---------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
if ! apt-get install -y --no-install-recommends "${PKGLIST[@]}"; then
	die "$RC_DEPS" "Die Paketinstallation ist fehlgeschlagen." \
		"Setze den Zustand mit 'sudo ./scripts/rollback.sh' zurueck."
fi
log_ok "Die Pakete sind installiert."

if [ ! -f "/boot/vmlinuz-$MT2_KERNEL_RELEASE" ]; then
	die "$RC_GRUB" "Das Kernelabbild /boot/vmlinuz-$MT2_KERNEL_RELEASE fehlt." \
		"Die Installation war unvollstaendig. Setze mit 'sudo ./scripts/rollback.sh' zurueck."
fi
log_ok "Kernelabbild gefunden: /boot/vmlinuz-$MT2_KERNEL_RELEASE"

# ---------------------------------------------------------------------------
log_step "Module und Konfiguration schreiben"
# ---------------------------------------------------------------------------
write_file "$ROOT/config/modules/t2.conf"           /etc/modules-load.d/t2.conf
write_file "$ROOT/config/modules/t2-touchbar.conf"  /etc/modprobe.d/t2-touchbar.conf
write_file "$ROOT/config/modules/initramfs-modules.conf" /etc/initramfs-tools/modules 1
write_file "$ROOT/config/network/99-network-t2-ncm.rules" /etc/udev/rules.d/99-network-t2-ncm.rules
write_file "$ROOT/config/network/99-network-t2-ncm.conf"  /etc/NetworkManager/conf.d/99-network-t2-ncm.conf
write_file "$ROOT/config/power/99-maximus-t2-sleep.conf"  /etc/systemd/logind.conf.d/99-maximus-t2-sleep.conf

# ---------------------------------------------------------------------------
log_step "Luefterdienst einrichten"
# ---------------------------------------------------------------------------
run systemctl enable t2fanrd
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
	log_ok "Die Luefterkurve ist auf 55 bis 80 Grad Celsius gesetzt."
	systemctl restart t2fanrd 2>/dev/null || log_warn "Der Dienst t2fanrd liess sich nicht neu starten."
else
	log_warn "/etc/t2fand.conf wurde noch nicht erzeugt. Pruefe die Werte nach dem Teststart."
	log_info "Referenzwerte stehen in config/fan/t2fand.conf.reference."
fi

# ---------------------------------------------------------------------------
log_step "Kernelparameter in GRUB ergaenzen"
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
log_step "Initialramdisk und GRUB-Menue neu erzeugen"
# ---------------------------------------------------------------------------
if ! update-initramfs -u -k all; then
	die "$RC_GRUB" "Die Initialramdisk liess sich nicht erzeugen." \
		"Starte das Geraet NICHT neu. Fuehre 'sudo ./scripts/rollback.sh' aus."
fi
log_ok "Die Initialramdisk ist erzeugt."

if ! update-grub; then
	die "$RC_GRUB" "Das GRUB-Menue liess sich nicht erzeugen." \
		"Starte das Geraet NICHT neu. Fuehre 'sudo ./scripts/rollback.sh' aus."
fi
log_ok "Das GRUB-Menue ist erzeugt."

if ! bash -n /boot/grub/grub.cfg 2>/dev/null; then
	die "$RC_GRUB" "Die neue GRUB-Konfiguration hat einen Syntaxfehler." \
		"Stelle sie sofort zurueck: sudo cp $BACKUP_DIR/grub.cfg /boot/grub/grub.cfg"
fi
log_ok "Die GRUB-Konfiguration hat keine Syntaxfehler."

if ! grep -q "$MT2_KERNEL_RELEASE" /boot/grub/grub.cfg; then
	die "$RC_GRUB" "Im GRUB-Menue fehlt ein Eintrag fuer $MT2_KERNEL_RELEASE." \
		"Pruefe /boot und fuehre 'sudo update-grub' erneut aus."
fi
log_ok "Das GRUB-Menue enthaelt einen Eintrag fuer $MT2_KERNEL_RELEASE."

# ---------------------------------------------------------------------------
log_step "Einmaligen Teststart vorbereiten"
# ---------------------------------------------------------------------------
ENTRY="$("$SELF_DIR/lib/grub-entry.sh" "$MT2_KERNEL_RELEASE" || true)"
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
{
	printf 'stamp=%s\n' "$STAMP"
	printf 'kernel_package=%s\n' "$MT2_KERNEL_PACKAGE"
	printf 'kernel_version=%s\n' "$MT2_KERNEL_VERSION"
	printf 'kernel_release=%s\n' "$MT2_KERNEL_RELEASE"
	printf 'backup_dir=%s\n' "$BACKUP_DIR"
	printf 'package_root=%s\n' "$ROOT"
	printf 'installed_packages=%s\n' "$INST_TOTAL"
} > "$MT2_STATE_DIR/install-state"

log_ok "PACKAGE_READY und INSTALLATION_READY sind erfuellt."
log_warn "HARDWARE_READY ist NICHT erteilt. Die Hardwaretests fehlen noch."
log ""
log "Naechste Schritte:"
log "  1. Lies recovery/GRUB-NOTSTART.txt. Lege das Blatt bereit."
log "  2. Starte das Geraet neu: sudo reboot"
log "  3. Melde dich an. Nutze bei Bedarf eine externe USB-Tastatur."
log "  4. Fuehre die Abnahme aus: sudo ./scripts/verify.sh"
log "  5. Hole die WLAN-Firmware nach firmware/README.md."
log ""
log "Bei einem Fehlstart: Waehle im GRUB-Menue den Kernel $(uname -r)."
log "Zum Zurueckrollen: sudo ./scripts/rollback.sh"
exit "$RC_OK"
