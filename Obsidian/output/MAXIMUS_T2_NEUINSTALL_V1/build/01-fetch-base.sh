#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Projekt-ISO holen und pruefen
#
# Ergebnis: Das Abbild des Projekts t2linux liegt geprueft im Bauverzeichnis.
#
# Das Projekt teilt das Abbild in vier Teile auf, weil ein Anhang bei GitHub
# hoechstens 2 GB gross sein darf. Dieses Skript setzt sie zusammen und
# prueft die Pruefsumme gegen die Liste des Projekts.
#
# Aufruf: bash 01-fetch-base.sh [--tag v7.1.8-1] [--out DIR]

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="v7.1.8-1"
OUT="$SELF_DIR/base"
while [ "$#" -gt 0 ]; do
	case "$1" in
		--tag) TAG="${2:?}"; shift ;;
		--out) OUT="${2:?}"; shift ;;
		-h|--help) sed -n '2,12p' "$0"; exit 0 ;;
		*) printf 'FEHLER: Unbekannte Option %s\n' "$1" >&2; exit 2 ;;
	esac
	shift
done

KVER="${TAG#v}"; KVER="${KVER%-*}"
ISO="ubuntu-24.04-${KVER}-t2-noble.iso"
BASEURL="https://github.com/t2linux/T2-Ubuntu/releases/download/${TAG}"

command -v curl >/dev/null 2>&1 || { printf 'FEHLER: curl fehlt.\n' >&2; exit 6; }
mkdir -p "$OUT"
cd "$OUT"

printf '=== 1. Pruefsummenliste des Projekts holen ===\n'
curl -sSL --retry 3 --max-time 120 -o sha256-ubuntu-24.04 "$BASEURL/sha256-ubuntu-24.04"
SOLL="$(cut -d' ' -f1 < sha256-ubuntu-24.04)"
printf 'Projekt nennt: %s\n' "$SOLL"
[ -n "$SOLL" ] || { printf 'FEHLER: Die Liste ist leer.\n' >&2; exit 13; }

if [ -f "$ISO" ]; then
	IST="$(sha256sum "$ISO" | cut -d' ' -f1)"
	if [ "$SOLL" = "$IST" ]; then
		printf 'Das Abbild liegt schon vor und stimmt.\n'
		printf '%s  %s\n' "$SOLL" "$ISO" > "$ISO.sha256-erwartet"
		exit 0
	fi
	printf 'Das vorhandene Abbild weicht ab. Es wird neu geladen.\n'
	rm -f "$ISO"
fi

printf '\n=== 2. Die vier Teile laden ===\n'
for p in 00 01 02 03; do
	printf 'Teil %s ... ' "$p"
	curl -sSL --retry 3 --max-time 1800 "$BASEURL/$ISO.$p" >> "$ISO" \
		|| { printf 'FEHLER\n' >&2; exit 14; }
	printf '%s Byte gesamt\n' "$(stat -c%s "$ISO")"
done

printf '\n=== 3. Pruefsumme vergleichen ===\n'
IST="$(sha256sum "$ISO" | cut -d' ' -f1)"
printf 'erwartet: %s\n' "$SOLL"
printf 'gemessen: %s\n' "$IST"
if [ "$SOLL" != "$IST" ]; then
	printf 'FEHLER: Die Pruefsumme stimmt nicht. Das Abbild wird geloescht.\n' >&2
	rm -f "$ISO"
	exit 13
fi
printf 'Die Pruefsumme stimmt.\n'
printf '%s  %s\n' "$SOLL" "$ISO" > "$ISO.sha256-erwartet"

printf '\n=== 4. Startkette des Abbilds ===\n'
if command -v xorriso >/dev/null 2>&1; then
	xorriso -indev "$ISO" -report_system_area plain 2>/dev/null \
		| grep -E 'System area summary|APM partition' | sed 's/^/  /'
fi
printf '\nDas Abbild liegt bereit: %s/%s\n' "$OUT" "$ISO"
