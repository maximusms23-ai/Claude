#!/usr/bin/env bash
# MAXIMUS_T2_INSTALLER V4.2 - Fallverzeichnis erzeugen
#
# Ergebnis: Das Skript schreibt reports/TESTFALL_INVENTAR.md.
# Jede Zeile nennt Kennung, Gruppe, Bezeichnung und die Quellzeile.
# Damit ist jeder Testfall im Quelltext nachweisbar.
#
# Aufruf: bash scripts/make-inventory.sh [--check]
#   --check  Prueft nur. Es wird keine Datei geschrieben.
#
# Rufe das Skript mit 'bash' auf. Auf exFAT fehlt das Ausfuehrungsbit.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SELF_DIR/.." && pwd)"
SRC="$SELF_DIR/regression.sh"
OUT="$ROOT/reports/TESTFALL_INVENTAR.md"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

# Gruppenzeilen und Fallzeilen mit Zeilennummer einlesen.
# Die Gruppe R17 fuehrt die Schlussrechnung. Sie zaehlt nicht mit.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

awk '
	/^group "/ {
		line = $0
		sub(/^group "/, "", line); sub(/".*$/, "", line)
		grp = line
		next
	}
	/^[[:space:]]*record "R[0-9]+\.[0-9]+[a-z]?/ {
		label = $0
		sub(/^[[:space:]]*record "/, "", label)
		sub(/".*$/, "", label)
		split(label, parts, " ")
		id = parts[1]
		if (id in seen) next
		seen[id] = 1
		name = label
		sub(/^[^ ]+ /, "", name)
		printf "%s\t%s\t%s\t%d\n", id, grp, name, NR
	}
' "$SRC" | grep -v '^R17\.' > "$TMP/cases.tsv"

COUNT="$(grep -c . "$TMP/cases.tsv")"
N_GROUPS="$(cut -f2 "$TMP/cases.tsv" | sort -u | grep -c .)"

if [ "$CHECK" -eq 1 ]; then
	printf 'Faelle: %s\nGruppen: %s\nQuelle: %s\n' "$COUNT" "$N_GROUPS" "$SRC"
	exit 0
fi

{
	printf -- '---\n'
	printf 'title: Testfall-Inventar\n'
	printf 'created: %s\n' "$(date -u +%Y-%m-%d)"
	printf 'type: bericht\n'
	printf 'tags: [maximus, t2linux, tests]\n'
	printf -- '---\n\n'
	printf '# Testfall-Inventar\n\n'
	# shellcheck disable=SC2016  # Die Zeichen sind Markdown, keine Expansion.
	printf 'Erzeugt aus `scripts/regression.sh` von `scripts/make-inventory.sh`.\n'
	printf 'Diese Datei wird nicht von Hand gepflegt.\n\n'
	printf 'Faelle: **%s**. Gruppen: **%s**.\n\n' "$COUNT" "$N_GROUPS"
	printf 'Die Gruppe R17 fuehrt die Schlussrechnung. Sie zaehlt nicht mit.\n'
	printf 'Jeder Lauf vergleicht dieses Verzeichnis mit den Rohdaten.\n'
	printf 'Ein Fall ohne Ergebnis laesst den Lauf fehlschlagen.\n\n'
	printf '## Faelle je Gruppe\n\n'
	printf '| Gruppe | Faelle |\n| --- | --- |\n'
	cut -f2 "$TMP/cases.tsv" | sort | uniq -c \
		| sed 's/^[[:space:]]*//' | sort -k2 -V \
		| while read -r n grp; do printf '| %s | %s |\n' "$grp" "$n"; done
	printf '\n## Vollstaendige Liste\n\n'
	printf '| Kennung | Bezeichnung | Quelle |\n| --- | --- | --- |\n'
	while IFS="$(printf '\t')" read -r id grp name line; do
	# shellcheck disable=SC2016  # Die Zeichen sind Markdown, keine Expansion.
		printf '| `%s` | %s | `scripts/regression.sh:%s` |\n' \
			"$id" "${name//|/\\|}" "$line"
	done < "$TMP/cases.tsv"
} > "$OUT"

printf 'geschrieben: %s (%s Faelle, %s Gruppen)\n' "$OUT" "$COUNT" "$N_GROUPS"
