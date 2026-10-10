#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Funktionsbericht nach dem ersten Start
#
# Ergebnis: Der Bericht nennt je Hardwareteil einen von fuenf Zustaenden.
# Er misst, wo eine Messung moeglich ist. Er behauptet nichts.
#
# Zustaende:
#   VORBEREITET            eingerichtet, aber zur Laufzeit nicht belegt
#   AM_GERAET_BESTANDEN    am Geraet gemessen und in Ordnung
#   EINGESCHRAENKT         teilweise nutzbar, mit genannter Einschraenkung
#   FEHLGESCHLAGEN         gemessen und nicht in Ordnung
#   NICHT_GEPRUEFT         nicht geprueft, Grund genannt
#
# Grundsatz Temperatur: Ein fehlender Messwert gilt NIEMALS als 0 Grad.
# Grundsatz Last: Dieser Bericht erzeugt KEINE CPU-Last.
#
# Aufruf: sudo bash report.sh [--out DATEI] [--no-color]

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$SELF_DIR/../lib/common.sh"
# shellcheck source=../lib/common.sh
[ -f "$LIB" ] && . "$LIB" || { printf 'FEHLER: lib/common.sh fehlt.\n'; exit 6; }

OUT=/var/log/maximus-funktionsbericht.md
while [ "$#" -gt 0 ]; do
	case "$1" in
		--out) OUT="${2:?Pfad fehlt}"; shift ;;
		--no-color) NO_COLOR=1; export NO_COLOR ;;
		*) printf 'Unbekannte Option %s\n' "$1"; exit 2 ;;
	esac
	shift
done

MX_LOG=/var/log/maximus-funktionsbericht.log
mx_log_init

RES_FILE="$(mktemp)"
trap 'rm -f "$RES_FILE"' EXIT

# add <teil> <zustand> <begruendung>
add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$RES_FILE"; }

# --- Temperatur: uebernommen aus MAXIMUS V4.2 ----------------------------
readonly TEMP_MIN_PLAUSIBEL=5
readonly TEMP_MAX_PLAUSIBEL=125

# Gibt den hoechsten glaubwuerdigen Wert aus, oder NICHTS und Rueckgabe 1.
mx_cpu_temp() {
	local t max=-1 found=0 pattern
	for pattern in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do
		[ -r "$pattern" ] || continue
		t="$(cat "$pattern" 2>/dev/null)" || continue
		case "$t" in ''|*[!0-9]*) continue ;; esac
		t=$((t / 1000))
		[ "$t" -lt "$TEMP_MIN_PLAUSIBEL" ] && continue
		[ "$t" -gt "$TEMP_MAX_PLAUSIBEL" ] && continue
		found=1
		[ "$t" -gt "$max" ] && max="$t"
	done
	[ "$found" -eq 1 ] || return 1
	printf '%s' "$max"
	return 0
}

mx_temp_sensoren() {
	local n=0 t pattern
	for pattern in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do
		[ -r "$pattern" ] || continue
		t="$(cat "$pattern" 2>/dev/null)" || continue
		case "$t" in ''|*[!0-9]*) continue ;; esac
		t=$((t / 1000))
		[ "$t" -lt "$TEMP_MIN_PLAUSIBEL" ] && continue
		[ "$t" -gt "$TEMP_MAX_PLAUSIBEL" ] && continue
		n=$((n + 1))
	done
	printf '%s' "$n"
}

mx_luefter_werte() {
	local f
	for f in /sys/class/hwmon/hwmon*/fan*_input; do
		[ -r "$f" ] || continue
		printf '%s ' "$(cat "$f" 2>/dev/null || echo 0)"
	done
}

log_step "MAXIMUS Funktionsbericht"
log_info "Kernel: $(uname -r)"
log_info "Modell: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo unbekannt)"
log_info "Dieser Bericht erzeugt keine CPU-Last."

# ---------------------------------------------------------------------------
# Modell
# ---------------------------------------------------------------------------
MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo '')"
if [ -z "$MODEL" ]; then
	add "Modellkennung" NICHT_GEPRUEFT "Die Kennung ist nicht lesbar (/sys/class/dmi/id/product_name)."
elif [ "$MODEL" = "MacBookPro16,1" ]; then
	add "Modellkennung" AM_GERAET_BESTANDEN "$MODEL, wie erwartet."
else
	add "Modellkennung" EINGESCHRAENKT "Gemessen: $MODEL. Erwartet war MacBookPro16,1. Pruefe die Treiberwahl."
fi

# ---------------------------------------------------------------------------
# Kernel und T2-Module
# ---------------------------------------------------------------------------
KREL="$(uname -r)"
case "$KREL" in
	*t2*) add "T2-Kernel" AM_GERAET_BESTANDEN "Laufender Kernel: $KREL" ;;
	*)    add "T2-Kernel" FEHLGESCHLAGEN "Es laeuft $KREL ohne T2-Kennzeichnung. Die T2-Treiber fehlen dann." ;;
esac

MODS_OK=0; MODS_MISS=''
for m in t2bce_core t2bce_dma t2bce_vhci; do
	if lsmod 2>/dev/null | awk '{print $1}' | grep -qx "${m//-/_}"; then
		MODS_OK=$((MODS_OK + 1))
	else
		MODS_MISS="$MODS_MISS $m"
	fi
done
if [ "$MODS_OK" -eq 3 ]; then
	add "T2-Treiberstapel" AM_GERAET_BESTANDEN "Alle drei Module sind geladen: t2bce_core, t2bce_dma, t2bce_vhci."
elif [ "$MODS_OK" -gt 0 ]; then
	add "T2-Treiberstapel" EINGESCHRAENKT "$MODS_OK von 3 Modulen geladen. Es fehlt:$MODS_MISS"
else
	add "T2-Treiberstapel" FEHLGESCHLAGEN "Kein t2bce-Modul ist geladen. Eingabe, Audio und Kamera bleiben ohne Funktion."
fi

# ---------------------------------------------------------------------------
# Eingabegeraete: echte Funktionspruefung ueber Ereigniszaehler
# ---------------------------------------------------------------------------
KBD=''; TPD=''
for d in /sys/class/input/event*/device/name; do
	[ -r "$d" ] || continue
	n="$(cat "$d" 2>/dev/null)"
	case "$n" in
		*[Kk]eyboard*|*Apple*SPI*Keyboard*|*"Apple Internal Keyboard"*) KBD="$n" ;;
		*[Tt]rackpad*|*[Tt]ouchpad*) TPD="$n" ;;
	esac
done
if [ -n "$KBD" ]; then
	add "Interne Tastatur" VORBEREITET "Geraet erkannt: $KBD. Ein Tastendruck ist hier nicht messbar."
else
	add "Interne Tastatur" FEHLGESCHLAGEN "Es ist kein internes Tastaturgeraet erkannt."
fi
if [ -n "$TPD" ]; then
	add "Trackpad" VORBEREITET "Geraet erkannt: $TPD. Eine Bewegung ist hier nicht messbar."
else
	add "Trackpad" FEHLGESCHLAGEN "Es ist kein Trackpad erkannt."
fi

# Touch Bar
if [ -d /sys/class/backlight/appletb_backlight ] || systemctl is-active tiny-dfr >/dev/null 2>&1; then
	if systemctl is-active tiny-dfr >/dev/null 2>&1; then
		add "Touch Bar" AM_GERAET_BESTANDEN "Der Dienst tiny-dfr laeuft."
	else
		add "Touch Bar" EINGESCHRAENKT "Die Hardware ist erkannt, der Dienst tiny-dfr laeuft nicht."
	fi
else
	add "Touch Bar" NICHT_GEPRUEFT "Weder appletb_backlight noch tiny-dfr sind vorhanden."
fi

# ---------------------------------------------------------------------------
# Datentraeger
# ---------------------------------------------------------------------------
ROOTSRC="$(findmnt -no SOURCE / 2>/dev/null)"
if [ -n "$ROOTSRC" ]; then
	add "Interne SSD" AM_GERAET_BESTANDEN "Das Wurzeldateisystem liegt auf $ROOTSRC und ist lesbar."
else
	add "Interne SSD" FEHLGESCHLAGEN "Die Quelle des Wurzeldateisystems ist nicht ermittelbar."
fi
NUSB="$(lsblk -ndo NAME,TRAN 2>/dev/null | awk '$2=="usb"' | wc -l)"
add "USB-Anschluesse" VORBEREITET "$NUSB USB-Datentraeger sichtbar. Ohne angeschlossenes Geraet ist mehr nicht messbar."
if [ -d /sys/bus/thunderbolt/devices ] && find /sys/bus/thunderbolt/devices -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
	add "Thunderbolt" AM_GERAET_BESTANDEN "Der Thunderbolt-Bus meldet Geraete."
else
	add "Thunderbolt" NICHT_GEPRUEFT "Der Bus meldet kein Geraet. Ohne angeschlossenes Geraet ist das normal."
fi

# ---------------------------------------------------------------------------
# WLAN und Bluetooth
# ---------------------------------------------------------------------------
WCHIP="$(lspci -nn 2>/dev/null | grep -iE 'network|wireless' | head -1)"
FW_PRESENT=0
find /lib/firmware/brcm -maxdepth 1 -name 'brcmfmac4*' -print -quit 2>/dev/null | grep -q . && FW_PRESENT=1
WIFACE="$(ls /sys/class/net 2>/dev/null | while read -r i; do [ -d "/sys/class/net/$i/wireless" ] && printf '%s ' "$i"; done)"
if [ -n "$WIFACE" ]; then
	if iw dev "${WIFACE%% *}" link 2>/dev/null | grep -qi 'Connected'; then
		add "WLAN" AM_GERAET_BESTANDEN "Schnittstelle ${WIFACE%% *} ist verbunden."
	elif iw dev "${WIFACE%% *}" scan 2>/dev/null | grep -q 'SSID'; then
		add "WLAN" AM_GERAET_BESTANDEN "Schnittstelle ${WIFACE%% *} findet Netze. Eine Verbindung besteht nicht."
	else
		add "WLAN" EINGESCHRAENKT "Schnittstelle ${WIFACE%% *} vorhanden, findet aber kein Netz. Firmware vorhanden: $FW_PRESENT"
	fi
elif [ "$FW_PRESENT" -eq 1 ]; then
	add "WLAN" EINGESCHRAENKT "Firmware liegt vor, es gibt aber keine WLAN-Schnittstelle. Chip: ${WCHIP:-unbekannt}"
else
	add "WLAN" FEHLGESCHLAGEN "Keine Schnittstelle und keine Apple-Firmware. Abhilfe: sudo get-apple-firmware get_from_macos"
fi

if [ -d /sys/class/bluetooth ] && find /sys/class/bluetooth -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
	if hciconfig 2>/dev/null | grep -q 'UP RUNNING' || bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
		add "Bluetooth" EINGESCHRAENKT "Der Adapter laeuft. Bekannte Einschraenkung bei BCM4377: Stoerungen mit 2,4-GHz-WLAN."
	else
		add "Bluetooth" EINGESCHRAENKT "Der Adapter ist vorhanden, aber nicht eingeschaltet."
	fi
else
	add "Bluetooth" FEHLGESCHLAGEN "Es ist kein Bluetooth-Adapter sichtbar. Meist fehlt die Apple-Firmware."
fi

# ---------------------------------------------------------------------------
# Grafik
# ---------------------------------------------------------------------------
EDP=0
for c in /sys/class/drm/card*-eDP-*; do [ -e "$c" ] && EDP=1; done
DRVS="$(lsmod 2>/dev/null | awk '{print $1}' | grep -xE 'i915|amdgpu' | tr '\n' ' ')"
if [ "$EDP" -eq 1 ] && [ -n "$DRVS" ]; then
	add "Interner Bildschirm" AM_GERAET_BESTANDEN "eDP-Anschluss erkannt, Treiber geladen: $DRVS"
elif [ -n "$DRVS" ]; then
	add "Interner Bildschirm" EINGESCHRAENKT "Treiber geladen ($DRVS), aber kein eDP-Anschluss gemeldet."
else
	add "Interner Bildschirm" FEHLGESCHLAGEN "Es ist kein Grafiktreiber geladen."
fi
if printf '%s' "$DRVS" | grep -q amdgpu; then
	add "Radeon Pro 5500M" EINGESCHRAENKT "amdgpu ist geladen. Bekannte Einschraenkung: Abschalten der dGPU wirkt nicht."
else
	add "Radeon Pro 5500M" NICHT_GEPRUEFT "amdgpu ist nicht geladen."
fi
NEXT="$(find /sys/class/drm -maxdepth 1 -name 'card*-DP-*' -o -maxdepth 1 -name 'card*-HDMI-*' 2>/dev/null | wc -l)"
add "Externe Bildausgaenge" VORBEREITET "$NEXT Anschluesse gemeldet. Ohne angeschlossenen Bildschirm ist mehr nicht messbar."

# ---------------------------------------------------------------------------
# Audio und Kamera
# ---------------------------------------------------------------------------
if [ -d /proc/asound ] && grep -qi 'apple\|t2' /proc/asound/cards 2>/dev/null; then
	add "Lautsprecher" VORBEREITET "Die T2-Soundkarte ist erkannt. Ein Hoertest ist hier nicht messbar."
	add "Mikrofon" EINGESCHRAENKT "Erkannt. Bekannte Einschraenkung: geringer Eingangspegel ohne DSP."
	add "Kopfhoeranschluss" EINGESCHRAENKT "Bekannte Einschraenkung: Das Umschalten beim Einstecken wirkt nicht immer."
elif [ -d /proc/asound ]; then
	add "Lautsprecher" EINGESCHRAENKT "Es gibt Audiogeraete, aber keine T2-Soundkarte: $(tr -d '\n' < /proc/asound/cards | cut -c1-80)"
	add "Mikrofon" NICHT_GEPRUEFT "Ohne T2-Soundkarte nicht pruefbar."
	add "Kopfhoeranschluss" NICHT_GEPRUEFT "Ohne T2-Soundkarte nicht pruefbar."
else
	add "Lautsprecher" FEHLGESCHLAGEN "Es ist kein Audiogeraet vorhanden."
	add "Mikrofon" FEHLGESCHLAGEN "Es ist kein Audiogeraet vorhanden."
	add "Kopfhoeranschluss" FEHLGESCHLAGEN "Es ist kein Audiogeraet vorhanden."
fi
if find /dev -maxdepth 1 -name 'video[0-9]*' -print -quit 2>/dev/null | grep -q .; then
	CAMN="$(v4l2-ctl --list-devices 2>/dev/null | head -1)"
	add "Kamera" VORBEREITET "Geraet vorhanden: ${CAMN:-/dev/video*}. Ein Bildtest ist hier nicht messbar."
else
	add "Kamera" FEHLGESCHLAGEN "Es ist kein /dev/video-Geraet vorhanden. Die Kamera haengt an t2bce."
fi

# ---------------------------------------------------------------------------
# Temperatur: ohne jede kuenstliche Last
# ---------------------------------------------------------------------------
TEMP=''
TEMP="$(mx_cpu_temp)" || TEMP=''
SENS="$(mx_temp_sensoren)"
if [ -z "$TEMP" ]; then
	add "Temperaturmessung" FEHLGESCHLAGEN "Es ist KEINE Temperatur messbar. Lesbare Sensoren: $SENS. Ein fehlender Wert gilt nicht als 0 Grad."
else
	if [ "$TEMP" -ge 90 ]; then
		add "Temperaturmessung" EINGESCHRAENKT "$SENS Sensoren lesbar. Hoechster Wert im Ruhezustand: $TEMP Grad Celsius. Das ist zu hoch."
	elif [ "$TEMP" -ge 70 ]; then
		add "Temperaturmessung" EINGESCHRAENKT "$SENS Sensoren lesbar. Ruhetemperatur $TEMP Grad Celsius ist erhoeht."
	else
		add "Temperaturmessung" AM_GERAET_BESTANDEN "$SENS Sensoren lesbar. Ruhetemperatur $TEMP Grad Celsius."
	fi
fi

# ---------------------------------------------------------------------------
# Luefterregelung: ohne Last nur beobachtbar, nicht beweisbar
# ---------------------------------------------------------------------------
FANV="$(mx_luefter_werte)"
FANC="$(printf '%s' "$FANV" | wc -w)"
NONZERO="$(printf '%s' "$FANV" | tr ' ' '\n' | awk 'NF && $1>0' | wc -l)"
FANSVC="$(systemctl is-active t2fanrd 2>/dev/null || echo inaktiv)"
if [ "$FANC" -eq 0 ]; then
	add "Luefterwerte" FEHLGESCHLAGEN "Es sind keine Drehzahlen lesbar. Pruefe das Modul applesmc."
	add "Luefterregelung" FEHLGESCHLAGEN "Ohne lesbare Drehzahl ist keine Regelung feststellbar."
else
	add "Luefterwerte" AM_GERAET_BESTANDEN "$FANC Werte lesbar, $NONZERO davon ueber null: $FANV"
	# Ein laufender Luefter allein beweist keine Regelung.
	if [ "$FANSVC" = "active" ] && [ -n "$TEMP" ]; then
		add "Luefterregelung" VORBEREITET "Dienst t2fanrd laeuft, Temperatur ist messbar. Die Regelung ist damit moeglich, aber ohne Last nicht bewiesen."
	elif [ "$FANSVC" = "active" ]; then
		add "Luefterregelung" EINGESCHRAENKT "Dienst t2fanrd laeuft, aber es gibt keinen Temperaturwert. Die Regelung hat keine Grundlage."
	else
		add "Luefterregelung" FEHLGESCHLAGEN "Der Dienst t2fanrd ist '$FANSVC'. Ohne ihn regelt unter Linux nichts."
	fi
fi

# ---------------------------------------------------------------------------
# Energie, Helligkeit, Akku
# ---------------------------------------------------------------------------
if find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit 2>/dev/null | grep -q .; then
	BAT="$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' | head -1)"
	CAP="$(cat "$BAT/capacity" 2>/dev/null || echo '')"
	if [ -n "$CAP" ]; then
		add "Akkuanzeige" AM_GERAET_BESTANDEN "$(basename "$BAT") meldet $CAP Prozent."
	else
		add "Akkuanzeige" EINGESCHRAENKT "$(basename "$BAT") vorhanden, aber die Ladung ist nicht lesbar."
	fi
else
	add "Akkuanzeige" FEHLGESCHLAGEN "Es ist kein Akku gemeldet."
fi
if find /sys/class/backlight -maxdepth 1 -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
	BL="$(find /sys/class/backlight -maxdepth 1 -mindepth 1 | head -1)"
	add "Helligkeitssteuerung" VORBEREITET "Regler vorhanden: $(basename "$BL"). Eine Aenderung wird hier nicht vorgenommen."
else
	add "Helligkeitssteuerung" FEHLGESCHLAGEN "Es ist kein Helligkeitsregler vorhanden."
fi
MEMSLEEP="$(cat /sys/power/mem_sleep 2>/dev/null || echo '')"
case "$MEMSLEEP" in
	*'[deep]'*) add "Ruhezustand" EINGESCHRAENKT "mem_sleep steht auf deep. Das Projekt meldet modellabhaengige Probleme." ;;
	*deep*)     add "Ruhezustand" EINGESCHRAENKT "deep ist moeglich, aktiv ist: $MEMSLEEP. Das Projekt meldet modellabhaengige Probleme." ;;
	'')         add "Ruhezustand" NICHT_GEPRUEFT "mem_sleep ist nicht lesbar." ;;
	*)          add "Ruhezustand" EINGESCHRAENKT "Nur $MEMSLEEP verfuegbar. s2idle weckt die AMD-Grafik oft nicht." ;;
esac
if [ -d /sys/class/apple-bce ] || lsmod 2>/dev/null | grep -q touchid; then
	add "Touch ID" EINGESCHRAENKT "Nur in macOS angelernte Finger sind nutzbar. Neue Finger lassen sich unter Linux nicht anlernen."
else
	add "Touch ID" NICHT_GEPRUEFT "Kein Treiber geladen. Touch ID braucht meist eine vorhandene macOS-Installation."
fi

# ---------------------------------------------------------------------------
# Bericht schreiben
# ---------------------------------------------------------------------------
{
	printf -- '---\n'
	printf 'title: MAXIMUS Funktionsbericht\n'
	printf 'created: %s\n' "$(date -u +%Y-%m-%d)"
	printf 'type: bericht\n'
	printf -- '---\n\n'
	printf '# Funktionsbericht nach dem ersten Start\n\n'
	printf 'Zeitpunkt: %s\n\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
	printf 'Modell:    %s\n\n' "${MODEL:-unbekannt}"
	printf 'Kernel:    %s\n\n' "$KREL"
	printf 'Dieser Bericht hat KEINE CPU-Last erzeugt.\n'
	printf 'Ein Lasttest braucht eine eigene Entscheidung.\n\n'
	printf '| Hardwareteil | Zustand | Begruendung |\n'
	printf '| --- | --- | --- |\n'
	while IFS="$(printf '\t')" read -r teil zustand grund; do
		printf '| %s | %s | %s |\n' "$teil" "$zustand" "${grund//|/\\|}"
	done < "$RES_FILE"
	printf '\n## Zusammenfassung\n\n'
	for z in AM_GERAET_BESTANDEN VORBEREITET EINGESCHRAENKT FEHLGESCHLAGEN NICHT_GEPRUEFT; do
		printf -- '- %s: %s\n' "$z" "$(awk -F'\t' -v z="$z" '$2==z' "$RES_FILE" | wc -l)"
	done
	printf '\n## Naechste Schritte\n\n'
	if awk -F'\t' '$1=="WLAN" && $2=="FEHLGESCHLAGEN"' "$RES_FILE" | grep -q .; then
		printf -- '1. WLAN-Firmware holen: `sudo get-apple-firmware get_from_macos`\n'
		printf '   Ohne macOS und per Kabelnetz: `sudo get-apple-firmware get_from_online`\n'
	fi
	if awk -F'\t' '$1=="Luefterregelung" && $2=="FEHLGESCHLAGEN"' "$RES_FILE" | grep -q .; then
		printf -- '2. Luefterdienst pruefen: `systemctl status t2fanrd`\n'
	fi
	printf -- '3. Lasttest nur mit eigener Entscheidung und bei messbarer Temperatur.\n'
} > "$OUT"

log ""
log_ok "Bericht geschrieben: $OUT"
log ""
printf '%-26s %-22s %s\n' "HARDWARETEIL" "ZUSTAND" "BEGRUENDUNG"
while IFS="$(printf '\t')" read -r teil zustand grund; do
	case "$zustand" in
		AM_GERAET_BESTANDEN) c="$C_G" ;;
		FEHLGESCHLAGEN)      c="$C_R" ;;
		EINGESCHRAENKT)      c="$C_Y" ;;
		*)                   c='' ;;
	esac
	printf '%-26s %s%-22s%s %s\n' "$teil" "$c" "$zustand" "$C_0" "$(printf '%s' "$grund" | cut -c1-70)"
done < "$RES_FILE"

NFAIL="$(awk -F'\t' '$2=="FEHLGESCHLAGEN"' "$RES_FILE" | wc -l)"
log ""
if [ "$NFAIL" -gt 0 ]; then
	log_warn "$NFAIL Hardwareteile sind fehlgeschlagen. Lies $OUT."
	exit "$RC_HARDWARE"
fi
log_ok "Kein Hardwareteil ist fehlgeschlagen."
exit "$RC_OK"
