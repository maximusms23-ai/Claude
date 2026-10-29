---
title: "ADR-001: Smart Connections Privacy-Incident + UI-Exclude statt .scignore"
created: 2026-04-10
type: adr
status: accepted
tags: [adr, privacy, obsidian, smart-connections, v1.4]
---

# ADR-001: Smart Connections Privacy-Incident + UI-Exclude statt `.scignore`

**Status:** Accepted
**Date:** 2026-04-10
**Milestone:** v1.4 (Phase 29-Hotfix)
**Deciders:** Maxim, Tom

## Context

Phase 29 (`v1.4`) hat das Obsidian-Community-Plugin **Smart Connections** v4.3.0 installiert und die Privacy-Exclude-Strategie über eine `.scignore`-Datei im Vault-Root implementiert (OBPL-04). Die `.scignore` listet alle persönlichen Ordner (`10_Personen`, `20_Dokumente`, `40_Aufgaben`, `50_Gesundheit`, `60_Finanzen`, `70_Hardware`, `80_Social_Media`, `95_Gehirn/daily`, `Archiv`, `raw`, `Clippings`, `99_Vorlagen`) explizit aus. Nur `90_Wiki/` und `95_Gehirn/knowledge/` sollten indiziert werden.

Nach Maxim's Plugin-Aktivierung in Obsidian UI (2026-04-10) wurde beim Initial-Index festgestellt, dass **`.scignore` vom Plugin nicht respektiert wurde**. Alle 56 persönlichen Files landeten als `.ajson`-Embeddings in `$TOM_VAULT/.smart-env/multi/`:

```
10_Personen_Eltern_Nina-Schmidt_md.ajson         (43.6K)
10_Personen_Eltern_Waldemar-Schmidt_md.ajson     (44.4K)
10_Personen_Familie_Maxim-Schmidt_md.ajson       (34.1K)
20_Dokumente_01_Arbeitgeber_Arbeitsamt_md.ajson  (20.6K)
20_Dokumente_13_Betreuung_md.ajson               (23.1K)
30_Projekte_Tom_md.ajson                         (63.4K)
40_Aufgaben_TODOS_md.ajson                       (15.9K)
95_Gehirn_daily_2026-04-10_md.ajson              (229.2K)
... (insgesamt 56 Files)
```

**Impact:** Die Embeddings blieben zwar **lokal** auf Maxim's Mac (kein Cloud-Leak), aber sie widersprechen dem Privacy-Ausschluss-Versprechen von OBPL-04. Hätte Tom OBPL-04 als `[x]` markiert und den Milestone geschlossen, wäre das faktisch unehrlich gewesen.

## Decision

1. **Privacy-Leak sofort fixen** (Phase 29-Hotfix, noch im Milestone v1.4):
   - Alle persönlichen `.ajson`-Files aus `.smart-env/multi/` löschen
   - Nur `90_Wiki_*` und `95_Gehirn_knowledge_*` Files behalten

2. **Exclude-Liste im Plugin-UI setzen** statt in `.scignore`:
   - `Settings → Smart Connections → Excluded Folders`
   - 17 Einträge (siehe `smart-connections.json` → `excluded_folders_ui_list`)
   - Maxim macht UI-Eingabe, Tom dokumentiert die Liste

3. **`.scignore` bleibt erhalten** als Referenz-Dokumentation:
   - Header-Kommentar macht klar: "NICHT wirksam für Smart Connections v4.3, nur Referenz"
   - Blueprint für die UI-Eingabe
   - Falls eine künftige Plugin-Version `.scignore` doch liest, ist die Liste bereits korrekt

4. **Neue Requirements in v1.4:**
   - **OBPL-06**: `.smart-env/multi/` enthält keine Files aus persönlichen Ordnern
   - **OBPL-07**: Exclude-Liste dokumentiert im Config-Backup mit dem tatsächlich wirksamen Mechanismus

## Consequences

### Positive
- Privacy-Versprechen ist vor Milestone-Close eingelöst (keine unehrlichen `[x]`-Markierungen)
- Lessons-Learned dokumentiert für künftige Plugin-Installations: immer erst prüfen WIE ein Plugin Exclude-Listen liest
- Config-Backup (`smart-connections.json`) ist jetzt realitätsnäher und reproducibility-fähig

### Negative
- `.scignore` ist "tote" Doku — kann verwirren wenn jemand sie liest ohne Header zu verstehen (Mitigation: Warning-Header oben in der Datei)
- Exclude-Liste muss per UI gesetzt werden — nicht deklarativ seed-bar aus einer Config-Datei. Bei Vault-Restore oder Plugin-Reinstall ist manueller Aufwand nötig (Mitigation: `activation_steps` in `smart-connections.json` dokumentiert jeden Klick)
- Wenn Plugin-Update das Setting-Schema ändert, muss die Liste neu gesetzt werden

### Neutral
- `data.json` des Plugins wird von Smart Connections selbst geschrieben — wir seeden sie nicht direkt, weil Schema nicht stabil ist
- `.scignore` bleibt technisch im Vault; keine Müll-Datei, nur umfunktioniert zu Dokumentation

## Alternatives Considered

1. **`.scignore` debuggen / Plugin-Issue filen**
   - Ziel: Plugin-Autor überzeugen, `.scignore` zu respektieren
   - Abgelehnt: Zeitaufwand, unklares ETA, Milestone-Close würde warten

2. **`data.json` direkt seeden**
   - Ziel: Config via `.obsidian/plugins/smart-connections/data.json` setzen
   - Abgelehnt: Schema ist nicht dokumentiert, wechselt zwischen Plugin-Versionen, Obsidian validiert Settings beim Laden und verwirft stillschweigend falsche Werte (siehe VERIFICATION.md Phase 29 "Why Not Fully Autonomous")

3. **Plugin komplett ausmustern, Copilot nutzen**
   - Ziel: Fallback auf `obsidian-copilot` mit Ollama-Backend
   - Abgelehnt: Smart Connections funktioniert grundsätzlich, nur die Exclude-Methode war falsch. Plugin-Wechsel wäre Overkill für einen Config-Bug. Copilot bleibt als dokumentierte Alternative in `smart-connections.json.fallback_plugin_if_smart_connections_unusable`.

4. **Persönliche Ordner auf File-System-Ebene maskieren** (z.B. via `.obsidian`-Exclude)
   - Abgelehnt: würde Obsidian selbst die Ordner verstecken, nicht nur vor Smart Connections

## Verification

```bash
# Nach Cache-Clean (sofort)
ls "$TOM_VAULT/.smart-env/multi/" | wc -l                                  # 25
ls "$TOM_VAULT/.smart-env/multi/" | grep -vE "^(90_Wiki|95_Gehirn_knowledge)" | wc -l  # 0

# Nach Maxim's Re-Index (pending)
ls "$TOM_VAULT/.smart-env/multi/" | grep -vE "^(90_Wiki|95_Gehirn_knowledge)" | wc -l  # MUSS 0 bleiben
```

## References

- `.planning/phases/29-smart-connections/VERIFICATION.md` → Hotfix-Addendum
- `.planning/obsidian-plugin-config/smart-connections.json` → `lessons_learned` + `excluded_folders_ui_list`
- `$TOM_VAULT/.scignore` → Header-Warning
- `.planning/REQUIREMENTS.md` → OBPL-06, OBPL-07
