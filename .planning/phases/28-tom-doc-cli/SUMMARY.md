# Phase 28 Summary

**tom-doc CLI** — v1.4 Phase 28

## What Shipped

- `bin/tom-doc` Bash-Wrapper mit 4 Subcommands: `index`, `search`, `list`, `show`
- `ocr_pipeline.py` erweitert um `list_documents()` + `show_document()` + CLI-Flags `--list`, `--show`, `--limit`, `--excerpt`
- `~/bin/tom-doc` Symlink
- CLAUDE.md Wissens-Kaskade um zwei Stellen erweitert: "Answering User Questions" Punkt 4 (Dokumenten-Fragen) und Wissens-Kaskade Punkt 5 (Persönliche Dokumente Volltext)

## Requirements Complete

TDOC-01..07 ✓ (7/7)

## Key Decisions

- **Python statt reinem Bash**: Die Pipeline-Logik lebt in `ocr_pipeline.py`, der Bash-Wrapper ist nur Routing. Vorteil: DB-Operationen sauber testbar, SQL-Queries bleiben in einem File.
- **`show` mit flexibler ID-Auflösung**: Akzeptiert numerische ID, vollständigen Pfad, Filename oder SHA256-Prefix. Nutzer müssen nicht wissen, welche Form — nachvollziehbar beim Rumprobieren.
- **Excerpt-Standard 2000 Zeichen**: Großzügig genug für typische Briefe, klein genug um Terminal nicht zu fluten. Override via `--excerpt N`.
- **CLAUDE.md zweifach erweitert**: Einmal in "Answering User Questions" (für Tom-Routing), einmal in der eigentlichen Wissens-Kaskade (für systematisches Tool-Lookup). Vermeidet dass der tom-doc-Pfad übersehen wird.

## Not Shipped

- JSON-Output-Modus (YAGNI)
- Interactive TUI (CLI reicht)
- Batch-Index aller Archiv-Kategorien (passiert wenn Maxim Dokumente befüllt)

## Next Up

**Phase 29: Gemma-in-Obsidian via Smart Connections** — Plugin-Install + Ollama-Backend + Privacy-Exclude. Parallelisierbar mit Phase 30 (Clipper Auto-Enrichment).
