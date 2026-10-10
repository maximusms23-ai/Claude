#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - Aenderungen zuruecknehmen
#
# Ergebnis: Das Zielgeraet startet wieder mit der Konfiguration von vor der
# Installation. Die vorhandenen Ubuntu-Kernel bleiben unangetastet.
#
# Aufruf:  sudo ./rollback.sh [OPTIONEN]
#   --dry-run        Simuliert alle Schritte. Es wird nichts geaendert.
#   --backup PFAD    Nutzt diese Sicherung. Standard ist die letzte Sicherung.
#   --purge-t2       Entfernt zusaetzlich die T2-Pakete und den T2-Kernel.
#   --keep-holds     Laesst den Schutz der Ubuntu-Kernel bestehen.
#   --yes            Setzt die Freigabe voraus.
#   --no-color       Gibt keine Farbcodes aus.
#
# Standardverhalten: Die Konfiguration wird zurueckgesetzt. Der T2-Kernel
# bleibt installiert, wird aber nicht mehr gestartet. Das ist der sicherste
# Weg, weil kein Bootpfad geloescht wird.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"

DRY_RUN=0
PURGE=0
KEEP_HOLDS=0
ASSUME_YES=0
BACKUP_DIR=''

while [ "$#" -gt 0 ]; do
	case "$1" in
		--dry-run)    DRY_RUN=1 ;;
		--backup)     shift; BACKUP_DIR="${1:-}" ;;
		--purge-t2)   PURGE=1 ;;
		--keep-holds) KEEP_HOLDS=1 ;;
		--yes)        ASSUME_YES=1 ;;
		--no-color)   NO_COLOR=1; export NO_COLOR ;;
		-h|--help)    sed -n '2,20p' "$0"; exit "$RC_OK" ;;
		*)            die "$RC_USAGE" "Unbekannte Option '$1'." "Rufe '$0 --help' auf." ;;
	esac
	shift
done

mt2_require_root "$@"

run() {
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde ausfuehren] %s\n' "$*"
		return 0
	fi
	log_info "fuehre aus: $*"
	"$@"
}

remove_path() {
	local p="$1"
	if [ ! -e "$p" ]; then
		log_info "nicht vorhanden, uebersprungen: $p"
		return 0
	fi
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde loeschen] %s\n' "$p"
	else
		rm -f "$p" && log_ok "geloescht: $p"
	fi
}

log "MAXIMUS_T2_INSTALLER_V4 - Rueckfall"
if [ "$DRY_RUN" -eq 1 ]; then
	log "Betriebsart: SIMULATION (es wird nichts geaendert)"
else
	log "Betriebsart: ECHTER RUECKFALL"
	mt2_start_log rollback
fi

# ---------------------------------------------------------------------------
log_step "Sicherung auswaehlen"
# ---------------------------------------------------------------------------
if [ -z "$BACKUP_DIR" ] && [ -f "$MT2_STATE_DIR/last-backup" ]; then
	BACKUP_DIR="$(cat "$MT2_STATE_DIR/last-backup")"
fi
if [ -z "$BACKUP_DIR" ]; then
	BACKUP_DIR="$(find "$MT2_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1 || true)"
fi
if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
	die "$RC_BACKUP" "Es wurde keine Sicherung gefunden." \
		"Gib eine Sicherung an: $0 --backup $MT2_BACKUP_ROOT/<Zeitstempel>"
fi
log_ok "Sicherung: $BACKUP_DIR"
[ -f "$BACKUP_DIR/running-kernel.txt" ] && log_info "Kernel vor der Installation: $(cat "$BACKUP_DIR/running-kernel.txt")"

# ---------------------------------------------------------------------------
log_step "Umfang anzeigen"
# ---------------------------------------------------------------------------
log "Es werden zurueckgenommen:"
log "  1. /etc/default/grub aus der Sicherung."
log "  2. Die T2-Konfigurationsdateien unter /etc."
log "  3. Die lokale Offline-Paketquelle."
log "  4. Die Abschaltung des Ruhezustands."
if [ "$KEEP_HOLDS" -eq 0 ]; then
	log "  5. Der Schutz der Ubuntu-Kernel wird aufgehoben."
fi
if [ "$PURGE" -eq 1 ]; then
	log_warn "  6. Die T2-Pakete und der T2-Kernel werden ENTFERNT."
else
	log "  6. Der T2-Kernel bleibt installiert. Er wird nur nicht mehr gestartet."
fi
log ""
log "Nicht angetastet werden: EFI, NVRAM, Partitionen, Ubuntu-Kernel, Benutzerdaten."

if [ "$DRY_RUN" -eq 0 ] && [ "$ASSUME_YES" -eq 0 ]; then
	if ! mt2_confirm "Soll der Rueckfall jetzt ausgefuehrt werden?"; then
		die "$RC_ABORT" "Die Freigabe wurde nicht erteilt." "Es wurde nichts geaendert."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Bootkonfiguration zuruecksetzen"
# ---------------------------------------------------------------------------
if [ -f "$BACKUP_DIR/etc-default-grub" ]; then
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde zuruecksetzen] %s -> /etc/default/grub\n' "$BACKUP_DIR/etc-default-grub"
	else
		cp -a /etc/default/grub "/etc/default/grub.maximus-before-rollback" 2>/dev/null || true
		install -m 0644 "$BACKUP_DIR/etc-default-grub" /etc/default/grub
		log_ok "zurueckgesetzt: /etc/default/grub"
	fi
else
	log_warn "In der Sicherung fehlt /etc/default/grub. Die Datei bleibt unveraendert."
fi

# ---------------------------------------------------------------------------
log_step "T2-Konfigurationsdateien entfernen"
# ---------------------------------------------------------------------------
remove_path /etc/modules-load.d/t2.conf
remove_path /etc/modprobe.d/t2-touchbar.conf
remove_path /etc/udev/rules.d/99-network-t2-ncm.rules
remove_path /etc/NetworkManager/conf.d/99-network-t2-ncm.conf
remove_path /etc/systemd/logind.conf.d/99-maximus-t2-sleep.conf
remove_path "$MT2_APT_LIST"

if [ -f "$BACKUP_DIR/initramfs-modules" ]; then
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde zuruecksetzen] /etc/initramfs-tools/modules\n'
	else
		install -m 0644 "$BACKUP_DIR/initramfs-modules" /etc/initramfs-tools/modules
		log_ok "zurueckgesetzt: /etc/initramfs-tools/modules"
	fi
elif [ -f /etc/initramfs-tools/modules ]; then
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde bereinigen] /etc/initramfs-tools/modules\n'
	else
		sed -i '/MAXIMUS_T2_INSTALLER_V4/,$d' /etc/initramfs-tools/modules
		log_ok "bereinigt: /etc/initramfs-tools/modules"
	fi
fi

if [ -f "$BACKUP_DIR/t2fand.conf" ]; then
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde zuruecksetzen] /etc/t2fand.conf\n'
	else
		install -m 0644 "$BACKUP_DIR/t2fand.conf" /etc/t2fand.conf
		log_ok "zurueckgesetzt: /etc/t2fand.conf"
	fi
fi

# ---------------------------------------------------------------------------
log_step "Kernelschutz behandeln"
# ---------------------------------------------------------------------------
if [ "$KEEP_HOLDS" -eq 1 ]; then
	log_info "Der Schutz der Ubuntu-Kernel bleibt bestehen."
elif [ -f "$MT2_STATE_DIR/held-by-maximus.txt" ]; then
	declare -a HELD=()
	mapfile -t HELD < "$MT2_STATE_DIR/held-by-maximus.txt"
	if [ "${#HELD[@]}" -gt 0 ]; then
		run apt-mark unhold "${HELD[@]}"
	fi
else
	log_info "Es ist keine Liste geschuetzter Pakete hinterlegt."
fi

# ---------------------------------------------------------------------------
log_step "T2-Pakete behandeln"
# ---------------------------------------------------------------------------
if [ "$PURGE" -eq 1 ]; then
	declare -a T2PKGS=()
	mapfile -t T2PKGS < <(dpkg-query -W -f='${Package} ${Status}\n' \
		'linux-t2*' 'linux-image-*-t2-noble' 'linux-headers-*-t2-noble' \
		'tiny-dfr' 't2fanrd' 't2-ncm' 't2-touchid' 'apple-t2-audio-config' \
		't2-apple-audio-dsp-*' 'apple-firmware-script' 2>/dev/null \
		| awk '$NF=="installed"{print $1}' | sort -u || true)
	if [ "${#T2PKGS[@]}" -eq 0 ]; then
		log_info "Es ist kein T2-Paket installiert."
	else
		log_warn "Folgende Pakete werden entfernt:"
		printf '         %s\n' "${T2PKGS[@]}"
		# Gegenprobe: Es darf kein Ubuntu-Kernel betroffen sein.
		for p in "${T2PKGS[@]}"; do
			case "$p" in
				*-generic) die "$RC_BACKUP" "Die Entfernungsliste enthaelt den Ubuntu-Kernel '$p'." \
					"Das ist nicht zulaessig. Brich ab und melde den Fehler." ;;
			esac
		done
		run apt-get purge -y "${T2PKGS[@]}"
		run apt-get autoremove -y
	fi
else
	log_info "Der T2-Kernel bleibt installiert."
	log_info "Waehle beim Start den Ubuntu-Kernel im GRUB-Menue."
fi

# ---------------------------------------------------------------------------
log_step "Initialramdisk und GRUB-Menue erneuern"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
	printf '         [wuerde ausfuehren] update-initramfs -u -k all\n'
	printf '         [wuerde ausfuehren] update-grub\n'
else
	update-initramfs -u -k all || log_warn "update-initramfs meldete einen Fehler. Pruefe die Ausgabe."
	if ! update-grub; then
		log_err "update-grub schlug fehl."
		if [ -f "$BACKUP_DIR/grub.cfg" ]; then
			install -m 0444 "$BACKUP_DIR/grub.cfg" /boot/grub/grub.cfg
			log_ok "Die gesicherte grub.cfg wurde direkt zurueckgeschrieben."
		else
			die "$RC_GRUB" "Das GRUB-Menue liess sich nicht erneuern und es gibt keine Sicherung." \
				"Starte NICHT neu. Lies recovery/GRUB-NOTSTART.txt."
		fi
	fi
	if ! bash -n /boot/grub/grub.cfg 2>/dev/null; then
		if [ -f "$BACKUP_DIR/grub.cfg" ]; then
			install -m 0444 "$BACKUP_DIR/grub.cfg" /boot/grub/grub.cfg
			log_warn "Die neue grub.cfg war fehlerhaft. Die Sicherung wurde zurueckgeschrieben."
		else
			die "$RC_GRUB" "Die GRUB-Konfiguration ist fehlerhaft." "Starte NICHT neu. Lies recovery/GRUB-NOTSTART.txt."
		fi
	fi
	log_ok "Die GRUB-Konfiguration ist gueltig."
fi

# ---------------------------------------------------------------------------
log_step "Abschluss"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	remove_path "$MT2_STATE_DIR/test-boot-entry"
	systemctl restart systemd-logind 2>/dev/null || log_warn "systemd-logind startete nicht neu. Ein Neustart behebt das."
fi
log_ok "Der Rueckfall ist abgeschlossen."
log ""
log "Pruefe vor dem Neustart:"
log "  grep -c menuentry /boot/grub/grub.cfg"
log "  ls /boot/vmlinuz-*"
log ""
log "Starte danach neu: sudo reboot"
exit "$RC_OK"
