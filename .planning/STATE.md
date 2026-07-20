---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Expansion
status: in_progress
last_updated: "2026-07-19T00:00:00.000Z"
progress:
  total_phases: 8
  completed_phases: 5
  total_plans: 0
  completed_plans: 0
---

# State: Tom v1.6

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-17)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.6 — Expansion: externe Open-Source-Tools integrieren (RAG, Codex, Autoresearch, Skills, Clicky, audiobridge)

## Current Position

Phase: **61** Shortcuts-Forge (in Arbeit) · **49** Codex ✓ · **52** Clicky (Build ✓, Proxy+Doku; E2E-Ollama offen) · **53** audiobridge (`53-RUNBOOK.md`) · **51** ✓ · 50 ✓ · 54 Bridge (Repo shipped; Apply laut Maxim)
Plan: `61-shortcuts-forge/61-01-PLAN.md` · `52-clicky-local/` (`52-OLLAMA-PROXY.md`) · `53-audiobridge-transcription/` (`53-RUNBOOK.md`) · Phase 54 · `51-openspace-skill-engine/SUMMARY.md`
Status: Maxim 2026-04-16 — manuelle Schritte erledigt; REQ siehe `REQUIREMENTS.md`. Clicky: noch CLK16-02–05 bis Screenshot→Ollama verifiziert. 2026-07-19: Phase 61 gestartet (AI→Apple-Shortcuts-Pipeline).

Next: **Phase 61** Waves 2–6 (Helper, CLI, Stream Deck, E2E) · **Clicky** curl in `52-OLLAMA-PROXY.md` · **audiobridge** `53-RUNBOOK.md` + `VERIFICATION.md` · optional Vault-`log.md`

**v1.6 Phasen-Übersicht:**

- Phase 47 ✓ Plugins + Raw/Vault-Cleanup (Security Guidance, Raw-Cleanup, Inventar)
- Phase 48 ✓ RAG-Anything Multimodal (venv, tom-doc multi-search, MCP, Eval-Protokoll)
- Phase 49 ✓ Codex-Plugin Token-Opt (MITTEL)
- Phase 50 ✓ Autoresearch Eval-Pipeline (MITTEL)
- Phase 54 ✓ OpenClaw Workspace-Bridge (OPS, parallel — Repo+Stream-Deck; Live-Lauf manuell)
- Phase 51 ✓ OpenSpace Skill-Engine (MITTEL-NIEDRIG; Skills + RTK-Baseline)
- Phase 52 — Clicky Lokal-Build (NIEDRIG; Wave 0 Repo shipped)
- Phase 53 — audiobridge Transkription (NIEDRIG; Wave 0 + `53-RUNBOOK.md` shipped)
- Phase 61 — Shortcuts-Forge: AI→Apple-Shortcuts-Pipeline (in Arbeit seit 2026-07-19)

Last activity: 2026-07-19 — Phase 61 gestartet: `61-01-PLAN.md`, SCF16-01..06 in REQUIREMENTS, ROADMAP-Eintrag + Coverage 41

## Progress

```text
v1.5: [x] Phase 36  [x] 37  [x] 38  [x] 39  [x] 40  [x] 41a  [x] 41b  [x] 42  [x] 43  [x] 44
       100% (Milestone v1.5 shipped)
v1.6: [x] Phase 47  [x] 48  [x] 49  [x] 50  [x] 51  [ ] 52  [ ] 53  [x] 54-repo  [ ] 61
       63% (5/8 Kernphasen; 54 Repo shipped; 61 in Arbeit)
```

## Accumulated Context (von v1.5 übernommen)

### Architektur-Entscheidungen shipped (bis v1.5)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, MkDocs) und `95_Gehirn/` (privat, NIE publiziert)
- **claude-memory-compiler als externes Tool** in `/Users/maxim/Claude/claude-memory-compiler/`, gepatcht auf `$TOM_VAULT/95_Gehirn/`
- **Hooks projekt-lokal** in `/Users/maxim/Claude/.claude/settings.json`, merged mit globalen GSD+RTK Hooks
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + Artikel, `qwen3:8b` synthetisiert lokal. Schwelle: 500 Artikel
- **RAG dritte Collection `gehirn`** additiv in `Gemma/rag/`
- **launchd Daily-Compile-Job** (18:00 Europe/Berlin) via `bin/tom-compile-safe`
- **Volltext-Dokumenten-Fundament**: OCR (`pdftotext` → `ocrmypdf` Fallback), SQLite FTS5, SHA256-Idempotenz unter `archivum/`
- **Primärer lokaler KI-Stack**: Ollama + LangChain + `qwen3:8b` mit Embeddings über `BAAI/bge-small-en-v1.5`
- **Lifecycle-State-Machine**: 6 Bereiche, Meta Bind Buttons, Dataview-Dashboards, Auto-Transitions
- **MCP-Bridge**: FastMCP v3 Server mit 6 Read-only-Tools in Cursor (inkl. `tom_doc_multi_search`)
- **Lokaler Claude-Modus**: `nutze-ollama`/`tom-local` für CCR/Ollama-Pfad

### Bestehende Werkzeuge

- `bin/tom-issue` — Maximus_OS Audit-Channel
- `bin/tom-ask` — RAG-Query (Cosine über wiki/clippings/gehirn)
- `bin/tom-wiki` — Karpathy Index-first Wiki-Query
- `bin/tom-compile` / `bin/tom-compile-safe` — Daily Brain-Compile via launchd
- `bin/tom-lint` — Brain-Health-Check (`--structural-only` als launchd-Default)
- `bin/tom-eval` — Eval-Wrapper (`Gemma/eval/run_eval.py`, Phase 50)
- `bin/tom-codex-preflight` — Node/npm + Codex-CLI-Hinweis, Claude-Code-Befehle ausgeben (Phase 49)
- `bin/tom-clicky-hints` — Phase-52-Kurzcheckliste (Phase 52)
- `bin/tom-audiobridge-preflight` — Phase-53-Install-/Vault-Hinweise (Phase 53)
- `bin/tom-xcode-select-app` — prüft `xcode-select`; gibt `sudo xcode-select -s …/Xcode.app/...` aus falls nötig (Phase 52)
- `bin/tom-clicky-build` — Clicky Debug-Build mit `DEVELOPER_DIR` + ad-hoc Signing (Phase 52)
- `bin/tom-clicky-ollama-proxy` — Anthropic→Ollama `/chat`-Bridge für Clicky (Phase 52)
- `bin/tom-clicky-apply-local-proxy` — Patch `workerBaseURL` im Clicky-Checkout (Phase 52)
- `bin/tom-clicky-ollama-smoke` — HEAD + Stream-Smoke gegen lokalen Proxy (Phase 52)
- `bin/tom-vault-transkripte-dir` — `$TOM_VAULT/raw/transkripte/` anlegen (Phase 53 / AUD16-04)
- `bin/tom-doc` — FTS5 (`search`) + optional RAG-Anything (`multi-search`, Phase 48)
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
- **Fine-Tuning qwen3:8b** — passiv Q&A sammeln
- **Vault-in-git Entscheidung** (ADR-002) — bleibt deferred
- **Antwortschreiben-Generation** — lifecycle-abhängig
