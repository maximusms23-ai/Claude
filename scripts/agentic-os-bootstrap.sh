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
# Das Gedaechtnis selbst bleibt im Repo (siehe "Obsidian/Agentic OS/AI Memory
# Protocol.md"): Cloud-Container sind ephemer, nur git ueberlebt den Wechsel.
# Hier entstehen nur Verweise, keine Kopien — damit es keine zweite Wahrheit gibt.
#
# Aufruf (aus dem Repo heraus):
#   ./scripts/agentic-os-bootstrap.sh              # Projekt "claude-default"
#   ./scripts/agentic-os-bootstrap.sh mein-projekt # eigener Projektname
#
# Idempotent: mehrfaches Ausfuehren ist unschaedlich. Vorhandene echte Dateien
# werden nie ueberschrieben, nur Symlinks aktualisiert.

set -euo pipefail

project="${1:-claude-default}"

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
