---
title: "ADR-004: mcp-tools als v1.5-Integrationskandidat"
created: 2026-04-10
type: adr
status: deferred
tags: [adr, obsidian, mcp, v1.4.1, v1.5-candidate]
---

# ADR-004: `mcp-tools` als v1.5-Integrationskandidat

**Status:** Deferred (v1.5 Kandidat)
**Date:** 2026-04-10
**Milestone:** v1.4.1 (Phase 34 — Plugin-Audit)
**Deciders:** Maxim, Tom

## Context

Im v1.4.1-Plugin-Audit wurde `mcp-tools` v0.2.27 (Jack Steam) als eines der 17 neuen Plugins erfasst. Plugin-Beschreibung:

> Securely connect Claude Desktop to your vault with semantic search, templates, and file management capabilities.

Das Plugin implementiert das **Model Context Protocol (MCP)** in Obsidian. MCP ist ein offenes Protokoll (seit Ende 2024), über das LLM-Clients (Claude Desktop, Claude Code, Cursor etc.) auf externe Tools zugreifen können — u.a. Semantic Search im Vault, Template-Expansion und File-Management.

**Warum relevant für Tom:**
Tom hat mehrere CLI-Tools (`tom-doc`, `tom-wiki`, `tom-ask`, `tom-clip-enrich`, `tom-lint`), die aktuell nur vom Terminal aus oder über den Claude-Code-Hook nutzbar sind. Wenn `mcp-tools` einen MCP-Server bereitstellt, der diese Tools als MCP-Tools exposed, wären sie direkt in Obsidian verfügbar — z.B. als Palette-Commands, Template-Variablen oder Inline-Aufrufe. Das würde Tom's Ad-hoc-Nutzung im Vault massiv vereinfachen.

## Decision

**Für v1.4.1: Nur Dokumentation, keine Integration.**

1. Plugin bleibt installed-but-unused im Vault (Files liegen in `.obsidian/plugins/mcp-tools/`).
2. ADR-004 dokumentiert den Integrations-Kandidat-Status.
3. Echte Integration bekommt eine **eigene v1.5-Phase** mit mindestens:
   - Recherche des MCP-Server-Schemas (Plugin-Dokumentation + Upstream-MCP-Spec)
   - Entscheidung welche Tom-CLI-Tools als MCP-Tools exposed werden
   - Privacy-Check: welche Vault-Bereiche darf der MCP-Server lesen/schreiben?
   - Config-Backup + Setup-Dokumentation analog zu Smart Connections (`smart-connections.json`)
   - Koexistenz-Entscheidung mit Smart Connections (beide nutzen Vault-Inhalte)
   - Smoke-Test mit 1 Tom-Tool (wahrscheinlich `tom-doc search`)

## Rationale

- **MCP ist jung** (Ende 2024). Upstream-Spec und Plugin-Qualität noch im Fluss — Integration in v1.4.1-Bridge wäre Überscope.
- **Integration braucht Phase**, nicht Commit: MCP-Server exposed Tools, d.h. Tom-CLI-Wrapper müssen ggf. MCP-kompatible Schnittstellen bekommen. Nicht mit einem PR gemacht.
- **Privacy-kritisch**: MCP-Clients können Text aus dem Vault an Remote-LLMs schicken. Ohne klare Exclude-Liste (wie Smart Connections UI-Exclude) ist das Privacy-Leak-Risiko hoch.
- **v1.4.1-Scope sauber halten**: Die drei Bridge-Phasen (Doku-Routine, Plugin-Audit, Clipper-Templates) sind bewusst klein. mcp-tools-Integration wäre eine eigene Major-Phase.

## Alternatives Considered

1. **Sofortige Aktivierung ohne Tom-Tool-Integration**: Plugin aktivieren mit Default-Config, keine Tom-CLI-Anbindung. → Verworfen, weil der Plugin-Wert ohne Tom-Tools marginal ist (nur Semantic Search, die Smart Connections schon liefert).
2. **Skip vollständig, Plugin deinstallieren**: Verworfen, weil das Plugin als Integrations-Kandidat dokumentiert bleiben soll und die Dateien in `.obsidian/plugins/mcp-tools/` nicht stören.
3. **Komplette Integration in v1.4.1**: Verworfen wegen Scope + Privacy + Zeit.

## Consequences

- `mcp-tools` bleibt in v1.4.1 passiv. Kein Setup, keine Config-Backup-Datei (`.planning/obsidian-plugin-config/mcp-tools.json` wird erst in der v1.5-Integrationsphase erstellt).
- v1.5-Roadmap muss eine **Phase "mcp-tools Integration"** enthalten mit den 6 Arbeitsschritten aus der Decision.
- Die zwei Ad-hoc-Wege, Tom aus Obsidian heraus zu triggern (`open-in-terminal`-Plugin + CLI, oder Smart Connections Panel), bleiben bis v1.5 die empfohlenen.
- Wenn Maxim vor v1.5 aktiv in `mcp-tools` klickt und es konfiguriert, sollte Tom das als neuen Input für die v1.5-Phase nehmen (Lessons Learned aus User-Exploration).

## References

- [Model Context Protocol Spec](https://modelcontextprotocol.io/) (offen seit Ende 2024)
- CLAUDE.md "Obsidian Plugin Landscape" (Empfehlung-Box in v1.4.1-Update)
- `plugin-audit-v1.4.1.md` Zeile 10
- Smart Connections ADR-001 (Muster für Plugin-Integration mit Privacy-Check)
