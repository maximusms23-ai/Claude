---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Aktive KI + Dokumenten-Fundament
status: executing
last_updated: "2026-04-10T18:50:00.000Z"
progress:
  total_phases: 6
  completed_phases: 4
  total_plans: 4
  completed_plans: 4
---

# State: Tom v1.4

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** Milestone v1.4 startet — Phase 27 (OCR-Toolkette + Archiv-Fundament)

## Current Position

Phases: 27 ✓, 28 ✓, 29 ✓ (mit Maxim-UI-Handoff für Plugin-Aktivierung), 30 ✓
Next: Phase 31 — Token-Spar-Lokalisierung
Status: Wave 2 done, Phase 31 unabhängig
Last activity: 2026-04-10 — Phase 29 + 30 shipped parallel

## Progress

```
v1.4: [x] Phase 27  [x] Phase 28  [~] Phase 29  [x] Phase 30  [ ] Phase 31  [ ] Phase 32
       67%                                                                              100%
```

Phase 29 hat einen expliziten Maxim-UI-Handoff (Plugin-Aktivierung in Obsidian Settings) der separat verifiziert werden muss nach dem nächsten Obsidian-Start.

## Phase 27 Decisions

- pdftotext-first Extraction mit ocrmypdf-Fallback (150× schneller für moderne PDFs)
- Normale FTS5-Table statt contentless (Snippets brauchen dupliziertes Storage)
- SHA256-basierte Idempotenz (pfad-unabhängig)
- Poppler als zusätzliche Baseline-Dependency

## Accumulated Context (von v1.3 übernommen)

### Architektur-Entscheidungen shipped (bis v1.3)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, MkDocs) und `95_Gehirn/` (privat, NIE publiziert)
- **claude-memory-compiler als externes Tool** in `/Users/maxim/Claude/claude-memory-compiler/`, gepatcht auf `$TOM_VAULT/95_Gehirn/`, Patches in `TOM-PATCHES.md`
- **Hooks projekt-lokal** in `/Users/maxim/Claude/.claude/settings.json`, merged mit globalen GSD+RTK Hooks
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + Artikel, `gemme` synthetisiert lokal. RAG als Fallback. **Schwelle: 500 Artikel** (v1.3-Entscheidung: bleibt unverändert)
- **RAG dritte Collection `gehirn`** additiv in `Gemma/rag/`
- **launchd Daily-Compile-Job** (18:00 Europe/Berlin) via `bin/tom-compile-safe` Preflight-Wrapper
- **tom-wiki Quality-Pass**: Keyword-Filter, TOP_K=5, harter Zitations-Prompt
- **Eval-Baseline v1.3**: `tom-wiki` 60% Avg (80% Wiki-Queries) vs `tom-ask` 33% — Karpathy empirisch bestätigt
- **Anthropic-SDK-Clarification**: bundled-CLI-Pfad nutzt Max-Subscription (TOM-PATCHES.md #8)

### Bestehende Werkzeuge

- `bin/tom-issue`, `bin/tom-ask`, `bin/tom-wiki`, `bin/tom-compile`, `bin/tom-compile-safe`, `bin/tom-lint`

### Ist-Zustand relevant für v1.4 (aus Plan-Exploration 2026-04-10)

- `~/Downloads/Archiv/` existiert mit 15 Kategorien aber **0 Dateien** — Cold-Start
- `$TOM_VAULT/Archiv/` Symlink **fehlt** (CLAUDE.md-Behauptung ist zu fixen in Phase 27)
- `tesseract` + `ocrmypdf` **nicht installiert** — Phase 27
- SQLite 3.51.0 mit FTS5 ✓ vorhanden
- Python `ollama` 0.6.1 ✓ in `Gemma/rag/.venv` + `claude-memory-compiler/.venv`
- Obsidian: nur `obsidian-local-images-plus` Community-Plugin installiert — kein Smart Connections
- Clipping-Frontmatter-Schema: `title / source / author / published / created / description / tags`

## Milestone v1.4 Scope

Phasen 27–32 in `.planning/ROADMAP.md` vollständig beschrieben.

**Fokus:**

1. **Phase 27**: OCR-Toolkette (tesseract + ocrmypdf + deu) + `archivum/` + SQLite FTS5 + erstes echtes PDF indiziert
2. **Phase 28**: `bin/tom-doc` CLI (index/search/list/show) + CLAUDE.md-Integration
3. **Phase 29**: Smart Connections Obsidian-Plugin mit Ollama-Backend + Privacy-Exclude
4. **Phase 30**: `bin/tom-clip-enrich` — Summary + Tags + Konzept-Vorschläge + Wiki-Kategorie
5. **Phase 31**: `tom-compile --local` + Eval-Vergleich + `tom-lint --structural-only` als Default
6. **Phase 32**: Milestone-Close nach v1.3-Checklist (6 Doku-Kanäle)

**Wave-Deps:**
- 27 → 28 (tom-doc braucht SQLite-Schema)
- 29 || 30 parallelisierbar
- 31 unabhängig
- 32 zuletzt

## Open Questions (zu klären in Phasen-Planning)

- **Phase 30**: tom-clip-enrich als Hook in tom-compile-safe oder eigener launchd-Job? (CLIP-08)
- **Phase 29**: Obsidian Copilot nur als Fallback vorbereitet oder parallel installiert?
- **Phase 27**: OCR-Pipeline als Python-Script oder Bash+ocrmypdf-CLI? (Empfehlung: Python)
- **Phase 31**: `tom-lint --no-llm` neu oder existierendes `--structural-only` dokumentieren? (Empfehlung: letzteres)

## Deferred → v1.5+

- **Document-Lifecycle-State-Machine** (Eingang → Antwort → Warte → …) — eigener Milestone, "wir machen es dann zusammen"
- **Antwortschreiben-Generation** — lifecycle-abhängig
- **Auto-Projekt-/Ordner-Routing mit State-Triggern**
- **Inbox-Watcher** (Email-Polling / Scan-Ordner)
- **Full-Local `tom-compile` als Default** — hängt von LOCAL-02 Eval ab
- **Fine-Tuning gemme** — weiterhin passiv Q&A sammeln
- **Handschrift-OCR**, **multimodales gemme**
