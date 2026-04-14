---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Expansion
status: in_progress
last_updated: "2026-04-14T19:00:00.000Z"
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 0
  completed_plans: 0
---

# State: Tom v1.6

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-14 after v1.6 milestone start)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.6 — Expansion: externe Open-Source-Tools integrieren (RAG, Codex, Autoresearch, Skills, Clicky, audiobridge)

## Current Position

Phase: 47 — Plugins + Raw/Vault-Cleanup (Done)
Plan: `.planning/phases/47-plugins-raw-cleanup/SUMMARY.md`
Status: Done (Security Guidance installiert, claude-mem übersprungen, 122 leere Raw-Ordner bereinigt)

Next: Phase 48 — RAG-Anything Multimodal

**v1.6 Phasen-Übersicht:**

- Phase 47 ✓ Plugins + Raw/Vault-Cleanup (Security Guidance, Raw-Cleanup, Inventar)
- Phase 48 — RAG-Anything Multimodal (HOCH)
- Phase 49 — Codex-Plugin Token-Opt (MITTEL)
- Phase 50 — Autoresearch Eval-Pipeline (MITTEL)
- Phase 51 — OpenSpace Skill-Engine (MITTEL-NIEDRIG)
- Phase 52 — Clicky Lokal-Build (NIEDRIG)
- Phase 53 — audiobridge Transkription (NIEDRIG)

Last activity: 2026-04-14 — Phase 47 Done

## Progress

```text
v1.5: [x] Phase 36  [x] 37  [x] 38  [x] 39  [x] 40  [x] 41a  [x] 41b  [x] 42  [x] 43  [x] 44
       100% (Milestone v1.5 shipped)
v1.6: [x] Phase 47  [ ] 48  [ ] 49  [ ] 50  [ ] 51  [ ] 52  [ ] 53
       14% (1/7 phases)
```

## Accumulated Context (von v1.5 übernommen)

### Architektur-Entscheidungen shipped (bis v1.5)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, MkDocs) und `95_Gehirn/` (privat, NIE publiziert)
- **claude-memory-compiler als externes Tool** in `/Users/maxim/Claude/claude-memory-compiler/`, gepatcht auf `$TOM_VAULT/95_Gehirn/`
- **Hooks projekt-lokal** in `/Users/maxim/Claude/.claude/settings.json`, merged mit globalen GSD+RTK Hooks
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + Artikel, `qwen2.5:3b` synthetisiert lokal. Schwelle: 500 Artikel
- **RAG dritte Collection `gehirn`** additiv in `Gemma/rag/`
- **launchd Daily-Compile-Job** (18:00 Europe/Berlin) via `bin/tom-compile-safe`
- **Volltext-Dokumenten-Fundament**: OCR (`pdftotext` → `ocrmypdf` Fallback), SQLite FTS5, SHA256-Idempotenz unter `archivum/`
- **Primärer lokaler KI-Stack**: Ollama + LangChain + `qwen2.5:3b` mit Embeddings über `BAAI/bge-small-en-v1.5`
- **Lifecycle-State-Machine**: 6 Bereiche, Meta Bind Buttons, Dataview-Dashboards, Auto-Transitions
- **MCP-Bridge**: FastMCP v3 Server mit 5 Read-only-Tools in Cursor
- **Lokaler Claude-Modus**: `nutze-ollama`/`tom-local` für CCR/Ollama-Pfad

### Bestehende Werkzeuge

- `bin/tom-issue` — Maximus_OS Audit-Channel
- `bin/tom-ask` — RAG-Query (Cosine über wiki/clippings/gehirn)
- `bin/tom-wiki` — Karpathy Index-first Wiki-Query
- `bin/tom-compile` / `bin/tom-compile-safe` — Daily Brain-Compile via launchd
- `bin/tom-lint` — Brain-Health-Check (`--structural-only` als launchd-Default)
- `bin/tom-doc` — Volltext-Suche über persönliche Dokumente (SQLite FTS5)
- `bin/tom-clip-enrich` — Clipper-Auto-Enrichment Fallback
- `bin/nutze-ollama.sh` + `bin/tom-local` — Lokaler Claude-Switch via CCR/Ollama
- `bin/tom-doc-intake` — KI-gestützte Dokument-Aufnahme
- `bin/tom-raw-inject` — Raw→Inbox Injection (inkl. Book-Modus)
- `bin/tom-state` — Lifecycle-Migration + Auto-Transition
- `bin/tom-status` — Vault-weite Terminal-Zusammenfassung
- `bin/tom-raw-cleanup` — Leere Raw-Ordner bereinigen (NEU v1.6 Phase 47)

## Deferred → v1.7+

- **LinkedIn-Kontakte → Obsidian** (Phase 45) — Research done, Implementierung deferred
- **Full-Local `tom-compile` als Default** — weiterhin eval-abhängig
- **Fine-Tuning qwen2.5:3b** — passiv Q&A sammeln
- **Vault-in-git Entscheidung** (ADR-002) — bleibt deferred
- **Antwortschreiben-Generation** — lifecycle-abhängig
