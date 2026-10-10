#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.1 - Schritt 1: System und Hardware pruefen
#
# Ergebnis: Das Skript meldet, ob das Zielgeraet die Installation zulaesst.
#
# Es aendert KEINE Systemdatei und KEINE Systemeinstellung.
# Es legt mit Rootrechten zwei eigene Arbeitsbereiche an:
#   /var/lib/maximus-t2/apt   gepinnte Paketquelle fuer die Offline-Pruefung
#   ein temporaeres Verzeichnis, das danach geloescht wird
# Ohne Rootrechte entfaellt die Offline-Pruefung.
#
# Aufruf:  sudo bash preflight.sh [--quick] [--no-color]
#
# Rufe das Skript mit 'bash' auf. Auf exFAT fehlt das Ausfuehrungsbit.
#   --quick     Ueberspringt die Pruefsummenpruefung aller Paketdateien.
#   --no-color  Gibt keine Farbcodes aus.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

QUICK=0
for arg in "$@"; do
	case "$arg" in
		--quick)    QUICK=1 ;;
		--no-color) NO_COLOR=1; export NO_COLOR ;;
		-h|--help)  sed -n '2,12p' "$0"; exit "$RC_OK" ;;
		*)          die "$RC_USAGE" "Unbekannte Option '$arg'." "Erlaubt sind --quick, --no-color und --help." ;;
	esac
done

FAILED=0
PASSED=0
WARNED=0
declare -a FINDINGS=()

check_pass() { PASSED=$((PASSED + 1)); log_ok "$1"; }
check_warn() { WARNED=$((WARNED + 1)); log_warn "$1"; FINDINGS+=("WARN  $1"); }
check_fail() { FAILED=$((FAILED + 1)); log_err "$1"; FINDINGS+=("FEHLER $1"); }

TMPDIR_MT2="$(mktemp -d -t maximus-t2-preflight-XXXXXX)"
# shellcheck disable=SC2317  # Die Funktion ruft die EXIT-Falle auf.
cleanup() { rm -rf "$TMPDIR_MT2"; }
trap cleanup EXIT

log "MAXIMUS_T2_INSTALLER V$MT2_VERSION - Vorpruefung"
log "Paketwurzel: $ROOT"
log "Zeitpunkt:   $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---------------------------------------------------------------------------
log_step "Zielgeraet identifizieren"
# ---------------------------------------------------------------------------
MODEL="$(mt2_model || true)"
if [ -z "$MODEL" ]; then
	check_fail "Das Mac-Modell ist nicht lesbar. Erwartet wird $MT2_SUPPORTED_MODEL."
elif [ "$MODEL" = "$MT2_SUPPORTED_MODEL" ]; then
	check_pass "Modell erkannt: $MODEL"
else
	check_fail "Falsches Modell: '$MODEL'. Dieses Paket gilt nur fuer $MT2_SUPPORTED_MODEL."
fi

BOARD="$(cat /sys/class/dmi/id/board_name 2>/dev/null || echo unbekannt)"
log_info "Hauptplatine: $BOARD"
log_info "Prozessor:    $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //' || echo unbekannt)"
log_info "Kerne:        $(nproc 2>/dev/null || echo unbekannt)"
log_info "Hauptspeicher: $(awk '/MemTotal/{printf "%.0f GB", $2/1048576}' /proc/meminfo 2>/dev/null || echo unbekannt)"

# ---------------------------------------------------------------------------
log_step "Betriebssystem pruefen"
# ---------------------------------------------------------------------------
REL="$(mt2_release_id || true)"
CODE="$(mt2_codename || true)"
ARCH="$(dpkg --print-architecture 2>/dev/null || echo unbekannt)"

if [ "$REL" = "$MT2_SUPPORTED_RELEASE" ] && [ "$CODE" = "$MT2_SUPPORTED_CODENAME" ]; then
	check_pass "Ubuntu $REL ($CODE) wird unterstuetzt."
else
	check_fail "Nicht unterstuetzte Version: '$REL' / '$CODE'. Erwartet: $MT2_SUPPORTED_RELEASE / $MT2_SUPPORTED_CODENAME."
fi

if [ "$ARCH" = "amd64" ]; then
	check_pass "Architektur amd64 bestaetigt."
else
	check_fail "Falsche Architektur: '$ARCH'. Erwartet: amd64."
fi

log_info "Laufender Kernel: $(uname -r)"

# ---------------------------------------------------------------------------
log_step "Rueckfallkernel pruefen"
# ---------------------------------------------------------------------------
mapfile -t UBU_KERNELS < <(dpkg-query -W -f='${Package} ${Status}\n' 'linux-image-*-generic' 2>/dev/null \
	| awk '$NF=="installed"{print $1}' | sort -V || true)
if [ "${#UBU_KERNELS[@]}" -ge 2 ]; then
	check_pass "Es sind ${#UBU_KERNELS[@]} Ubuntu-Kernel installiert. Ein Rueckfall ist moeglich."
	printf '         %s\n' "${UBU_KERNELS[@]}"
elif [ "${#UBU_KERNELS[@]}" -eq 1 ]; then
	check_warn "Nur ein Ubuntu-Kernel ist installiert: ${UBU_KERNELS[0]}. Der Rueckfall ist einfach."
else
	check_fail "Es wurde kein Ubuntu-Kernel gefunden. Ohne Rueckfallkernel darf nicht installiert werden."
fi

VMLINUZ_COUNT="$(mt2_count_files /boot -maxdepth 1 -name 'vmlinuz-*')"
if [ "$VMLINUZ_COUNT" -ge 1 ]; then
	check_pass "In /boot liegen $VMLINUZ_COUNT Kernelabbilder."
else
	check_fail "In /boot liegt kein Kernelabbild."
fi

# ---------------------------------------------------------------------------
log_step "Bootloader pruefen"
# ---------------------------------------------------------------------------
if [ -f /etc/default/grub ]; then
	check_pass "/etc/default/grub ist vorhanden."
else
	check_fail "/etc/default/grub fehlt. GRUB ist der Bootloader. Ohne diese Datei ist keine Anpassung moeglich."
fi

GRUB_CFG=''
for c in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
	[ -f "$c" ] && GRUB_CFG="$c" && break
done
# V4.1: Die Pruefung laeuft mit grub-script-check.
# 'bash -n' ist fuer grub.cfg falsch. Gemessen: Fehlalarm bei gueltiger Datei,
# kein Alarm bei nicht geschlossener menuentry-Klammer.
if GRUB_TOOL="$(mt2_grub_check_tool)"; then
	check_pass "GRUB-Pruefprogramm vorhanden: $GRUB_TOOL"
else
	check_fail "Das Programm 'grub-script-check' fehlt. Installiere es mit: sudo apt install grub-common"
fi

if [ -n "$GRUB_CFG" ]; then
	check_pass "GRUB-Konfiguration gefunden: $GRUB_CFG"
	GRUB_RC=0
	mt2_grub_check_cfg "$GRUB_CFG" || GRUB_RC=$?
	case "$GRUB_RC" in
		0) check_pass "grub-script-check bestaetigt die GRUB-Konfiguration." ;;
		6) check_fail "Die GRUB-Konfiguration ist nicht pruefbar. Das Programm grub-script-check fehlt." ;;
		*) check_fail "grub-script-check meldet einen Fehler in $GRUB_CFG. Behebe ihn vor der Installation." ;;
	esac
	MENU_ENTRIES="$(grep -c '^\s*menuentry' "$GRUB_CFG" 2>/dev/null || true)"
	log_info "Menueeintraege: ${MENU_ENTRIES:-0}"
else
	check_fail "Keine GRUB-Konfiguration gefunden. Die Installation ist ohne Bootloader nicht sicher."
fi

if [ -d /sys/firmware/efi ]; then
	check_pass "Das System startet im EFI-Modus."
else
	check_warn "Kein EFI-Modus erkannt. Das ist bei T2-Macs unerwartet."
fi

# ---------------------------------------------------------------------------
log_step "Freien Speicherplatz pruefen"
# ---------------------------------------------------------------------------
free_mib() { df -Pm "$1" 2>/dev/null | awk 'NR==2{print $4}'; }
ROOT_FREE="$(free_mib / || echo 0)"
BOOT_FREE="$(free_mib /boot || echo 0)"
if [ "${ROOT_FREE:-0}" -ge 4096 ]; then
	check_pass "Auf / sind ${ROOT_FREE} MiB frei. Mindestens 4096 MiB sind erforderlich."
else
	check_fail "Auf / sind nur ${ROOT_FREE:-0} MiB frei. Mindestens 4096 MiB sind erforderlich."
fi
if [ "${BOOT_FREE:-0}" -ge 512 ]; then
	check_pass "Auf /boot sind ${BOOT_FREE} MiB frei."
else
	check_fail "Auf /boot sind nur ${BOOT_FREE:-0} MiB frei. Mindestens 512 MiB sind erforderlich."
fi

# ---------------------------------------------------------------------------
log_step "Paketpfad und Dateisystem pruefen"
# ---------------------------------------------------------------------------
# V4.1: Der Paketpfad wandert in eine apt-Quelle.
# Gemessen: Ein Leerzeichen im Pfad zerlegt die file://-Quelle.
PKG_DIR="$ROOT/packages"
PKG_DIR_ENC="$(mt2_url_encode_path "$PKG_DIR")"
if [ "$PKG_DIR_ENC" = "$PKG_DIR" ]; then
	check_pass "Der Paketpfad enthaelt keine Sonderzeichen."
else
	check_pass "Der Paketpfad enthaelt Sonderzeichen. Fuer apt wird er kodiert: $PKG_DIR_ENC"
fi
case "$PKG_DIR" in
	*$'\n'*|*$'\t'*)
		check_fail "Der Paketpfad enthaelt einen Zeilen- oder Tabulatorumbruch. Haenge die Samsung T7 unter einem einfachen Pfad ein." ;;
esac

read -r FS_TYPE FS_EXEC <<EOF
$(mt2_fs_info "$ROOT")
EOF
log_info "Dateisystem der Paketwurzel: $FS_TYPE   Einhaengung: $FS_EXEC"
if mt2_fs_keeps_modes "$FS_TYPE"; then
	check_pass "Das Dateisystem '$FS_TYPE' speichert Unix-Rechte."
else
	check_warn "Das Dateisystem '$FS_TYPE' speichert keine Unix-Rechte. Rufe jedes Skript mit 'bash' auf."
fi
if [ "$FS_EXEC" = "noexec" ]; then
	check_warn "Die Einhaengung traegt 'noexec'. Ein direkter Aufruf scheitert. Der Aufruf ueber 'bash' funktioniert."
else
	check_pass "Die Einhaengung erlaubt die Ausfuehrung."
fi
# Gegenprobe: Laesst sich ein Skript ueber bash starten?
if bash -c ". \"$SELF_DIR/lib/common.sh\"; exit 0" 2>/dev/null; then
	check_pass "Die Skripte sind ueber 'bash' aufrufbar."
else
	check_fail "Die Skripte sind nicht ueber 'bash' aufrufbar. Pruefe die Leserechte auf $SELF_DIR."
fi

# ---------------------------------------------------------------------------
log_step "Paketstruktur pruefen"
# ---------------------------------------------------------------------------
for f in manifest.json SHA256SUMS README.md scripts/install.sh scripts/verify.sh scripts/rollback.sh; do
	if [ -e "$ROOT/$f" ]; then
		check_pass "Datei vorhanden: $f"
	else
		check_fail "Datei fehlt: $f"
	fi
done
for d in packages/t2linux packages/ubuntu packages/dependencies config firmware recovery reports; do
	if [ -d "$ROOT/$d" ]; then
		check_pass "Verzeichnis vorhanden: $d"
	else
		check_fail "Verzeichnis fehlt: $d"
	fi
done

DEB_COUNT="$(mt2_count_files "$ROOT/packages" -name '*.deb')"
if [ "$DEB_COUNT" -gt 0 ]; then
	check_pass "Es liegen $DEB_COUNT Paketdateien bereit."
else
	check_fail "Es liegen keine Paketdateien bereit. Fuehre zuerst scripts/fetch-packages.sh auf dem Baurechner aus."
fi

# ---------------------------------------------------------------------------
log_step "Pruefsummen pruefen"
# ---------------------------------------------------------------------------
if [ "$QUICK" -eq 1 ]; then
	check_warn "Die Pruefsummenpruefung wurde mit --quick uebersprungen."
elif [ -f "$ROOT/packages/SHA256SUMS.debs" ] && [ "$DEB_COUNT" -gt 0 ]; then
	if mt2_verify_sha256 "$ROOT/packages/SHA256SUMS.debs" "$ROOT/packages"; then
		check_pass "Alle $DEB_COUNT Paketdateien haben die erwartete SHA-256-Pruefsumme."
	else
		check_fail "Mindestens eine Paketdatei hat eine falsche Pruefsumme. Die Installation ist gesperrt."
	fi
else
	check_warn "packages/SHA256SUMS.debs fehlt. Die Paketdateien sind nicht geprueft."
fi

# ---------------------------------------------------------------------------
log_step "Offline-Aufloesbarkeit pruefen"
# ---------------------------------------------------------------------------
# V4.1: Die Pruefung nutzt genau die Technik, die install.sh benutzt.
# Eine eigene, abweichende Technik koennte ein falsches Ergebnis liefern.
if [ ! -f "$PKG_DIR/Packages" ]; then
	check_fail "packages/Packages fehlt. Die lokale Paketquelle ist unvollstaendig."
elif ! command -v apt-get >/dev/null 2>&1; then
	check_fail "apt-get fehlt auf dem Zielgeraet."
else
	declare -a PKGLIST=()
	if [ -f "$ROOT/config/install-packages.list" ]; then
		mapfile -t PKGLIST < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
			"$ROOT/config/install-packages.list")
	fi
	if [ "${#PKGLIST[@]}" -eq 0 ]; then
		check_fail "config/install-packages.list fehlt oder ist leer."
	elif [ "$(id -u)" -ne 0 ]; then
		check_warn "Ohne Rootrechte ist die Offline-Pruefung nicht moeglich. Starte: sudo bash $0"
	else
		if mt2_apt_pin_create "$PKG_DIR"; then
			check_pass "Die gepinnte Paketverwaltung ist angelegt (Sandkasten: $MT2_APT_SANDBOX)."
		else
			check_fail "Die gepinnte Paketverwaltung liess sich nicht anlegen."
		fi
		if mt2_apt update -qq >/dev/null 2>&1; then
			check_pass "Die lokale Paketquelle wurde gelesen."
		else
			check_fail "Die lokale Paketquelle liess sich nicht lesen."
		fi
		if mt2_apt_pin_verify; then
			check_pass "Es ist ausschliesslich die lokale Quelle sichtbar."
		else
			check_fail "Die gepinnte Paketverwaltung sieht eine Netzquelle. Ein unbeabsichtigter Download waere moeglich."
		fi
		SIMOUT="$TMPDIR_MT2/sim.txt"
		if mt2_apt install -s -y --no-install-recommends "${PKGLIST[@]}" > "$SIMOUT" 2>&1; then
			NEWC="$(awk '/newly installed/{for(i=1;i<=NF;i++) if($i=="newly") {print $(i-1); exit}}' "$SIMOUT" 2>/dev/null)"
			check_pass "Alle angeforderten Pakete sind offline aufloesbar (${NEWC:-0} neue Pakete)."
			if grep -qE '^Remv ' "$SIMOUT"; then
				check_fail "Die Installation wuerde Pakete entfernen:"
				grep -E '^Remv ' "$SIMOUT" | head -5 | sed 's/^/         /'
			else
				check_pass "Es wuerde kein Paket entfernt."
			fi
			if grep -qE 'https?://' "$SIMOUT"; then
				check_fail "Die Simulation nennt eine Netzadresse. Die Offline-Installation ist nicht gesichert."
			else
				check_pass "Die Simulation nennt keine Netzadresse."
			fi
			# Liegt jede benoetigte Paketdatei wirklich lokal?
			MISS_F=0
			NET_F=0
			while IFS= read -r deb; do
				[ -n "$deb" ] || continue
				case "$deb" in NETZ:*) NET_F=$((NET_F + 1)); continue ;; esac
				[ -f "$deb" ] || MISS_F=$((MISS_F + 1))
			done < <(mt2_apt_wanted_files "${PKGLIST[@]}")
			if [ "$NET_F" -gt 0 ]; then
				check_fail "$NET_F Pakete sollen aus dem Netz kommen. Die Offline-Installation ist nicht gesichert."
			else
				check_pass "Kein Paket soll aus dem Netz kommen."
			fi
			if [ "$MISS_F" -eq 0 ]; then
				check_pass "Jede benoetigte Paketdatei liegt lokal vor."
			else
				check_fail "$MISS_F benoetigte Paketdateien fehlen im lokalen Bestand."
			fi
		else
			check_fail "Die Offline-Aufloesung schlug fehl. Details stehen in der Ausgabe unten."
			sed -n '1,25p' "$SIMOUT" | sed 's/^/         /'
		fi
	fi
fi

# ---------------------------------------------------------------------------
log_step "Paketbestand des Zielsystems auswerten"
# ---------------------------------------------------------------------------
# V4.1: Die tatsaechlichen Abhaengigkeiten des Zielsystems werden ausgewertet.
if command -v dpkg-query >/dev/null 2>&1 && [ -f "$ROOT/config/install-packages.list" ]; then
	mt2_pkg_snapshot "$TMPDIR_MT2/pkg-now.txt"
	log_info "Installierte Pakete auf dem Zielgeraet: $(wc -l < "$TMPDIR_MT2/pkg-now.txt")"
	A=0; M=0
	declare -a WANTED=()
	mapfile -t WANTED < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
		"$ROOT/config/install-packages.list")
	for w in "${WANTED[@]}"; do
		if cut -f1 "$TMPDIR_MT2/pkg-now.txt" | grep -qx "$w"; then A=$((A + 1)); else M=$((M + 1)); fi
	done
	check_pass "Aus der Installationsliste bereits vorhanden: $A, fehlend: $M"
	# Konfliktpakete duerfen nicht installiert sein.
	CONFL=''
	for bad in apple-bce apple-touchbar applesmc-t2 bcm5974-t2 broadcom-wl bcmwl-kernel-source; do
		cut -f1 "$TMPDIR_MT2/pkg-now.txt" | grep -qx "$bad" && CONFL="$CONFL $bad"
	done
	if [ -z "$CONFL" ]; then
		check_pass "Es ist kein konfliktbehaftetes Treiberpaket installiert."
	else
		check_fail "Diese Pakete sind installiert und erzeugen Konflikte mit dem T2-Kernel:$CONFL. Entferne sie vorher."
	fi
else
	check_warn "Der Paketbestand des Zielsystems war nicht auswertbar."
fi

# ---------------------------------------------------------------------------
log_step "Hardwarezustand erfassen"
# ---------------------------------------------------------------------------
if command -v lspci >/dev/null 2>&1; then
	WIFI="$(lspci -nn 2>/dev/null | grep -iE 'network|wireless' || true)"
	if [ -n "$WIFI" ]; then
		log_info "WLAN-Geraet: $WIFI"
	else
		check_warn "Kein WLAN-Geraet auf dem PCI-Bus gefunden."
	fi
	GPU="$(lspci -nn 2>/dev/null | grep -iE 'vga|display|3d' || true)"
	if [ -n "$GPU" ]; then
		printf '         Grafik: %s\n' "$GPU"
	fi
else
	check_warn "lspci fehlt. Das Paket pciutils liegt im Installationspaket bereit."
fi

FW_WIFI_COUNT="$(mt2_count_files /lib/firmware/brcm -maxdepth 1 -name 'brcmfmac43*')"
if [ "$FW_WIFI_COUNT" -gt 0 ]; then
	check_pass "Es liegen $FW_WIFI_COUNT brcmfmac-Firmwaredateien in /lib/firmware/brcm."
else
	check_warn "Es liegt keine Apple-WLAN-Firmware in /lib/firmware/brcm. WLAN und Bluetooth bleiben ohne Funktion. Siehe firmware/README.md."
fi

if [ -d /sys/devices/platform/applesmc.768 ] || grep -qw applesmc /proc/modules 2>/dev/null; then
	check_pass "Das Modul applesmc ist aktiv. Die Luefterwerte sind lesbar."
else
	check_warn "Das Modul applesmc ist nicht aktiv. Die Luefterwerte sind noch nicht lesbar."
fi

TEMP_MAX=0
for z in /sys/class/thermal/thermal_zone*/temp; do
	[ -r "$z" ] || continue
	t="$(cat "$z" 2>/dev/null || echo 0)"
	t=$((t / 1000))
	[ "$t" -gt "$TEMP_MAX" ] && TEMP_MAX="$t"
done
if [ "$TEMP_MAX" -eq 0 ]; then
	check_warn "Es war keine CPU-Temperatur lesbar. Die thermische Abnahme bleibt offen."
elif [ "$TEMP_MAX" -lt 70 ]; then
	check_pass "Hoechste gemessene Temperatur: ${TEMP_MAX} Grad Celsius."
elif [ "$TEMP_MAX" -lt 85 ]; then
	check_warn "Hoechste gemessene Temperatur: ${TEMP_MAX} Grad Celsius. Das ist erhoeht."
else
	check_fail "Hoechste gemessene Temperatur: ${TEMP_MAX} Grad Celsius. Das ist kritisch. Kuehle das Geraet vor der Installation ab."
fi

FANS="$(mt2_count_files /sys/class/hwmon -name 'fan*_input')"
log_info "Gefundene Luefterwerte: $FANS"

# ---------------------------------------------------------------------------
log_step "Ergebnis"
# ---------------------------------------------------------------------------
log "Erfolgreich: $PASSED   Warnungen: $WARNED   Fehler: $FAILED"
if [ "${#FINDINGS[@]}" -gt 0 ]; then
	log ""
	log "Befunde:"
	printf '  %s\n' "${FINDINGS[@]}"
fi

if [ "$FAILED" -gt 0 ]; then
	log ""
	log_err "Die Vorpruefung ist fehlgeschlagen. Die Installation ist gesperrt."
	exit "$RC_DEPS"
fi

log ""
log_ok "INSTALLATION_READY (Vorpruefung bestanden)"
log "Naechster Schritt: sudo bash scripts/install.sh --dry-run"
exit "$RC_OK"
