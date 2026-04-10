# State: Tom v1.2

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.2 abgeschlossen — bereit für nächsten Milestone (v1.3 oder Pause)

## Current Position

- **Milestone:** v1.2 — Karpathy Wiki + claude-memory-compiler ✓ Complete
- **Phase:** Alle 8 Phasen (14–21) abgeschlossen
- **Plan:** —
- **Status:** v1.2 shipped — bereit für v1.3 Planning
- **Last activity:** 2026-04-10 — Milestone v1.2 abgeschlossen

## Progress

```
Phase:  [14][15][16][17][18][19][20][21]
Status: [ ✓ ][ ✓ ][ ✓ ][ ✓ ][ ✓ ][ ✓ ][ ✓ ][ ✓ ]
```

## Accumulated Context (v1.2)

### Architektur-Entscheidungen v1.2 (shipped)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, external data, MkDocs publiziert) und `95_Gehirn/` (privat, internal data, NIE publiziert). Physische Trennung + `docs_dir: 90_Wiki` in mkdocs.yml verhindert Accident-Publishing.
- **claude-memory-compiler als externes Tool**: Clone in `/Users/maxim/Claude/claude-memory-compiler/`, `scripts/config.py` + 3 Hook-Files gepatcht damit Pfade auf `$TOM_VAULT/95_Gehirn/` zeigen. `state.json` bleibt im Tool-Repo (git-trackable). Patches dokumentiert in `TOM-PATCHES.md`.
- **Hooks projekt-lokal**: `/Users/maxim/Claude/.claude/settings.json` mit SessionStart/End/PreCompact. Merged mit globalen GSD+RTK Hooks — beide bleiben aktiv. SessionEnd ist detached via Popen.
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + alle Artikel und lässt `gemme` lokal synthetisieren. RAG (`tom-ask`) bleibt als Fallback für fuzzy Queries. Bei > 500 Artikeln Umstieg auf RAG-Primary → v1.3+.
- **RAG dritte Collection**: `Gemma/rag/` additiv um `gehirn` erweitert (`config.py` + `index.py` + `query.py`). Nur kompilierte Artikel aus `95_Gehirn/knowledge/`, nicht rohe daily-logs.
- **Multi-Projekt via `wiki_path`**: Konvention in `claude-memory-compiler/docs/multi-project.md`, erstes Demo-Projekt: `Gemma/CLAUDE.md` mit Wissens-Kaskade-Sektion.
- **Lokale Ollama statt Claude Agent SDK für tom-wiki**: Spart Subscription-Quota, ist kostenlos + offline. `tom_tools/wiki_query.py` als neues Modul im compiler-Repo.

### Audit-Trail

FAM-119 (Phase 14), FAM-120 (15), FAM-121 (16), FAM-122 (17), FAM-123 (18), FAM-124 (19), FAM-125 (20), FAM-126 (21 CEO-Close).

### Neue Werkzeuge ab v1.2

- `bin/tom-wiki [--brain] "Frage"` — Karpathy Index-first über lokalen gemme
- `bin/tom-compile` — Wrapper um compile.py (Claude Agent SDK, subscription-covered)
- `bin/tom-lint [--structural-only]` — Brain-Struktur-Health-Check
- Alle in `~/bin/` symlinked

### v1.1 Bestand (referenziert, unverändert)

- iCloud-Vault als Single Source of Truth
- `bin/tom-issue`, `bin/tom-ask`
- Ollama + `gemme` + ChromaDB-RAG
- Maximus_OS Hybrid-Kommunikation

## Open Questions (für v1.3+)

- Fine-Tuning (MLX-LM oder Unsloth) — deferred aus v1.2, Q&A-Pairs wachsen weiter
- Skalierungs-Schwelle Karpathy → RAG-Primary (ab > 500 Artikeln)
- Compile-Trigger-Automatisierung (Cron oder git-hook statt manuell)
- Maximus_OS-Tom-Agent in error-State — Tracking via FAM-112
