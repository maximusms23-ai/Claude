---
title: "ADR-002: Obsidian Git installed-but-unused, Vault-in-git-Entscheidung auf v1.5/v1.6 vertagt"
created: 2026-04-10
type: adr
status: deferred
tags: [adr, git, obsidian, backup, v1.4, deferred]
---

# ADR-002: Obsidian Git installed-but-unused, Vault-in-git-Entscheidung auf v1.5/v1.6 vertagt

**Status:** Deferred (accepted as "do-not-configure for v1.4")
**Date:** 2026-04-10
**Milestone:** v1.4 (Phase 32 Close)
**Deciders:** Maxim, Tom

## Context

Maxim hat im v1.4-Zeitraum 33 Community-Plugins in Obsidian installiert, darunter **`obsidian-git`** (`denolehov/obsidian-git`). Das Plugin kann Obsidian-Vaults als Git-Repositories verwalten — automatische Commits, Push/Pull, Merge-Konflikt-Handling.

Der aktuelle Zustand von Tom's Vault (`$TOM_VAULT` = `Obsidian_Zentralw/`):
- **NICHT in git** — bewusste Entscheidung seit v1.1 (siehe `CLAUDE.md` "Vault-Pfad")
- Backup via **iCloud Sync** + **Time Machine** (2 unabhängige Kanäle)
- Grund: `$TOM_VAULT` enthält PII (10_Personen, 20_Dokumente, 50_Gesundheit, 60_Finanzen). Ein öffentliches oder auch nur falsch konfiguriertes Git-Remote wäre ein massiver Privacy-Leak

Die Installation des Plugins wirft die Frage auf: **Soll der Vault (oder Teile davon) in git versioniert werden?**

Mögliche Motivationen für ein "ja":
- Feingranulare History statt Time-Machine-Snapshots
- Diff-Views für Notizen (inkrementelle Änderungen)
- Cross-device-Sync via privater Remote (z.B. Gitea auf einem Maxim-eigenen Server) als zusätzlicher Backup-Kanal
- Rollback auf File-Ebene

Mögliche Motivationen für ein "nein":
- PII-Risiko bei Fehlkonfiguration des Remote (z.B. versehentlich public repo)
- Git-Binaries (Embeddings in `.smart-env/`, große PDFs in `raw/`) blähen Repo-Größe auf
- iCloud-Sync reicht für Cross-device; Time Machine reicht für History
- Zusätzliche Komplexität (Merge-Konflikte in Markdown, gitignore-Pflege)

## Decision

**Für v1.4: Plugin ist installed-but-unused.**

- `obsidian-git` bleibt in `.obsidian/plugins/` installiert (Maxim hat es aktiv)
- Es wird für v1.4 **nicht konfiguriert** (kein Repository initialisiert, kein Remote gesetzt, kein Auto-Commit aktiv)
- Die Vault-in-git-Frage ist **eigenständige Entscheidung**, nicht Quick-Add zu v1.4 Close
- Entscheidung wird in **v1.5 oder v1.6** getroffen, wenn Maxim konkrete Anforderungen hat (z.B. Cross-device-Sync-Probleme mit iCloud, Wunsch nach Diff-History, etc.)

## Consequences

### Positive
- Kein Privacy-Risiko in v1.4 durch falsch konfiguriertes Git-Remote
- Time für eine gründliche Entscheidung in v1.5/v1.6 (Remote-Wahl, Scope, Gitignore-Strategie, Repo-Größe)
- Plugin ist bereits vorbereitet, falls Maxim später aktivieren will — keine Neuinstall nötig

### Negative
- Plugin-Inventar wirkt "inkonsistent" (installiert, aber ungenutzt). Mitigation: In `CLAUDE.md` "Obsidian Plugin Landscape"-Sektion unter "Tom-relevant — deferred" ausweisen

### Neutral
- Time Machine + iCloud bleiben die Primary-Backup-Kanäle — wie bisher seit v1.1

## Bedingungen für Re-Evaluation in v1.5/v1.6

Re-Open ADR wenn eine der folgenden Bedingungen eintritt:
1. **iCloud-Sync-Problem**: Wiederholter Verlust oder Konflikt zwischen Devices, den iCloud nicht auflösen kann
2. **Time-Machine-Lücke**: Time Machine ist nicht verfügbar (z.B. Hardware-Wechsel ohne TM-Restore)
3. **Diff-Anforderung**: Maxim braucht file-level History mit Diff-Views, die Time-Machine nicht bietet
4. **Cross-device-Wunsch**: Sync auf ein zweites Gerät (Handy, anderer Mac) mit einem zusätzlichen unabhängigen Kanal

## Empfehlung für v1.5/v1.6 (nicht bindend)

Wenn Vault-in-git doch kommt:
- **Nur sekundäres Backup** (nicht Primary — iCloud bleibt Primary)
- **Scope**: NUR `90_Wiki/` + `95_Gehirn/knowledge/` (analog zu `.scignore`-Strategie aus ADR-001). Persönliche Ordner NIEMALS in git
- **Remote**: Privates Gitea oder Forgejo auf Maxim-eigenem Server, NIE GitHub/GitLab public
- **Gitignore**: `.smart-env/`, `.obsidian/workspace*`, `output/`, `raw/`, `Clippings/`, `Archiv/`, `10_Personen/`, `20_Dokumente/`, `30_Projekte/`, `40_Aufgaben/`, `50_Gesundheit/`, `60_Finanzen/`, `70_Hardware/`, `80_Social_Media/`, `95_Gehirn/daily/`, `95_Gehirn/reports/`, `95_Gehirn/qa/`, `00_Inbox/`, `99_Vorlagen/`, `CLAUDE.md`, `log.md`
- **Commit-Kadenz**: Auto-commit täglich, manuelle Push-Entscheidung

## Alternatives Considered (für v1.4)

1. **Jetzt in v1.4 aktivieren, full vault**
   - Abgelehnt: Privacy-Risiko zu hoch, keine Ablage-Entscheidung, kein Remote-Plan

2. **Jetzt in v1.4 aktivieren, nur 90_Wiki/**
   - Abgelehnt: Scope der Entscheidung größer als "ein Feature" — braucht ADR mit Remote-Plan, Gitignore-Strategie, Commit-Kadenz. Nicht mehr Quick-Add

3. **Plugin deinstallieren**
   - Abgelehnt: Maxim hat es bewusst installiert; Deinstall wäre Over-Step. Installed-but-unused ist sauberer

## References

- `/Users/maxim/Claude/CLAUDE.md` → "Vault-Pfad (Single Source of Truth seit v1.1)" — iCloud + Time Machine als Backup
- `/Users/maxim/Claude/CLAUDE.md` → "Obsidian Plugin Landscape" (neue Sektion in v1.4)
- `.planning/briefings/v1.4-CEO-Briefing.md` → Teil 7 "Vault-Infrastructure-Expansion"
