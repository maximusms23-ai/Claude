#!/usr/bin/env bash
#
# Richtet den lokalen Agentic-OS-Arbeitsplatz fuer dieses Repo ein.
#
#   ~/.agentic-os/claude-projects/<projekt>/
#     ├── repo        -> Symlink auf dieses Repo
#     ├── vault       -> Symlink auf den Obsidian-Vault
#     ├── MEMORY.md   -> Symlink auf das versionierte Gedaechtnis im Repo
#     └── README.md     kurze Orientierung
#
# ACHTUNG — DIESES LAYOUT IST GERATEN, NICHT VERIFIZIERT.
#
# Agent OS (/Users/maxim/Projects/Maximus_OS) bringt einen EIGENEN, dokumentierten
# Obsidian-Connector mit: siehe dort `install/11-MEMORY-OBSIDIAN.md`. Der ist der
# richtige Weg, damit der Vault im Dashboard (http://localhost:3737) erscheint.
# Laut dessen README genuegt es, einen Terminal-Agenten IN jenem Ordner zu starten
# und zu sagen: "connect my Obsidian vault to the Agent OS".
#
# Dieses Skript wurde geschrieben, ohne Agent OS gesehen zu haben. Was es in
# ~/.agentic-os/claude-projects/<projekt>/ anlegt, entspricht moeglicherweise
# NICHT dem, was Agent OS dort erwartet — es koennte dessen Dashboard verwirren.
# Deshalb laeuft es nur mit --confirm.
#
# Das Gedaechtnis selbst bleibt im Repo (siehe "Obsidian/Agentic OS/AI Memory
# Protocol.md"): Cloud-Container sind ephemer, nur git ueberlebt den Wechsel.
# Hier entstehen nur Verweise, keine Kopien — damit es keine zweite Wahrheit gibt.
#
# Aufruf (aus dem Repo heraus):
#   ./scripts/agentic-os-bootstrap.sh --confirm                # "claude-default"
#   ./scripts/agentic-os-bootstrap.sh mein-projekt --confirm   # eigener Name
#
# Idempotent: mehrfaches Ausfuehren ist unschaedlich. Vorhandene echte Dateien
# werden nie ueberschrieben, nur Symlinks aktualisiert.

set -euo pipefail

confirm=0
project=""
for arg in "$@"; do
  case "$arg" in
    --confirm) confirm=1 ;;
    -*) echo "Unbekannte Option: $arg" >&2; exit 1 ;;
    *) project="$arg" ;;
  esac
done
project="${project:-claude-default}"

if [ "$confirm" -ne 1 ]; then
  cat >&2 <<'WARNEOF'
Dieses Skript legt ein Verzeichnis-Layout an, das GERATEN ist.

Agent OS bringt einen eigenen Obsidian-Connector mit. Nimm zuerst den:

  1. Terminal-Agenten in /Users/maxim/Projects/Maximus_OS starten
  2. sagen: "connect my Obsidian vault to the Agent OS"
  3. Details stehen dort in install/11-MEMORY-OBSIDIAN.md

Nur wenn das nicht passt und du weisst, dass du dieses Layout willst:

  ./scripts/agentic-os-bootstrap.sh [projektname] --confirm
WARNEOF
  exit 2
fi

case "$project" in
  */*|.|..|"")
    echo "Fehler: ungueltiger Projektname: '$project'" >&2
    exit 1
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vault="$repo_root/Obsidian"
memory="$vault/Agentic OS/MEMORY.md"
base="${AGENTIC_OS_HOME:-$HOME/.agentic-os}/claude-projects"
target="$base/$project"

if [ ! -d "$vault" ]; then
  echo "Fehler: kein Obsidian-Vault unter $vault — laeuft das Skript im richtigen Repo?" >&2
  exit 1
fi

mkdir -p "$target"

# Symlink setzen, ohne je eine echte Datei zu zerstoeren.
link() {
  src="$1"
  dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "  uebersprungen: $dst existiert als echte Datei/Verzeichnis"
    return 0
  fi
  ln -s "$src" "$dst"
  echo "  verlinkt: $(basename "$dst") -> $src"
}

echo "Agentic OS — Projekt '$project'"
echo "Ziel: $target"
echo

link "$repo_root" "$target/repo"
link "$vault" "$target/vault"

if [ -f "$memory" ]; then
  link "$memory" "$target/MEMORY.md"
else
  echo "  Hinweis: $memory fehlt — Gedaechtnis nach der Vorlage im Protokoll anlegen"
fi

if [ ! -e "$target/README.md" ]; then
  cat > "$target/README.md" <<READMEEOF
# Agentic OS — $project

Erzeugt von \`scripts/agentic-os-bootstrap.sh\`. Dieses Verzeichnis haelt nur
Verweise; Inhalte liegen im Repo und damit in git.

- \`repo/\` — das Repo ($repo_root)
- \`vault/\` — der Obsidian-Vault
- \`MEMORY.md\` — Projektgedaechtnis, gepflegt nach \`vault/Agentic OS/AI Memory Protocol.md\`

Agenten und Hooks kommen aus \`repo/.claude/\` und gelten automatisch, wenn
Claude Code im Repo gestartet wird.

Nicht in git und nur lokal vorhanden: \`vault/TODOS.md\`, \`vault/PROJEKTE.md\`.
READMEEOF
  echo "  erstellt: README.md"
fi

echo
echo "Fertig. Naechster Schritt:"
echo "  cd \"$target/repo\" && claude"
echo
echo "Der SessionStart-Hook laedt das Gedaechtnis dann automatisch."
