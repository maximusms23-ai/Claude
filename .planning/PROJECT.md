# Tom — Persönlicher Lebens-Assistent

## What This Is

Tom ist Maxims persönlicher KI-Assistent auf Basis eines Obsidian-Vaults. Er unterstützt im gesamten Leben: Familie (Ehefrau Olga, Töchter Karina & Elina), Betreuung der Eltern (Waldemar & Nina Schmidt) inkl. Dokumentenarchivierung, Hardware-Einrichtung, Social-Media-Posts und Wissensaufbau. Das bestehende Research-Wiki wird zu einem strukturierten Lebens-Vault umgebaut, der als "Gehirnzentrale" dient.

## Core Value

Maxim hat eine einzige, vertrauenswürdige Ablage für alles, was in seinem Leben wichtig ist — Tom weiß, wo was liegt, und kann proaktiv bei Familie, Eltern-Betreuung, Dokumenten, Hardware und Social Media unterstützen.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- ✓ Obsidian-Wiki mit MkDocs-Deploy — bestehendes Research-Wiki
- ✓ RTK Token-Optimierung für CLI-Operationen
- ✓ Dokumentenarchiv unter `~/Downloads/Archiv/` mit 15 Kategorien (01–15)
- ✓ Obsidian Web Clipper in Chrome eingerichtet
- ✓ PaperclipAI Integration (localhost:3100, Company `Maximus_OS`)
- ✓ Tom v1.0 — Lebens-Vault Bootstrap (Phasen 1–7, Commit `525c073`)
- ✓ Tom v1.1 — Maximus_OS + Ollama Gemma Revival (Phasen 8–13):
  - iCloud-Vault als Single Source of Truth
  - `bin/tom-issue` Maximus_OS Audit-Channel
  - Ollama + `gemma4:e4b` + Custom-Model `gemme`
  - RAG-Pipeline gegen iCloud-Vault
  - `bin/tom-ask` für lokale Wiki-Queries
- ✓ Tom v1.2 — Karpathy Wiki + claude-memory-compiler (Phasen 14–21):
  - `claude-memory-compiler` installiert + auf `$TOM_VAULT/95_Gehirn/` gepatcht
  - `95_Gehirn/` private Brain-Struktur mit Privacy-Regeln
  - Projekt-lokale Claude-Code-Hooks (SessionStart/End/PreCompact)
  - `90_Wiki/index.md` im Karpathy-Retrieval-Stil (statt Changelog)
  - Gemma RAG um dritte Collection `gehirn` erweitert
  - `bin/tom-wiki`, `bin/tom-compile`, `bin/tom-lint` Wrapper
  - Multi-Projekt-`wiki_path`-Konvention (Gemma/ als erstes Sub-Projekt)

**Active:** v1.3 — Compile-Automation + Quality-Pass (siehe unten)

## Current Milestone: v1.3 — Compile-Automation + Quality-Pass

**Goal:** Den in v1.2 gebauten Brain- und Wiki-Flow in den Dauerbetrieb bringen — launchd-Automation für `tom-compile`, Quality-Pass für `tom-wiki`, erweitertes Eval-Framework, dokumentierte Karpathy-Schwelle (1500) und Anthropic-SDK-Clarification. Kleine, pragmatische Verbesserungen, keine Architektur-Änderungen.

**Target features:**
- Compile-Automation via launchd Daily-Job (18:00 Europe/Berlin) mit fehlertolerantem Wrapper `tom-compile-safe`
- `tom-wiki` Quality-Pass: stärkerer System-Prompt, Context-Filter, bessere Quellen-Zitation
- `Gemma/eval/` erweitert um Brain-Artikel + quantitativer Vergleich `tom-wiki` vs. `tom-ask`
- Karpathy-Schwelle 1500 in `CLAUDE.md` dokumentiert inkl. Umstiegspfad RAG-Primary
- Anthropic-SDK-Clarification in `claude-memory-compiler/TOM-PATCHES.md` + CEO-Briefing
- Abschluss-Doku + Milestone-Close

### Active

<!-- Milestone v1.3 scope. -->

Siehe `.planning/REQUIREMENTS.md` (Milestone v1.3).

### Out of Scope

- **Eigene App / UI** — Tom lebt in Claude Code + Obsidian, keine eigene Oberfläche
- **Automatische Dokumenten-Digitalisierung (OCR-Pipeline)** — Scans kommen manuell oder via Web Clipper
- **Gesamtes Archiv public deployen** — nur `90_Wiki/` wird per MkDocs publiziert, alles Persönliche bleibt lokal
- **Proaktive Interviews zum Ausfüllen leerer Seiten** — Inhalte wachsen organisch beim ersten Use-Case

## Context

- **Sprache**: Deutsch für Inhalte, Englisch für Code/technische Identifier
- **Bestehender Vault**: `/Users/maxim/Claude/Obsidian/` (Research-Wiki, wird Quelle für Migration nach `90_Wiki/`)
- **Archiv**: `~/Downloads/Archiv/` mit 15 Kategorien — Originale bleiben unangetastet, Obsidian verlinkt via Symlink
- **Personen-Kreis**: Maxim, Olga, Karina, Elina Schmidt + Eltern Waldemar und Nina Schmidt
- **Publishing**: MkDocs + Material Theme + roamlinks-Plugin
- **Entscheidung getroffen (2026-04-10)**: Vault zunächst lokal unter `/Users/maxim/Claude/Obsidian_Zentralw/` anlegen, später manuell in iCloud migrieren
- **Codebase-Maps vorhanden**: `.planning/codebase/` (ARCHITECTURE, STRUCTURE, CONCERNS, CONVENTIONS, STACK, TESTING, INTEGRATIONS)

## Constraints

- **Sprache**: Deutsch für alle Vault-Inhalte — Maxim ist deutschsprachig und führt den Vault privat
- **Privacy**: Persönliche Ordner (00_Inbox, 10_Personen, 20_Dokumente, 40_Aufgaben, 50_Gesundheit, 60_Finanzen) dürfen NIE auf die öffentliche MkDocs-Seite — nur `90_Wiki/` wird publiziert
- **Archiv-Integrität**: `~/Downloads/Archiv/` bleibt Source of Truth für Dokumente, Obsidian hält nur Metadaten
- **Brownfield**: Bestehender `wiki/`-Inhalt darf nicht verloren gehen — Migration statt Neubau
- **Tech**: MkDocs + Material + roamlinks-Plugin (schon etabliert)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Vault-Pfad zunächst lokal (`/Users/maxim/Claude/Obsidian_Zentralw/`) | iCloud-Pfad liegt außerhalb Claude-Sandbox; spätere Migration trivial | — Pending |
| Symlink statt Kopie für Archiv-Anbindung | Originale bleiben unangetastet, Dateien auffindbar aus Obsidian heraus | — Pending |
| Nur `90_Wiki/` public, Rest privat (mkdocs.yml) | Persönliche Daten dürfen nicht publiziert werden | — Pending |
| Bootstrap ohne Interviews (leeres Gerüst + Templates) | Inhalte wachsen organisch beim ersten echten Use-Case | — Pending |
| 00_Inbox → 99_Vorlagen Nummerierungsschema | Ordnet sich auto-sortiert, Trennung persönlich/wiki bleibt visuell | — Pending |

---
*Last updated: 2026-04-10 after Tom v1.3 milestone start*
