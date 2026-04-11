---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Lifecycle + Integration
status: in_progress
last_updated: "2026-04-11T14:00:00.000Z"
progress:
  total_phases: 9
  completed_phases: 1
  total_plans: 1
  completed_plans: 1
---

# State: Tom v1.5

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-11 after v1.5 milestone start)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.5 — Lifecycle-State-Machine + MCP-Bridge + lokaler Tool-Use

## Current Position

Phase: Defining requirements (v1.5 Kickoff)
Plan: —
Status: Defining requirements

**v1.5 Phasen-Übersicht:**

- Phase 36 ✓ Lokaler Ollama-Switch (out-of-band shipped 2026-04-11, retroaktiv aufzunehmen)
- Phase 37 ○ Vault-Hygiene & Cleanup
- Phase 38 ○ Local Tool-Use Modell-Upgrade
- Phase 39 ○ mcp-tools Integration
- Phase 40 ○ Lifecycle Foundation — Dokumente
- Phase 41 ○ Lifecycle — Aufgaben & Termine
- Phase 42 ○ Lifecycle — Projekte / Finanzen / Social
- Phase 43 ○ Lifecycle Dashboards & Auto-Routing
- Phase 44 ○ Milestone-Close v1.5

Last activity: 2026-04-11 — Phase 36 out-of-band shipped, v1.5 Kickoff started

## Progress

```text
v1.4: [x] Phase 27  [x] Phase 28  [x] Phase 29+Hotfix  [x] Phase 30  [x] Phase 31  [x] Phase 32
       100%
v1.4.1: [x] Phase 33  [x] Phase 34  [x] Phase 35 (+Hotfix)
        100%
v1.5: [x] Phase 36  [ ] 37  [ ] 38  [ ] 39  [ ] 40  [ ] 41  [ ] 42  [ ] 43  [ ] 44
       11% (1/9 — Phase 36 out-of-band opener)
```

## v1.5 Open Handoffs (carryover aus v1.4 / v1.4.1)

Diese werden in Phase 37 (Vault-Hygiene) gebündelt geschlossen:

- **CLIP141-04** (Phase 35): Web-Clipper-Smoke-Test mit echtem Browser-Clip
- **CLIP141-13** (Phase 35-Hotfix): Interpreter-Smoke-Test, blockiert durch Ollama-Models-Path-Defekt
- **OBPL-03** (Phase 29): Smart Connections "TurboQuant" Smoke-Test nach UI-Reconfig
- **Plugin-Audit Q1–Q5** (`plugin-audit-v1.4.1.md`): eml-reader / apple-reminders Setup-Entscheidungen

## Phase 36 Decisions (out-of-band, 2026-04-11)

- Lokaler Modus ist **Chat-Only** — Tool-Use mit qwen2.5-coder via CCR-`tooluse`-Transformer empirisch broken (Tool-Calls als Text-String)
- `ccr activate` als env-Var-Quelle statt Hardcoding (zero-maintenance bei CCR-Updates)
- Model-Aliasing statt Custom-Namen im `/model`-Picker (Anthropic-Namen sind hardcoded in Claude Code)
- Phase 38 wird qwen3-coder oder glm-4.5-air pullen + Tool-Use-Gate retesten

## Accumulated Context (von v1.4/v1.4.1 übernommen)

### Architektur-Entscheidungen shipped (bis v1.4.1)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, MkDocs) und `95_Gehirn/` (privat, NIE publiziert)
- **claude-memory-compiler als externes Tool** in `/Users/maxim/Claude/claude-memory-compiler/`, gepatcht auf `$TOM_VAULT/95_Gehirn/`
- **Hooks projekt-lokal** in `/Users/maxim/Claude/.claude/settings.json`, merged mit globalen GSD+RTK Hooks
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + Artikel, `gemme` synthetisiert lokal. Schwelle: 500 Artikel
- **RAG dritte Collection `gehirn`** additiv in `Gemma/rag/`
- **launchd Daily-Compile-Job** (18:00 Europe/Berlin) via `bin/tom-compile-safe`
- **Volltext-Dokumenten-Fundament**: OCR (`pdftotext` → `ocrmypdf` Fallback), SQLite FTS5, SHA256-Idempotenz unter `archivum/`
- **Smart Connections Obsidian-Plugin** v4.3.0 mit Ollama-Backend (`nomic-embed-text` + `gemme`), Privacy-Exclude via UI (ADR-001)
- **Web-Clipper-Template-System**: 7 typ-spezifische Templates + `tom-clip-enrich` Auto-Enrichment (gemme), Interpreter primary mit Fallback
- **Obsidian-Doku-Routine pro Phase**: Phase-Note + Journal + Entscheidungen + Dashboard (CLAUDE.md "Mandatory pro GSD-Phase")
- **Lokaler Claude-Code-Modus** (Phase 36 out-of-band): Claude Code Router auf Port 3456, `nutze-ollama`/`tom-local`-Wrapper, **Chat-Only** (Tool-Use broken bis Phase 38)
- **52 Obsidian-Plugins inventarisiert** mit 4-Klassen-Klassifikation (Plugin Landscape in CLAUDE.md)

### Bestehende Werkzeuge

- `bin/tom-issue` — Maximus_OS Audit-Channel
- `bin/tom-ask` — RAG-Query (Cosine über wiki/clippings/gehirn)
- `bin/tom-wiki` — Karpathy Index-first Wiki-Query
- `bin/tom-compile` / `bin/tom-compile-safe` — Daily Brain-Compile via launchd
- `bin/tom-lint` — Brain-Health-Check (`--structural-only` als launchd-Default)
- `bin/tom-doc` — Volltext-Suche über persönliche Dokumente (SQLite FTS5)
- `bin/tom-clip-enrich` — Clipper-Auto-Enrichment Fallback (Interpreter primary)
- `bin/nutze-ollama.sh` + `bin/tom-local` — Lokaler Claude-Code-Switch (Chat-Only)

### Ist-Zustand relevant für v1.5 (aus heutiger Recherche 2026-04-11)

- **Smart Connections defekt**: `data.json` nur 62 Bytes, Phase-29-Playbook re-anwenden
- **6 unused LLM-Plugins enabled** (cao, tars, large-language-models, llm-summary, llm-test-gen, ai-latex-generator) — sollen disabled werden
- **OLLAMA_ORIGINS leer** — Web Clipper CORS, dauerhaft via launchctl setzen
- **CCR installiert** auf `/opt/homebrew/bin/ccr`, Daemon läuft Port 3456
- **Modelle**: gemme:latest (9.6 GB), qwen2.5-coder:latest (4.7 GB), gemma4:e4b (9.6 GB), nomic-embed-text:latest (274 MB)
- **VSCode Ollama Extension**: `warm3snow.vscode-ollama-1.2.1` installiert (Chat-Panel, kein File-I/O, kein Privacy-Risiko)
- **mcp-tools Plugin** v0.2.27 in Obsidian installiert (ADR-004, ungenutzt — Integrations-Kandidat für Phase 39)
- **CLAUDE.md "Lokaler Ollama-Modus"** Sektion in Phase 36 hinzugefügt

## Deferred → v1.6+

- **Auto-Projekt-/Ordner-Routing mit State-Triggern** — kommt in v1.5 als Read-Only-Dashboards, echte Auto-Routing erst v1.6
- **Inbox-Watcher** (Email-Polling / Scan-Ordner) — separater Stack-Aufbau, später
- **Full-Local `tom-compile` als Default** — hängt von Phase-38 Eval-Ergebnis ab
- **Fine-Tuning gemme** — weiterhin passiv Q&A sammeln
- **Handschrift-OCR**, **multimodales gemme**
- **MCP-Bridge für tom-issue/tom-compile/tom-lint** — Tom-Development bleibt Cloud, MCP nur für Lese-Tools
- **Vault-in-git Entscheidung** (ADR-002) — bleibt deferred, kommt erst wenn Backup-Strategie konkret wird
- **Antwortschreiben-Generation** — lifecycle-abhängig, eigene Phase nach v1.5
