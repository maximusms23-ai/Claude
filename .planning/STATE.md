---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Lifecycle + Integration
status: completed
last_updated: "2026-04-12T20:00:00.000Z"
progress:
  total_phases: 9
  completed_phases: 9
  total_plans: 9
  completed_plans: 9
---

# State: Tom v1.5

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-11 after v1.5 milestone start)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.5 — Lifecycle-State-Machine + MCP-Bridge + lokaler Tool-Use

## Current Position

Phase: 44 — Milestone-Close v1.5 (Done)
Plan: `.planning/phases/44-milestone-close/SUMMARY.md`
Status: Done (CLOSE15-01..07, REQUIREMENTS + ROADMAP + Vault Tom.md/index.md, CEO-Briefing, tom-issue CEO Close)

**v1.5 Phasen-Übersicht:**

- Phase 36 ✓ Lokaler Ollama-Switch (out-of-band shipped 2026-04-11, retroaktiv aufzunehmen)
- Phase 37 ✓ Vault-Hygiene & Cleanup (6 HYG Known Gaps / Maxim-Handoff dokumentiert)
- Phase 38 ✓ Local Tool-Use Modell-Upgrade (qwen2.5:3b native Tool-Use)
- Phase 39 ✓ MCP-Bridge für Tom-CLIs (FastMCP v3, Cursor-Client, 5 Read-only-Tools)
- Phase 40 ✓ Lifecycle Foundation — Dokumente (Meta Bind Buttons, Dataview Dashboard, tom-state)
- Phase 41a ✓ Universelle Lifecycle-Engine (4 Modelle, 22 Buttons, 3 Dashboards)
- Phase 41b ✓ KI-Intake + Triage (tom-doc-intake, 5 Templates, QuickAdd AI, Book-Chunking)
- Phase 42 ✓ Lifecycle — Projekte / Finanzen / Social (3 Dashboards, Cross-Area-Backlinks)
- Phase 43 ✓ Lifecycle Dashboards & Auto-Routing (Heute.md, auto-transition, Verpasst-Handling, KI-Prompts, tom-status)
- Phase 44 ✓ Milestone-Close v1.5 (Doku-Kaskade, CLOSE15, CEO-Briefing, Maximus_OS Audit)

Last activity: 2026-04-12 — Phase 44 Done (v1.5 Milestone geschlossen)

## Progress

```text
v1.4: [x] Phase 27  [x] Phase 28  [x] Phase 29+Hotfix  [x] Phase 30  [x] Phase 31  [x] Phase 32
       100%
v1.4.1: [x] Phase 33  [x] Phase 34  [x] Phase 35 (+Hotfix)
        100%
v1.5: [x] Phase 36  [x] 37  [x] 38  [x] 39  [x] 40  [x] 41a  [x] 41b  [x] 42  [x] 43  [x] 44
       100% (Milestone v1.5 shipped — 6 HYG Known Gaps dokumentiert)
```

## v1.5 Open Handoffs (carryover aus v1.4 / v1.4.1)

Diese werden in Phase 37 (Vault-Hygiene) gebündelt geschlossen:

- **CLIP141-04** (Phase 35): Web-Clipper-Smoke-Test mit echtem Browser-Clip
- **CLIP141-13** (Phase 35-Hotfix): Interpreter-Smoke-Test, blockiert durch Ollama-Models-Path-Defekt
- **OBPL-03** (Phase 29): Smart Connections "TurboQuant" Smoke-Test nach UI-Reconfig
- **Plugin-Audit Q1–Q5** (`plugin-audit-v1.4.1.md`): eml-reader / apple-reminders Setup-Entscheidungen

## Phase 36 Decisions (out-of-band, 2026-04-11)

- Lokaler Claude-Pfad nutzt den dokumentierten **CCR-/Qwen-/Gemma-Prototyp** aus Phase 36
- `nutze-ollama` und `ollama-status` bleiben als historische Kompatibilitaetsnamen bestehen
- Model-Aliasing statt Custom-Namen im `/model`-Picker (Anthropic-Namen sind hardcoded in Claude Code)
- Separater Tom-/Gemme-Stack bleibt absichtlich unberuehrt

## Accumulated Context (von v1.4/v1.4.1 übernommen)

### Architektur-Entscheidungen shipped (bis v1.4.1)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, MkDocs) und `95_Gehirn/` (privat, NIE publiziert)
- **claude-memory-compiler als externes Tool** in `/Users/maxim/Claude/claude-memory-compiler/`, gepatcht auf `$TOM_VAULT/95_Gehirn/`
- **Hooks projekt-lokal** in `/Users/maxim/Claude/.claude/settings.json`, merged mit globalen GSD+RTK Hooks
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + Artikel, `qwen2.5:3b` synthetisiert lokal. Schwelle: 500 Artikel
- **RAG dritte Collection `gehirn`** additiv in `Gemma/rag/`
- **launchd Daily-Compile-Job** (18:00 Europe/Berlin) via `bin/tom-compile-safe`
- **Volltext-Dokumenten-Fundament**: OCR (`pdftotext` → `ocrmypdf` Fallback), SQLite FTS5, SHA256-Idempotenz unter `archivum/`
- **Primärer lokaler KI-Stack**: Ollama + LangChain + `qwen2.5:3b` mit Embeddings über `BAAI/bge-small-en-v1.5`
- **Open WebUI/OpenClaw**: lokaler Research-Pfad mit Web-Search/Web-Fetch, Apple-Silicon-tauglich und getrennt von Vault-Schreib-Workflows
- **Web-Clipper-Template-System**: 7 typ-spezifische Templates + `tom-clip-enrich` Auto-Enrichment (`qwen2.5:3b`), Interpreter primary mit Fallback
- **Obsidian-Doku-Routine pro Phase**: Phase-Note + Journal + Entscheidungen + Dashboard (CLAUDE.md "Mandatory pro GSD-Phase")
- **Lokaler Claude-Modus** (Phase 36 out-of-band): `nutze-ollama`/`tom-local`-Wrapper fuer den CCR-/Ollama-Pfad
- **52 Obsidian-Plugins inventarisiert** mit 4-Klassen-Klassifikation (Plugin Landscape in CLAUDE.md)

### Bestehende Werkzeuge

- `bin/tom-issue` — Maximus_OS Audit-Channel
- `bin/tom-ask` — RAG-Query (Cosine über wiki/clippings/gehirn)
- `bin/tom-wiki` — Karpathy Index-first Wiki-Query
- `bin/tom-compile` / `bin/tom-compile-safe` — Daily Brain-Compile via launchd
- `bin/tom-lint` — Brain-Health-Check (`--structural-only` als launchd-Default)
- `bin/tom-doc` — Volltext-Suche über persönliche Dokumente (SQLite FTS5)
- `bin/tom-clip-enrich` — Clipper-Auto-Enrichment Fallback (Interpreter primary)
- `bin/nutze-ollama.sh` + `bin/tom-local` — Lokaler Claude-Switch via CCR/Ollama
- `bin/tom-doc-intake` — KI-gestuetzte Dokument-Aufnahme (Ollama + Pydantic Schema)
- `bin/tom-raw-inject --book` — Buch-Modus mit Kapitel-Erkennung (PyPDF2 + Heading-Heuristik)
- `bin/tom-archiv-migrate` — Archiv-Migration ~/Downloads/Archiv/ → /Volumes/Archiv/ARCIV/
- `bin/tom-state` — Lifecycle-Migration + Auto-Transition (migrate-dokumente, -aufgaben, -termine, -dokumente-v2, -dokumente-v3, auto-transition)
- `bin/tom-state-safe` — Fehlertoleranter Wrapper fuer auto-transition via launchd
- `bin/tom-status` — Vault-weite Terminal-Zusammenfassung "Was steht an?"

### Ist-Zustand relevant für v1.5 (aus heutiger Recherche 2026-04-11)

- **Smart Connections defekt**: `data.json` nur 62 Bytes, Phase-29-Playbook re-anwenden
- **6 unused LLM-Plugins enabled** (cao, tars, large-language-models, llm-summary, llm-test-gen, ai-latex-generator) — sollen disabled werden
- **OLLAMA_ORIGINS leer** — Web Clipper CORS, dauerhaft via launchctl setzen
- **OpenClaw-Default**: lokaler Ollama-Pfad (`ollama/qwen2.5:3b`) mit Search/Fetch aktiviert
- **Claude-Code lokal**: historischer CCR/Ollama-Switch bleibt dokumentiert
- **VSCode Ollama Extension**: `warm3snow.vscode-ollama-1.2.1` installiert (Chat-Panel, kein File-I/O, kein Privacy-Risiko)
- **mcp-tools Plugin** v0.2.27 in Obsidian installiert (ADR-004, ungenutzt — Integrations-Kandidat für Phase 39)
- **CLAUDE.md "Lokaler Ollama-Modus"** Sektion in Phase 36 hinzugefügt

## Deferred → v1.6+

- **Auto-Projekt-/Ordner-Routing mit State-Triggern** — kommt in v1.5 als Read-Only-Dashboards, echte Auto-Routing erst v1.6
- **Inbox-Watcher** (Email-Polling / Scan-Ordner) — separater Stack-Aufbau, später
- **Full-Local `tom-compile` als Default** — hängt von Phase-38 Eval-Ergebnis ab
- **Fine-Tuning qwen2.5:3b** — weiterhin passiv Q&A sammeln
- **Handschrift-OCR**, **multimodale Nachfolgeoption** fuer spaetere lokale Upgrades
- **MCP-Bridge für tom-issue/tom-compile/tom-lint** — Tom-Development bleibt Cloud, MCP nur für Lese-Tools
- **Vault-in-git Entscheidung** (ADR-002) — bleibt deferred, kommt erst wenn Backup-Strategie konkret wird
- **Antwortschreiben-Generation** — lifecycle-abhängig, eigene Phase nach v1.5
