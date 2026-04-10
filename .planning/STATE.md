# State: Tom v1.3

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-10)

**Core value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles — Tom weiß, wo was liegt.
**Current focus:** v1.3 — Compile-Automation + Quality-Pass (Phase 22 bereit)

## Current Position

- **Milestone:** v1.3 — Compile-Automation + Quality-Pass
- **Phase:** Phase 22 — Compile-Automation (Not started)
- **Plan:** —
- **Status:** Roadmap erstellt, bereit für Phase 22
- **Last activity:** 2026-04-10 — v1.3 Roadmap (Phasen 22–26) erstellt

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
