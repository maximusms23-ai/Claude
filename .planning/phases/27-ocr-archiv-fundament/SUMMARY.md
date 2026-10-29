# Phase 27 Summary

**OCR-Toolkette + Archiv-Fundament** — v1.4 Phase 27

## What Shipped

- OCR-Stack installiert: `tesseract`, `tesseract-lang` (inkl. `deu`), `ocrmypdf`, `poppler` (für `pdftotext`/`pdfinfo`)
- `$TOM_VAULT/Archiv/` Symlink auf `~/Downloads/Archiv/` angelegt (CLAUDE.md-Behauptung ist jetzt Realität)
- `/Users/maxim/Claude/archivum/` Struktur: `db/`, `ocr-cache/`, `logs/`, `README.md`, `.gitignore`
- SQLite FTS5 Volltext-Index (`archivum/db/archivum.db`) mit `documents` + `documents_fts` (Tokenizer `unicode61 remove_diacritics 2`)
- `archivum/ocr_pipeline.py` — pdftotext-first Extraction mit ocrmypdf-Fallback, SHA256-Idempotenz-Cache, CLI mit `--init`, `--file`, `--category`, `--all`, `--search`
- Smoke-Test gegen echtes 27-Seiten-PDF (`2204_Arbeitsvertrag_Schmidt.pdf`) — indiziert in 0.07s, FTS5-Queries liefern präzise Snippets

## Requirements Complete

DOC14-01..06 ✓ (6/6)

## Key Decisions

- **pdftotext zuerst, ocrmypdf als Fallback**: Die meisten modernen PDFs haben bereits Text. `pdftotext -layout` ist ~150× schneller als `ocrmypdf --force-ocr`. Nur bei <100 Zeichen Rückgabe (Scan ohne OCR-Layer) wird ocrmypdf geladen.
- **Contentless FTS5 verworfen**: Snippet-Funktion braucht dupliziertes Storage. DB-Größe bleibt unkritisch (~100KB pro Dokument).
- **SHA256-basierte Idempotenz**: Nicht pfadbasiert — Umbenennungen/Moves brechen den Cache nicht.
- **Poppler nachinstalliert**: Ursprünglich nicht im Plan, aber nötig für `pdftotext`. Jetzt Teil der Baseline.

## Not Shipped (Out of Scope for Phase 27)

- `bin/tom-doc` CLI-Wrapper → Phase 28
- Batch-Run über alle 15 Archiv-Kategorien → kommt wenn Archiv real befüllt ist
- Integration in `CLAUDE.md` Wissens-Kaskade → Phase 28 (zusammen mit tom-doc)

## Commit
Next: ein einziger Commit für `feat(archivum): OCR + FTS5 Volltext-Fundament`.

## Next Up

**Phase 28: tom-doc CLI** — User-freundlicher Wrapper mit `index`/`search`/`list`/`show` Subcommands, dann in CLAUDE.md-Wissens-Kaskade verankern.
