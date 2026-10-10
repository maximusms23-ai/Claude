#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.1 - Hardware-Abnahme nach der Installation
#
# Ergebnis: Das Skript prueft jede Hardwarefunktion und schreibt einen Bericht.
# Es fuehrt echte Funktionstests aus, nicht nur Modulpruefungen.
#
# Aufruf:  sudo bash verify.sh [OPTIONEN]
#   --non-interactive   Fuehrt nur selbsttaetige Tests aus.
#                       Tests mit Mitwirkung erhalten NOT_TESTED.
#   --allow-suspend     Erlaubt den Standby-Test. Standard ist BLOCKED.
#   --thermal-seconds N Dauer des Lasttests in Sekunden. Standard 60.
#   --out DATEI         Zielpfad des Berichts.
#   --no-color          Gibt keine Farbcodes aus.
#
# Bewertung: PASS, PARTIAL, FAIL, BLOCKED, NOT_TESTED
# Ein nicht getestetes Geraet erhaelt niemals PASS.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
ROOT="$(cd "$SELF_DIR/.." && pwd)"

INTERACTIVE=1
ALLOW_SUSPEND=0
THERMAL_SECONDS=60
OUTFILE=''
readonly TEMP_ABORT=90

while [ "$#" -gt 0 ]; do
	case "$1" in
		--non-interactive)  INTERACTIVE=0 ;;
		--allow-suspend)    ALLOW_SUSPEND=1 ;;
		--thermal-seconds)  mt2_opt_needs_value "$#" --thermal-seconds; THERMAL_SECONDS="$2"; shift ;;
		--out)              mt2_opt_needs_value "$#" --out; OUTFILE="$2"; shift ;;
		--no-color)         NO_COLOR=1; export NO_COLOR ;;
		-h|--help)          sed -n '2,20p' "$0"; exit "$RC_OK" ;;
		*)                  die "$RC_USAGE" "Unbekannte Option '$1'." "Rufe '$0 --help' auf." ;;
	esac
	shift
done

case "$THERMAL_SECONDS" in
	''|*[!0-9]*) die "$RC_USAGE" "--thermal-seconds erwartet eine ganze Zahl." "Beispiel: --thermal-seconds 60" ;;
esac

mt2_require_root "$@"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$MT2_LOG_DIR" 2>/dev/null || true
[ -n "$OUTFILE" ] || OUTFILE="$MT2_LOG_DIR/HARDWARE_TEST_REPORT-$STAMP.md"

declare -a R_FIELD=() R_RESULT=() R_NOTE=()
add_result() {
	R_FIELD+=("$1"); R_RESULT+=("$2"); R_NOTE+=("$3")
	case "$2" in
		PASS)       log_ok   "$1: PASS - $3" ;;
		PARTIAL)    log_warn "$1: PARTIAL - $3" ;;
		FAIL)       log_err  "$1: FAIL - $3" ;;
		BLOCKED)    log_warn "$1: BLOCKED - $3" ;;
		NOT_TESTED) log_info "$1: NOT_TESTED - $3" ;;
	esac
}

# ask_user: Stellt eine Frage mit Mitwirkung. Gibt PASS, FAIL oder NOT_TESTED aus.
ask_user() {
	local question="$1" answer=''
	if [ "$INTERACTIVE" -eq 0 ]; then
		printf 'NOT_TESTED'
		return 0
	fi
	printf '\n%s%s%s\n' "$C_Y" "$question" "$C_0" >&2
	printf 'Antwort [j = funktioniert / n = funktioniert nicht / u = uebersprungen]: ' >&2
	if ! IFS= read -r answer; then
		printf 'NOT_TESTED'
		return 0
	fi
	case "$answer" in
		j|J|y|Y) printf 'PASS' ;;
		n|N)     printf 'FAIL' ;;
		*)       printf 'NOT_TESTED' ;;
	esac
}

# V4.1: Ein '|' im Text zerstoert die Markdown-Tabelle.
# Gemessen: Die Zeile mit den Kernelparametern brach die Tabelle auf.
md_cell() {
	printf '%s' "$1" | sed -e 's/|/\\|/g' -e 's/\r//g' | tr '\n' ' '
}

max_temp_c() {
	local t max=0 z
	for z in /sys/class/thermal/thermal_zone*/temp; do
		[ -r "$z" ] || continue
		t="$(cat "$z" 2>/dev/null || echo 0)"
		t=$((t / 1000))
		[ "$t" -gt "$max" ] && max="$t"
	done
	printf '%s' "$max"
}

fan_rpm_list() {
	local f
	for f in /sys/class/hwmon/hwmon*/fan*_input; do
		[ -r "$f" ] || continue
		printf '%s ' "$(cat "$f" 2>/dev/null || echo 0)"
	done
}

log "MAXIMUS_T2_INSTALLER V$MT2_VERSION - Hardware-Abnahme"
log "Zeitpunkt: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Kernel:    $(uname -r)"
log "Bericht:   $OUTFILE"
if [ "$INTERACTIVE" -eq 0 ]; then
	log_warn "Betriebsart ohne Mitwirkung. Tests mit Mitwirkung erhalten NOT_TESTED."
fi

# ---------------------------------------------------------------------------
log_step "Systemstart"
# ---------------------------------------------------------------------------
RUNNING="$(uname -r)"
if [ "$RUNNING" = "$MT2_KERNEL_RELEASE" ]; then
	add_result "Systemstart" PASS "Der T2-Kernel $RUNNING ist aktiv."
elif [ "$RUNNING" = "$MT2_KERNEL_FALLBACK_RELEASE" ]; then
	add_result "Systemstart" PARTIAL "Der T2-Rueckfallkernel $RUNNING ist aktiv, nicht $MT2_KERNEL_RELEASE."
else
	add_result "Systemstart" FAIL "Es laeuft $RUNNING. Erwartet wird $MT2_KERNEL_RELEASE."
	log_err "Alle weiteren T2-Tests sind ohne T2-Kernel nicht aussagekraeftig."
fi

CMDLINE="$(cat /proc/cmdline 2>/dev/null || true)"
MISSING_PARAMS=''
for p in intel_iommu=on iommu=pt pm_async=off; do
	printf '%s' "$CMDLINE" | grep -q -- "$p" || MISSING_PARAMS="$MISSING_PARAMS $p"
done
if [ -z "$MISSING_PARAMS" ]; then
	add_result "Kernelparameter" PASS "intel_iommu=on, iommu=pt und pm_async=off sind aktiv."
else
	add_result "Kernelparameter" FAIL "Es fehlen:$MISSING_PARAMS"
fi

T2_MODULES="$(awk '{print $1}' /proc/modules 2>/dev/null | grep -c '^t2bce' || true)"
if [ "${T2_MODULES:-0}" -ge 1 ]; then
	add_result "T2-Treiberstapel" PASS "Es sind $T2_MODULES t2bce-Module geladen."
else
	add_result "T2-Treiberstapel" FAIL "Es ist kein t2bce-Modul geladen."
fi

# ---------------------------------------------------------------------------
log_step "Tastatur"
# ---------------------------------------------------------------------------
KBD_DEV="$(grep -il 'apple' /sys/class/input/event*/device/name 2>/dev/null | head -1 || true)"
KBD_NAMES="$(cat /sys/class/input/event*/device/name 2>/dev/null | grep -i 'apple' | tr '\n' ';' || true)"
if [ -n "$KBD_NAMES" ]; then
	log_info "Apple-Eingabegeraete: $KBD_NAMES"
	TYPED="$(ask_user "Tippe auf der INTERNEN Tastatur ein paar Zeichen in dieses Fenster. Funktioniert sie?")"
	case "$TYPED" in
		PASS)       add_result "Tastatur" PASS "Die interne Tastatur erzeugt Eingaben. Geraete: $KBD_NAMES" ;;
		FAIL)       add_result "Tastatur" FAIL "Die interne Tastatur ist sichtbar, erzeugt aber keine Eingaben." ;;
		*)          add_result "Tastatur" PARTIAL "Das Eingabegeraet ist vorhanden. Der Funktionstest fehlt." ;;
	esac
else
	add_result "Tastatur" FAIL "Es ist kein Apple-Eingabegeraet registriert. Pruefe das Modul t2bce_vhci."
fi
[ -n "$KBD_DEV" ] && log_info "Erstes Geraet: $KBD_DEV"

# ---------------------------------------------------------------------------
log_step "Trackpad"
# ---------------------------------------------------------------------------
TP_FOUND=0
if command -v libinput >/dev/null 2>&1; then
	if libinput list-devices 2>/dev/null | grep -qiE 'touchpad|trackpad'; then TP_FOUND=1; fi
fi
if [ "$TP_FOUND" -eq 0 ] && cat /sys/class/input/event*/device/name 2>/dev/null | grep -qiE 'touchpad|trackpad'; then
	TP_FOUND=1
fi
if [ "$TP_FOUND" -eq 1 ]; then
	A="$(ask_user "Bewege den Zeiger mit dem internen Trackpad und klicke einmal. Funktioniert es?")"
	B="$(ask_user "Funktionieren Zwei-Finger-Scrollen und Zwei-Finger-Klick?")"
	if [ "$A" = "PASS" ] && [ "$B" = "PASS" ]; then
		add_result "Trackpad" PASS "Zeiger, Klick und die geprueften Gesten funktionieren."
	elif [ "$A" = "PASS" ]; then
		add_result "Trackpad" PARTIAL "Zeiger und Klick funktionieren. Gesten sind eingeschraenkt oder ungeprueft. Force Touch und Handballenerkennung fehlen bauartbedingt."
	elif [ "$A" = "FAIL" ]; then
		add_result "Trackpad" FAIL "Das Trackpad ist sichtbar, bewegt den Zeiger aber nicht."
	else
		add_result "Trackpad" PARTIAL "Das Trackpad ist registriert. Der Funktionstest fehlt."
	fi
else
	add_result "Trackpad" FAIL "Es ist kein Trackpad registriert."
fi

# ---------------------------------------------------------------------------
log_step "Touch Bar"
# ---------------------------------------------------------------------------
TB_MOD=0
grep -qE '^hid_appletb' /proc/modules 2>/dev/null && TB_MOD=1
TB_SVC="nicht installiert"
if systemctl list-unit-files 2>/dev/null | grep -q '^tiny-dfr'; then
	TB_SVC="$(systemctl is-active tiny-dfr 2>/dev/null || echo inaktiv)"
fi
log_info "hid-appletb geladen: $TB_MOD   tiny-dfr: $TB_SVC"
if [ "$TB_MOD" -eq 1 ]; then
	A="$(ask_user "Zeigt die Touch Bar Symbole an und reagiert eine Taste darauf (zum Beispiel Helligkeit)?")"
	case "$A" in
		PASS) add_result "Touch Bar" PASS "Die unterstuetzten Funktionstasten reagieren. tiny-dfr: $TB_SVC" ;;
		FAIL) add_result "Touch Bar" FAIL "Der Treiber ist geladen, die Touch Bar reagiert aber nicht." ;;
		*)    add_result "Touch Bar" PARTIAL "Der Treiber ist geladen. Der Funktionstest fehlt." ;;
	esac
else
	add_result "Touch Bar" FAIL "Das Modul hid-appletb ist nicht geladen."
fi

# ---------------------------------------------------------------------------
log_step "WLAN"
# ---------------------------------------------------------------------------
# V4.1: Der Funkchip wird AUSSCHLIESSLICH durch Hardwareerkennung bestimmt.
# Eine Annahme aus einem frueheren Bericht gilt nicht als Nachweis.
PCI_NET="$(lspci -nn 2>/dev/null | grep -iE 'network|wireless' | head -1 || true)"
PCI_ID="$(printf '%s' "$PCI_NET" | sed -n 's/.*\[\([0-9a-f]\{4\}:[0-9a-f]\{4\}\)\].*/\1/p' | head -1)"
CHIP_LOG="$(journalctl -k -b 0 --no-pager 2>/dev/null \
	| sed -n 's/.*using brcm\/brcmfmac\([0-9a-z]*\)-pcie for chip \(BCM[0-9/]*\).*/\2 (Dateipraefix brcmfmac\1)/p' | head -1)"
if [ -z "$CHIP_LOG" ]; then
	CHIP_LOG="$(journalctl -k -b 0 --no-pager 2>/dev/null \
		| sed -n 's/.*Firmware: \(BCM[0-9/]*\).*/\1/p' | head -1)"
fi
FW_FILES="$(find /lib/firmware/brcm -maxdepth 1 -name 'brcmfmac4*' -printf '%f\n' 2>/dev/null | sort || true)"
CHIP_FW="$(printf '%s' "$FW_FILES" | sed -n 's/^brcmfmac\([0-9]\{4\}\).*/BCM\1/p' | sort -u | tr '\n' ' ')"

log_info "PCI-Eintrag:      ${PCI_NET:-keiner}"
log_info "PCI-Kennung:      ${PCI_ID:-unbekannt}"
log_info "Chip laut Kernel: ${CHIP_LOG:-nicht gemeldet}"
log_info "Chip laut Firmwaredateien: ${CHIP_FW:-keine}"

if [ -n "$CHIP_LOG" ]; then
	add_result "WLAN-Chip" PASS "Durch Hardwareerkennung bestaetigt: $CHIP_LOG. PCI-Kennung ${PCI_ID:-unbekannt}."
elif [ -n "$PCI_ID" ]; then
	add_result "WLAN-Chip" PARTIAL "Der Funkchip ist am PCI-Bus sichtbar (${PCI_ID}), der Treiber meldet ihn aber nicht. Vermutlich fehlt die Firmware."
elif [ -n "$CHIP_FW" ]; then
	add_result "WLAN-Chip" PARTIAL "Es liegt Firmware fuer $CHIP_FW vor. Das Geraet ist nicht am PCI-Bus sichtbar."
else
	add_result "WLAN-Chip" FAIL "Der Funkchip liess sich nicht bestimmen. Pruefe: lspci -nn | grep -i network"
fi

FW_COUNT="$(mt2_count_files /lib/firmware/brcm -maxdepth 1 -name 'brcmfmac43*')"
WIFI_IF=''
for n in /sys/class/net/wl*; do
	[ -e "$n" ] || continue
	WIFI_IF="$(basename "$n")"
	break
done
BRCM_LOG="$(journalctl -k -b 0 --no-pager 2>/dev/null | grep -c 'brcmfmac' || true)"
log_info "Firmwaredateien: $FW_COUNT   Schnittstelle: ${WIFI_IF:-keine}   Kernelmeldungen: ${BRCM_LOG:-0}"
if [ "$FW_COUNT" -eq 0 ]; then
	add_result "WLAN" FAIL "Es fehlt die Apple-WLAN-Firmware in /lib/firmware/brcm. Siehe firmware/README.md."
elif [ -z "$WIFI_IF" ]; then
	add_result "WLAN" FAIL "Die Firmware liegt vor, es entstand aber keine WLAN-Schnittstelle."
else
	SCAN_COUNT=0
	if command -v iw >/dev/null 2>&1; then
		SCAN_COUNT="$(iw dev "$WIFI_IF" scan 2>/dev/null | grep -c '^BSS' || true)"
	fi
	CONN_STATE="unbekannt"
	if command -v nmcli >/dev/null 2>&1; then
		CONN_STATE="$(nmcli -t -f DEVICE,STATE device 2>/dev/null | grep "^$WIFI_IF:" | cut -d: -f2 || echo unbekannt)"
	fi
	log_info "Gefundene Netze: $SCAN_COUNT   Verbindungszustand: $CONN_STATE"
	if [ "$CONN_STATE" = "connected" ]; then
		add_result "WLAN" PASS "Die Schnittstelle $WIFI_IF ist verbunden. $SCAN_COUNT Netze sichtbar."
	elif [ "${SCAN_COUNT:-0}" -gt 0 ]; then
		add_result "WLAN" PARTIAL "Die Suche findet $SCAN_COUNT Netze. Es besteht keine Verbindung."
	else
		add_result "WLAN" FAIL "Die Schnittstelle $WIFI_IF findet kein Netz."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Bluetooth"
# ---------------------------------------------------------------------------
BT_CTRL=0
if command -v bluetoothctl >/dev/null 2>&1; then
	bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && BT_CTRL=1
fi
BT_DEV="$(find /sys/class/bluetooth -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | head -1 || true)"
log_info "Bluetooth-Adapter: ${BT_DEV:-keiner}   eingeschaltet: $BT_CTRL"
if [ -z "$BT_DEV" ]; then
	add_result "Bluetooth" FAIL "Es ist kein Bluetooth-Adapter registriert. Die Firmware fehlt vermutlich."
else
	A="$(ask_user "Koppele ein Bluetooth-Geraet und nutze es kurz. Funktioniert es? HINWEIS: Nutze 5-GHz-WLAN oder schalte WLAN ab, sonst stoert es.")"
	case "$A" in
		PASS) add_result "Bluetooth" PARTIAL "Die Kopplung gelang. Die Stoerung durch 2,4-GHz-WLAN bleibt bauartbedingt bestehen." ;;
		FAIL) add_result "Bluetooth" FAIL "Der Adapter ist vorhanden, die Kopplung gelang nicht." ;;
		*)    add_result "Bluetooth" PARTIAL "Der Adapter ist vorhanden. Der Kopplungstest fehlt." ;;
	esac
fi

# ---------------------------------------------------------------------------
log_step "Kamera"
# ---------------------------------------------------------------------------
CAM_DEV=''
for v in /dev/video*; do
	[ -c "$v" ] || continue
	CAM_DEV="$v"
	break
done
if [ -z "$CAM_DEV" ]; then
	add_result "Kamera" FAIL "Es ist kein Videogeraet vorhanden. Pruefe das Modul t2bce_vhci."
elif ! command -v ffmpeg >/dev/null 2>&1; then
	add_result "Kamera" PARTIAL "Das Geraet $CAM_DEV ist vorhanden. ffmpeg fehlt fuer den Aufnahmetest."
else
	CAMFILE="$(mktemp -t maximus-cam-XXXXXX.mkv)"
	if ffmpeg -hide_banner -loglevel error -y -f v4l2 -i "$CAM_DEV" -frames:v 15 "$CAMFILE" 2>/dev/null \
		&& [ -s "$CAMFILE" ]; then
		add_result "Kamera" PASS "Die Aufnahme von 15 Bildern aus $CAM_DEV gelang ($(stat -c%s "$CAMFILE") Byte)."
	else
		add_result "Kamera" FAIL "Das Geraet $CAM_DEV liefert kein Bild."
	fi
	rm -f "$CAMFILE"
fi

# ---------------------------------------------------------------------------
log_step "Audio: Karte und Profil"
# ---------------------------------------------------------------------------
CARD_ID="$(sed -n 's/.*\(AppleT2[^ ]*\) -.*/\1/p' /proc/asound/cards 2>/dev/null | head -1 || true)"
log_info "Audiokarte: ${CARD_ID:-keine}"
if [ -z "$CARD_ID" ]; then
	add_result "Audiokarte" FAIL "Es ist keine AppleT2-Audiokarte registriert."
elif [ "$CARD_ID" = "AppleT2" ]; then
	add_result "Audiokarte" PARTIAL "Die Karte heisst '$CARD_ID' ohne Modellkennung. Die Lautsprecheraufteilung fehlt. Nutze die DSP-Pakete NICHT."
else
	add_result "Audiokarte" PASS "Die Karte heisst '$CARD_ID'. Die modellbezogene Aufteilung liegt vor."
fi

# ---------------------------------------------------------------------------
log_step "Mikrofon"
# ---------------------------------------------------------------------------
if ! command -v arecord >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
	add_result "Mikrofon" PARTIAL "arecord oder ffmpeg fehlt. Der Aufnahmetest ist nicht moeglich."
elif [ -z "$CARD_ID" ]; then
	add_result "Mikrofon" BLOCKED "Ohne Audiokarte ist keine Aufnahme moeglich."
else
	MICFILE="$(mktemp -t maximus-mic-XXXXXX.wav)"
	log_info "Sprich jetzt 4 Sekunden deutlich in Richtung des Bildschirms."
	if arecord -d 4 -f cd -t wav "$MICFILE" >/dev/null 2>&1 && [ -s "$MICFILE" ]; then
		MEAN="$(ffmpeg -hide_banner -nostats -i "$MICFILE" -af volumedetect -f null /dev/null 2>&1 \
			| sed -n 's/.*mean_volume: \(-\?[0-9.]*\) dB.*/\1/p' | head -1)"
		log_info "Mittlere Lautstaerke: ${MEAN:-unbekannt} dB"
		if [ -z "$MEAN" ]; then
			add_result "Mikrofon" PARTIAL "Die Aufnahme gelang. Die Lautstaerke war nicht messbar."
		elif awk -v m="$MEAN" 'BEGIN{exit !(m > -50)}'; then
			add_result "Mikrofon" PASS "Die Aufnahme enthaelt Signal (${MEAN} dB)."
		elif awk -v m="$MEAN" 'BEGIN{exit !(m > -70)}'; then
			add_result "Mikrofon" PARTIAL "Die Aufnahme ist sehr leise (${MEAN} dB). Das ist bauartbedingt. Pruefe die DSP-Kette."
		else
			add_result "Mikrofon" FAIL "Die Aufnahme ist stumm (${MEAN} dB)."
		fi
	else
		add_result "Mikrofon" FAIL "Die Aufnahme mit arecord schlug fehl."
	fi
	rm -f "$MICFILE"
fi

# ---------------------------------------------------------------------------
log_step "Lautsprecher"
# ---------------------------------------------------------------------------
if [ -z "$CARD_ID" ]; then
	add_result "Lautsprecher" BLOCKED "Ohne Audiokarte ist keine Wiedergabe moeglich."
elif [ "$INTERACTIVE" -eq 0 ]; then
	add_result "Lautsprecher" NOT_TESTED "Die Wiedergabe erfordert eine Hoerpruefung."
else
	log_warn "Die Lautstaerke wird auf 20 Prozent gesetzt. Eine zu hohe Lautstaerke kann die Hochtoener schaedigen."
	if command -v wpctl >/dev/null 2>&1; then
		wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.2 2>/dev/null || true
	elif command -v amixer >/dev/null 2>&1; then
		amixer -q set Master 20% 2>/dev/null || true
	fi
	if command -v speaker-test >/dev/null 2>&1; then
		log_info "Es folgt ein kurzer Testton."
		speaker-test -t sine -f 440 -l 1 -s 1 >/dev/null 2>&1 || true
	fi
	A="$(ask_user "War der Testton leise und unverzerrt aus den internen Lautsprechern hoerbar?")"
	case "$A" in
		PASS) add_result "Lautsprecher" PASS "Die Wiedergabe ueber die internen Lautsprecher funktioniert." ;;
		FAIL) add_result "Lautsprecher" FAIL "Es war kein oder ein verzerrter Ton hoerbar." ;;
		*)    add_result "Lautsprecher" NOT_TESTED "Die Hoerpruefung wurde uebersprungen." ;;
	esac
fi

# ---------------------------------------------------------------------------
log_step "Luefter"
# ---------------------------------------------------------------------------
FAN_VALUES="$(fan_rpm_list)"
FAN_COUNT="$(printf '%s' "$FAN_VALUES" | wc -w)"
FAN_SVC="$(systemctl is-active t2fanrd 2>/dev/null || echo inaktiv)"
log_info "Luefterwerte: ${FAN_VALUES:-keine}   Dienst t2fanrd: $FAN_SVC"
FAN_OK=0
if [ "${FAN_COUNT:-0}" -eq 0 ]; then
	add_result "Luefter" FAIL "Es sind keine Luefterdrehzahlen lesbar. Pruefe das Modul applesmc."
else
	NONZERO="$(printf '%s' "$FAN_VALUES" | tr ' ' '\n' | awk '$1>0' | wc -l)"
	if [ "$NONZERO" -ge 1 ] && [ "$FAN_SVC" = "active" ]; then
		add_result "Luefter" PASS "$FAN_COUNT Luefter sind lesbar, $NONZERO drehen, der Dienst laeuft."
		FAN_OK=1
	elif [ "$NONZERO" -ge 1 ]; then
		add_result "Luefter" PARTIAL "$NONZERO Luefter drehen. Der Dienst t2fanrd ist '$FAN_SVC'."
		FAN_OK=1
	else
		add_result "Luefter" PARTIAL "$FAN_COUNT Luefter sind lesbar, drehen aber nicht. Das kann bei geringer Last normal sein."
	fi
fi

# ---------------------------------------------------------------------------
log_step "CPU-Temperatur und Drosselung"
# ---------------------------------------------------------------------------
TEMP_IDLE="$(max_temp_c)"
log_info "Temperatur im Ruhezustand: ${TEMP_IDLE} Grad Celsius"
THROTTLE_BEFORE="$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count 2>/dev/null || echo 0)"

if [ "$FAN_OK" -eq 0 ]; then
	add_result "CPU" BLOCKED "Der Lasttest ist gesperrt. Die Luefterpruefung ist nicht bestanden. Temperatur im Ruhezustand: ${TEMP_IDLE} Grad Celsius."
elif [ "${TEMP_IDLE:-0}" -ge 80 ]; then
	add_result "CPU" BLOCKED "Der Lasttest ist gesperrt. Die Ruhetemperatur ${TEMP_IDLE} Grad Celsius ist zu hoch."
elif ! command -v stress-ng >/dev/null 2>&1; then
	add_result "CPU" PARTIAL "stress-ng fehlt. Ruhetemperatur: ${TEMP_IDLE} Grad Celsius."
else
	log_info "Lasttest ueber ${THERMAL_SECONDS} Sekunden. Abbruch ab ${TEMP_ABORT} Grad Celsius."
	stress-ng --cpu 0 --timeout "${THERMAL_SECONDS}s" --metrics-brief >/dev/null 2>&1 &
	STRESS_PID=$!
	TEMP_PEAK="$TEMP_IDLE"
	ABORTED=0
	while kill -0 "$STRESS_PID" 2>/dev/null; do
		T="$(max_temp_c)"
		[ "$T" -gt "$TEMP_PEAK" ] && TEMP_PEAK="$T"
		if [ "$T" -ge "$TEMP_ABORT" ]; then
			log_err "Abbruch: ${T} Grad Celsius erreicht."
			kill "$STRESS_PID" 2>/dev/null || true
			ABORTED=1
			break
		fi
		sleep 2
	done
	wait "$STRESS_PID" 2>/dev/null || true
	FAN_AFTER="$(fan_rpm_list)"
	THROTTLE_AFTER="$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count 2>/dev/null || echo 0)"
	THROTTLE_DELTA=$((THROTTLE_AFTER - THROTTLE_BEFORE))
	log_info "Spitzentemperatur: ${TEMP_PEAK} Grad Celsius   Luefter danach: ${FAN_AFTER:-unbekannt}   Drosselungen: ${THROTTLE_DELTA}"
	if [ "$ABORTED" -eq 1 ]; then
		add_result "CPU" FAIL "Der Lasttest wurde bei ${TEMP_PEAK} Grad Celsius abgebrochen. Drosselungen: ${THROTTLE_DELTA}."
	elif [ "$TEMP_PEAK" -ge 85 ]; then
		add_result "CPU" PARTIAL "Spitzentemperatur ${TEMP_PEAK} Grad Celsius. Drosselungen: ${THROTTLE_DELTA}. Die Kuehlung ist grenzwertig."
	else
		add_result "CPU" PASS "Spitzentemperatur ${TEMP_PEAK} Grad Celsius ueber ${THERMAL_SECONDS} Sekunden. Drosselungen: ${THROTTLE_DELTA}."
	fi
	# Reagiert die Steuerung auf Temperatur?
	SUM_BEFORE="$(printf '%s' "$FAN_VALUES"  | tr ' ' '\n' | awk '{s+=$1} END{print s+0}')"
	SUM_AFTER="$(printf '%s' "$FAN_AFTER"    | tr ' ' '\n' | awk '{s+=$1} END{print s+0}')"
	if [ "$SUM_AFTER" -gt "$SUM_BEFORE" ]; then
		add_result "Luefterregelung" PASS "Die Drehzahl stieg unter Last von ${SUM_BEFORE} auf ${SUM_AFTER}."
	else
		add_result "Luefterregelung" PARTIAL "Die Drehzahl stieg nicht messbar (${SUM_BEFORE} -> ${SUM_AFTER})."
	fi
fi

# ---------------------------------------------------------------------------
log_step "Grafik"
# ---------------------------------------------------------------------------
I915=0; AMDGPU=0
grep -qw i915 /proc/modules 2>/dev/null && I915=1
grep -qw amdgpu /proc/modules 2>/dev/null && AMDGPU=1
RENDERER="unbekannt"
if command -v glxinfo >/dev/null 2>&1; then
	RENDERER="$(glxinfo -B 2>/dev/null | sed -n 's/.*OpenGL renderer string: //p' | head -1)"
	[ -n "$RENDERER" ] || RENDERER="unbekannt"
fi
VAAPI="unbekannt"
if command -v vainfo >/dev/null 2>&1; then
	vainfo >/dev/null 2>&1 && VAAPI="verfuegbar" || VAAPI="nicht verfuegbar"
fi
log_info "i915: $I915   amdgpu: $AMDGPU   Renderer: $RENDERER   VA-API: $VAAPI"

# V4.1: Welcher Grafikchip treibt den internen Bildschirm?
# Fuer dieses Modell ist dokumentiert, dass gmux den internen Bildschirm an
# die AMD-Grafik legen kann. Das Geraet haengt dann beim Sitzungsstart.
EDP_DRV=''
for c in /sys/class/drm/card*-eDP-*; do
	[ -e "$c/status" ] || continue
	if [ "$(cat "$c/status" 2>/dev/null)" = "connected" ]; then
		EDP_DRV="$(basename "$(readlink -f "$c/../device/driver" 2>/dev/null)" 2>/dev/null || true)"
		log_info "Interner Bildschirm: $(basename "$c")   Treiber: ${EDP_DRV:-unbekannt}"
		break
	fi
done
GMUX=0
[ -d /sys/bus/platform/devices/apple-gmux ] && GMUX=1
log_info "apple-gmux vorhanden: $GMUX"
case "$EDP_DRV" in
	i915)   add_result "Interner Bildschirm" PASS "Der interne Bildschirm haengt an der Intel-Grafik (i915). Das ist der erwuenschte Zustand." ;;
	amdgpu) add_result "Interner Bildschirm" PARTIAL "Der interne Bildschirm haengt an der AMD-Grafik. Fuer dieses Modell ist ein Haenger beim Sitzungsstart dokumentiert. Beobachte das Verhalten." ;;
	'')     add_result "Interner Bildschirm" PARTIAL "Der Treiber des internen Bildschirms liess sich nicht bestimmen." ;;
	*)      add_result "Interner Bildschirm" PARTIAL "Der interne Bildschirm haengt am Treiber '$EDP_DRV'." ;;
esac
if [ "$I915" -eq 1 ] && [ "$AMDGPU" -eq 1 ]; then
	add_result "GPU" PARTIAL "Beide Treiber sind geladen. Renderer: $RENDERER. VA-API: $VAAPI. Das Abschalten der dedizierten Grafik funktioniert bauartbedingt nicht."
elif [ "$I915" -eq 1 ]; then
	add_result "GPU" PARTIAL "Nur i915 ist geladen. Die Radeon Pro 5500M ist nicht aktiv. Renderer: $RENDERER."
elif [ "$AMDGPU" -eq 1 ]; then
	add_result "GPU" PARTIAL "Nur amdgpu ist geladen. Renderer: $RENDERER."
else
	add_result "GPU" FAIL "Es ist kein Grafiktreiber geladen."
fi

# ---------------------------------------------------------------------------
log_step "Standby"
# ---------------------------------------------------------------------------
if [ "$ALLOW_SUSPEND" -eq 0 ]; then
	add_result "Standby" BLOCKED "Der Test ist absichtlich gesperrt. Der Ruhezustand ist auf diesem Modell nachweislich fehlerhaft. Siehe config/power/README.md. Freigabe mit --allow-suspend."
else
	log_warn "Der Standby-Test kann das Geraet zum Haengen bringen. Sichere alle Daten."
	SLEEP_MODE="$(cat /sys/power/mem_sleep 2>/dev/null || echo unbekannt)"
	log_info "Verfuegbare Ruhezustaende: $SLEEP_MODE"
	case "$SLEEP_MODE" in
		*'[s2idle]'*) log_warn "Aktiv ist 's2idle'. Fuer dieses Modell ist dokumentiert, dass die"
		              log_warn "AMD-Grafik daraus nicht aufwacht. Setze vorher mem_sleep_default=deep." ;;
		*'[deep]'*)   log_info "Aktiv ist 'deep'. Das ist fuer dieses Modell der empfohlene Zustand." ;;
	esac
	A="$(ask_user "Soll der Standby-Test jetzt starten? Antworte nur mit j, wenn alle Daten gesichert sind.")"
	if [ "$A" = "PASS" ]; then
		systemctl suspend || true
		sleep 5
		B="$(ask_user "Ist das Geraet eingeschlafen und wieder vollstaendig aufgewacht? Funktionieren Tastatur, Trackpad und Bildschirm danach?")"
		case "$B" in
			PASS) add_result "Standby" PARTIAL "Ein Durchlauf gelang. Der Ruhezustand bleibt auf diesem Modell nicht zugesichert." ;;
			FAIL) add_result "Standby" FAIL "Der Ruhezustand oder das Aufwachen schlug fehl." ;;
			*)    add_result "Standby" NOT_TESTED "Das Ergebnis wurde nicht bewertet." ;;
		esac
	else
		add_result "Standby" NOT_TESTED "Der Test wurde nicht gestartet."
	fi
fi

# ---------------------------------------------------------------------------
log_step "USB-C"
# ---------------------------------------------------------------------------
XHCI="$(grep -c '^xhci' /proc/modules 2>/dev/null || true)"
TB_DEVS="$(mt2_count_files /sys/bus/thunderbolt/devices -maxdepth 1 -mindepth 1)"
USB_DEVS="$(lsusb 2>/dev/null | wc -l)"
log_info "xhci-Module: ${XHCI:-0}   Thunderbolt-Geraete: $TB_DEVS   USB-Geraete: $USB_DEVS"
A="$(ask_user "Stecke ein USB-C-Speichermedium an, kopiere eine Datei darauf und lies sie zurueck. Gelingt das?")"
case "$A" in
	PASS) add_result "USB-C" PASS "Die Datenuebertragung ueber USB-C gelang. Thunderbolt-Geraete: $TB_DEVS." ;;
	FAIL) add_result "USB-C" FAIL "Die Datenuebertragung ueber USB-C gelang nicht." ;;
	*)    add_result "USB-C" NOT_TESTED "Der Uebertragungstest wurde nicht ausgefuehrt. xhci-Module: ${XHCI:-0}." ;;
esac

# ---------------------------------------------------------------------------
log_step "Akku"
# ---------------------------------------------------------------------------
BAT="$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -1 || true)"
if [ -z "$BAT" ]; then
	add_result "Akku" FAIL "Es ist kein Akku registriert."
else
	BSTAT="$(cat "$BAT/status" 2>/dev/null || echo unbekannt)"
	BCAP="$(cat "$BAT/capacity" 2>/dev/null || echo unbekannt)"
	log_info "Akku: $BSTAT, ${BCAP} Prozent"
	A="$(ask_user "Ziehe das Netzteil ab und stecke es wieder an. Wechselt die Statusanzeige zwischen Entladen und Laden?")"
	case "$A" in
		PASS) add_result "Akku" PASS "Status '$BSTAT', Ladestand ${BCAP} Prozent. Der Wechsel wird erkannt." ;;
		FAIL) add_result "Akku" FAIL "Der Wechsel zwischen Netz- und Akkubetrieb wird nicht erkannt." ;;
		*)    add_result "Akku" PARTIAL "Status '$BSTAT', Ladestand ${BCAP} Prozent. Der Wechsel wurde nicht geprueft." ;;
	esac
fi

# ---------------------------------------------------------------------------
log_step "Kernelmeldungen und Neustarts"
# ---------------------------------------------------------------------------
# V4.1: Die Suche ist jetzt gross- und kleinschreibungsempfindlich und
# schliesst bekannte harmlose Meldungen aus.
# Gemessen: 'ACPI BIOS Bug:' kommt auf Apple-Firmware regelmaessig vor und
# haette die Abnahme mit einem Fehlbefund blockiert.
OOPS="$(journalctl -k -b 0 --no-pager 2>/dev/null \
	| grep -E 'Kernel panic|BUG: |Oops|scheduling while atomic|NULL pointer dereference' \
	| grep -cvE 'ACPI BIOS (Bug|Error)|DEBUG|debug' || true)"
BENIGN="$(journalctl -k -b 0 --no-pager 2>/dev/null | grep -cE 'ACPI BIOS (Bug|Error)' || true)"
[ "${BENIGN:-0}" -gt 0 ] && log_info "Zusaetzlich ${BENIGN} harmlose ACPI-BIOS-Meldungen der Apple-Firmware (nicht gewertet)."
BOOTS="$(journalctl --list-boots --no-pager 2>/dev/null | wc -l)"
log_info "Auffaellige Kernelmeldungen im laufenden Start: ${OOPS:-0}   Startvorgaenge im Protokoll: $BOOTS"
if [ "${OOPS:-0}" -eq 0 ]; then
	add_result "Kernelmeldungen" PASS "Es gibt keine auffaelligen Kernelmeldungen im laufenden Start."
else
	add_result "Kernelmeldungen" FAIL "Es gibt ${OOPS} auffaellige Kernelmeldungen. Pruefe: journalctl -k -b 0 | grep -E 'BUG: |Oops|atomic'"
fi
add_result "Dauerbetrieb" NOT_TESTED "Der Langzeittest ueber mehrere Stunden steht aus. Er ist Voraussetzung fuer MAXIMUS_WORKER_READY."

# ---------------------------------------------------------------------------
log_step "Bericht schreiben"
# ---------------------------------------------------------------------------
N_PASS=0; N_PARTIAL=0; N_FAIL=0; N_BLOCKED=0; N_NT=0
for r in "${R_RESULT[@]}"; do
	case "$r" in
		PASS)       N_PASS=$((N_PASS + 1)) ;;
		PARTIAL)    N_PARTIAL=$((N_PARTIAL + 1)) ;;
		FAIL)       N_FAIL=$((N_FAIL + 1)) ;;
		BLOCKED)    N_BLOCKED=$((N_BLOCKED + 1)) ;;
		NOT_TESTED) N_NT=$((N_NT + 1)) ;;
	esac
done

{
	printf -- '---\n'
	printf 'title: Hardware-Abnahme MacBookPro16,1\n'
	printf 'created: %s\n' "$(date -u +%Y-%m-%d)"
	printf 'type: bericht\n'
	printf 'tags: [maximus, t2linux, hardware-abnahme]\n'
	printf -- '---\n\n'
	printf '# Hardware-Abnahme MacBookPro16,1\n\n'
	printf '| Angabe | Wert |\n| --- | --- |\n'
	printf '| Zeitpunkt | %s |\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	printf '| Fassung | %s |\n' "$MT2_VERSION"
	printf '| Kernel | %s |\n' "$(md_cell "$(uname -r)")"
	printf '| Modell | %s |\n' "$(md_cell "$(mt2_model || echo unbekannt)")"
	printf '| Ubuntu | %s |\n' "$(md_cell "$(mt2_release_id || echo unbekannt)")"
	printf '| Betriebsart | %s |\n' "$([ "$INTERACTIVE" -eq 1 ] && echo 'mit Mitwirkung' || echo 'ohne Mitwirkung')"
	# shellcheck disable=SC2016  # Die Backticks sind Markdown, keine Substitution.
	printf '| Kernelparameter | `%s` |\n' "$(md_cell "$CMDLINE")"
	printf '\n## Ergebnisse\n\n'
	printf '| Prueffeld | Ergebnis | Anmerkung |\n| --- | --- | --- |\n'
	i=0
	while [ "$i" -lt "${#R_FIELD[@]}" ]; do
		printf '| %s | %s | %s |\n' "$(md_cell "${R_FIELD[$i]}")" "${R_RESULT[$i]}" "$(md_cell "${R_NOTE[$i]}")"
		i=$((i + 1))
	done
	printf '\n## Zusammenfassung\n\n'
	printf '| Bewertung | Anzahl |\n| --- | --- |\n'
	printf '| PASS | %d |\n| PARTIAL | %d |\n| FAIL | %d |\n| BLOCKED | %d |\n| NOT_TESTED | %d |\n' \
		"$N_PASS" "$N_PARTIAL" "$N_FAIL" "$N_BLOCKED" "$N_NT"
	printf '\n## Statusbewertung\n\n'
	if [ "$N_FAIL" -eq 0 ] && [ "$N_NT" -eq 0 ] && [ "$N_BLOCKED" -eq 0 ]; then
		printf 'HARDWARE_READY: erteilt.\n'
	else
		printf 'HARDWARE_READY: NICHT erteilt.\n\n'
		printf 'Begruendung: %d Fehler, %d gesperrte und %d ungepruefte Felder.\n' "$N_FAIL" "$N_BLOCKED" "$N_NT"
	fi
	printf '\nMAXIMUS_WORKER_READY: NICHT erteilt. Der Dauerbetrieb ist nicht nachgewiesen.\n'
} > "$OUTFILE"

log_ok "Bericht geschrieben: $OUTFILE"
# V4.1: Die mitgelieferte Vorlage wird NIE ueberschrieben.
# Die Kopie traegt einen Zeitstempel und entsteht nur auf dem Zielgeraet.
# Gemessen in V4.1: Ein Testlauf in der Bauumgebung hatte die Vorlage mit
# unbrauchbaren Werten ersetzt.
REPORT_MODEL="$(mt2_model || true)"
if [ "$REPORT_MODEL" != "$MT2_SUPPORTED_MODEL" ]; then
	log_warn "Dies ist nicht $MT2_SUPPORTED_MODEL (erkannt: '${REPORT_MODEL:-unbekannt}')."
	log_warn "Der Bericht wird NICHT in das Paket kopiert. Er liegt nur unter $OUTFILE."
elif [ ! -w "$ROOT/reports" ]; then
	log_info "Das Verzeichnis $ROOT/reports ist nicht beschreibbar. Der Bericht liegt nur unter $OUTFILE."
else
	COPY_TARGET="$ROOT/reports/HARDWARE_TEST_REPORT-$STAMP.md"
	if cp "$OUTFILE" "$COPY_TARGET" 2>/dev/null; then
		log_ok "Kopie: $COPY_TARGET"
		log_info "Die Vorlage reports/HARDWARE_TEST_REPORT.md bleibt unveraendert."
	else
		log_warn "Die Kopie nach $ROOT/reports/ gelang nicht. Das Medium ist vermutlich schreibgeschuetzt."
	fi
fi

log ""
log "PASS: $N_PASS   PARTIAL: $N_PARTIAL   FAIL: $N_FAIL   BLOCKED: $N_BLOCKED   NOT_TESTED: $N_NT"
if [ "$N_FAIL" -gt 0 ]; then
	log_err "Die Abnahme ist fehlgeschlagen. HARDWARE_READY wird nicht erteilt."
	exit "$RC_HARDWARE"
fi
if [ "$N_NT" -gt 0 ] || [ "$N_BLOCKED" -gt 0 ]; then
	log_warn "Die Abnahme ist unvollstaendig. HARDWARE_READY wird nicht erteilt."
	exit "$RC_HARDWARE"
fi
log_ok "HARDWARE_READY ist erteilt."
exit "$RC_OK"
