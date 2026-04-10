# State: Tom v1.2

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** Milestone v1.2 — Karpathy Wiki + claude-memory-compiler

## Current Position

- **Milestone:** v1.2 — Karpathy Wiki + claude-memory-compiler
- **Phase:** Not started (defining requirements)
- **Plan:** —
- **Status:** Defining requirements
- **Last activity:** 2026-04-10 — Milestone v1.2 started

## Progress

```
Phase:  [14][15][16][17][18][19][20][21]
Status: [ ○ ][ ○ ][ ○ ][ ○ ][ ○ ][ ○ ][ ○ ][ ○ ]
```

## Accumulated Context

### v1.2 Architektur-Entscheidungen (aus User-Plan)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, external data, MkDocs) und neuer `95_Gehirn/` (privat, internal data, NIE publiziert). Physische Trennung verhindert Accident-Publishing.
- **claude-memory-compiler** als externes Tool: Clone in `/Users/maxim/Claude/claude-memory-compiler/`, `scripts/config.py` patchen damit Pfade auf `$TOM_VAULT/95_Gehirn/` zeigen. `state.json` bleibt im Tool-Repo.
- **Hooks projekt-lokal**: `/Users/maxim/Claude/.claude/settings.json` mit SessionStart/SessionEnd/PreCompact Hooks. Merged mit globalen GSD+RTK Hooks, brechen diese nicht. SessionEnd detached (Popen) gegen Hook-Timeout.
- **Karpathy Index-first**: Bei bekannten Themen `tom-wiki` (index.md → direkte Reads, keine Embeddings). RAG (`tom-ask`) bleibt als Fallback für fuzzy Queries. Bei 20–500 Artikeln ist Index-first präziser als Cosine-Similarity.
- **RAG Hybrid**: Gemma-RAG bekommt dritte Collection `gehirn` (nur kompilierte Artikel aus `95_Gehirn/knowledge/`, NICHT rohe daily-logs).
- **Multi-Projekt via `wiki_path`**: Andere Projekte referenzieren `$TOM_VAULT/90_Wiki/` in ihrer eigenen `CLAUDE.md` und können `tom-wiki` nutzen. Alle füttern dasselbe `95_Gehirn/`.
- **Fine-Tuning deferred**: MLX-LM FT aus v1.2 raus, auf v1.3+ verschoben. Q&A-Pairs wachsen weiter.
- **Compile-Kosten**: Memory-Compiler nutzt Claude Agent SDK unter User-Subscription (laut User-Message, im CEO-Briefing zu bestätigen).
- **iCloud-Latenz**: daily-log-Writes laufen in iCloud-Cache, Sync im Hintergrund — Mitigation bei Problemen: lokaler `/Users/maxim/brain/daily/` + Symlink.

### v1.1 Bestand (referenziert)

- iCloud-Vault `$TOM_VAULT` als Single Source of Truth
- Ollama + `gemme` + ChromaDB-RAG über `90_Wiki` + `Clippings`
- `bin/tom-issue`, `bin/tom-ask` als Wrapper-Vorlage für neue Tools
- Maximus_OS Hybrid-Kommunikation via FAM-Issues

### Personen in Maxims Leben (unverändert)

- **Familie**: Maxim, Olga, Karina, Elina Schmidt
- **Eltern**: Waldemar, Nina Schmidt (Betreuung durch Maxim)

## Open Questions

Nicht-Blocker:
- Welches zweite Projekt testet `wiki_path`-Konvention in Phase 20? (Default: Gemma/ als eigenständiges Projekt)
- Compile-Trigger-Zeit: 6 PM Default oder anderen Rhythmus?
- Anthropic-Clarification zum Subscription-Deckungsumfang im CEO-Briefing dokumentieren
