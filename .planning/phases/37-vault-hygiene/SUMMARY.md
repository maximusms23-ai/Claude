# Phase 37: Vault-Hygiene & Cleanup — SUMMARY

**Milestone:** v1.5 — Lifecycle + Integration
**Status:** In Progress
**Started:** 2026-04-12

## Ziel

Alle prepared-pending Handoffs aus v1.4/v1.4.1 schließen, Smart Connections reparieren, 6 unused LLM-Plugins disablen, eml-reader und apple-reminders-plugin konfigurieren, OLLAMA_ORIGINS persistent setzen.

## Erledigte Schritte (programmatisch)

### HYG-02: 6 LLM-Plugins disabled
- `cao`, `tars`, `large-language-models`, `llm-summary`, `llm-test-gen`, `ai-latex-generator` aus `community-plugins.json` entfernt
- 52 → 46 aktive Plugins
- CLAUDE.md Plugin Landscape aktualisiert

### HYG-03: OLLAMA_ORIGINS persistent
- LaunchAgent `~/Library/LaunchAgents/com.maxim.ollama-origins.plist` erstellt
- Setzt `OLLAMA_ORIGINS=chrome-extension://*,moz-extension://*,safari-web-extension://*` bei Login
- Verifiziert: `launchctl getenv OLLAMA_ORIGINS` liefert korrekten Wert

### HYG-06: Plugin-Audit Q1–Q5 beantwortet
- Q1 (Apple Reminders): Ja, aktivieren — AppleScript-basiert, v2.0.0 stabil
- Q2 (eml-reader): Ja, aktivieren — reiner lokaler Preview, kein Privacy-Risiko
- Q3 (TaskRobin): Nein, eml-reader-only für jetzt — TaskRobin braucht Cloud-Account
- Q4 (LLM-Konsolidierung): Nur Smart Connections bleibt aktiv
- Q5 (marker-api): Deferred nach v1.6+ — pdftotext/ocrmypdf reicht

## Offene Schritte (Maxim-Handoff)

### HYG-01 + HYG-09: Smart Connections Repair
1. Obsidian öffnen
2. Settings → Smart Connections → "Reset Data" klicken
3. Excluded Folders prüfen (17 Einträge aus `smart-connections.json`)
4. Embed Model: Ollama → `nomic-embed-text:latest`
5. Chat Model: Ollama → `qwen2.5:3b`
6. Re-Index abwarten
7. Smoke-Test: "TurboQuant" im Smart Connections Panel suchen → muss `90_Wiki/konzepte/turboquant.md` finden
8. Verifizierung: `ls $TOM_VAULT/.smart-env/multi/` → nur `90_Wiki_*` und `95_Gehirn_knowledge_*` Dateien

### HYG-04: eml-reader Smoke-Test
1. Eine `.eml`-Test-Datei in `$TOM_VAULT/20_Dokumente/13_Betreuung/` ablegen
2. In Obsidian öffnen → Preview sollte Email-Inhalt rendern
3. Falls kein `.eml` vorhanden: aus Mail.app eine beliebige Email als `.eml` exportieren

### HYG-05: Apple Reminders Plugin
1. Obsidian Settings → Apple Reminders → Konfigurieren
2. In einer Test-Note einen Code-Block einfügen: ```reminders\nlist: Reminders\n```
3. Prüfen ob Reminders angezeigt werden
4. Optional: Test-Reminder in Apple Reminders.app erstellen → sollte in Obsidian erscheinen

### HYG-07: Web-Clipper Smoke-Test
1. In Chrome/Safari eine beliebige Webseite clippen mit Obsidian Web Clipper
2. Prüfen ob Frontmatter korrekt ist (title, url, created, type)
3. Prüfen ob Datei in `$TOM_VAULT/Clippings/<Typ>/` gelandet ist

### HYG-08: Interpreter Smoke-Test
1. Beim Clippen "Interpret" Button klicken (vor "Speichern in Obsidian")
2. Prüfen ob `summary`, `tags`, `konzepte_vorschlaege` im Frontmatter stehen
3. Falls Ollama nicht erreichbar → `enriched_by` Feld prüfen

## Recherche-Ergebnisse (2026-04-12)

- Smart Connections: Reset-Data + Re-Index ist der empfohlene Fix (GitHub Issue #20)
- Apple Reminders: `urishiraval/obsidian-apple-reminders-plugin` v2.0.0 AppleScript-basiert, stabil
- LLM-Konsolidierung: Smart Connections als einziges LLM-Plugin, Rest disabled
- qwen3-coder-next als Phase-38 Upgrade-Kandidat identifiziert (80B/3B aktiv, Tool-Calling nativ)
- FastMCP CLI-Wrapper als Phase-39 MCP-Bridge-Architektur identifiziert (`fast-obsidian-mcp` als Referenz)
