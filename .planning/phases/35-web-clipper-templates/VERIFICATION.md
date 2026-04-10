# Phase 35 Verification

**Phase:** 35 — Web-Clipper-Template-System
**Milestone:** v1.4.1
**Date:** 2026-04-10
**Status:** ✓ PASS (mit Maxim-Handoff für Smoke-Test)

## Success Criteria

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| 1 | 7 Templates in `99_Vorlagen/web-clipper/` | Artikel, Paper, Video, Dokument, Social-Post, Rezept, Werkzeug | ✓ |
| 2 | README.md mit Setup + Variablen-Referenz + Troubleshooting | `99_Vorlagen/web-clipper/README.md` | ✓ |
| 3 | 7 Ziel-Ordner in `Clippings/` | Artikel, Paper, Videos, Dokumente, Social, Rezepte, Werkzeuge | ✓ |
| 4 | Pro Ziel-Ordner README-Stub mit Frontmatter | 7 README.md in `Clippings/<Typ>/` | ✓ |
| 5 | CLAUDE.md Ingesting-Sektion erweitert | Web-Clipper-Flow-Subsektion + tom-clip-enrich-Beispiel | ✓ |
| 6 | Tom-konformes Frontmatter in allen Templates | `title`, `created`, `type`, `source`, `tags`, `enriched`, `suggested_wiki_category` | ✓ |
| 7 | Smoke-Test mit echtem Clip | Maxim-Handoff — wird nach Plan-Execution durchgeführt | ⏳ |

## Requirements

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CLIP141-01 | ✓ | 7 Templates + README.md in `web-clipper/` |
| CLIP141-02 | ✓ | 7 Ziel-Ordner in `Clippings/` mit README-Stubs |
| CLIP141-03 | ✓ | Browser-Extension-Setup in README Schritt-für-Schritt |
| CLIP141-04 | ⏳ | Smoke-Test Maxim-Handoff (prepared-pending) |
| CLIP141-05 | ✓ | CLAUDE.md Ingesting-Sektion ergänzt |
| CLIP141-06 | ✓ | `tom-clip-enrich`-Aufruf-Beispiel in README |

## Handoff an Maxim — Smoke-Test

Um CLIP141-04 zu schließen, muss Maxim folgende Schritte manuell ausführen:

1. **Browser-Extension öffnen** (Obsidian Web Clipper)
2. **Settings → Templates**: 7 Templates aus `99_Vorlagen/web-clipper/*.md` einfügen (Copy-Paste des kompletten File-Contents)
3. **Pro Template Path setzen**: `Clippings/Artikel/`, `Clippings/Paper/`, etc.
4. **Test-Clip** (empfohlen: eine beliebige Wikipedia-Seite mit `Artikel.md`-Template)
5. **Prüfen:** Neue Datei in `$TOM_VAULT/Clippings/Artikel/` mit korrektem Frontmatter (`type: artikel`, `source: https://...`, `enriched: false`)
6. **Enrichment:** `tom-clip-enrich "$TOM_VAULT/Clippings/Artikel/<file>.md"`
7. **Verifikation:** `enriched: true`, Summary + Tags + Konzepte vorhanden
8. **Idempotenz:** Zweiter `tom-clip-enrich`-Lauf skipt sauber

**Variablen-Syntax-Validierung:** Sollte der Obsidian Web Clipper andere Variablen-Syntax als `{{title|default:""}}` unterstützen (z.B. `<%= title %>` oder andere Delimiter), muss in einem Template die Syntax angepasst werden, dann auf die anderen 6 übertragen. Das bestehende Mannheim-Clipping aus Phase 30 kann als Referenz für das Extension-Output-Format dienen.

## Notes

- Phase 35 folgt der neuen Dogfooding-Regel aus Phase 33: Phase-35-Note im Vault, Journal-Update, keine neuen Entscheidungen (reine Feature-Implementation).
- `tom-clip-enrich` wird laut Phase-30-Summary nicht verändert — der Enricher akzeptiert bereits beliebige Pfade unter `Clippings/`, die neuen Unterordner funktionieren out-of-the-box.
