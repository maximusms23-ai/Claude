# Phase 34 Summary

**Plugin-Audit + Setup der 17 neuen Plugins** — v1.4.1 Phase 34

## What Shipped

- **`plugin-audit-v1.4.1.md`** — Vollständige 17-Plugin-Tabelle mit manifest-Metadaten (Name, Version, Autor, Description), 4-Klassen-Klassifikation (★/~/·/⚠), Tom-Touchpoint-Notizen und Summary-Block
- **ADR-003** — `obsidian-ocr` Koexistenz mit `tom-doc`: Schreibgrenze, Rollen-Teilung, Status-Check
- **ADR-004** — `mcp-tools` als v1.5-Integrationskandidat: 6 Arbeitsschritte für echte Integration dokumentiert, explizit NICHT in v1.4.1
- **Config-Backup-Stubs** für 2 Setup-Kandidaten (`eml-reader`, `obsidian-apple-reminders-plugin`) nach `smart-connections.json`-Pattern — Status `prepared-pending-maxim-activation`
- **`CLAUDE.md` Plugin Landscape** auf 52 Plugins erweitert:
  - Tom-relevant Tabelle um 4 v1.4.1-Einträge ergänzt (`eml-reader`, `obsidian-apple-reminders-plugin`, `mcp-tools`, `marker-api`)
  - Neue Kategorie "LLM-Alternativen (installed-but-unused)" mit 6 Plugins
  - Neue Kategorie "Email / Messaging"
  - Neue Warning-Box `obsidian-ocr vs tom-doc`
  - Neue Empfehlungs-Box `mcp-tools`
  - Referenzen um ADR-003, ADR-004, plugin-audit-v1.4.1.md erweitert

## Requirements Complete

OBPL141-01..05 ✓ (5/5)

## Key Decisions

- **Keine Plugin-Aktivierungen in Phase 34**: Tom respektiert das UI-Handoff-Prinzip aus ADR-001. Aktivierung ist Maxim-Only via Obsidian-UI. Phase 34 liefert Analyse + Config-Stubs, nicht automatische data.json-Seedung.
- **Setup-Kandidaten-Konsolidierung**: Von 17 neuen Plugins bleiben genau 2 als Setup-Kandidaten übrig (`eml-reader` ohne Vorbedingung, `obsidian-apple-reminders-plugin` nur wenn Maxim Reminders nutzt). Die restlichen 15 teilen sich in LLM-Alternativen (bleiben installed-but-unused), orthogonale Convenience (risikofrei, kein Setup), und v1.5-Kandidaten (`mcp-tools`, `marker-api`).
- **`marker-api` kein eigenes ADR**: Nur als v1.5+-Upgrade-Kandidat in CLAUDE.md notiert. Kein ADR, weil keine architektonische Entscheidung fällt — es ist ein zukünftiger Backend-Swap in `tom-doc`, keine neue Integration.
- **Gesamtzahl 52 statt 53**: Plan sprach von "53 Plugins auf CLAUDE.md", tatsächliches `ls .obsidian/plugins/` zeigt 52. CLAUDE.md reflektiert die reale Zahl.

## Not Shipped

- **Echte Plugin-Aktivierung in Obsidian UI** → Maxim-Handoff (5 offene Fragen in plugin-audit-v1.4.1.md)
- **`mcp-tools` Integration** → eigene v1.5-Phase (ADR-004)
- **`marker-api` Backend-Swap** → v1.5+ Kandidat
- **`messager`/`taskrobin` mit Accounts** → v1.5 Email-Workflow-Phase

## Commit

`docs(phase-34): v1.4.1 Phase 34 — Plugin-Audit + ADR-003/004 + CLAUDE.md-Update`

## Next Up

**Phase 35 — Web-Clipper-Templates** (letzte v1.4.1-Phase). 7 typ-spezifische Clipper-Templates + Ziel-Ordner + Browser-Extension-Konfig-Doku + Smoke-Test mit Maxim.
