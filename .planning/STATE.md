# State: Tom v1.1

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** Milestone v1.1 — Maximus_OS Integration + Ollama Gemma Revival

## Current Position

- **Milestone:** v1.1 — Maximus_OS Integration + Ollama Gemma Revival
- **Phase:** Not started (defining requirements)
- **Plan:** —
- **Status:** Defining requirements
- **Last activity:** 2026-04-10 — Milestone v1.1 started

## Accumulated Context

### Architektur-Entscheidungen v1.1 (user-confirmed)

- **Vault-Cleanup Option A**: iCloud-Vault (`/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw/`) wird Single Source of Truth, lokales Duplikat wird aus Git und Dateisystem entfernt. Backup via iCloud + Time Machine.
- **Maximus_OS Hybrid-Modell**: Tom macht interaktive Arbeit direkt (< 5 Min), Maximus_OS bekommt Issues für Milestones, Audit-Trail, Background-Tasks, Handoffs an spezialisierte Agents. Company-ID `2ff8e79a-c0f8-4966-aaba-13b9ea06cc03`.
- **Ollama Pfad**: `/Users/maxim/Ollama` via `OLLAMA_MODELS` Env-Var, persistent in `~/.zshrc`.
- **Base-Model**: `gemma2:9b` (ca. 5.4 GB). Custom model `gemme` via `Gemma/modelfile/Modelfile`.
- **Kein echtes Fine-Tuning in v1.1**: Self-Instruct-Datensammlung aus `90_Wiki/` → späteres externes FT (MLX-LM/Unsloth) in v1.2+.
- **Dual-Nutzung**: Tom (Claude Code) + Maximus_OS-Agent "Tom" nutzen beide `ollama run gemme` mit derselben RAG-Quelle.

### Personen in Maxims Leben (unverändert)

- **Familie**: Maxim, Olga, Karina, Elina Schmidt
- **Eltern**: Waldemar, Nina Schmidt (Betreuung durch Maxim)

### v1.0 Bestand (referenziert)

- Vault-Gerüst 00–99 exists (Phase 2)
- 6 Personen-Seiten + Archiv-Symlink + mkdocs-Scope (Phases 3–5)
- Templates + Workflows WF-01..05 (Phases 5, 7)
- Tom-Identität in CLAUDE.md / AGENTS.md (Phase 1)
- Commit: `525c073`

### Neue Tools v1.1

- `bin/tom-issue` — Wrapper um `paperclipai issue create` (Maximus_OS-Kommunikation)
- `bin/tom-ask` — Wrapper um `Gemma/rag/query.py` (lokales RAG-Query)

## Open Questions

Keine Blocker. Nicht-Blocker:
- Ollama Server Management: manuell vs. `brew services` — Default manuell
- Fine-Tuning explizit nicht in v1.1
