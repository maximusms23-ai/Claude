# State: Tom v1.3

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.3 — Compile-Automation + Quality-Pass (defining requirements)

## Current Position

- **Milestone:** v1.3 — Compile-Automation + Quality-Pass
- **Phase:** Not started (defining requirements)
- **Plan:** —
- **Status:** Defining requirements
- **Last activity:** 2026-04-10 — Milestone v1.3 started

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

Siehe `.planning/REQUIREMENTS.md` und `.planning/ROADMAP.md`.

**Fokus:**
1. Compile-Automation via launchd + fehlertoleranter Wrapper
2. `tom-wiki` Quality-Pass (Prompt + Context-Filter)
3. Eval-Framework erweitert um Brain-Artikel
4. Doku: Karpathy-Schwelle 1500 + Umstiegspfad
5. Anthropic-SDK-Clarification
6. Abschluss + Close

## Open Questions (deferred)

- Fine-Tuning (MLX-LM/Unsloth) → v1.5+
- tom-compile Trigger-Zeit (18:00 vs 03:00) → wird in Phase 22 entschieden
