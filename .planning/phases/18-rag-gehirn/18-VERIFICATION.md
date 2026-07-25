---
status: passed
---

# Phase 18: RAG-Erweiterung um gehirn-Collection — Verification

**Status:** ✅ passed
**Maximus_OS Issue:** FAM-123

## Requirements

| ID | Status | Evidence |
|---|---|---|
| RAG2-01 | ✅ | `config.py`: `GEHIRN_PATH = TOM_VAULT / "95_Gehirn" / "knowledge"` |
| RAG2-02 | ✅ | `index.py`: `index_all()` ruft `index_directory(client, "gehirn", GEHIRN_PATH, "gehirn")` zusätzlich auf |
| RAG2-03 | ✅ | `query.py`: `for col_name in ["wiki", "clippings", "gehirn"]` |
| RAG2-04 | ✅ | Smoke-Test: `index_directory` gegen leeres `gehirn/knowledge/` → "Keine Markdown-Dateien", return (0, 0), keine Exception |
| RAG2-05 | ✅ | FAM-123 an CTO |

## Collections-Status (aktuell)

| Collection | Chunks | Status |
|---|---|---|
| wiki | 58 | aus v1.1 indiziert |
| clippings | 533 | aus v1.1 indiziert |
| gehirn | 0 | neu, noch leer (wird befüllt sobald compile.py läuft) |

Query-Loop durchläuft alle drei sauber — `get_collection` wirft `NotFoundError` für `gehirn`, wird im `try/except continue`-Block abgefangen.
