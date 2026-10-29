# Phase 17: Karpathy-Index für 90_Wiki - Context

**Gathered:** 2026-04-10
**Status:** Complete

<domain>
`90_Wiki/index.md` ist von Changelog-Stil auf Karpathy-Retrieval-Stil umgestellt; der alte Changelog lebt in `history.md` weiter.
</domain>

<decisions>
### Gruppierung
Gruppen 1:1 aus Ordnerstruktur: Konzepte, Themen, Projekte, Quellen, Personen, Meta & Werkzeuge. Plus Meta-Links auf Index-Dateien je Kategorie.

### Beschreibungslänge
1–2 Zeilen pro Artikel — gerade genug Kontext für LLM-Routing, aber nicht so viel dass der Index selbst zu schwer wird.

### Pflege
Manuell bei jeder neuen Wiki-Seite. `claude-memory-compiler` ist explizit auf `95_Gehirn/` beschränkt und touchet `90_Wiki/index.md` nicht — muss in CLAUDE.md als Pflege-Hinweis stehen.
</decisions>
