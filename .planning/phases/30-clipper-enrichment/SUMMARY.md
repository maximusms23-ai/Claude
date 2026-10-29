# Phase 30 Summary

**Clipper Auto-Enrichment** — v1.4 Phase 30

## What Shipped

- `claude-memory-compiler/tom_tools/clip_enrich.py` — Enrichment-Modul mit minimalem Frontmatter-Parser (kein PyYAML-Dep), gemme-Call im JSON-Format, Konzept-Queue-Writer
- `bin/tom-clip-enrich` — Bash-Wrapper nach tom-wiki-Pattern (uv run)
- `~/bin/tom-clip-enrich` Symlink
- `$TOM_VAULT/90_Wiki/konzepte-vorschlaege.md` — Review-Queue für vorgeschlagene Konzepte (wird bei erster Nutzung angelegt)

## Requirements Complete

- **CLIP-01..05, 07, 08** ✓ (7/8)
- **CLIP-06** deferred → v1.5 (`--watch` optional, CLI reicht für v1.4)

## Key Decisions

- **Minimaler Frontmatter-Parser statt PyYAML**: 40 Zeilen Code, handles flat keys + lists, preserves key order. Weniger Dependencies, weniger Bugs.
- **gemme mit `format="json"`**: Strukturierte Ausgabe, kein fragiles Regex-Parsen, temperature=0.3 für Konsistenz.
- **Konzepte in Review-Queue statt Auto-Stubs**: Maxim hat explizit Review-Schleife gewünscht. `konzepte-vorschlaege.md` als Sammelstelle mit Backlinks zu den Quell-Clippings.
- **On-demand statt Hook**: Clipper-Enrichment ist opportunistisch, tom-compile ist täglich — zeitliche Kopplung bringt keinen Mehrwert. launchd-Integration bleibt für v1.5 offen.
- **Link/Footnote-Stripping vor LLM**: Obsidian-Markdown ist voller `[text](url)` und `[^fn]` — das nervt gemme und verbraucht Kontext. Preview-Cleanup gibt 6000 klare Zeichen statt 6000 mit Noise.
- **Tag-Merge case-insensitive**: Verhindert `Mannheim` + `mannheim` Duplikate beim Re-Run.

## Smoke-Test

Mannheim-Wikipedia-Clipping (236 KB, deutschsprachiger Wikipedia-Artikel):
- Summary: 4-sätzige präzise Zusammenfassung
- 5 neue Tags: `badenwürttemberg`, `mannheim`, `universitätsstadt`, `rhein-neckar`, `quadratestadt`
- 4 Konzepte: `Metropolregion Rhein-Neckar`, `Quadratestadt`, `Kurpfalz`, `UNESCO City of Music`
- Kategorie: `themen`
- Zweiter Lauf: skip (idempotent)

**Keine Halluzinationen** — alle Enrichment-Felder im Text belegbar.

## Next Up

**Phase 29: Smart Connections** (parallel — jetzt dran) und danach **Phase 31: Token-Spar-Lokalisierung**.
