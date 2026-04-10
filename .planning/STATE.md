---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: Complete
status: unknown
last_updated: "2026-04-10T12:22:10.405Z"
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 3
  completed_plans: 1
---

# State: Tom v1.3

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** Phase 22 — compile-automation

## Current Position

Phase: 22 (compile-automation) — EXECUTING
Plan: 2 of 2

## Decisions

- **22-01:** `set -uo pipefail` statt `set -euo pipefail` in tom-compile-safe damit Exit-Code nach Lauf captured wird
- **22-01:** SKIP+exit 0 fuer transiente Fehler (ollama down, iCloud unmounted), FAIL+exit 1 nur fuer Setup-Fehler (Konfigurationsproblem)

## Progress

```
v1.3: [ ] Phase 22  [ ] Phase 23  [ ] Phase 24  [ ] Phase 25  [ ] Phase 26
       0%                                                              100%
```

## Accumulated Context (von v1.2 übernommen)

### Architektur-Entscheidungen v1.2 (shipped)

- **Zwei Wissens-Räume**: `90_Wiki/` (public, MkDocs) und `95_Gehirn/` (privat, NIE publiziert)
- **claude-memory-compiler als externes Tool** in `/Users/maxim/Claude/claude-memory-compiler/`, gepatcht auf `$TOM_VAULT/95_Gehirn/`, Patches in `TOM-PATCHES.md`
- **Hooks projekt-lokal** in `/Users/maxim/Claude/.claude/settings.json`, merged mit globalen GSD+RTK Hooks
- **Karpathy Index-first als Primary**: `tom-wiki` lädt Index + Artikel, `gemme` synthetisiert lokal. RAG als Fallback. **Schwelle v1.3: 1500 Artikel** (vorher 500)
- **RAG dritte Collection `gehirn`** additiv in `Gemma/rag/`
- **Lokale Ollama statt Claude Agent SDK** für `tom-wiki` (Anthropic-SDK-Clarification in v1.3)

### Neue Werkzeuge ab v1.2

- `bin/tom-wiki`, `bin/tom-compile`, `bin/tom-lint` (zusätzlich zu v1.1 `tom-issue`, `tom-ask`)

## Milestone v1.3 Scope

Phasen 22–26 in `.planning/ROADMAP.md` vollständig beschrieben.

**Fokus:**

1. Phase 22: Compile-Automation via launchd + fehlertoleranter Wrapper `tom-compile-safe`
2. Phase 23: `tom-wiki` Quality-Pass (Prompt + Context-Filter + Quellen-Zitation)
3. Phase 24: Eval-Framework erweitert um Brain-Artikel + Side-by-Side-Vergleich
4. Phase 25: Doku Karpathy-Schwelle 1500 + Umstiegspfad (reine Doku-Phase)
5. Phase 26: Anthropic-SDK-Clarification + Milestone-Close

## Open Questions (deferred)

- Fine-Tuning (MLX-LM/Unsloth) → v1.5+
- tom-compile Trigger-Zeit (18:00 vs 03:00) → wird in Phase 22 entschieden
