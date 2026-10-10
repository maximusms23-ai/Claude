---
description: Indexseiten und Statistiken mit dem Dateibestand abgleichen
---

Ziehe die Navigationsebene der Wissensbasis nach.

Starte den Agenten `wiki-index`. Er gleicht die fuenf `*-Index.md` und die Statistiken in `Obsidian/wiki/index.md` mit dem tatsaechlichen Dateibestand ab.

Pruefe das Ergebnis danach mit `python3 scripts/wiki_check.py` — es darf anschliessend keine Index-Drift- und keine Statistik-Warnung mehr geben.
