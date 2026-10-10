#!/bin/sh
# MAXIMUS T2 Neuinstallation V1 - Haken aus preseed/early_command
#
# Ergebnis: Dieses Skript legt den Assistenten im Live-System ab.
# Es installiert nichts. Es loescht nichts. Es formatiert nichts.
#
# Umgebung: Casper fuehrt es im Initramfs aus, siehe
# /scripts/casper-bottom/24preseed des mitgelieferten Initramfs.
# Das Live-System liegt dort unter /root.
# Das Medium liegt unter /root/cdrom, weil 05mountpoints es dorthin
# verschoben hat.
#
# Aufruf: sh early.sh [medienpfad]

set -u

LIVE=/root
MED="${1:-}"

# Medienpfad bestimmen. Die Reihenfolge deckt beide Casper-Fassungen ab.
if [ -z "$MED" ] || [ ! -d "$MED/maximus" ]; then
	for p in /root/cdrom /cdrom /run/live/medium; do
		if [ -d "$p/maximus" ]; then MED="$p"; break; fi
	done
fi

say() { printf 'MAXIMUS: %s\n' "$1" > /dev/console 2>/dev/null; }

if [ -z "${MED:-}" ] || [ ! -d "$MED/maximus" ]; then
	say "FEHLER: Das Verzeichnis maximus/ ist auf dem Medium nicht auffindbar."
	exit 0
fi

if [ ! -d "$LIVE" ]; then
	say "FEHLER: Das Live-System ist unter /root nicht auffindbar."
	exit 0
fi

# Nachweis, dass die Preseed geladen und dieser Haken ausgefuehrt wurde.
# Die Zeichenfolge ist eindeutig. Der Starttest sucht genau danach.
say "PRESEED-GELADEN-UND-EARLY-COMMAND-AUSGEFUEHRT medium=$MED"

mkdir -p "$LIVE/opt/maximus" 2>/dev/null
cp -a "$MED/maximus/." "$LIVE/opt/maximus/" 2>/dev/null \
	|| { say "FEHLER: Das Kopieren nach /opt/maximus schlug fehl."; exit 0; }

# Marke mit dem Medienpfad. Der Assistent liest sie.
printf '%s\n' "$MED" > "$LIVE/opt/maximus/medium-pfad" 2>/dev/null

# Dienst einrichten. Er laeuft nur mit maximus.install=1 auf der Kernelzeile.
UNIT="$LIVE/etc/systemd/system/maximus-wizard.service"
mkdir -p "$LIVE/etc/systemd/system/multi-user.target.wants" 2>/dev/null
cat > "$UNIT" <<'UNITEOF'
[Unit]
Description=MAXIMUS T2 Neuinstallation (Assistent)
Documentation=file:/opt/maximus/README.txt
After=systemd-user-sessions.service plymouth-quit-wait.service
After=systemd-udev-settle.service getty@tty1.service
Wants=systemd-udev-settle.service
# Gemessen im Prueflauf: Ohne diese Zeile uebernimmt getty@tty1 die Konsole
# und ueberdeckt den Assistenten mit einer Anmeldeaufforderung.
Conflicts=getty@tty1.service
ConditionKernelCommandLine=maximus.install=1
ConditionPathExists=/opt/maximus/wizard.sh

[Service]
Type=idle
ExecStart=/bin/bash /opt/maximus/wizard.sh
StandardInput=tty-force
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
Restart=no
TimeoutStartSec=infinity

[Install]
WantedBy=multi-user.target
UNITEOF

ln -sf ../maximus-wizard.service \
	"$LIVE/etc/systemd/system/multi-user.target.wants/maximus-wizard.service" 2>/dev/null

# Zweiter Dienst: der Selbsttest. Er installiert nichts.
# Er laeuft nur mit maximus.selftest=1 auf der Kernelzeile.
UNIT2="$LIVE/etc/systemd/system/maximus-selftest.service"
cat > "$UNIT2" <<'UNIT2EOF'
[Unit]
Description=MAXIMUS T2 Selbsttest (Nachweis, keine Installation)
After=systemd-user-sessions.service systemd-udev-settle.service
Wants=systemd-udev-settle.service
ConditionKernelCommandLine=maximus.selftest=1
ConditionPathExists=/opt/maximus/selftest.sh

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash /opt/maximus/selftest.sh
StandardOutput=journal+console
StandardError=journal+console
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
UNIT2EOF
ln -sf ../maximus-selftest.service \
	"$LIVE/etc/systemd/system/multi-user.target.wants/maximus-selftest.service" 2>/dev/null

if [ -f "$UNIT" ]; then
	say "Assistent eingerichtet: /opt/maximus/wizard.sh auf tty1"
else
	say "FEHLER: Der Dienst liess sich nicht einrichten."
fi

exit 0
