# Phase 29 Verification

**Phase:** 29 — Gemma-in-Obsidian via Smart Connections
**Milestone:** v1.4
**Date:** 2026-04-10
**Status:** ✓ PASS (mit explizitem Handoff an Maxim für Aktivierung)

## Success Criteria

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| 1 | Plugin-Files vorhanden | `main.js` 1.2MB, `manifest.json` v4.3.0, `styles.css` 18KB | ✓ |
| 2 | `community-plugins.json` enabled | `["obsidian-local-images-plus", "smart-connections"]` | ✓ |
| 3 | `.scignore` mit Privacy-Exclude | 10_–80_, raw, Clippings, Archiv, Vorlagen ausgeschlossen | ✓ |
| 4 | Config-Backup vorhanden | `.planning/obsidian-plugin-config/smart-connections.json` | ✓ |
| 5 | CLAUDE.md Punkt 6 dokumentiert | "Ad-hoc im Editor → Smart Connections Panel" | ✓ |
| 6 | Plugin in UI aktiviert | **⏳ Maxim-Handoff** (muss in Obsidian UI aktiviert werden) | ⏳ |
| 7 | Smoke-Test "TurboQuant" | **⏳ Maxim-Handoff** (braucht aktiviertes Plugin + Initial-Index) | ⏳ |

## Requirements

| Requirement | Status | Evidence |
|-------------|--------|----------|
| OBPL-01 | ~ | Files installiert, Aktivierung braucht Obsidian-UI |
| OBPL-02 | ✓ | `.planning/obsidian-plugin-config/smart-connections.json` |
| OBPL-03 | ⏳ | Smoke-Test pending Maxim-Aktivierung |
| OBPL-04 | ✓ | `.scignore` mit 20+ Ausschluss-Regeln |
| OBPL-05 | ✓ | CLAUDE.md Wissens-Kaskade Punkt 6 |

## Handoff an Maxim — Obsidian UI Schritte

Nach Phase 29 muss Maxim diese Schritte in Obsidian ausführen, damit Plugin live geht:

1. **Obsidian neu starten** (oder Settings → Community Plugins → Reload)
2. **Settings → Community Plugins** — "Smart Connections" sollte in der Liste auftauchen
3. **Plugin aktivieren** (Toggle ON)
4. **Settings → Smart Connections → Embed Model**:
   - Provider: **Ollama**
   - Endpoint: `http://localhost:11434`
   - Model: `nomic-embed-text:latest`
5. **Settings → Smart Connections → Chat Model**:
   - Provider: **Ollama**
   - Model: `gemme:latest`
6. **Initial-Indexing abwarten** — dauert ein paar Minuten für 90_Wiki/ + 95_Gehirn/knowledge/
7. **Smoke-Test:** Command Palette → "Smart Connections: Open Smart View" → Query "TurboQuant"
   - Erwartetes Ergebnis: `90_Wiki/konzepte/turboquant.md` in den Top-Treffern

## Why Not Fully Autonomous

Obsidian-Plugin-Config (`data.json` im Plugin-Folder) ist nicht stabil von außen setzbar:
- Schema wechselt zwischen Plugin-Versionen
- Obsidian validiert Settings beim Laden — falsche Werte werden stillschweigend verworfen
- Plugin muss aktiv laufen damit die Settings-UI die Ollama-Endpoints pingen kann
- Initial-Embedding-Index kann nur aus dem laufenden Plugin heraus angestoßen werden

Manuelle UI-Aktivierung ist **2 Minuten Arbeit**, das Auto-Seeden der data.json wäre **stundenlanges Reverse-Engineering** mit Drift-Risiko bei Plugin-Updates.

## Verification Commands (after Maxim's activation)

```bash
# Plugin aktiv?
cat "$TOM_VAULT/.obsidian/community-plugins.json" | grep smart-connections

# Data.json nach Aktivierung prüfen (Maxim-Config)
ls "$TOM_VAULT/.obsidian/plugins/smart-connections/data.json"

# Index-Dir entstanden?
ls -la "$TOM_VAULT/.smart-env/" 2>&1 || echo "not yet"
```

## Files Changed

- `+ $TOM_VAULT/.obsidian/plugins/smart-connections/{main.js,manifest.json,styles.css}` (outside git)
- `~ $TOM_VAULT/.obsidian/community-plugins.json` (outside git)
- `+ $TOM_VAULT/.scignore` (outside git)
- `+ .planning/obsidian-plugin-config/smart-connections.json`
- `+ .planning/phases/29-smart-connections/{29-01-PLAN,VERIFICATION,SUMMARY}.md`
- `~ CLAUDE.md` (Wissens-Kaskade Punkt 6)
- `~ .planning/REQUIREMENTS.md`

## Status: ✓ AUTONOMER ANTEIL COMPLETE — MAXIM UI-HANDOFF DOKUMENTIERT

---

## Hotfix-Addendum (2026-04-10)

Nach Maxim's Plugin-Aktivierung in Obsidian UI wurde festgestellt, dass Smart Connections v4.3.0 die `.scignore`-Datei **nicht respektiert**. Der Initial-Index hat 56 persönliche Files in `.smart-env/multi/` geschrieben, darunter:
- `10_Personen/*` (Eltern, Familie, Kontakte)
- `20_Dokumente/*` (alle 15 Kategorien)
- `30_Projekte/Tom`, `40_Aufgaben/*`, `50_Gesundheit/*`, `60_Finanzen/*`, `70_Hardware/*`, `80_Social_Media/*`
- `95_Gehirn/daily/*`, `95_Gehirn/CLAUDE.md`, `95_Gehirn/log.md`
- Vault-Root-Files (`CLAUDE.md`, `log.md`, `index.md`)
- `Clippings/*`, `raw/*`, `99_Vorlagen/*`

Dies verletzt OBPL-04 (Privacy-Ausschluss-Versprechen).

### Root-Cause
Smart Connections liest `.scignore` nicht (oder erst nach dem Initial-Index). Die Exclude-Liste muss über die Plugin-UI gesetzt werden: `Settings → Smart Connections → Excluded Folders`.

### Fix (vollständig)
1. ✓ **Cache gelöscht**: 56 persönliche `.ajson` Files aus `.smart-env/multi/` entfernt. Nach Löschung: 25 Files verbleibend, ausschließlich `90_Wiki_*` (24) und `95_Gehirn_knowledge_*` (1).
2. ✓ **Config-Backup aktualisiert**: `.planning/obsidian-plugin-config/smart-connections.json` enthält jetzt `lessons_learned`-Block + `excluded_folders_ui_list` mit 17 Einträgen + erweiterte `activation_steps`.
3. ✓ **`.scignore` mit Warning-Header ergänzt**: Datei bleibt als Referenz-Dokumentation, Header macht klar dass sie vom Plugin nicht gelesen wird.
4. ✓ **ADR-001**: `.planning/obsidian-plugin-config/adr-001-smart-connections-privacy.md` dokumentiert den Incident + Decision.
5. ⏳ **Maxim-Handoff**: Excluded-Folders-Liste im Plugin-UI eintragen, Plugin re-enable, Re-Index abwarten, Smoke-Test `TurboQuant`.

### Verifikation (nach Maxim's Re-Index)
```bash
# Privacy-Check (MUSS 0 zurückgeben)
ls "$TOM_VAULT/.smart-env/multi/" | grep -vE "^(90_Wiki|95_Gehirn_knowledge)" | wc -l
```

Aktueller Stand direkt nach Cache-Clean (vor Re-Index):
```
$ ls .smart-env/multi/ | wc -l
25
$ ls .smart-env/multi/ | grep -vE "^(90_Wiki|95_Gehirn_knowledge)" | wc -l
0
```

### Neue Requirements (tracked in v1.4)
- **OBPL-06** — `.smart-env/multi/` enthält keine Files aus persönlichen Ordnern (✓ cache-clean, ⏳ post-re-index)
- **OBPL-07** — Exclude-Liste dokumentiert im Config-Backup mit dem tatsächlich wirksamen Mechanismus (✓ smart-connections.json v2)

## Status nach Hotfix: ✓ CACHE CLEAN, ✓ DOCS UPDATED — MAXIM UI-RECONFIG PENDING
