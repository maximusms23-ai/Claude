---
status: passed
---

# Phase 19: Neue Wrapper tom-wiki/tom-compile/tom-lint — Verification

**Status:** ✅ passed
**Maximus_OS Issue:** FAM-124

## Requirements

| ID | Status | Evidence |
|---|---|---|
| WRAP-01 | ✅ | `bin/tom-wiki` — Bash-Wrapper + `tom_tools/wiki_query.py` Python-Modul. Unterstützt `--brain`, `--root`, Default `$TOM_VAULT/90_Wiki` |
| WRAP-02 | ✅ | `bin/tom-compile` — ruft `uv run scripts/compile.py` mit durchgereichten Flags |
| WRAP-03 | ✅ | `bin/tom-lint` — ruft `uv run scripts/lint.py` mit durchgereichten Flags (inkl. `--structural-only`) |
| WRAP-04 | ✅ | Symlinks `~/bin/tom-wiki`, `~/bin/tom-compile`, `~/bin/tom-lint` → `/Users/maxim/Claude/bin/*`, alle executable |
| WRAP-05 | ✅ | Smoke-Tests: `tom-lint --structural-only` läuft durch (0 errors, 1 warning weil daily-log 2026-04-10 uncompiled); `tom-wiki "Was ist TurboQuant?"` liefert gemme-Antwort via Index+Files |
| WRAP-06 | ✅ | `CLAUDE.md` + `AGENTS.md` enthalten neue Sektion "Wissens-Kaskade" (Direct-Read → tom-wiki → tom-wiki --brain → tom-ask) |
| WRAP-07 | ✅ | FAM-124 an CTO |

## Implementation Notes

- `tom-wiki` nutzt Ollama + `gemme` statt Claude Agent SDK → komplett lokal, kostenlos, keine API-Credits
- Alle Artikel werden in-Prompt geladen (Karpathy-Stil); bei > 100k chars wird getrimmt mit Hinweis auf `tom-ask` als Fallback
- `ollama` Python-Package via `uv add ollama` zum compiler-repo dependencies hinzugefügt

## Nebenbefund

Der tom-lint-Smoke-Test hat einen Warning geliefert: `daily/2026-04-10.md - Uncompiled daily log`. Das beweist, dass HOOK-03 aus Phase 16 **tatsächlich funktioniert** hat — beim Python-Import-Smoke-Test in Phase 16 wurde ein echter daily-log-Entry erzeugt ("FLUSH_OK - Nothing worth saving from this session"). Phase 16 kann dadurch retrospektiv von `human_needed` auf `passed` aufgewertet werden.
