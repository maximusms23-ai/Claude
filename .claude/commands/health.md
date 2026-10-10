---
description: Health-Check der Wissensbasis (offene Links, Duplikate, Frontmatter, Index-Drift)
---

Pruefe die Wissensbasis auf Integritaet.

1. Fuehre zuerst `python3 scripts/wiki_check.py` aus — das liefert die maschinell pruefbaren Befunde (Frontmatter, offene Links, Index-Drift, Statistiken).
2. Starte danach den Agenten `wiki-health` fuer das, was ein Skript nicht sieht: Duplikate, inhaltliche Widersprueche, schwach vernetzte Seiten, sinnvolle neue Verknuepfungen.

Offene `[[Links]]` sind keine Fehler, sondern Themenvorschlaege — behandle sie als Material fuer neue Seiten, nicht als Defekt.

Berichte am Ende: behobene Faelle, offene Befunde, und konkrete Vorschlaege zur Entscheidung.
