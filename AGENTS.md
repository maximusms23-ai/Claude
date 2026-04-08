# AGENTS.md

Arbeitsanweisungen fuer Codex in diesem Workspace.

## Zweck

- Wir pflegen gemeinsam eine Obsidian-Wissensbasis in `Obsidian/`.
- Codex arbeitet proaktiv: Inhalte erweitern, verlinken, konsolidieren und aktuell halten.
- Ziel ist eine strukturierte, konsistente und durchsuchbare Wissensbasis.

## Geltungsbereich

- Hauptarbeitsbereich: `Obsidian/wiki/` und `Obsidian/output/`
- Nicht manuell bearbeiten: `Obsidian/raw/` und `Obsidian/Clippings/`

## Inhaltsregeln fuer Wiki-Seiten

- Jede neue `.md`-Seite enthaelt YAML-Frontmatter mit mindestens:
  - `title`
  - `created` (Format `YYYY-MM-DD`)
  - `type`
  - optional `tags`
- Sprache fuer Inhalte: Deutsch
- Technische Bezeichner (Code, API, Klassen, Libraries): Englisch
- Interne Verlinkung ueber Obsidian-Wikilinks wie `[[Seitenname]]`
- Keine doppelten Seiten anlegen; bestehende Seiten bevorzugt erweitern

## Pflicht-Updates bei inhaltlichen Aenderungen

- Relevante Indexseiten aktualisieren:
  - `Obsidian/wiki/themen/Themen-Index.md`
  - `Obsidian/wiki/konzepte/Konzepte-Index.md`
  - `Obsidian/wiki/personen/Personen-Index.md`
  - `Obsidian/wiki/projekte/Projekte-Index.md`
  - `Obsidian/wiki/quellen/Quellen-Index.md`
- `Obsidian/wiki/index.md` aktualisieren:
  - Tabelle "Letzte Aktualisierungen"
  - Statistiken

## Workflow: Neue Quelle einarbeiten

1. Quelle in `wiki/quellen/` erfassen oder aktualisieren
2. Zentrale Begriffe in `wiki/konzepte/` anlegen/erweitern
3. Themenartikel in `wiki/themen/` anlegen/erweitern
4. Beteiligte Personen in `wiki/personen/` und Projekte in `wiki/projekte/` verknuepfen
5. Relevante Indexseiten + `wiki/index.md` nachziehen

## Workflow: Fragen beantworten

1. Zuerst in `wiki/` suchen, danach in `raw/`, dann in `Clippings/`
2. Antwort aus vorhandenen Quellen synthetisieren
3. Erkenntnisse dauerhaft in die Wissensbasis zurueckschreiben

## Qualitaets-Checks

- Duplikate vermeiden
- Wikilinks auf Gueltigkeit pruefen
- Inkonsistenzen markieren und korrigieren
- Schwach vernetzte Seiten mit sinnvollen Links anreichern
- Bei Bedarf neue, hilfreiche Themenvorschlaege machen

## Zusammenarbeit

- Bei Unklarheit zuerst sinnvolle Annahmen treffen und transparent nennen
- Bei irreversiblen oder riskanten Schritten kurz Ruecksprache halten
- Keine destruktiven Aktionen ohne explizite Freigabe
