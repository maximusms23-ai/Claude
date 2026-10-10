#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - Schritt 1: System und Hardware pruefen
#
# Ergebnis: Das Skript meldet, ob das Zielgeraet die Installation zulaesst.
# Es aendert nichts. Es schreibt nur in ein temporaeres Verzeichnis.
#
# Aufruf:  ./preflight.sh [--quick] [--no-color]
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

log "MAXIMUS_T2_INSTALLER_V4 - Vorpruefung"
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
if [ -n "$GRUB_CFG" ]; then
	check_pass "GRUB-Konfiguration gefunden: $GRUB_CFG"
	if command -v bash >/dev/null 2>&1 && bash -n "$GRUB_CFG" 2>/dev/null; then
		check_pass "Die GRUB-Konfiguration hat keine erkennbaren Syntaxfehler."
	else
		check_warn "Die Syntaxpruefung der GRUB-Konfiguration war nicht aussagekraeftig. Pruefe sie vor dem Neustart manuell."
	fi
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
if [ ! -f "$ROOT/packages/Packages" ]; then
	check_fail "packages/Packages fehlt. Die lokale Paketquelle ist unvollstaendig."
elif ! command -v apt-get >/dev/null 2>&1; then
	check_fail "apt-get fehlt auf dem Zielgeraet."
else
	AR="$TMPDIR_MT2/aptroot"
	mkdir -p "$AR"/{etc/apt/apt.conf.d,etc/apt/preferences.d,etc/apt/sources.list.d,var/lib/apt/lists/partial,var/lib/dpkg,var/cache/apt/archives/partial,var/log/apt}
	cp /var/lib/dpkg/status "$AR/var/lib/dpkg/status" 2>/dev/null || : > "$AR/var/lib/dpkg/status"
	printf 'amd64\n' > "$AR/var/lib/dpkg/arch"
	printf 'deb [arch=amd64 trusted=yes] file://%s ./\n' "$ROOT/packages" > "$AR/etc/apt/sources.list"
	cat > "$TMPDIR_MT2/apt.conf" <<EOF
Dir "$AR";
Dir::State "$AR/var/lib/apt";
Dir::State::status "$AR/var/lib/dpkg/status";
Dir::Cache "$AR/var/cache/apt";
Dir::Etc "$AR/etc/apt";
Dir::Etc::sourcelist "$AR/etc/apt/sources.list";
Dir::Etc::sourceparts "$AR/etc/apt/sources.list.d";
Dir::Log "$AR/var/log/apt";
APT::Architecture "amd64";
APT::Architectures "amd64";
Acquire::Languages "none";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
	if APT_CONFIG="$TMPDIR_MT2/apt.conf" apt-get update -qq >/dev/null 2>&1; then
		check_pass "Die lokale Paketquelle wurde gelesen."
	else
		check_fail "Die lokale Paketquelle liess sich nicht lesen."
	fi
	declare -a PKGLIST=()
	if [ -f "$ROOT/config/install-packages.list" ]; then
		mapfile -t PKGLIST < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' \
			"$ROOT/config/install-packages.list")
	fi
	if [ "${#PKGLIST[@]}" -eq 0 ]; then
		check_fail "config/install-packages.list fehlt oder ist leer."
	else
		SIMOUT="$TMPDIR_MT2/sim.txt"
		if APT_CONFIG="$TMPDIR_MT2/apt.conf" apt-get install -s -y --no-install-recommends \
			"${PKGLIST[@]}" > "$SIMOUT" 2>&1; then
			NEWC="$(awk '/newly installed/{for(i=1;i<=NF;i++) if($i=="newly") {print $(i-1); exit}}' "$SIMOUT" 2>/dev/null)"
			check_pass "Alle angeforderten Pakete sind offline aufloesbar (${NEWC:-?} neue Pakete)."
		else
			check_fail "Die Offline-Aufloesung schlug fehl. Details stehen in der Ausgabe unten."
			sed -n '1,25p' "$SIMOUT" | sed 's/^/         /'
		fi
	fi
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
log "Naechster Schritt: sudo ./scripts/install.sh --dry-run"
exit "$RC_OK"
