# archivum — Tom Dokumenten-Volltext-Index

Volltext-Index über Maxims 15 Archiv-Kategorien (OCR-basiert).

**Milestone:** v1.4 Phase 27 (OCR-Fundament)

## Inhalt

```
archivum/
├── db/
│   └── archivum.db        SQLite FTS5 — Volltext-Index
├── ocr-cache/             OCR-Text pro PDF (SHA256-basiert, idempotent)
├── logs/                  Pipeline-Run-Logs
├── ocr_pipeline.py        OCR-Batch-Script
└── README.md              Diese Datei
```

## Architektur

- **Source**: `~/Downloads/Archiv/<NN Kategorie>/*.pdf` (read-only, Tom touch nothing) + `$TOM_VAULT/raw/**/*.pdf`
- **OCR**: `ocrmypdf --language deu --sidecar` → reiner Text nach `ocr-cache/<sha256>.txt`
- **Index**: SQLite 3 FTS5 (`documents` + `documents_fts` Tabellen)
- **Idempotenz**: `ocr_pipeline.py` hasht PDFs per SHA256, überspringt bereits verarbeitete Files (Existenz-Check im Cache)

## Schema

Siehe `db/archivum.db` (nach Init-Run). Erstellt via `ocr_pipeline.py --init`.

## Nutzung

```bash
# Initial-Setup (DB anlegen)
python3 /Users/maxim/Claude/archivum/ocr_pipeline.py --init

# Batch-Run über eine Kategorie
python3 /Users/maxim/Claude/archivum/ocr_pipeline.py --category "07 Verträge"

# Single-File OCR + Index
python3 /Users/maxim/Claude/archivum/ocr_pipeline.py --file "/path/to/doc.pdf"

# Alle Kategorien
python3 /Users/maxim/Claude/archivum/ocr_pipeline.py --all
```

Phase 28 bringt einen nutzerfreundlichen `bin/tom-doc` Wrapper oben drüber.

## Privacy

- `archivum/` ist NIE in MkDocs-Scope
- `archivum/` ist lokal — kein iCloud, kein Git-Commit der DB (siehe `.gitignore`)
- OCR-Cache enthält Volltext persönlicher Dokumente → bleibt lokal auf Maxims Mac

## Logs

`logs/ocr-pipeline.log` — ein Zeilenstil: `Timestamp | Action | File | Status | Duration`
