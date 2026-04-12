# Stream Deck — Brain Ops & Tom (macOS)

Dieses Verzeichnis enthält **`.command`-Skripte** (AppleScript + Bash), die aus der **Elgato Stream Deck**-Software heraus per „Open / Shell“ angebunden werden können. Sie ersetzen kein exportiertes Elgato-Profil, sind aber die **versionierte Quelle** für die dokumentierten „Seite 10 / Brain Ops“-Aktionen.

## Brain Ops (Auszug)

| Skript | Zweck |
|--------|--------|
| `brain-lint-claude.command` … `brain-lint-apple.command` | `tom-brain-lint --backend …` |
| `brain-lint-status.command` | Neuesten Report anzeigen |
| `brain-book-local.command` / `brain-book-web.command` | `tom-raw-inject` Buch-Modus |
| `model-ollama-qwen.command` / `model-ollama-gemme.command` | Ollama-Modellbezug |
| `openclaw-*.command` | OpenClaw-Diagnose/TUI |

Gemeinsame Variablen: [`_common.sh`](_common.sh) (`TOM_VAULT`, `TOM_PROJECT_ROOT`, …).

## Einrichtung

1. In Stream Deck: Aktion **System → Open** oder **Terminal/Shell** mit Pfad zu einer `.command`-Datei.
2. Erstausführung: macOS kann Gatekeeper-Warnung zeigen → „Im Finder öffnen“ → einmalig erlauben.

## Siehe auch

- [`CLAUDE.md`](../../CLAUDE.md) — Rolle Tom, Ollama, Paperclip
- [`.planning/codebase/INTEGRATIONS.md`](../../.planning/codebase/INTEGRATIONS.md)
