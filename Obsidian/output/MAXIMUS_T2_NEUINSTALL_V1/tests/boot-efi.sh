#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - EFI-Starttest
#
# Ergebnis: Der Test startet das ISO unter OVMF, waehlt einen Menueeintrag
# und sammelt die Ausgabe der seriellen Schnittstelle ein.
#
# Grenze dieses Tests: Eine virtuelle Maschine beweist KEINE funktionierende
# T2-Hardware. Sie beweist die EFI-Startkette, das Startmenue und das
# Laden der Preseed.
#
# Aufruf: bash boot-efi.sh --iso ISO --out DIR [--entry N] [--minutes M]
#                          [--disk DATEI:GROESSE] [--no-net]

set -uo pipefail

ISO=''; OUTD=''; ENTRY=0; MINUTES=10; DISKSPEC=''; NONET=0
while [ "$#" -gt 0 ]; do
	case "$1" in
		--iso)     ISO="${2:?}"; shift ;;
		--out)     OUTD="${2:?}"; shift ;;
		--entry)   ENTRY="${2:?}"; shift ;;
		--minutes) MINUTES="${2:?}"; shift ;;
		--disk)    DISKSPEC="${2:?}"; shift ;;
		--no-net)  NONET=1 ;;
		-h|--help) sed -n '2,14p' "$0"; exit 0 ;;
		*) printf 'FEHLER: Unbekannte Option %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done
[ -n "$ISO" ] && [ -f "$ISO" ] || { printf 'FEHLER: --iso fehlt.\n' >&2; exit 2; }
[ -n "$OUTD" ] || { printf 'FEHLER: --out fehlt.\n' >&2; exit 2; }
for t in qemu-system-x86_64 socat; do
	command -v "$t" >/dev/null 2>&1 || { printf 'FEHLER: %s fehlt.\n' "$t" >&2; exit 6; }
done
[ -f /usr/share/OVMF/OVMF_CODE_4M.fd ] || { printf 'FEHLER: OVMF fehlt.\n' >&2; exit 6; }

rm -rf "$OUTD"; mkdir -p "$OUTD"
cp /usr/share/OVMF/OVMF_VARS_4M.fd "$OUTD/vars.fd"

DISKARGS=()
if [ -n "$DISKSPEC" ]; then
	DF="${DISKSPEC%%:*}"; DS="${DISKSPEC##*:}"
	qemu-img create -f qcow2 "$DF" "$DS" >/dev/null
	DISKARGS=(-drive "file=$DF,if=none,id=hd0,format=qcow2"
	          -device "virtio-blk-pci,drive=hd0,serial=MAXIMUSTESTZIEL01")
	printf 'Testzielplatte: %s (%s), Seriennummer MAXIMUSTESTZIEL01\n' "$DF" "$DS"
fi
NETARGS=(-netdev user,id=n0 -device virtio-net-pci,netdev=n0)
if [ "$NONET" -eq 1 ]; then
	NETARGS=(-nic none)
	printf 'Netzwerk: ABGESCHALTET (Nachweis der Offline-Installation)\n'
fi

printf 'ISO:      %s\n' "$ISO"
printf 'Eintrag:  %s\n' "$ENTRY"
printf 'Laufzeit: %s Minuten\n' "$MINUTES"

qemu-system-x86_64 \
	-machine q35 -m 6144 -smp 4 -cpu qemu64 \
	-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
	-drive if=pflash,format=raw,unit=1,file="$OUTD/vars.fd" \
	-drive "file=$ISO,media=cdrom,readonly=on,if=none,id=cd0" \
	-device ide-cd,drive=cd0,bootindex=0 \
	"${DISKARGS[@]}" "${NETARGS[@]}" \
	-vga std -display none \
	-serial "file:$OUTD/serial.log" \
	-monitor "unix:$OUTD/mon.sock,server,nowait" \
	-boot menu=off -no-reboot \
	>"$OUTD/qemu.log" 2>&1 &
QPID=$!
printf 'qemu PID %s\n' "$QPID"

mon() { printf '%s\n' "$1" | timeout 10 socat - "unix-connect:$OUTD/mon.sock" >/dev/null 2>&1; }

# Auf das Startmenue warten, dann den Eintrag waehlen.
for i in $(seq 1 40); do
	sleep 2
	grep -q 'GNU GRUB' "$OUTD/serial.log" 2>/dev/null && break
done
if grep -q 'GNU GRUB' "$OUTD/serial.log" 2>/dev/null; then
	printf 'GRUB ist erschienen nach etwa %s Sekunden.\n' "$((i * 2))"
	sleep 2
	if [ "$ENTRY" -gt 0 ]; then
		for _ in $(seq 1 "$ENTRY"); do mon 'sendkey down'; sleep 0.3; done
	fi
	mon 'sendkey ret'
	printf 'Eintrag %s ausgewaehlt.\n' "$ENTRY"
else
	printf 'FEHLER: GRUB ist nicht erschienen.\n' >&2
fi

END=$(( $(date +%s) + MINUTES * 60 ))
SHOT=0
while [ "$(date +%s)" -lt "$END" ]; do
	sleep 20
	kill -0 "$QPID" 2>/dev/null || { printf 'qemu endete von selbst.\n'; break; }
	SHOT=$((SHOT + 1))
	mon "$(printf 'screendump %s/shot-%03d.ppm' "$OUTD" "$SHOT")"
	if grep -q 'MAXIMUS-SELBSTTEST: ENDE' "$OUTD/serial.log" 2>/dev/null; then
		printf 'Der Selbsttest hat sich beendet gemeldet.\n'; break
	fi
done
mon 'quit'; sleep 2; kill "$QPID" 2>/dev/null; wait "$QPID" 2>/dev/null

printf '\n=== Ergebnis ===\n'
printf 'serial.log: %s Byte, %s Abzuege\n' \
	"$(wc -c <"$OUTD/serial.log" 2>/dev/null || echo 0)" \
	"$(ls "$OUTD"/shot-*.ppm 2>/dev/null | wc -l)"
exit 0
