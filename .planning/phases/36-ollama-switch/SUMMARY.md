# Phase 36 Summary

**Lokaler Ollama-Switch für Claude Code** — v1.5 Phase 36 (erste v1.5-Phase, Milestone-Kickoff folgt separat)

## What Shipped

- **`bin/nutze-ollama.sh`** — Sourced Shell-Library mit 3 Funktionen:
  - `nutze-ollama` — Preflight + `eval $(ccr activate)` → ANTHROPIC_BASE_URL im current shell
  - `nutze-claude` — unset aller CCR-env-vars → Cloud-Mode
  - `ollama-status` — zeigt Modus, Ollama-Daemon, CCR-Daemon, Modell-Liste, Aliasing
- **`bin/tom-local`** — Executable Wrapper für Subshell-Spawn (`tom-local`) und One-Shot (`tom-local <cmd>`)
- **Symlink** `~/bin/tom-local` → `/Users/maxim/Claude/bin/tom-local` (Konvention analog tom-ask)
- **`~/.claude-code-router/config.json`** — CCR-Config mit Ollama-Provider und Model-Aliasing:
  - `claude-*-opus-*` → `qwen2.5-coder:latest`
  - `claude-*-haiku-*` (background) → `gemme:latest`
  - Transformer `tooluse` (model-specific) — wirkt aber nicht (siehe Key Decisions)
- **`.planning/phases/36-ollama-switch/ccr-config.reference.json`** — Version-controlled Reference-Copy
- **CLAUDE.md erweitert** — neue Sektion "Lokaler Ollama-Modus für Claude Code (seit v1.5 Phase 36)" mit Kommando-Referenz, Architektur-Diagramm, Known Limitations, Rollback, VSCode-Extension-Koexistenz
- **Dependencies installiert**: `@musistudio/claude-code-router` (npm global, 32k-Stars), `qwen2.5-coder:latest` (4.7 GB Ollama-Modell)
- **VSCode Extension identifiziert**: `warm3snow.vscode-ollama-1.2.1` — reines Chat-Panel, kein File-I/O, kein Privacy-Risiko, dokumentiert in CLAUDE.md

## Requirements Complete

LOCAL-05-01..07 ✓ (7/7) — mit dokumentierter Tool-Use-Degradation

## Key Decisions

- **Chat-Only-Modus statt Full-Agentic** — Recherche-Prediction verifiziert: qwen2.5-coder liefert Tool-Calls als Text-String (`{"name": "list_files", "arguments": {...}}`) statt als Anthropic `tool_use`-Content-Block. Weder globaler noch model-spezifischer CCR-`tooluse`-Transformer fixt das. Claude Code erkennt die Tool-Calls nicht. Der Lokal-Modus ist damit **praktikabel für Chat-Queries, untauglich für Code-Editing/Bash/Multi-Step-Agentic**. Phase landet bewusst als "dokumentierter Chat-Only-Modus" — alle Infrastruktur funktioniert, die Einschränkung steht prominent in CLAUDE.md + `nutze-ollama`-Warning-Echo.
- **Qwen2.5-coder statt Qwen3.5-coder** — `ollama pull qwen3.5-coder` schlägt fehl (`pull model manifest: file does not exist`, existiert nicht in Ollama Library). Fallback auf `qwen2.5-coder:latest` (4.7 GB).
- **`ccr activate` statt hardcoded env-vars** — CCR emittiert die exakten Shell-Exports mit korrektem Port, Auth-Token, Timeout, NO_PROXY. `nutze-ollama` ruft `eval $(ccr activate)` auf, keine Hardcoding, automatisch kompatibel mit CCR-Updates.
- **Model-Aliasing statt Custom-Namen im Picker** — Claude Code `/model`-Picker ist hardcoded auf Anthropic-Namen. Custom-Namen wie "gemme" tauchen nicht auf. Lösung: CCR-Router bildet `opus` → qwen, `background/haiku` → gemme. Maxims ursprünglicher Wunsch "nur Gemma im Picker" ist **nicht erfüllbar** — prominent dokumentiert.
- **Shell-Funktion in ~/.zshrc sourced + Wrapper-Script zusammen** — Ein sourced Lib-File (`nutze-ollama.sh`) definiert Funktionen für current-shell-Flip, `tom-local` nutzt dieselbe Lib für Subshell/One-Shot. Alle drei UX-Varianten aus dem Plan in einem Code-Path, keine Duplikation.
- **VSCode Extension ist reines Chat-Panel, orthogonal zum CLI-Switch** — `warm3snow.vscode-ollama-1.2.1` hat Commands `vscode-ollama.openChat` + `vscode-ollama.settings`, Config `baseUrl` + `model`. Kein File-I/O, keine Vault-Indexierung. Koexistiert konfliktfrei (Port 11434 vs Port 3456). Kein Privacy-Risiko, kein ADR nötig.
- **`~/.zshrc`-Edit pending Maxim-Consent** — Die eine Zeile `[[ -f "$HOME/Claude/bin/nutze-ollama.sh" ]] && source ...` wird erst nach expliziter Bestätigung gesetzt. Bis dahin sind die Funktionen nur nach manuellem `source` verfügbar. `tom-local` funktioniert bereits unabhängig.

## Not Shipped

- **Working Tool-Use im Lokal-Modus** — verifiziert als nicht einsatzbereit, dokumentierte Einschränkung
- **`~/.zshrc`-Source-Line** — pending Maxim-Consent (eine Zeile, guarded, reversibel)
- **Custom Model-Namen im `/model`-Picker** — nicht möglich mit bestehenden Tools
- **MCP-Tools-Integration** — bleibt v1.5-Kandidat (ADR-004, eigene Phase)
- **launchctl-Service für CCR-Daemon** — Daemon startet on-demand via `nutze-ollama`-Preflight, `ccr stop` manuell

## Commit-Plan

Atomic commits für diese Phase:

1. `feat(phase-36-ollama-switch): add PLAN.md + CCR config reference`
2. `feat(phase-36-ollama-switch): add nutze-ollama.sh + tom-local + symlink`
3. `docs(phase-36-ollama-switch): CLAUDE.md Ollama-Modus section`
4. `feat(phase-36-ollama-switch): SUMMARY + VERIFICATION + vault docs`

## Next Up

**v1.5-Kickoff** (separat, nicht in dieser Phase):

- `/gsd:new-milestone` für offiziellen v1.5-Start
- Requirements-Definition für v1.5 (Lifecycle-State-Machine + Plugin-Integrationen + mcp-tools)
- Entscheidung: Sollen `tom-doc`, `tom-wiki`, `tom-ask` via MCP in Claude Code erreichbar werden? (ADR-004-Thema)

**Folge-Arbeiten an Phase 36** (optional):

- Maxim-Consent für `~/.zshrc`-Source-Line
- VSCode Ollama Extension: Model-Setting auf `gemme` pinnen (Maxim-Handoff in VSCode UI)
- Smoke-Test durch Maxim: `nutze-ollama` → `claude` → Chat-Query (nicht Tool-Use!)
