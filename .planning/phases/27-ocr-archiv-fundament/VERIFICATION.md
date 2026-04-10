# Phase 27 Verification

**Phase:** 27 — OCR-Toolkette + Archiv-Fundament
**Milestone:** v1.4
**Date:** 2026-04-10
**Status:** ✓ PASS

## Success Criteria

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| 1 | `which tesseract ocrmypdf` → both installed | `/opt/homebrew/bin/tesseract`, `/opt/homebrew/bin/ocrmypdf` | ✓ |
| 2 | `tesseract --list-langs` contains `deu` | `deu` present (grep -c → 1) | ✓ |
| 3 | `$TOM_VAULT/Archiv/` symlink exists | `-> /Users/maxim/Downloads/Archiv` | ✓ |
| 4 | SQLite FTS5 schema with `documents` + `documents_fts` | `.schema` shows both tables + indices | ✓ |
| 5 | `ocr_pipeline.py --init` runs clean | Exit 0, "schema at …/archivum.db" | ✓ |
| 6 | Smoke-Test: real PDF indexed + searchable | 89805 chars, 27 pages, search hits "Arbeitsvertrag"/"Gehalt"/"Schmidt" with snippets | ✓ |
| 7 | Idempotency: second run on same file → skip | `status: skip, id=1` on re-run | ✓ |

## Requirements

| Requirement | Status | Evidence |
|-------------|--------|----------|
| DOC14-01 | ✓ | `tesseract --list-langs \| grep deu` |
| DOC14-02 | ✓ | `test -L "$TOM_VAULT/Archiv"` |
| DOC14-03 | ✓ | `ls archivum/{db,ocr-cache,logs,README.md,.gitignore}` |
| DOC14-04 | ✓ | `sqlite3 archivum/db/archivum.db ".schema"` |
| DOC14-05 | ✓ | `archivum/ocr_pipeline.py` (CLI: --init, --file, --category, --all, --search) |
| DOC14-06 | ✓ | `python3 ocr_pipeline.py --search "Arbeitsvertrag"` returns hit with snippet |

## Smoke-Test Details

**Test-Dokument:** `$TOM_VAULT/raw/2204_Arbeitsvertrag_Schmidt.pdf` (8.7 MB)

**Index-Run:**
```
status: ok, id: 1, chars: 89805, method: pdftotext, pages: 27
SHA256: 7dcfc40b6026b8ea83de01d05c0866978a12ffb0becc0b930d9c1e78998ff79b
Duration: 0.07s (pdftotext path, no OCR needed — PDF has text layer)
```

**Search-Queries:**
- `"Arbeitsvertrag"` → Snippet: `"…Schriftformklausel / Dieser [Arbeitsvertrag] ersetzt alle eventuellen vorherigen Vereinbarungen…"`
- `"Gehalt"` → Snippet: `"…Bei unvollständigen Personalunterlagen kann unter Umständen kein [Gehalt] überwiesen werden!…"`
- `"Schmidt"` → Snippet: `"…maxim.[schmidt]@vodafonemail.de / Krankenkasse: IKK-classic…"`

**Idempotency:** Second `--file` run returned `status: skip, id=1` (SHA256-Cache-Hit).

## Architectural Notes

- **pdftotext-first strategy**: `ocr_pipeline.py` tries `pdftotext -layout` first (fast, works for PDFs with text layer). Falls back to `ocrmypdf --force-ocr --language deu` only for image-based PDFs. Empirisch: reine Text-PDFs landen in <0.1s im Index, statt >10s mit ocrmypdf.
- **Contentless FTS5 verworfen**: Erste Iteration nutzte `content=''` (external-content FTS5), was `snippet()` unbrauchbar machte. Jetzt: normale FTS5-Table mit dupliziertem Storage — Snippets funktionieren, DB-Größe unkritisch (89kb Text pro Dokument).
- **SHA256-Cache**: Idempotenz über Datei-Hash, nicht Pfad. Wenn Maxim ein PDF umbenennt oder verschiebt: wird als "schon indiziert" erkannt, Pfad in `documents.path` bleibt alter Pfad (akzeptabel für v1.4; ggf. später Update-Logik).
- **Poppler installiert**: Initial nicht geplant, nachgezogen weil `pdftotext` + `pdfinfo` für die Fast-Path nötig sind. Jetzt Teil der Tool-Baseline.

## Files Changed

- `+ archivum/README.md`
- `+ archivum/.gitignore`
- `+ archivum/ocr_pipeline.py`
- `+ archivum/db/archivum.db` (gitignored)
- `+ archivum/ocr-cache/7dcfc40b…txt` (gitignored)
- `+ archivum/logs/ocr-pipeline.log` (gitignored)
- `+ $TOM_VAULT/Archiv` (symlink, outside git)
- `+ .planning/phases/27-ocr-archiv-fundament/27-01-PLAN.md`
- `+ .planning/phases/27-ocr-archiv-fundament/VERIFICATION.md`
- `~ .planning/REQUIREMENTS.md` (DOC14-01..06 → Complete)

## External Dependencies Installed

- `tesseract` (brew)
- `tesseract-lang` (brew) — includes `deu`
- `ocrmypdf` (brew)
- `poppler` (brew) — provides `pdftotext`, `pdfinfo`

## Status: ✓ READY FOR PHASE 28 (tom-doc CLI)
