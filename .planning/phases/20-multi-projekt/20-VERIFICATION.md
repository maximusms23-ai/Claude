---
status: passed
---

# Phase 20: Multi-Projekt-Konvention — Verification

**Status:** ✅ passed
**Maximus_OS Issue:** FAM-125

## Requirements

| ID | Status | Evidence |
|---|---|---|
| MULTI-01 | ✅ | `claude-memory-compiler/docs/multi-project.md` — Template-Sektion für konsumierende Projekte + optionaler Hook-Setup für contributing Projekte |
| MULTI-02 | ✅ | `Gemma/CLAUDE.md` angelegt — erstes Sub-Projekt mit voller `wiki_path`-Sektion, demonstriert die Konvention |
| MULTI-03 | ✅ | Smoke-Test: `cd Gemma && tom-wiki "..."` läuft durch, Output identisch wie aus Parent-Repo |
| MULTI-04 | ✅ | `$TOM_VAULT/95_Gehirn/CLAUDE.md` Multi-Projekt-Sektion ergänzt um Liste der aktuell konsumierenden Projekte + Hinweis dass Auto-Capture optional ist |
| MULTI-05 | ✅ | FAM-125 an wiki-kurator |

## Konvention im Kurztest

Eine `wiki_path`-Sektion besteht aus:
1. Zeiger auf `$TOM_VAULT`
2. Auflistung der vier Wissens-Tools (`tom-wiki`, `tom-wiki --brain`, `tom-ask`)
3. Hinweis auf die 4-stufige Kaskade
4. Privacy-Hinweis bei Projekten, die ggf. PII enthalten

Die Wrapper in `bin/` sind cwd-unabhängig (setzen `TOM_VAULT` + cd im Script selbst), daher funktionieren sie aus jedem beliebigen Projekt.
