# Milestones

## v1.0 — Tom Bootstrap (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Claude-Rolle zu "Tom" umstellen + Obsidian-Vault als Lebens-Zentrale strukturieren
**Phases:** 1–7
**Status:** ✓ Shipped (commit `525c073`)

## v1.1 — Maximus_OS Integration + Ollama Gemma Revival (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Vault-Single-Source (iCloud), Hybrid-Integration mit Maximus_OS/PaperclipAI, lokales Gemma-Model gegen neuen Vault mit RAG
**Phases:** 8–13 (6 Phasen, 35 Requirements)
**Status:** ✓ Shipped

**Commits:**
- Phase 8 — `43d1f7a` refactor(vault): iCloud als single source
- Phase 9 — `611f9c2` feat(tools): tom-issue wrapper + Maximus_OS Kommunikationsregeln
- Phase 10 — `05e4fee` feat(llm): ollama + gemma4:e4b
- Phase 11 — `46b752a` feat(gemma): custom model + RAG auf iCloud-Vault
- Phase 12 — `810b63b` feat(tools): tom-ask wrapper
- Phase 13 — `ec4a62a` docs: Tom v1.1 Abschluss-Doku

**Maximus_OS Audit-Trail:** FAM-106, FAM-107, FAM-108, FAM-109, FAM-110, FAM-112, FAM-113

## v1.2 — Karpathy Wiki + claude-memory-compiler (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Hybrid Wissens-System mit Karpathy Index-first Retrieval für `90_Wiki/` (external), privatem `95_Gehirn/` (internal) mit Auto-Capture aus Claude-Code-Konversationen, RAG als Fallback mit dritter `gehirn`-Collection, Multi-Projekt-Nutzung via `wiki_path`-Konvention.
**Phases:** 14–21 (8 Phasen, 43 Requirements)
**Status:** ✓ Shipped

**Commits:**
- Phase 14 — `f27402d` feat(tools): clone + patch claude-memory-compiler
- Phase 15 — `60bb16a` feat(vault): 95_Gehirn Brain-Struktur + Privacy-Regeln
- Phase 16 — `1da397f` feat(hooks): project-level SessionEnd/PreCompact/SessionStart
- Phase 17 — `a76af5e` docs(wiki): rewrite 90_Wiki/index.md als Karpathy-Retrieval-Index
- Phase 18 — `92ccf35` feat(rag): add 95_Gehirn/knowledge als dritte RAG-Collection
- Phase 19 — `d1a1e9e` feat(tools): tom-wiki / tom-compile / tom-lint Wrapper
- Phase 20 — `12dbfda` docs: multi-project wiki_path convention
- Phase 21 — (diesem folgend) docs: Tom v1.2 Abschluss-Doku

**Maximus_OS Audit-Trail:** FAM-119, FAM-120, FAM-121, FAM-122, FAM-123, FAM-124, FAM-125

**Neue Tools:** `tom-wiki`, `tom-compile`, `tom-lint` (zusätzlich zu v1.1 `tom-issue`, `tom-ask`)

## v1.3 — Compile-Automation + Quality-Pass (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Den in v1.2 gebauten Brain- und Wiki-Flow in den Dauerbetrieb bringen — launchd-Automation, `tom-wiki` Quality-Pass, Eval-Baseline, Schwellen-Doku, SDK-Clarification. Keine Architektur-Änderungen.
**Phases:** 22–26 (5 Phasen, 30 Requirements)
**Status:** ✓ Shipped

**Commits:**
- Phase 22 — `330cc7a`..`146759d` Compile-Automation (launchd + `tom-compile-safe`)
- Phase 23 — `d47e2a9`..`1a6b47f` tom-wiki Quality-Pass (Keyword-Filter, TOP_K=5, harter System-Prompt)
- Phase 24 — `c3431b3`..`08d9c63` Eval-Framework-Erweiterung (v1.3-Baseline: tom-wiki 60%/80% vs tom-ask 33%)
- Phase 25 — `7a77699`..`1b48915` Schwellen-Doku (Karpathy-Schwelle bleibt 500 — bewusste Entscheidung gegen 1500)
- Phase 26 — `6fc9644`..<close> SDK-Clarification + Milestone-Close

**Maximus_OS Audit-Trail:** FAM-128, FAM-129, FAM-133, FAM-135 (+ CEO-Close-Issue aus Phase 26)

**Neue Werkzeuge:** `bin/tom-compile-safe` (Preflight-Wrapper für launchd-Job)

**Eval-Baseline (v1.3):** `tom-wiki` 60% Avg (80% auf Wiki-Queries) vs `tom-ask` 33% — dokumentiert unter `Gemma/eval/results/v1.3-baseline.md`. Karpathy Index-first empirisch bestätigt.

## v1.4 — Aktive KI + Dokumenten-Fundament (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Tom bekommt (1) ein Volltext-Dokumenten-Fundament via OCR + SQLite-FTS5, (2) Obsidian-native Semantic-Search via Smart Connections mit Ollama-Backend, (3) automatisches Clipper-Enrichment (Summary/Tags/Konzepte/Wiki-Kategorie-Vorschlag), (4) einen dokumentierten Token-Spar-Pfad für `tom-compile`. Die Document-Lifecycle-State-Machine ist bewusst nach v1.5 deferred.
**Phases:** 27–32 (6 Phasen, 39 Requirements inkl. Phase 29-Hotfix OBPL-06/07 + CLOSE14-08/09/10)
**Status:** ✓ Shipped

**Commits:**
- Phase 27 — `9c045db` feat(archivum): OCR + FTS5 Volltext-Fundament
- Phase 28 — `0e6f5ee` feat(tom-doc): CLI-Wrapper für Dokumenten-Volltext
- Phase 29 — `2b692a8` feat(obsidian): Smart Connections Plugin-Install + Privacy-Exclude
- Phase 29-Hotfix — `6ec745d` fix(smart-connections): Privacy-Leak Repair + ADRs
- Phase 30 — `d18952b` feat(tom-clip-enrich): Clipper Auto-Enrichment via gemme
- Phase 31 — `1df1dca` feat(tom-compile): Token-Spar-Lokalisierung via gemme
- Phase 32 — (diesem folgend) docs: Tom v1.4 Abschluss-Doku + CLAUDE.md Plugin-Landscape

**Maximus_OS Audit-Trail:** FAM-149 (CEO, Phase 32 Close-Issue, priority=high) + phasenweise CTO/archivarius-Issues aus Phasen 27–31

**Neue Werkzeuge:**
- `bin/tom-doc` — CLI für SQLite-FTS5-Volltextsuche über OCR'd Archiv-PDFs (Subcommands: `index`, `search`, `list`, `show`)
- `bin/tom-clip-enrich` — Summary + Auto-Tags + Konzept-Vorschläge + Wiki-Kategorie-Vorschlag für Clippings (idempotent via `enriched: true`)
- `tom-compile --local` — Alternative Compile-Implementierung via `gemme` ohne `claude_agent_sdk` (Default bleibt claude-sdk)
- `archivum/` Sub-Projekt: OCR-Pipeline (`pdftotext` → `ocrmypdf` Fallback), SQLite FTS5 Schema, SHA256-Idempotenz-Cache
- Smart Connections Obsidian-Plugin v4.3.0 mit Ollama-Backend (`nomic-embed-text` + `gemme`)

**Mid-Phase-Intervention (Phase 29-Hotfix):**
Nach Maxim's Aktivierung von Smart Connections in Obsidian UI wurde festgestellt, dass das Plugin `.scignore` nicht respektiert. 56 persönliche `.ajson`-Embeddings landeten trotz Exclude-Liste in `.smart-env/multi/`. Fix: Cache-Clean, UI-Exclude-Anleitung, ADR-001 dokumentiert Incident + Decision. Neue Requirements OBPL-06/07 in v1.4 gezogen.

**Plugin-Landschaft (neu in v1.4):**
Maxim hat zusätzlich 33 Community-Plugins in Obsidian installiert. Dokumentiert in `CLAUDE.md` "Obsidian Plugin Landscape". Tom-relevante Plugins (Dataview, Templater, Tasks, QuickAdd, obsidian-git) sind für v1.5-Integration vorgemerkt. ADR-002 vertagt Vault-in-git-Entscheidung explizit auf v1.5/v1.6.

Siehe `.planning/ROADMAP.md` für Phasen-Details, `.planning/briefings/v1.4-CEO-Briefing.md` für Executive Summary.

## v1.4.1 — Bridge-Patch (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Drei Vor-Arbeiten zwischen v1.4-Close und v1.5-Kickoff — Obsidian-Doku-Routine etablieren (Phase 33), Plugin-Audit der 17 zwischen v1.4-Close und v1.4.1 installierten Community-Plugins (Phase 34), typ-spezifische Web-Clipper-Templates mit Tom-konformem Frontmatter (Phase 35). Infrastruktur-Backfill vor Feature-Arbeit in v1.5.
**Phases:** 33–35 (3 Phasen, 17 Requirements: 6 DOC141 + 5 OBPL141 + 6 CLIP141)
**Status:** ✓ Shipped (mit 1 prepared-pending-maxim für Clipper-Smoke-Test CLIP141-04)

**Commits:**
- Phase 33 — `29a734e` docs(phase-33): Obsidian-Doku-Backfill + Arbeits-Routine
- Phase 34 — `4e08696` docs(phase-34): Plugin-Audit + ADR-003/004 + CLAUDE.md-Update
- Phase 35 — `3a3cff8` feat(phase-35): Web-Clipper-Template-System

**Maximus_OS Audit-Trail:** FAM-153 (CEO Mini-Close-Issue, priority=medium, 2026-04-10)

**Neue Werkzeuge / Artefakte:**
- **Obsidian-Doku-Routine pro GSD-Phase** — neue CLAUDE.md-Sektion "Mandatory pro GSD-Phase" mit 4-Punkte-Checklist (Phase-Note / Journal / Entscheidungen / Dashboard)
- **Tom-Meta-Struktur im Vault**: `30_Projekte/Tom/Phasen/`, `30_Projekte/Tom/Journal/`, `30_Projekte/Tom/Entscheidungen.md`, plus 2 Templates in `99_Vorlagen/` (`Tom-Phase.md`, `Tom-Journal.md`)
- **`plugin-audit-v1.4.1.md`** — Audit-Dokument für 17 neue Plugins mit 4-Klassen-Klassifikation
- **ADR-003** — `obsidian-ocr` Koexistenz mit `tom-doc`
- **ADR-004** — `mcp-tools` als v1.5-Integrationskandidat
- **Config-Backup-Stubs**: `eml-reader.json` + `obsidian-apple-reminders-plugin.json` (Status: `prepared-pending-maxim-activation`)
- **Web-Clipper-Template-System**: 7 typ-spezifische Templates + README in `99_Vorlagen/web-clipper/`, 7 Ziel-Unterordner in `Clippings/`
- **CLAUDE.md Plugin Landscape erweitert** von 35 auf 52 Plugins (+ neue Kategorien LLM-Alternativen, Email/Messaging, + Warning-Box obsidian-ocr, + Empfehlungs-Box mcp-tools)

**Backfill:** Phase 33 legte retroaktiv 8 Phase-Notes im Vault an (v1.4 Phasen 27, 28, 29, 29-Hotfix, 30, 31, 32 + Phase 33 selbst als Dogfooding).

**Maxim-Handoffs (bleiben offen nach v1.4.1):**
- CLIP141-04 Clipper-Smoke-Test mit echtem Browser-Clip + `tom-clip-enrich`-Run
- Setup der Plugin-Kandidaten `eml-reader` + `obsidian-apple-reminders-plugin` nach Maxim-Antworten auf 5 offene Fragen in `plugin-audit-v1.4.1.md`
- OBPL-03 aus v1.4 (Smart Connections "TurboQuant"-Smoke-Test nach UI-Reconfig) bleibt weiterhin offen

**Warum Patch statt v1.5-Phasen 33-35:** Klare Scope-Trennung. v1.5 macht Features (Lifecycle-State-Machine, Dataview-Dashboards, Templater-Frontmatter-Auto). v1.4.1 ist reines Infrastruktur-Backfill + Kompensation für Plugin-Installation zwischen v1.4-Close und jetzt. Kein eigenes CEO-Briefing, nur Mini-Close-Issue.

Siehe `.planning/ROADMAP.md` für Phasen-Details.
