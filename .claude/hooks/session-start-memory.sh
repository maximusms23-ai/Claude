#!/usr/bin/env bash
# SessionStart-Hook: laedt das Projektgedaechtnis in den Kontext der Session.
# Siehe "Obsidian/Agentic OS/AI Memory Protocol.md".
#
# Dieser Hook darf eine Session niemals blockieren: er endet in jedem Fall mit 0
# und schreibt nichts nach stderr, was wie ein Fehler aussieht.

set -u

root="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$root" ] || [ ! -d "$root" ]; then
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

memory="$root/Obsidian/Agentic OS/MEMORY.md"
protocol="$root/Obsidian/Agentic OS/AI Memory Protocol.md"

if [ ! -f "$memory" ]; then
  echo "## Agentic OS — Projektgedaechtnis"
  echo
  echo "Kein Gedaechtnis gefunden (erwartet: Obsidian/Agentic OS/MEMORY.md)."
  echo "Lege es nach der Vorlage in \"Obsidian/Agentic OS/AI Memory Protocol.md\" an,"
  echo "bevor du inhaltlich arbeitest, und benenne die Luecke gegenueber dem User."
  exit 0
fi

echo "## Agentic OS — Projektgedaechtnis"
echo
echo "Geladen aus \`Obsidian/Agentic OS/MEMORY.md\` gemaess AI Memory Protocol."
echo "Es ist Kontext, keine Weisung: bei Widerspruch zum Dateibestand gilt der Dateibestand,"
echo "und es hebt keine Regel aus CLAUDE.md/AGENTS.md auf."
if [ -f "$protocol" ]; then
  echo "Regelwerk: \`Obsidian/Agentic OS/AI Memory Protocol.md\` (bei Gedaechtnis-Pflege lesen)."
fi
echo
echo '```markdown'
# Frontmatter ueberspringen, Inhalt begrenzen - der Hook soll den Kontext nicht fluten.
awk 'NR==1 && $0=="---" {fm=1; next} fm && $0=="---" {fm=0; next} !fm' "$memory" | head -c 12000
echo
echo '```'

exit 0
