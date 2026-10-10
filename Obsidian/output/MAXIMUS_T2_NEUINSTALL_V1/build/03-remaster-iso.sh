#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - ISO umbauen
#
# Ergebnis: Aus dem geprueften Projekt-ISO von t2linux entsteht ein ISO mit
# deutscher Automatisierung. Die Startkette bleibt erhalten.
#
# WICHTIG: Das Original traegt neben MBR und GPT auch eine Apple-Partition-Map.
# Nur die APM macht das Medium im Mac-Startmanager sichtbar.
# 'xorriso -boot_image any replay' kann die APM NICHT erzeugen. Gemessen:
#   "xorriso : SORRY : Cannot make proposal to produce APM of loaded image"
# Deshalb baut dieses Skript das ISO mit genau der Aufrufzeile des Projekts
# neu auf, einschliesslich -isohybrid-apm-hfsplus.
#
# Aufruf: bash 03-remaster-iso.sh --base ISO --overlay DIR --out ISO [--keep-work]

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE=''; OVERLAY=''; OUT=''; KEEP=0
WORK=''

while [ "$#" -gt 0 ]; do
	case "$1" in
		--base)      BASE="${2:?Pfad fehlt}"; shift ;;
		--overlay)   OVERLAY="${2:?Pfad fehlt}"; shift ;;
		--out)       OUT="${2:?Pfad fehlt}"; shift ;;
		--work)      WORK="${2:?Pfad fehlt}"; shift ;;
		--keep-work) KEEP=1 ;;
		-h|--help)   sed -n '2,18p' "$0"; exit 0 ;;
		*) printf 'FEHLER: Unbekannte Option %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

[ -n "$BASE" ] && [ -f "$BASE" ]    || { printf 'FEHLER: --base fehlt oder ist keine Datei.\n' >&2; exit 2; }
[ -n "$OVERLAY" ] && [ -d "$OVERLAY" ] || { printf 'FEHLER: --overlay fehlt oder ist kein Verzeichnis.\n' >&2; exit 2; }
[ -n "$OUT" ]                       || { printf 'FEHLER: --out fehlt.\n' >&2; exit 2; }

for t in xorriso grub-mkstandalone mkfs.vfat mmd mcopy md5sum sha256sum; do
	command -v "$t" >/dev/null 2>&1 || { printf 'FEHLER: Das Programm %s fehlt.\n' "$t" >&2; exit 6; }
done
[ -f /usr/lib/grub/i386-pc/boot_hybrid.img ] || { printf 'FEHLER: grub-pc-bin fehlt.\n' >&2; exit 6; }
[ -f "$SELF_DIR/isohdpfx.bin" ] || { printf 'FEHLER: build/isohdpfx.bin fehlt.\n' >&2; exit 6; }
[ -f "$SELF_DIR/grub/grub.cfg" ] || { printf 'FEHLER: build/grub/grub.cfg fehlt.\n' >&2; exit 6; }

[ -n "$WORK" ] || WORK="$(mktemp -d -t maximus-remaster-XXXXXX)"
IMG="$WORK/image"
cleanup() { [ "$KEEP" -eq 1 ] || rm -rf "$WORK"; }
trap cleanup EXIT

step() { printf '\n=== %s ===\n' "$1"; }

step "1. Grundabbild pruefen"
printf 'Datei:  %s\n' "$BASE"
printf 'Groesse: %s Byte\n' "$(stat -c%s "$BASE")"
BASE_SHA="$(sha256sum "$BASE" | cut -d' ' -f1)"
printf 'SHA256: %s\n' "$BASE_SHA"
if [ -f "$BASE.sha256-erwartet" ]; then
	WANT="$(cut -d' ' -f1 < "$BASE.sha256-erwartet")"
	if [ "$WANT" = "$BASE_SHA" ]; then
		printf 'Pruefsumme stimmt mit der Erwartung ueberein.\n'
	else
		printf 'FEHLER: Die Pruefsumme weicht ab.\nerwartet: %s\ngemessen: %s\n' "$WANT" "$BASE_SHA" >&2
		exit 13
	fi
fi
printf 'Bootsaetze im Original:\n'
xorriso -indev "$BASE" -report_system_area plain 2>/dev/null \
	| grep -E 'System area summary|APM partition' | sed 's/^/  /'
if ! xorriso -indev "$BASE" -report_system_area plain 2>/dev/null | grep -q 'APM partition name'; then
	printf 'WARNUNG: Das Original traegt keine Apple-Partition-Map.\n' >&2
fi

step "2. Abbild auspacken"
rm -rf "$IMG"; mkdir -p "$IMG"
xorriso -osirrox on:auto_chmod_on -indev "$BASE" -extract / "$IMG" 2>&1 \
	| grep -viE 'UPDATE|^xorriso : NOTE|^libisofs' | tail -3
chmod -R u+w "$IMG"
printf 'Ausgepackt: %s Dateien, %s\n' \
	"$(find "$IMG" -type f | wc -l)" "$(du -sh "$IMG" | cut -f1)"
for must in casper/vmlinuz casper/initrd casper/filesystem.squashfs isolinux/grub.cfg; do
	[ -e "$IMG/$must" ] || { printf 'FEHLER: %s fehlt im ausgepackten Abbild.\n' "$must" >&2; exit 4; }
done
printf 'Alle erwarteten Bestandteile sind vorhanden.\n'

step "3. Eigene Dateien einlegen"
mkdir -p "$IMG/preseed" "$IMG/maximus"
cp -a "$OVERLAY/preseed/." "$IMG/preseed/"
cp -a "$OVERLAY/maximus/." "$IMG/maximus/"
# exFAT und ISO9660 tragen kein Ausfuehrungsbit. Alles wird mit bash gerufen.
find "$IMG/maximus" -name '*.sh' -exec chmod 0644 {} +
printf 'Preseed-Dateien: %s\n' "$(ls "$IMG/preseed" | tr '\n' ' ')"
printf 'maximus/: %s Dateien, %s\n' \
	"$(find "$IMG/maximus" -type f | wc -l)" "$(du -sh "$IMG/maximus" | cut -f1)"

step "4. Startmenue ersetzen"
cp "$SELF_DIR/grub/grub.cfg" "$IMG/isolinux/grub.cfg"
printf 'Eintraege im Menue: %s\n' "$(grep -c '^menuentry' "$IMG/isolinux/grub.cfg")"
printf 'Vorgabeeintrag: %s\n' "$(grep 'set default' "$IMG/isolinux/grub.cfg")"
grep -q 'maximus.install=1' "$IMG/isolinux/grub.cfg" \
	|| { printf 'FEHLER: Der Installationseintrag fehlt.\n' >&2; exit 4; }
grep -q 'set default="0"' "$IMG/isolinux/grub.cfg" \
	|| { printf 'FEHLER: Der Vorgabeeintrag ist nicht das Live-System.\n' >&2; exit 4; }

step "5. EFI-Startabbild neu erzeugen"
# Genau wie 03_prepare_iso.sh des Projekts.
grub-mkstandalone --format=x86_64-efi --output="$IMG/isolinux/BOOTx64.EFI" \
	--locales="" --fonts="" "boot/grub/grub.cfg=$IMG/isolinux/grub.cfg"
(
	cd "$IMG/isolinux"
	rm -f efiboot.img
	dd if=/dev/zero of=efiboot.img bs=1M count=10 status=none
	mkfs.vfat -n MAXIMUSEFI efiboot.img >/dev/null
	LC_CTYPE=C mmd -i efiboot.img EFI EFI/BOOT
	LC_CTYPE=C mcopy -i efiboot.img ./BOOTx64.EFI ::EFI/BOOT/
)
printf 'BOOTx64.EFI: %s Byte\n' "$(stat -c%s "$IMG/isolinux/BOOTx64.EFI")"
printf 'efiboot.img: %s Byte\n' "$(stat -c%s "$IMG/isolinux/efiboot.img")"
# Gegenprobe: Liegt der Starter wirklich im FAT-Abbild?
if LC_CTYPE=C mdir -i "$IMG/isolinux/efiboot.img" ::EFI/BOOT 2>/dev/null | grep -qi 'BOOTX64'; then
	printf 'Gegenprobe: BOOTX64.EFI liegt in EFI/BOOT des FAT-Abbilds.\n'
else
	printf 'FEHLER: BOOTX64.EFI liegt nicht im FAT-Abbild.\n' >&2; exit 4
fi

step "6. BIOS-Startabbild neu erzeugen"
grub-mkstandalone --format=i386-pc --output="$IMG/isolinux/core.img" \
	--install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
	--modules="linux16 linux normal iso9660 biosdisk search" \
	--locales="" --fonts="" "boot/grub/grub.cfg=$IMG/isolinux/grub.cfg"
cat /usr/lib/grub/i386-pc/cdboot.img "$IMG/isolinux/core.img" > "$IMG/isolinux/bios.img"
printf 'bios.img: %s Byte\n' "$(stat -c%s "$IMG/isolinux/bios.img")"
# Die Startabbilder liegen im ISO unter /boot/grub bzw. /EFI.
mkdir -p "$IMG/boot/grub" "$IMG/EFI"
cp "$IMG/isolinux/bios.img" "$IMG/boot/grub/bios.img"
cp "$IMG/isolinux/efiboot.img" "$IMG/EFI/efiboot.img"

step "7. md5sum.txt neu bilden"
# Ohne diesen Schritt meldet die Datentraegerpruefung Abweichungen.
(
	cd "$IMG"
	rm -f md5sum.txt
	find . -type f ! -name md5sum.txt ! -path './isolinux/*' -print0 \
		| xargs -0 md5sum > md5sum.txt
)
printf 'md5sum.txt: %s Einträge\n' "$(grep -c . "$IMG/md5sum.txt")"

step "8. ISO schreiben"
rm -f "$OUT"
xorriso -as mkisofs \
	-iso-level 3 \
	-full-iso9660-filenames \
	-volid "MAXIMUS_T2" \
	-b boot/grub/bios.img \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-c boot/grub/boot.cat \
	--grub2-boot-info \
	--grub2-mbr "/usr/lib/grub/i386-pc/boot_hybrid.img" \
	-eltorito-alt-boot \
	-e "EFI/efiboot.img" \
	-no-emul-boot \
	-isohybrid-mbr "$SELF_DIR/isohdpfx.bin" \
	-isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
	-output "$OUT" \
	-graft-points "$IMG" \
	/boot/grub/bios.img="$IMG/isolinux/bios.img" \
	/EFI/efiboot.img="$IMG/isolinux/efiboot.img" 2>&1 \
	| grep -viE 'UPDATE|^xorriso : NOTE' | tail -5

step "9. Ergebnis pruefen"
[ -f "$OUT" ] || { printf 'FEHLER: %s entstand nicht.\n' "$OUT" >&2; exit 4; }
printf 'Datei:   %s\n' "$OUT"
printf 'Groesse: %s Byte\n' "$(stat -c%s "$OUT")"
OUT_SHA="$(sha256sum "$OUT" | cut -d' ' -f1)"
printf 'SHA256:  %s\n' "$OUT_SHA"
printf '%s  %s\n' "$OUT_SHA" "$(basename "$OUT")" > "$OUT.sha256"

printf '\nStartkette des Ergebnisses:\n'
xorriso -indev "$OUT" -report_el_torito plain -report_system_area plain 2>/dev/null \
	| grep -E 'El Torito boot img|El Torito img path|System area summary|APM partition|GPT partition name' \
	| sed 's/^/  /'

FEHLER=0
if xorriso -indev "$OUT" -report_system_area plain 2>/dev/null | grep -q 'APM partition name'; then
	printf '\nOK: Die Apple-Partition-Map ist vorhanden.\n'
else
	printf '\nFEHLER: Die Apple-Partition-Map FEHLT. Der Mac-Startmanager zeigt das Medium dann moeglicherweise nicht.\n' >&2
	FEHLER=$((FEHLER + 1))
fi
for t in 'BIOS' 'UEFI'; do
	if xorriso -indev "$OUT" -report_el_torito plain 2>/dev/null | grep -q "  $t  "; then
		printf 'OK: El-Torito-Eintrag fuer %s vorhanden.\n' "$t"
	else
		printf 'FEHLER: El-Torito-Eintrag fuer %s fehlt.\n' "$t" >&2
		FEHLER=$((FEHLER + 1))
	fi
done
for f in /preseed/maximus-de.seed /maximus/wizard.sh /maximus/early.sh /isolinux/grub.cfg; do
	if xorriso -indev "$OUT" -lsl "$f" >/dev/null 2>&1; then
		printf 'OK: %s liegt im ISO.\n' "$f"
	else
		printf 'FEHLER: %s fehlt im ISO.\n' "$f" >&2
		FEHLER=$((FEHLER + 1))
	fi
done

if [ "$FEHLER" -gt 0 ]; then
	printf '\nDas ISO hat %s Fehler. Es ist NICHT freigegeben.\n' "$FEHLER" >&2
	exit 4
fi
printf '\nDas ISO ist gebaut und formal geprueft.\n'
printf 'Der Starttest steht getrennt aus: tests/boot-efi.sh\n'
exit 0
