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
- ✓ Tom v1.3 — Compile-Automation + Quality-Pass (Phasen 22–26):
  - `launchd` Daily-Compile-Job (18:00 Europe/Berlin) via `bin/tom-compile-safe` Preflight-Wrapper
  - `tom-wiki` Quality-Pass: Keyword-Filter, TOP_K=5, harter Zitations-Prompt
  - Eval-Framework erweitert: v1.3-Baseline `tom-wiki` 60% (80% auf Wiki-Queries) vs `tom-ask` 33%
  - Karpathy-Schwelle bleibt **500** (bewusste Entscheidung gegen Anhebung auf 1500); Skalierungs-Stufen dokumentiert
  - Anthropic-SDK-Clarification in `claude-memory-compiler/TOM-PATCHES.md` (bundled-CLI-Pfad nutzt Max-Subscription)
  - Obsidian-Doku-Lücke geschlossen: `log.md`-Eintrag, `30_Projekte/Tom.md` als Meta-Einstieg, Milestone-Close-Checklist in `CLAUDE.md`
- ✓ Tom v1.4 — Aktive KI + Dokumenten-Fundament (Phasen 27–32):
  - `archivum/` Sub-Projekt mit OCR-Pipeline (`pdftotext` → `ocrmypdf` Fallback), SQLite FTS5 Volltext-Index, SHA256-Idempotenz
  - `bin/tom-doc` CLI (index/search/list/show) mit Wissens-Kaskade-Anbindung für persönliche Dokumente
  - Smart Connections Obsidian-Plugin v4.3.0 mit Ollama-Backend (`nomic-embed-text` + `gemme`), Privacy-Exclude via UI (Phase 29-Hotfix)
  - `bin/tom-clip-enrich` — Summary + Auto-Tags + Konzept-Vorschläge + Wiki-Kategorie, idempotent via `enriched: true` Frontmatter-Flag
  - `tom-compile --local` via `gemme` als Alternative zum `claude_agent_sdk`-Default; Eval-Vergleich dokumentiert
  - `tom-lint --structural-only` als launchd-tauglicher Default in CLAUDE.md verankert
  - ADR-001 (`.scignore` nicht respektiert → UI-Exclude-Liste) + ADR-002 (Obsidian-Git deferred → v1.5/v1.6)
  - `CLAUDE.md` "Obsidian Plugin Landscape"-Sektion dokumentiert alle 35 Plugins mit Tom-Relevanz-Kategorisierung
- ✓ Tom v1.4.1 — Bridge-Patch (Phasen 33–35):
  - **Obsidian-Doku-Routine pro GSD-Phase** etabliert (`CLAUDE.md` "Mandatory pro GSD-Phase") — Backfill für v1.4 Phasen 27-32 + Hotfix im Vault sichtbar
  - `30_Projekte/Tom/Phasen/`, `Journal/`, `Entscheidungen.md` als Tom-Meta-Struktur im Vault; `99_Vorlagen/Tom-Phase.md` + `Tom-Journal.md` Templates
  - **Plugin-Audit** der 17 neu installierten Community-Plugins (`plugin-audit-v1.4.1.md`) — 4-Klassen-Klassifikation, 2 Setup-Kandidaten mit Config-Backup-Stubs (`eml-reader`, `obsidian-apple-reminders-plugin`)
  - ADR-003 (`obsidian-ocr` Koexistenz mit `tom-doc`) + ADR-004 (`mcp-tools` als v1.5-Integrationskandidat)
  - CLAUDE.md Plugin Landscape auf **52 Plugins** erweitert + neue Kategorien (LLM-Alternativen, Email/Messaging) + Warning/Empfehlungs-Boxen
  - **Web-Clipper-Template-System**: 7 typ-spezifische Templates (Artikel, Paper, Video, Dokument, Social-Post, Rezept, Werkzeug) in `99_Vorlagen/web-clipper/` + 7 Ziel-Unterordner in `Clippings/`, `tom-clip-enrich` unverändert kompatibel
- ✓ Tom v1.5a — Qwen/BGE-Migration (2026-04-12):
  - Aktiver lokaler Stack auf `qwen2.5:3b` vereinheitlicht
  - RAG-Embeddings auf `BAAI/bge-small-en-v1.5` via LangChain + SentenceTransformers umgestellt
  - OpenClaw/Open WebUI als stabiler lokaler Research-Pfad über Ollama dokumentiert
  - Gemma/Gemme und Qwen 3.5 aus aktiven Defaults entfernt

- ✓ Tom v1.5 — Lifecycle + Integration (Phasen 36–44):
  - **Lokaler Ollama-Switch**: `nutze-ollama`/`nutze-claude`/`ollama-status` Shell-Funktionen, `tom-local` Subshell-Wrapper, CCR-Daemon Port 3456
  - **Vault-Hygiene**: 6 redundante LLM-Plugins disabled, OLLAMA_ORIGINS via LaunchAgent, Plugin-Audit Q1-Q5 beantwortet
  - **Local Tool-Use**: `qwen2.5:3b` native `tool_calls` über Ollama, CCR übersetzt zu Anthropic `tool_use`-Blöcken
  - **MCP-Bridge**: FastMCP v3 Server (`mcp-server/tom_mcp.py`), 5 Read-only-Tools in Cursor, ADR-006
  - **Lifecycle-State-Machine**: 6 Bereiche (Dokumente 5 States, Aufgaben 4, Termine 5, Projekte 3, Verträge 5, Social 4), Meta Bind Buttons, `tom-state` CLI
  - **KI-Intake + Triage**: `tom-doc-intake` CLI, 5 KI-Templates, QuickAdd AI Assistant (9 Prompts), Book-Chunking
  - **7 Dataview-Dashboards**: Dokumente, Aufgaben, Termine, Projekte, Finanzen, Social, Morgen-Briefing
  - **Auto-Transitions**: `tom-state auto-transition` (Termine→Verpasst, Verträge→Frist-naht), launchd 07:00
  - **Verpasst-Handling**: tel:-Links, Doctolib/App-Links, Reminder-Task-Injection
  - **tom-status CLI**: Vault-weite Zusammenfassung mit Top-5 dringend
  - 6 HYG-Requirements als Known Gaps (Maxim-Handoff: Obsidian-UI/Browser-Interaktion)

**Active:** v1.6 Expansion — Phasen 47–53 (Phase 47 Done, Phase 48 nächste)

## Completed Milestones

Alle Milestones (v1.0–v1.5) sind abgeschlossen. Siehe `.planning/MILESTONES.md` für Details.

## v1.6 — Expansion

**Goal:** Tom's Werkzeug-Stack um externe Open-Source-Tools erweitern: multimodaler RAG, Token-Optimierung, Eval-Verbesserung, Skill-Engine, lokaler Menu-Bar-Assistant, Transkription.

### Phases

| Phase | Name | Prio | Status |
|-------|------|------|--------|
| 47 | Plugins + Raw/Vault-Cleanup | HOCH | ✓ Done (2026-04-14) |
| 48 | RAG-Anything Multimodal | HOCH | Planned |
| 49 | Codex-Plugin Token-Opt | MITTEL | Planned |
| 50 | Autoresearch Eval-Pipeline | MITTEL | Planned |
| 51 | OpenSpace Skill-Engine | MITTEL-NIEDRIG | Planned |
| 52 | Clicky Lokal-Build | NIEDRIG | Planned |
| 53 | audiobridge Transkription | NIEDRIG | Planned |

### Phase 47 ✓ — Plugins + Raw/Vault-Cleanup (Done)

Security Guidance installiert, claude-mem übersprungen (redundant), 122 leere Raw-Ordner bereinigt, Raw-Inventar dokumentiert.

## Planned Initiative

### Phase 45 — LinkedIn-Kontakte -> Obsidian (Deferred)

**Status:** Research + GSD-Plan vorhanden, Implementierung deferred (nicht in v1.6)

Siehe `.planning/phases/45-linkedin-kontakte-obsidian/45-01-PLAN.md`.

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
*Last updated: 2026-04-14 — Tom v1.6 Milestone-Start (Phase 47 Done, Phasen 48–53 geplant)*
