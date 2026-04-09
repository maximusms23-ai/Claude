# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

An LLM-maintained Obsidian knowledge base. The LLM actively writes, links, and maintains wiki content — not just reads it. The human rarely edits wiki files directly.

## Vault Structure

- `raw/` — Unprocessed source material (artikel, paper, repos, datasets, images). Never modify raw files.
- `Clippings/` — Web-Artikel via Obsidian Web Clipper. Behandle wie `raw/` (nicht manuell editieren). Werden in die Wiki injiziert.
- `wiki/` — Compiled knowledge base. **This is where you write.** Entry point: `wiki/index.md`
  - `themen/` — Topical articles
  - `konzepte/` — Term/concept definitions
  - `personen/` — People and authors
  - `projekte/` — Projects and repositories
  - `quellen/` — Source registry linking back to `raw/`
- `output/` — Generated deliverables (Marp slides, matplotlib plots, reports, canvas)

## Content Rules

- Every `.md` file must have YAML frontmatter: `title`, `created` (YYYY-MM-DD), `type`, optional `tags`
- Use Obsidian wikilinks `[[Page Name]]` for internal cross-references
- Extend existing pages when new info arrives — do not create duplicates
- Keep all index files (`*-Index.md`) updated when adding/removing pages
- Update the "Letzte Aktualisierungen" table and statistics in `wiki/index.md` after changes
- Language: German for content, English for code/technical identifiers

## Workflow: Ingesting a New Source

Quellen: `raw/`-Dateien oder `Clippings/`-Artikel (Web Clipper).

1. Place raw material in appropriate `raw/` subdirectory (oder nutze vorhandene Clippings)
2. Create or update a source entry in `wiki/quellen/`
3. Extract key concepts → create/update pages in `wiki/konzepte/`
4. Create or extend topical articles in `wiki/themen/`
5. Link people to `wiki/personen/`, projects to `wiki/projekte/`
6. Referenzierte Bilder lokal speichern und Pfade anpassen
7. Update all relevant index files

## Workflow: Answering Questions

1. Search wiki pages first, raw sources second, Clippings third
2. Synthesize answer from found material
3. **Ergebnisse immer zurueck ins Wiki schreiben** als neue oder aktualisierte Seiten
4. Generierte Outputs (Reports, Slides, Canvas) koennen zurueck ins Wiki "gefiled" werden um die Wissensbasis zu erweitern

## Output Generation

- Presentations: Marp format (YAML front matter with `marp: true`) → `output/slides/`
- Plots: matplotlib/Python → `output/plots/`
- Reports: Markdown → `output/reports/`
- Canvas: JSON Canvas (`.canvas`) fuer visuelle Wissensvernetzung → `output/canvas/`

## Persönliches Tracking (nicht im Wiki)

- `TODOS.md` — Aufgabenliste mit Zeitstempeln. Claude liest, bearbeitet (abhaken, verschieben), und erinnert per /loop.
- `PROJEKTE.md` — Projektübersicht mit Status und Log. Claude pflegt den Status und loggt Fortschritte.
- Beide Dateien sind in `.gitignore` und werden NICHT auf der Website angezeigt.
- Wenn der User fragt "was steht an?" oder "woran arbeite ich?" → diese Dateien lesen.
- Abgeschlossene Items: Checkbox setzen `[x]`, Zeitstempel ergänzen, in "Erledigt"-Sektion verschieben.

## Health Checks

Periodically check for:
- Duplicate pages, broken wikilinks, weakly linked orphan pages
- Contradictory or inkonsistente Daten
- Fehlende Daten die via Web-Recherche ergaenzt werden koennten
- Interessante Verbindungen zwischen Themen fuer neue Artikel vorschlagen
- Weitere Fragen zum Untersuchen empfehlen
