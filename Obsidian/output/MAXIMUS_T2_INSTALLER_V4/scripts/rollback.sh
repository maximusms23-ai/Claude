#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.1 - Aenderungen zuruecknehmen
#
# Ergebnis: Das Zielgeraet erhaelt die Konfiguration von vor der Installation
# zurueck. Die vorhandenen Ubuntu-Kernel bleiben unangetastet.
#
# Grundsatz: Es wird ausschliesslich das zurueckgenommen, was install.sh
# nachweislich geaendert hat. Die Nachweise stehen in
# /var/lib/maximus-t2/ und in der versiegelten Sicherung.
#
# Aufruf:  sudo bash rollback.sh [OPTIONEN]
#   --dry-run            Simuliert alle Schritte. Es wird nichts geaendert.
#   --backup PFAD        Nutzt diese Sicherung. Standard ist die letzte.
#   --remove-added       Entfernt genau die aufgezeichneten neuen Pakete.
#   --purge-added        Wie --remove-added, entfernt zusaetzlich deren Konfiguration.
#   --keep-holds         Laesst den Schutz der Ubuntu-Kernel bestehen.
#   --force-unverified   Nutzt eine Sicherung trotz fehlgeschlagener Pruefung.
#   --yes                Setzt die Freigabe voraus.
#   --no-color           Gibt keine Farbcodes aus.
#
# Standardverhalten: Nur die Konfiguration wird zurueckgesetzt.
# Die T2-Pakete bleiben installiert. Der T2-Kernel wird nicht mehr gestartet.
# Das ist der sicherste Weg, weil kein Bootpfad geloescht wird.
#
# Es wird NIEMALS 'apt-get autoremove' ausgefuehrt.
# Dieser Befehl entscheidet selbst, welche Pakete er entfernt.
# Das widerspricht dem Grundsatz oben.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"

DRY_RUN=0
REMOVE_ADDED=0
PURGE_ADDED=0
KEEP_HOLDS=0
FORCE_UNVERIFIED=0
ASSUME_YES=0
BACKUP_DIR=''

while [ "$#" -gt 0 ]; do
	case "$1" in
		--dry-run)          DRY_RUN=1 ;;
		--backup)           mt2_opt_needs_value "$#" --backup; BACKUP_DIR="$2"; shift ;;
		--remove-added)     REMOVE_ADDED=1 ;;
		--purge-added)      REMOVE_ADDED=1; PURGE_ADDED=1 ;;
		--keep-holds)       KEEP_HOLDS=1 ;;
		--force-unverified) FORCE_UNVERIFIED=1 ;;
		--yes)              ASSUME_YES=1 ;;
		--no-color)         NO_COLOR=1; export NO_COLOR ;;
		-h|--help)          sed -n '2,30p' "$0"; exit "$RC_OK" ;;
		*)                  die "$RC_USAGE" "Unbekannte Option '$1'." "Rufe 'bash $0 --help' auf." ;;
	esac
	shift
done

mt2_require_root "$@"

CHANGES=0

act() {
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde ausfuehren] %s\n' "$*"
		return 0
	fi
	log_info "fuehre aus: $*"
	CHANGES=$((CHANGES + 1))
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
		rm -f "$p" && log_ok "geloescht: $p" && CHANGES=$((CHANGES + 1))
	fi
}

restore_file() {
	local src="$1" dst="$2"
	if [ ! -f "$src" ]; then
		log_warn "In der Sicherung fehlt die Vorgaengerfassung von $dst. Die Datei bleibt unveraendert."
		return 1
	fi
	if [ "$DRY_RUN" -eq 1 ]; then
		printf '         [wuerde zuruecksetzen] %s -> %s\n' "${src##*/}" "$dst"
		return 0
	fi
	mkdir -p "$(dirname "$dst")"
	install -m 0644 "$src" "$dst" && log_ok "zurueckgesetzt: $dst" && CHANGES=$((CHANGES + 1))
	return 0
}

# Bildet einen Live-Pfad auf die Datei in der Sicherung ab.
# Gibt eine leere Zeichenkette aus, wenn es keine Zuordnung gibt.
backup_path_for() {
	local live="$1" base
	base="$(basename "$live")"
	case "$live" in
		/etc/default/grub)                    printf '%s\n' "$BACKUP_DIR/etc-default-grub" ;;
		/boot/grub/grub.cfg)                  printf '%s\n' "$BACKUP_DIR/grub.cfg" ;;
		/etc/t2fand.conf)                     printf '%s\n' "$BACKUP_DIR/t2fand.conf" ;;
		/etc/initramfs-tools/modules)         printf '%s\n' "$BACKUP_DIR/initramfs-modules" ;;
		/etc/modules-load.d/*)                printf '%s\n' "$BACKUP_DIR/modules-load.d/$base" ;;
		/etc/modprobe.d/*)                    printf '%s\n' "$BACKUP_DIR/modprobe.d/$base" ;;
		/etc/udev/rules.d/*)                  printf '%s\n' "$BACKUP_DIR/udev-rules.d/$base" ;;
		/etc/NetworkManager/conf.d/*)         printf '%s\n' "$BACKUP_DIR/NetworkManager-conf.d/$base" ;;
		/etc/systemd/logind.conf.d/*)         printf '%s\n' "$BACKUP_DIR/logind.conf.d/$base" ;;
		*)                                    printf '\n' ;;
	esac
}

log "MAXIMUS_T2_INSTALLER V$MT2_VERSION - Rueckfall"
if [ "$DRY_RUN" -eq 1 ]; then
	log "Betriebsart: SIMULATION (es wird nichts geaendert)"
else
	log "Betriebsart: ECHTER RUECKFALL"
	mt2_start_log rollback
fi

# ---------------------------------------------------------------------------
log_step "Zustand der Installation lesen"
# ---------------------------------------------------------------------------
PHASE='unbekannt'
if [ -f "$MT2_STATE_DIR/install-state" ]; then
	PHASE="$(awk -F= '/^phase=/{print $2}' "$MT2_STATE_DIR/install-state" | tail -1)"
	log_info "Aufgezeichneter Zustand:"
	sed 's/^/         /' "$MT2_STATE_DIR/install-state"
	case "$PHASE" in
		done) log_ok "Die Installation war vollstaendig." ;;
		''|unbekannt) log_warn "Der Zustand ist nicht lesbar." ;;
		*) log_warn "Die Installation wurde in der Phase '$PHASE' unterbrochen."
		   log_warn "Der Rueckfall nimmt nur die bis dahin erfolgten Aenderungen zurueck." ;;
	esac
else
	log_warn "Es liegt keine Zustandsdatei vor. Es lief vermutlich keine Installation."
fi

# ---------------------------------------------------------------------------
log_step "Sicherung auswaehlen und pruefen"
# ---------------------------------------------------------------------------
if [ -z "$BACKUP_DIR" ] && [ -f "$MT2_STATE_DIR/last-backup" ]; then
	BACKUP_DIR="$(cat "$MT2_STATE_DIR/last-backup")"
fi
if [ -z "$BACKUP_DIR" ]; then
	BACKUP_DIR="$(find "$MT2_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1 || true)"
fi
if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
	die "$RC_BACKUP" "Es wurde keine Sicherung gefunden." \
		"Gib eine Sicherung an: bash $0 --backup $MT2_BACKUP_ROOT/<Zeitstempel>"
fi
log_ok "Sicherung: $BACKUP_DIR"
[ -f "$BACKUP_DIR/running-kernel.txt" ] && log_info "Kernel vor der Installation: $(cat "$BACKUP_DIR/running-kernel.txt")"
[ -f "$BACKUP_DIR/installer-version.txt" ] && log_info "Erzeugt von Fassung: $(cat "$BACKUP_DIR/installer-version.txt")"

# V4.1: Die Sicherung wird gegen ihre eigene Pruefsummenliste geprueft.
# Ohne diese Pruefung koennte der Rueckfall eine beschaedigte Datei einspielen.
# Achtung: 'set -e' beendet das Skript, wenn eine Funktion direkt vor
# 'case $?' einen Wert ungleich 0 liefert.
BAK_RC=0
mt2_backup_verify "$BACKUP_DIR" || BAK_RC=$?
case "$BAK_RC" in
	0) log_ok "Die Sicherung ist unverfaelscht ($(grep -c . "$BACKUP_DIR/SHA256SUMS") Dateien)." ;;
	2) if [ "$FORCE_UNVERIFIED" -eq 1 ]; then
		log_warn "Die Sicherung hat keine Pruefsummenliste. Sie stammt vermutlich aus Fassung V4.0."
		log_warn "Sie wird auf ausdrueckliche Anweisung dennoch genutzt."
	   else
		die "$RC_CHECKSUM" "Die Sicherung hat keine Pruefsummenliste (SHA256SUMS)." \
			"Pruefe den Inhalt von $BACKUP_DIR von Hand. Nutze danach --force-unverified."
	   fi ;;
	*) if [ "$FORCE_UNVERIFIED" -eq 1 ]; then
		log_warn "Die Sicherung ist VERAENDERT. Sie wird auf ausdrueckliche Anweisung dennoch genutzt."
		( cd "$BACKUP_DIR" && sha256sum -c SHA256SUMS 2>&1 | grep -v ': OK$' | head -10 | sed 's/^/         /' ) || true
	   else
		log_err "Diese Dateien der Sicherung stimmen nicht mit der Liste ueberein:"
		( cd "$BACKUP_DIR" && sha256sum -c SHA256SUMS 2>&1 | grep -v ': OK$' | head -10 | sed 's/^/         /' ) || true
		die "$RC_CHECKSUM" "Die Sicherung ist veraendert." \
			"Spiele keine veraenderte Sicherung ein. Pruefe sie von Hand. Nutze danach --force-unverified."
	   fi ;;
esac

# ---------------------------------------------------------------------------
log_step "Umfang ermitteln"
# ---------------------------------------------------------------------------
declare -a WRITTEN=()
if [ -f "$MT2_STATE_DIR/files-written.txt" ]; then
	mapfile -t WRITTEN < "$MT2_STATE_DIR/files-written.txt"
	log_ok "${#WRITTEN[@]} Dateiaenderungen sind aufgezeichnet."
else
	log_warn "Es liegt keine Aufzeichnung der Dateiaenderungen vor."
	log_warn "Der Rueckfall nutzt die bekannte Dateiliste der Fassung V$MT2_VERSION."
	WRITTEN=(
		"create	/etc/modules-load.d/t2.conf"
		"create	/etc/modprobe.d/t2-touchbar.conf"
		"append	/etc/initramfs-tools/modules"
		"create	/etc/udev/rules.d/99-network-t2-ncm.rules"
		"create	/etc/NetworkManager/conf.d/99-network-t2-ncm.conf"
		"create	/etc/systemd/logind.conf.d/99-maximus-t2-sleep.conf"
		"replace	/etc/default/grub"
	)
fi

declare -a ADDED=()
if [ -f "$MT2_STATE_DIR/packages-added.txt" ]; then
	mapfile -t ADDED < <(cut -f1 "$MT2_STATE_DIR/packages-added.txt")
fi
declare -a CHANGED=()
if [ -f "$MT2_STATE_DIR/packages-changed.txt" ]; then
	mapfile -t CHANGED < <(cut -f1 "$MT2_STATE_DIR/packages-changed.txt")
fi

log "Es werden zurueckgenommen:"
log "  1. ${#WRITTEN[@]} aufgezeichnete Dateiaenderungen unter /etc."
log "  2. Die gepinnte Offline-Paketquelle unter $MT2_APT_DIR."
log "  3. Ein Alteintrag der Fassung V4.0 unter /etc/apt/sources.list.d, falls vorhanden."
log "  3a. Ein noch offener Teststart in den T2-Kernel."
log "  3b. Der Vorgabeeintrag wird auf den Kernel von vor der Installation gesetzt."
if [ "$KEEP_HOLDS" -eq 0 ]; then
	log "  4. Der von install.sh gesetzte Kernelschutz wird aufgehoben."
else
	log "  4. Der Kernelschutz bleibt bestehen."
fi
if [ "$REMOVE_ADDED" -eq 1 ]; then
	log_warn "  5. ${#ADDED[@]} aufgezeichnete neue Pakete werden entfernt."
else
	log "  5. Die T2-Pakete bleiben installiert. Der T2-Kernel wird nur nicht mehr gestartet."
fi
log ""
log "Es wird KEIN 'apt-get autoremove' ausgefuehrt."
log "Nicht angetastet werden: EFI, NVRAM, Partitionen, Ubuntu-Kernel, Benutzerdaten."

if [ "$DRY_RUN" -eq 0 ] && [ "$ASSUME_YES" -eq 0 ]; then
	if ! mt2_confirm "Soll der Rueckfall jetzt ausgefuehrt werden?"; then
		die "$RC_ABORT" "Die Freigabe wurde nicht erteilt." "Es wurde nichts geaendert."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Aufgezeichnete Dateiaenderungen zuruecknehmen"
# ---------------------------------------------------------------------------
for rec in "${WRITTEN[@]}"; do
	[ -n "$rec" ] || continue
	kind="${rec%%	*}"
	path="${rec#*	}"
	case "$kind" in
		create)
			# Die Datei gab es vorher nicht. Sie wird entfernt.
			remove_path "$path"
			;;
		replace)
			bak="$(backup_path_for "$path")"
			if [ -n "$bak" ] && [ -f "$bak" ]; then
				restore_file "$bak" "$path"
			else
				log_warn "Fuer '$path' liegt keine Vorgaengerfassung in der Sicherung. Die Datei bleibt unveraendert."
			fi
			;;
		append)
			bak="$(backup_path_for "$path")"
			if [ -n "$bak" ] && [ -f "$bak" ]; then
				restore_file "$bak" "$path"
			elif [ -f "$path" ]; then
				# V4.1: Nur den eigenen Block entfernen, nicht bis zum Dateiende.
				if [ "$DRY_RUN" -eq 1 ]; then
					printf '         [wuerde eigenen Block entfernen] %s\n' "$path"
				else
					sed -i -e '/^# MAXIMUS_T2_INSTALLER/,/^t2bce_vhci$/d' \
					       -e '/^# Required modules for getting the built-in apple keyboard/d' "$path"
					log_ok "eigener Block entfernt: $path"
					CHANGES=$((CHANGES + 1))
				fi
			fi
			;;
		*)
			log_warn "Unbekannte Aufzeichnung: '$rec'"
			;;
	esac
done

# Die Offline-Paketquelle und der Alteintrag der Fassung V4.0.
remove_path "$MT2_APT_LIST"
remove_path "$MT2_APT_CONF"
remove_path "$MT2_APT_LIST_LEGACY"
if [ -d "$MT2_APT_LISTS" ] && [ "$DRY_RUN" -eq 0 ]; then
	rm -rf "$MT2_APT_LISTS" && log_ok "geloescht: $MT2_APT_LISTS"
elif [ -d "$MT2_APT_LISTS" ]; then
	printf '         [wuerde loeschen] %s\n' "$MT2_APT_LISTS"
fi

# ---------------------------------------------------------------------------
log_step "Kernelschutz behandeln"
# ---------------------------------------------------------------------------
if [ "$KEEP_HOLDS" -eq 1 ]; then
	log_info "Der Schutz der Ubuntu-Kernel bleibt bestehen."
elif [ -f "$MT2_STATE_DIR/held-by-maximus.txt" ] && [ -s "$MT2_STATE_DIR/held-by-maximus.txt" ]; then
	declare -a HELD=()
	mapfile -t HELD < "$MT2_STATE_DIR/held-by-maximus.txt"
	log_info "${#HELD[@]} Pakete wurden von install.sh geschuetzt. Der Schutz wird aufgehoben."
	if [ "${#HELD[@]}" -gt 0 ]; then
		act apt-mark unhold "${HELD[@]}"
	fi
else
	log_info "install.sh hat keinen zusaetzlichen Kernelschutz gesetzt. Es wird nichts aufgehoben."
fi

# ---------------------------------------------------------------------------
log_step "Pakete behandeln"
# ---------------------------------------------------------------------------
if [ "$REMOVE_ADDED" -eq 0 ]; then
	log_info "Die T2-Pakete bleiben installiert."
	log_info "Waehle beim Start den Ubuntu-Kernel im GRUB-Menue."
	if [ "${#ADDED[@]}" -gt 0 ]; then
		log_info "Aufgezeichnete neue Pakete: ${#ADDED[@]}. Entfernen mit --remove-added."
	fi
elif [ "${#ADDED[@]}" -eq 0 ]; then
	log_warn "Es liegt keine Aufzeichnung neuer Pakete vor."
	log_warn "Ohne Aufzeichnung wird KEIN Paket entfernt. Das ist Absicht."
	log_info "Entferne die Pakete bei Bedarf einzeln und von Hand."
else
	# V4.1: Nur aufgezeichnete Pakete. Kein Namensmuster. Kein autoremove.
	declare -a TOREMOVE=()
	for p in "${ADDED[@]}"; do
		[ -n "$p" ] || continue
		case "$p" in
			*-generic)
				die "$RC_BACKUP" "Die Aufzeichnung nennt ein Ubuntu-Kernelpaket: '$p'." \
					"Das ist nicht zulaessig. Brich ab und melde den Fehler." ;;
			grub*|systemd*|libc6|dpkg|apt)
				die "$RC_BACKUP" "Die Aufzeichnung nennt ein Systemkernpaket: '$p'." \
					"Das ist nicht zulaessig. Brich ab und melde den Fehler." ;;
		esac
		# Gegenprobe gegen den Bestand VOR der Installation.
		if [ -f "$MT2_STATE_DIR/pkg-before.txt" ] && cut -f1 "$MT2_STATE_DIR/pkg-before.txt" | grep -qx "$p"; then
			log_warn "'$p' war schon vor der Installation vorhanden. Es wird NICHT entfernt."
			continue
		fi
		if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'ok installed'; then
			TOREMOVE+=("$p")
		fi
	done
	if [ "${#TOREMOVE[@]}" -eq 0 ]; then
		log_info "Keines der aufgezeichneten Pakete ist noch installiert."
	else
		log_warn "Folgende ${#TOREMOVE[@]} Pakete werden entfernt:"
		printf '         %s\n' "${TOREMOVE[@]}"
		if [ "$PURGE_ADDED" -eq 1 ]; then
			act apt-get purge -y "${TOREMOVE[@]}"
		else
			act apt-get remove -y "${TOREMOVE[@]}"
		fi
		log_info "Es wurde KEIN 'apt-get autoremove' ausgefuehrt."
		log_info "Pruefe nicht mehr benoetigte Pakete selbst: apt-get --dry-run autoremove"
	fi
fi

if [ "${#CHANGED[@]}" -gt 0 ]; then
	log_warn "${#CHANGED[@]} Pakete wurden durch die Installation auf eine neue Fassung gebracht."
	log_warn "Eine Zurueckstufung nimmt dieses Skript NICHT selbsttaetig vor."
	log_info "Die Liste mit alter und neuer Fassung steht in:"
	log_info "  $MT2_STATE_DIR/packages-changed.txt"
fi

# ---------------------------------------------------------------------------
log_step "Initialramdisk und GRUB-Menue erneuern"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
	printf '         [wuerde ausfuehren] update-initramfs -u -k all\n'
	printf '         [wuerde ausfuehren] update-grub\n'
	printf '         [wuerde pruefen]    grub-script-check /boot/grub/grub.cfg\n'
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
	# V4.1: Pruefung mit grub-script-check statt mit 'bash -n'.
	GRUB_RC=0
	mt2_grub_check_cfg /boot/grub/grub.cfg || GRUB_RC=$?
	case "$GRUB_RC" in
		0) log_ok "grub-script-check bestaetigt die GRUB-Konfiguration." ;;
		6) log_warn "Das Programm grub-script-check fehlt. Die Konfiguration ist nicht pruefbar."
		   log_warn "Pruefe sie von Hand, bevor du neu startest." ;;
		*) if [ -f "$BACKUP_DIR/grub.cfg" ]; then
			install -m 0444 "$BACKUP_DIR/grub.cfg" /boot/grub/grub.cfg
			log_warn "Die neue grub.cfg war fehlerhaft. Die Sicherung wurde zurueckgeschrieben."
			if ! mt2_grub_check_cfg /boot/grub/grub.cfg; then
				die "$RC_GRUB" "Auch die gesicherte grub.cfg ist fehlerhaft." \
					"Starte NICHT neu. Lies recovery/GRUB-NOTSTART.txt."
			fi
			log_ok "Die zurueckgeschriebene Konfiguration ist gueltig."
		   else
			die "$RC_GRUB" "Die GRUB-Konfiguration ist fehlerhaft und es gibt keine Sicherung." \
				"Starte NICHT neu. Lies recovery/GRUB-NOTSTART.txt."
		   fi ;;
	esac

	# V4.1: Einen noch offenen Teststart aufheben.
	# 'grub-reboot' hinterlaesst 'next_entry' in der GRUB-Umgebung.
	# Ohne dieses Aufheben startet der T2-Kernel noch einmal.
	if command -v grub-editenv >/dev/null 2>&1 && [ -f /boot/grub/grubenv ]; then
		if grub-editenv /boot/grub/grubenv list 2>/dev/null | grep -q '^next_entry='; then
			if grub-editenv /boot/grub/grubenv unset next_entry; then
				log_ok "Der offene Teststart wurde aufgehoben."
			else
				log_warn "Der offene Teststart liess sich nicht aufheben."
			fi
		else
			log_info "Es ist kein Teststart offen."
		fi
	fi

	# V4.1: Den Vorgabeeintrag ausdruecklich auf den Kernel von vorher setzen.
	# 'GRUB_DEFAULT=saved' ohne gesetztes 'saved_entry' laesst GRUB selbst
	# entscheiden. Der T2-Kernel bleibt installiert, also wird es eindeutig.
	PREV_KERNEL="$(cat "$BACKUP_DIR/running-kernel.txt" 2>/dev/null || true)"
	if [ -n "$PREV_KERNEL" ]; then
		PREV_ENTRY="$(bash "$SELF_DIR/lib/grub-entry.sh" "$PREV_KERNEL" || true)"
		if [ -n "$PREV_ENTRY" ] && grub-set-default "$PREV_ENTRY" 2>/dev/null; then
			log_ok "Vorgabeeintrag gesetzt auf $PREV_KERNEL."
		else
			log_warn "Der Vorgabeeintrag fuer $PREV_KERNEL liess sich nicht setzen."
			log_warn "Waehle den Kernel beim naechsten Start im Menue."
		fi
	fi

	# V4.1: Warnen, wenn das zurueckgesetzte Menue unsichtbar bleibt.
	RT="$(grep -E '^GRUB_TIMEOUT=' /etc/default/grub 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '"' || true)"
	RS="$(grep -E '^GRUB_TIMEOUT_STYLE=' /etc/default/grub 2>/dev/null | tail -1 | cut -d= -f2 | tr -d '"' || true)"
	if [ "${RT:-10}" = "0" ] || [ "${RS:-menu}" = "hidden" ]; then
		log_warn "Die zurueckgesetzte Konfiguration zeigt das GRUB-Menue nicht an."
		log_warn "GRUB_TIMEOUT=${RT:-unbekannt}, GRUB_TIMEOUT_STYLE=${RS:-unbekannt}."
		log_warn "Der T2-Kernel ist weiter installiert. Ohne Menue ist keine Auswahl moeglich."
		log_warn "Halte beim Start die linke UMSCHALT-Taste gedrueckt, um das Menue zu erzwingen."
	else
		log_ok "Das GRUB-Menue bleibt sichtbar (GRUB_TIMEOUT=${RT:-unbekannt})."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Abschluss"
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
	remove_path "$MT2_STATE_DIR/test-boot-entry"
	printf 'version=%s\nphase=rolled-back\nbackup_dir=%s\nupdated=%s\n' \
		"$MT2_VERSION" "$BACKUP_DIR" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		> "$MT2_STATE_DIR/install-state"
	systemctl restart systemd-logind 2>/dev/null || log_warn "systemd-logind startete nicht neu. Ein Neustart behebt das."
	log_ok "Der Rueckfall ist abgeschlossen. $CHANGES Aenderungen wurden ausgefuehrt."
else
	log_ok "Die Simulation ist abgeschlossen. Es wurde nichts geaendert."
fi
log ""
log "Pruefe vor dem Neustart:"
log "  grep -c menuentry /boot/grub/grub.cfg"
log "  ls /boot/vmlinuz-*"
log "  grub-script-check /boot/grub/grub.cfg && echo GRUB-OK"
log ""
log "Starte danach neu: sudo reboot"
exit "$RC_OK"
