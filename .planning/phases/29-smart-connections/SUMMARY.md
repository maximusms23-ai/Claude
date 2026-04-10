# Phase 29 Summary

**Gemma-in-Obsidian via Smart Connections** — v1.4 Phase 29

## What Shipped (autonomous)

- **Smart Connections v4.3.0 Plugin-Files** in `$TOM_VAULT/.obsidian/plugins/smart-connections/` (main.js 1.2MB, manifest.json, styles.css)
- **Plugin registriert** in `.obsidian/community-plugins.json`
- **`.scignore`** im Vault-Root mit Privacy-Exclude für alle persönlichen Ordner (10_–80_, raw, Clippings, Archiv, Vorlagen, 95_Gehirn/daily) — nur `90_Wiki/` + `95_Gehirn/knowledge/concepts+connections/` bleiben indizierbar
- **Config-Backup + Activation-Steps** in `.planning/obsidian-plugin-config/smart-connections.json` — komplette Schritt-für-Schritt-Anleitung für Maxim + Fallback-Plugin Copilot dokumentiert
- **CLAUDE.md Wissens-Kaskade** um Punkt 6 erweitert: "Ad-hoc im Editor → Smart Connections Panel"

## What Needs Maxim's Hand (UI-Handoff)

- Plugin-Toggle in Obsidian Settings → Community Plugins
- Ollama-Backend konfigurieren (Embed: `nomic-embed-text`, Chat: `gemme`)
- Initial-Indexing abwarten
- Smoke-Test Query "TurboQuant"

**Schritte dokumentiert** in `.planning/obsidian-plugin-config/smart-connections.json` → `activation_steps`.

## Requirements

- **OBPL-02, 04, 05** ✓ (3/5) — autonom abgeschlossen
- **OBPL-01, 03** ~ — Files installiert, Aktivierung/Smoke-Test nach Maxim-UI-Handoff

## Key Decisions

- **Kein automatisches data.json-Seeding**: Obsidian-Plugin-Settings-Schema ist nicht stabil zwischen Versionen. Manueller UI-Setup (2 min) statt stundenlanges Reverse-Engineering mit Drift-Risiko.
- **`.scignore` statt Plugin-interne Exclude-Liste**: Smart Connections unterstützt beides, aber `.scignore` ist Plugin-unabhängig und überlebt Plugin-Updates. Auch nutzbar von Copilot als Fallback.
- **Plugin v4.3.0 statt Latest-Tracking**: Explizite Version im Config-Backup für Reproducibility bei Vault-Restore.
- **Fallback Copilot dokumentiert**: Wenn Smart Connections UX schlecht ist, kann Maxim parallel Copilot installieren ohne Config-Konflikt.

## Risiko Mitigation

- **Plugin-Versions-Drift**: Config-Backup hält v4.3.0 fest. Spätere Updates erfordern ggf. neue Doku.
- **Ollama nicht erreichbar**: Plugin zeigt bei Aktivierung Fehler — Maxim kann `ollama serve` starten, kein Datenverlust.
- **Initial-Index langsam**: Bei <100 Files (aktuell) sollte Indexing in <1 min durch sein. Skaliert auch auf 500 Files gut.

## Next Up

**Phase 31: Token-Spar-Lokalisierung** — `tom-compile --local` + Eval-Vergleich + `tom-lint --structural-only` als launchd-Default.
