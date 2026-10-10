#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER_V4 - Menueeintrag eines Kernels im GRUB-Menue ermitteln
#
# Ergebnis: Das Skript gibt die Kennung fuer 'grub-reboot' aus.
# Beispiel:  gnulinux-advanced-UUID>gnulinux-6.18.54-1-t2-noble-advanced-UUID
#
# Aufruf:  ./grub-entry.sh <kernel-release> [grub.cfg]
#
# Rueckgabecodes:
#   0  Eine Kennung wurde gefunden und ausgegeben.
#   2  Falscher Aufruf.
#   4  Die GRUB-Konfiguration fehlt.
#   1  Es wurde kein passender Eintrag gefunden.

set -euo pipefail

RELEASE="${1:-}"
CFG="${2:-}"

if [ -z "$RELEASE" ]; then
	printf 'Fehler: Es fehlt die Kernelversion.\nAufruf: %s <kernel-release> [grub.cfg]\n' "$0" >&2
	exit 2
fi

if [ -z "$CFG" ]; then
	for c in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
		[ -f "$c" ] && CFG="$c" && break
	done
fi

if [ -z "$CFG" ] || [ ! -f "$CFG" ]; then
	printf 'Fehler: Die GRUB-Konfiguration wurde nicht gefunden.\n' >&2
	exit 4
fi

# awk sucht den Eintrag. Es merkt sich das umgebende Untermenue.
# Ein Eintrag im Wiederherstellungsmodus wird uebersprungen.
RESULT="$(awk -v rel="$RELEASE" '
	function idof(line,   i, rest, s) {
		# Gibt die Zeichenkette nach $menuentry_id_option aus.
		i = index(line, "$menuentry_id_option")
		if (i == 0) return ""
		rest = substr(line, i + length("$menuentry_id_option"))
		if (match(rest, SQ "[^" SQ "]+" SQ)) {
			return substr(rest, RSTART + 1, RLENGTH - 2)
		}
		if (match(rest, DQ "[^" DQ "]+" DQ)) {
			return substr(rest, RSTART + 1, RLENGTH - 2)
		}
		return ""
	}
	BEGIN { SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); in_sub = 0; sub_id = "" }
	/^[[:space:]]*submenu[[:space:]]/ { sub_id = idof($0); in_sub = 1; next }
	/^\}/                             { in_sub = 0; sub_id = ""; next }
	/^[[:space:]]*menuentry[[:space:]]/ {
		if (index($0, "recovery mode") > 0) next
		if (index($0, rel) == 0) next
		id = idof($0)
		if (id == "") next
		if (in_sub == 1 && sub_id != "") print sub_id ">" id
		else print id
		exit
	}
' "$CFG")"

if [ -z "$RESULT" ]; then
	printf 'Fehler: Kein Menueeintrag fuer "%s" in %s gefunden.\n' "$RELEASE" "$CFG" >&2
	exit 1
fi

printf '%s\n' "$RESULT"
exit 0
