#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Neustart des installierten Systems
#
# Ergebnis: Der Test startet die Testzielplatte OHNE das Medium und
# sammelt die Ausgabe ein. Er weist nach, dass das installierte System
# selbst startfaehig ist.
#
# Aufruf: bash boot-installed.sh --disk DATEI --out DIR [--minutes M]

set -uo pipefail
DISK=''; OUTD=''; MINUTES=40
while [ "$#" -gt 0 ]; do
	case "$1" in
		--disk) DISK="${2:?}"; shift ;;
		--out) OUTD="${2:?}"; shift ;;
		--minutes) MINUTES="${2:?}"; shift ;;
		*) printf 'FEHLER: Unbekannte Option %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done
[ -f "$DISK" ] || { printf 'FEHLER: --disk fehlt.\n' >&2; exit 2; }
[ -n "$OUTD" ] || { printf 'FEHLER: --out fehlt.\n' >&2; exit 2; }
rm -rf "$OUTD"; mkdir -p "$OUTD"
cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OUTD/vars.fd"

printf 'Testplatte: %s\n' "$DISK"
printf 'KEIN Installationsmedium angeschlossen.\n'

qemu-system-x86_64 \
	-machine q35 -m 4096 -smp 4 -cpu qemu64 \
	-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
	-drive if=pflash,format=raw,unit=1,file="$OUTD/vars.fd" \
	-drive "file=$DISK,if=none,id=hd0,format=qcow2" \
	-device virtio-blk-pci,drive=hd0,serial=MAXIMUSTESTZIEL01,bootindex=0 \
	-nic none \
	-vga std -display none \
	-serial "file:$OUTD/serial.log" \
	-monitor "unix:$OUTD/mon.sock,server,nowait" \
	-no-reboot \
	>"$OUTD/qemu.log" 2>&1 &
QPID=$!
printf 'qemu PID %s\n' "$QPID"
mon() { printf '%s\n' "$1" | timeout 10 socat - "unix-connect:$OUTD/mon.sock" >/dev/null 2>&1; }
END=$(( $(date +%s) + MINUTES * 60 )); SHOT=0
while [ "$(date +%s)" -lt "$END" ]; do
	sleep 20
	kill -0 "$QPID" 2>/dev/null || { printf 'qemu endete von selbst.\n'; break; }
	SHOT=$((SHOT + 1))
	mon "$(printf 'screendump %s/shot-%03d.ppm' "$OUTD" "$SHOT")"
done
mon 'quit'; sleep 2; kill "$QPID" 2>/dev/null; wait "$QPID" 2>/dev/null
printf 'serial.log: %s Byte, %s Abzuege\n' \
	"$(wc -c <"$OUTD/serial.log" 2>/dev/null || echo 0)" \
	"$(ls "$OUTD"/shot-*.ppm 2>/dev/null | wc -l)"
