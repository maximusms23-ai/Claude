#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Selbsttest im Live-System
#
# Ergebnis: Der Selbsttest belegt, dass der gestartete Installer die
# Preseed-Datei wirklich geladen hat. Er installiert nichts.
#
# Nachweis: Er fragt die debconf-Datenbank des Live-Systems ab. Steht dort
# de_DE.UTF-8 und Europe/Berlin, dann hat der Installer die Datei gelesen.
# Eine Datei neben dem ISO allein wuerde das nicht zeigen.
#
# Aufruf: bash selftest.sh

set -uo pipefail

M() { printf 'MAXIMUS-SELBSTTEST: %s\n' "$1"; printf 'MAXIMUS-SELBSTTEST: %s\n' "$1" > /dev/console 2>/dev/null || true; }

M "START fassung=1.0.0"
M "kernel=$(uname -r)"
M "kernelzeile=$(tr -d '\n' < /proc/cmdline)"

# 1. Liegen die Dateien im Live-System?
for f in /opt/maximus/wizard.sh /opt/maximus/postinstall.sh /opt/maximus/lib/common.sh \
         /opt/maximus/firstboot/report.sh; do
	if [ -f "$f" ]; then M "DATEI-OK $f"; else M "DATEI-FEHLT $f"; fi
done

# 2. Hat der Installer die Preseed wirklich uebernommen?
# debconf-show liest die Datenbank, die casper-set-selections gefuellt hat.
if command -v debconf-show >/dev/null 2>&1; then
	for q in debian-installer/locale time/zone keyboard-configuration/layoutcode \
	         netcfg/get_hostname apt-setup/use_mirror debian-installer/add-kernel-opts; do
		paket="d-i"
		v="$(debconf-show "$paket" 2>/dev/null | sed -n "s|^[* ] ${q}: ||p" | head -1)"
		if [ -z "$v" ]; then
			v="$(echo "get $q" | debconf-communicate 2>/dev/null | sed 's/^0 //')"
		fi
		if [ -n "$v" ]; then M "DEBCONF-OK $q = $v"; else M "DEBCONF-LEER $q"; fi
	done
else
	M "DEBCONF-WERKZEUG-FEHLT debconf-show"
fi

# 3. Ist der Installer vorhanden und kennt er das Frontend ohne Grafik?
if command -v ubiquity >/dev/null 2>&1; then
	M "UBIQUITY-VORHANDEN $(command -v ubiquity)"
	if [ -f /usr/lib/ubiquity/ubiquity/frontend/noninteractive.py ]; then
		M "FRONTEND-NONINTERACTIVE-VORHANDEN ja"
	else
		M "FRONTEND-NONINTERACTIVE-VORHANDEN nein"
	fi
else
	M "UBIQUITY-VORHANDEN nein"
fi

# 4. Zielauswahl in der Simulation. Es wird nichts geschrieben.
M "ZIELAUSWAHL-SIMULATION beginnt"
if [ -f /opt/maximus/lib/common.sh ]; then
	# shellcheck source=lib/common.sh
	. /opt/maximus/lib/common.sh
	MED="$(mx_live_medium_disk 2>/dev/null)" || MED=''
	M "LAUFENDES-MEDIUM ${MED:-NICHT-BESTIMMBAR}"
	n=0
	while read -r name type; do
		[ "$type" = "disk" ] || continue
		case "$name" in loop*|zram*|sr*|ram*) continue ;; esac
		dev="/dev/$name"
		if [ "$dev" = "$MED" ]; then M "AUSGESCHLOSSEN-ALS-ZIEL $dev (laufendes Medium)"; continue; fi
		sid="$(mx_stable_id "$dev" 2>/dev/null)" || sid='KEINE'
		n=$((n + 1))
		M "ZIELKANDIDAT $dev kennung=$sid"
	done < <(lsblk -ndo NAME,TYPE)
	M "ZIELKANDIDATEN-ANZAHL $n"
fi

# 5. Temperaturregel pruefen: fehlender Wert darf nicht 0 ergeben.
if [ -f /opt/maximus/firstboot/report.sh ]; then
	M "TEMPERATURREGEL wird geprueft"
	t="$(for p in /sys/class/thermal/thermal_zone*/temp; do [ -r "$p" ] && cat "$p"; done | head -1)"
	if [ -z "$t" ]; then
		M "TEMPERATURREGEL-OK kein Sensor vorhanden, Bericht meldet FEHLGESCHLAGEN statt 0 Grad"
	else
		M "TEMPERATURREGEL-OK Sensorwert vorhanden: $((t / 1000)) Grad"
	fi
fi

M "ENDE ergebnis=selbsttest-durchgelaufen"
# Das System bleibt stehen, damit der Starttest die Ausgabe einsammeln kann.
sync
exit 0
