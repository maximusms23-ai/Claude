#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Gegenproben zur Nachbereitung
#
# Ergebnis: Der Test prueft zwei Korrekturen ohne virtuelle Maschine.
#   Korrektur 5: Der Medienpfad wird zur Laufzeit bestimmt.
#   Korrektur 6: Im Startparameter bleibt kein Anfuehrungszeichen stehen.
#
# Aufruf: bash pruefe-nachbereitung.sh
P=/home/user/Claude/Obsidian/output/MAXIMUS_T2_NEUINSTALL_V1
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
FEHLER=0

echo "=== Korrektur 5: Medienpfad zur Laufzeit ==="
# Lage wie im Prueflauf: early.sh notierte /root/cdrom, das es nicht gibt.
mkdir -p "$W/self" "$W/cdrom/maximus/packages"
printf '/root/cdrom\n' > "$W/self/medium-pfad"
SELF_DIR="$W/self"
# Dieselbe Logik wie in postinstall.sh
MEDIUM_PATH=''
for d in "$W/cdrom" /run/live/medium /isodevice "$(cat "$SELF_DIR/medium-pfad" 2>/dev/null)"; do
	[ -n "$d" ] || continue
	if [ -d "$d/maximus" ]; then MEDIUM_PATH="$d"; break; fi
done
[ -n "$MEDIUM_PATH" ] || MEDIUM_PATH=/cdrom
printf 'notiert war:  %s\n' "$(cat "$SELF_DIR/medium-pfad")"
printf 'gefunden:     %s\n' "$MEDIUM_PATH"
if [ "$MEDIUM_PATH" = "$W/cdrom" ]; then
	echo "BESTANDEN: der vorhandene Pfad gewinnt, die tote Notiz nicht."
else
	echo "FEHLGESCHLAGEN"; FEHLER=$((FEHLER+1))
fi
# Gegenprobe: ohne vorhandenes Verzeichnis bleibt der Rueckfall
MEDIUM_PATH=''
for d in "$W/gibtsnicht" "$(cat "$SELF_DIR/medium-pfad" 2>/dev/null)"; do
	[ -n "$d" ] || continue
	if [ -d "$d/maximus" ]; then MEDIUM_PATH="$d"; break; fi
done
[ -n "$MEDIUM_PATH" ] || MEDIUM_PATH=/cdrom
printf 'Gegenprobe ohne Treffer: %s\n' "$MEDIUM_PATH"
[ "$MEDIUM_PATH" = "/cdrom" ] && echo "BESTANDEN: Rueckfall auf /cdrom." || { echo "FEHLGESCHLAGEN"; FEHLER=$((FEHLER+1)); }

echo
echo "=== Korrektur 6: Startparameter ohne stehendes Anfuehrungszeichen ==="
mkdir -p "$W/target/etc/default"
GRUBDEF="$W/target/etc/default/grub"
for VARIANTE in 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' "GRUB_CMDLINE_LINUX_DEFAULT='quiet splash'" 'GRUB_CMDLINE_LINUX_DEFAULT=quiet' 'GRUB_CMDLINE_LINUX_DEFAULT=""'; do
	printf 'GRUB_TIMEOUT=5\n%s\n' "$VARIANTE" > "$GRUBDEF"
	CUR="$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT=//p' "$GRUBDEF" | tail -1)"
	CUR="${CUR%\"}"; CUR="${CUR#\"}"; CUR="${CUR%\'}"; CUR="${CUR#\'}"
	NEW="$CUR"
	for opt in pm_async=off intel_iommu=on iommu=pt pcie_ports=native; do
		case " $NEW " in *" $opt "*) ;; *) NEW="$NEW $opt" ;; esac
	done
	NEW="$(printf '%s' "$NEW" | sed 's/^ *//;s/ *$//')"
	printf '%-45s -> [%s]\n' "$VARIANTE" "$NEW"
	case "$NEW" in
		*'"'*|*"'"*) echo "   FEHLGESCHLAGEN: Anfuehrungszeichen im Wert"; FEHLER=$((FEHLER+1)) ;;
		*) : ;;
	esac
done
# Gegenprobe: zweimaliges Anwenden darf nicht verdoppeln
printf 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pm_async=off"\n' > "$GRUBDEF"
CUR="$(sed -n 's/^GRUB_CMDLINE_LINUX_DEFAULT=//p' "$GRUBDEF" | tail -1)"
CUR="${CUR%\"}"; CUR="${CUR#\"}"
NEW="$CUR"
for opt in pm_async=off intel_iommu=on; do
	case " $NEW " in *" $opt "*) ;; *) NEW="$NEW $opt" ;; esac
done
printf 'Gegenprobe doppelt: [%s]\n' "$NEW"
[ "$(printf '%s' "$NEW" | grep -o 'pm_async=off' | wc -l)" -eq 1 ] \
	&& echo "BESTANDEN: kein doppelter Parameter." || { echo "FEHLGESCHLAGEN"; FEHLER=$((FEHLER+1)); }

echo
echo "Fehler gesamt: $FEHLER"
exit "$FEHLER"
