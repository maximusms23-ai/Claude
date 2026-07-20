# Requirements: Tom — Persönlicher Lebens-Assistent

**Defined:** 2026-04-10
**Current Milestone:** v1.6 — Expansion
**Core Value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles, was in seinem Leben wichtig ist — Tom weiß, wo was liegt, und unterstützt proaktiv.

## Planned Requirements (Candidate)

Requirements fuer eine skalierbare LinkedIn-Kontakt-Pipeline nach Obsidian. Fokus: Bulk-Import, Silver-Layer, selektive Materialisierung, Web-Clipper nur fuer Einzelprofile.

### LinkedIn Kontakte -> Obsidian (LIOBS)

- [ ] **LIOBS-01**: LinkedIn-Export-Flow ist dokumentiert (`Settings & Privacy -> Data Privacy -> Get a copy of your data`) und fuer einen echten Testlauf reproduzierbar
- [ ] **LIOBS-02**: Minimales Export-Paket ist festgelegt (`Connections` Pflicht, `Profile`/`Email Addresses`/`Phone Numbers`/`Contacts` optional)
- [ ] **LIOBS-03**: Ein explizites Schema mappt LinkedIn-Exportfelder auf das Tom-Personenmodell
- [ ] **LIOBS-04**: Bronze-Ingest ist copy-first, hash-basiert und idempotent
- [ ] **LIOBS-05**: Ein Normalizer erzeugt ein konsistentes Silver-Dataset als `csv` und `jsonl`
- [ ] **LIOBS-06**: Dedupe nutzt bevorzugt `public_profile_url`, dann `email`, dann einen stabilen Fallback-Key
- [ ] **LIOBS-07**: Die Massenansicht bleibt ausserhalb eines 1-Note-pro-Kontakt-Modells (z. B. `csv`/`sqlite`/subset Bases)
- [ ] **LIOBS-08**: Nur priorisierte Kontakte werden als echte Personen-Noten materialisiert
- [ ] **LIOBS-09**: Ein Web-Clipper-Template `Tom-LinkedIn-Profil` unterstuetzt gezielte Einzelprofil-Erfassung
- [ ] **LIOBS-10**: Fehlende Angaben werden nur fuer priorisierte Kontakte per Web-Recherche nachgetragen und mit Quellen-/Confidence-Hinweis markiert
- [ ] **LIOBS-11**: Jede materialisierte Kontakt-Note enthaelt KI-Bewertung, Prioritaet und naechsten Schritt
- [ ] **LIOBS-12**: Die Rollout-Reihenfolge ist pilotiert und skaliert kontrolliert (100 -> 1000 -> 10000 -> Full)

## v1.4 Requirements (Current)

Requirements für Dokumenten-Volltext-Fundament, `tom-doc` CLI, Smart-Connections-Integration in Obsidian, Clipper-Auto-Enrichment, Token-Spar-Lokalisierung und Milestone-Close. Jeder Eintrag mappt auf genau eine Phase im Roadmap (Phasen 27–32).

### OCR + Dokumenten-Fundament (DOC14)

- [x] **DOC14-01**: `tesseract` + `ocrmypdf` + `tesseract-lang-deu` via Homebrew installiert; `tesseract --list-langs` enthält `deu`
- [x] **DOC14-02**: `$TOM_VAULT/Archiv/` Symlink auf `~/Downloads/Archiv/` existiert
- [x] **DOC14-03**: `/Users/maxim/Claude/archivum/` mit `db/`, `ocr-cache/`, `logs/`, `README.md` angelegt
- [x] **DOC14-04**: SQLite FTS5 Schema in `archivum/db/archivum.db` — Tabellen `documents` + `documents_fts`
- [x] **DOC14-05**: OCR-Pipeline-Script `archivum/ocr_pipeline.py` — pdftotext-first + ocrmypdf Fallback, Cache nach `ocr-cache/<hash>.txt`, idempotent
- [x] **DOC14-06**: Smoke-Test mit `2204_Arbeitsvertrag_Schmidt.pdf` — 89805 Zeichen, 27 Seiten, via pdftotext, Suche nach "Arbeitsvertrag"/"Gehalt"/"Schmidt" findet Snippets

### tom-doc CLI (TDOC)

- [x] **TDOC-01**: `bin/tom-doc` Wrapper mit Subcommands `index`, `search`, `list`, `show`
- [x] **TDOC-02**: `tom-doc index [kategorie]` — scant Archiv-Kategorie, OCR'd neue PDFs, aktualisiert FTS5-Index
- [x] **TDOC-03**: `tom-doc search "query"` — FTS5-Query mit Trefferliste `kategorie/dateiname + Snippet`
- [x] **TDOC-04**: `tom-doc show <id|pfad|datei|sha>` — zeigt Metadaten + OCR-Text-Auszug
- [x] **TDOC-05**: `tom-doc list [kategorie]` — listet alle indizierten Dokumente einer Kategorie
- [x] **TDOC-06**: Symlink in `~/bin/tom-doc` angelegt
- [x] **TDOC-07**: `CLAUDE.md` Wissens-Kaskade-Punkt 4 und 5 um Dokumenten-Fragen (`tom-doc search`) erweitert

### Gemma-in-Obsidian via Community-Plugin (OBPL)

- [x] **OBPL-01**: Smart Connections Plugin v4.3.0 Files installiert + `.obsidian/community-plugins.json` enabled; Ollama-Backend-Aktivierung im Obsidian UI (Maxim-Handoff); Fallback-Option Copilot dokumentiert
- [x] **OBPL-02**: Plugin-Settings + Activation-Steps als JSON-Backup in `.planning/obsidian-plugin-config/smart-connections.json` (v2 nach Hotfix mit `lessons_learned` + `excluded_folders_ui_list`)
- [~] **OBPL-03**: Smoke-Test: Semantic-Search findet `konzepte/turboquant.md` bei Query "TurboQuant" — **pending Maxim-Re-Index nach Hotfix UI-Reconfig** (Cache wurde in Hotfix geleert, Re-Index muss mit korrekter Exclude-Liste neu laufen)
- [x] **OBPL-04**: Exclude-Regel für persönliche Ordner dokumentiert: `.scignore` existiert als Referenz, **tatsächlich wirksam** ist die UI-Exclude-Liste in `smart-connections.json.excluded_folders_ui_list` (17 Einträge). Siehe ADR-001 für Root-Cause.
- [x] **OBPL-05**: `CLAUDE.md` Wissens-Kaskade Punkt 6: "Ad-hoc im Editor → Smart Connections Panel" (inkl. Warnung dass `.scignore` nicht respektiert wird)
- [x] **OBPL-06**: `.smart-env/multi/` enthält keine Files aus persönlichen Ordnern (nach Hotfix: 25 Files, alle `90_Wiki_*` oder `95_Gehirn_knowledge_*`, 0 persönliche)
- [x] **OBPL-07**: Exclude-Liste dokumentiert im Config-Backup mit dem tatsächlich wirksamen Mechanismus (UI statt `.scignore`) — siehe `smart-connections.json` v2 + ADR-001

### Clipper Auto-Enrichment (CLIP)

- [x] **CLIP-01**: `bin/tom-clip-enrich` liest Clipping-Datei, ruft `qwen3:8b` lokal, schreibt angereicherte Version zurück; idempotent via `enriched: true` Frontmatter-Flag
- [x] **CLIP-02**: Enrichment — **Summary**: 3–5 Sätze in Frontmatter-Feld `summary`
- [x] **CLIP-03**: Enrichment — **Auto-Tags**: 3–5 lokale Qwen-Tags an existierende `tags` appended (dedupliziert)
- [x] **CLIP-04**: Enrichment — **Konzept-Extraktion**: 2–4 Begriffe als Zeilen in `$TOM_VAULT/90_Wiki/konzepte-vorschlaege.md` (Review-Schleife, NICHT direkt als Stub-Pages)
- [x] **CLIP-05**: Enrichment — **Wiki-Kategorie-Vorschlag**: `qwen3:8b` wählt eine `90_Wiki/`-Subkategorie (themen/konzepte/personen/projekte/quellen) → Frontmatter-Feld `suggested_wiki_category`
- [~] **CLIP-06**: `tom-clip-enrich --watch` — **deferred nach v1.5** (CLI on-demand reicht für v1.4)
- [x] **CLIP-07**: Smoke-Test mit `Mannheim – Wikipedia.md` — Summary, 5 Tags, 4 Konzepte, Kategorie "themen", keine Halluzinationen, Idempotenz-Test grün
- [x] **CLIP-08**: **Entscheidung dokumentiert**: NICHT als Hook in `tom-compile-safe` integriert. Begründung: Clipper-Enrichment ist opportunistisch (neue Clippings kommen unregelmäßig), während tom-compile täglich läuft. On-demand CLI reicht für v1.4. launchd-Integration offen für v1.5 bei Bedarf.

### Token-Spar-Lokalisierung (LOCAL)

- [x] **LOCAL-01**: `tom-compile --local` Alternative-Pfad über `qwen3:8b` via `tom_tools/compile_local.py`; Default bleibt `claude_agent_sdk` (bin/tom-compile dispatcht)
- [x] **LOCAL-02**: Eval-Vergleich in `Gemma/eval/results/v1.4-compile-local-vs-claude.md` — auf real-log (FLUSH_OK-only, beide Modi korrekt 0 Artikel) + synthetic-log (local: 2 Artikel in 67s, keine Halluzinationen, saubere Struktur). 3-Log-Vollvergleich deferred nach v1.5 wegen fehlender akkumulierter daily-logs.
- [x] **LOCAL-03**: `tom-lint --structural-only` als empfohlener launchd-Default in `CLAUDE.md` dokumentiert (kein neues `--no-llm` Flag — existierendes reicht, minimal-invasiv)
- [x] **LOCAL-04**: Maximus_OS-Issue zur Entscheidung (ausstehend — nach Commit)

### Milestone-Close v1.4 (CLOSE14)

- [x] **CLOSE14-01**: `.planning/MILESTONES.md` v1.4-Eintrag nach v1.1/v1.2/v1.3-Schema
- [x] **CLOSE14-02**: `.planning/PROJECT.md` Validated-Sektion um v1.4-Deliverables erweitert + STATE.md auf `milestone_name: Complete`
- [x] **CLOSE14-03**: `.planning/briefings/v1.4-CEO-Briefing.md` nach v1.3-Template (6 Teile + Teil 7 Plugin-Landscape + Anhänge)
- [x] **CLOSE14-04**: `$TOM_VAULT/log.md` v1.4-Eintrag nach v1.3-Schema
- [x] **CLOSE14-05**: `$TOM_VAULT/30_Projekte/Tom.md` Current-Milestone + Werkzeug-Liste um `tom-doc`, `tom-clip-enrich` ergänzt
- [x] **CLOSE14-06**: Maximus_OS-Issue an CEO (`priority=high`) schließt v1.4 offiziell ab
- [x] **CLOSE14-07**: Alle v1.4-Requirements in REQUIREMENTS.md als [x]
- [x] **CLOSE14-08**: `/Users/maxim/Claude/CLAUDE.md` neue Sektion "Obsidian Plugin Landscape (seit v1.4)" mit 3-Kategorisierung (Tom-relevant, Workflow-Ergänzung, Kosmetik) + Warning-Boxen für `obsidian-linter` (YAML-Rules disabled) und `obsidian-git` (installed-but-unused, ADR-002)
- [x] **CLOSE14-09**: `v1.4-CEO-Briefing.md` Teil 7 "Vault-Infrastructure-Expansion" — Plugin-Abriss, Privacy-Incident (Phase 29-Hotfix) ehrlich dokumentiert, v1.5-Integration-Hooks für Dataview/Templater/Tasks/QuickAdd
- [x] **CLOSE14-10**: `.planning/obsidian-plugin-config/adr-001-smart-connections-privacy.md` + `adr-002-obsidian-git-deferred.md` angelegt

## v1.3 Requirements (Shipped)

Requirements für Compile-Automation, `tom-wiki` Quality-Pass, Eval-Framework-Erweiterung, Doku-Updates und Anthropic-SDK-Clarification. Jeder Eintrag mappt auf genau eine Phase im Roadmap (Phasen 22–26).

### Compile-Automation (CRON)

- [x] **CRON-01**: `~/Library/LaunchAgents/com.maxim.tom-compile.plist` existiert und startet `tom-compile-safe` täglich um 18:00 Europe/Berlin
- [x] **CRON-02**: `bin/tom-compile-safe` prüft vor Ausführung, ob `ollama serve` läuft und `$TOM_VAULT` erreichbar ist — exitet sauber mit Log-Eintrag wenn nicht
- [x] **CRON-03**: `tom-compile-safe` schreibt Run-Log nach `~/Library/Logs/tom-compile.log` (Timestamp, Exit-Code, Duration)
- [x] **CRON-04**: `launchctl load` des Plists registriert den Job; `launchctl list | grep tom-compile` zeigt aktiven Eintrag
- [x] **CRON-05**: Manueller Trigger via `launchctl start com.maxim.tom-compile` erzeugt erfolgreichen Compile-Lauf ohne Fehler
- [x] **CRON-06**: Maximus_OS-Issue an CTO dokumentiert launchd-Job + Plist-Pfad + Log-Location

### tom-wiki Quality-Pass (QUAL)

- [x] **QUAL-01**: `claude-memory-compiler/tom_tools/wiki_query.py` hat neuen, stärkeren System-Prompt der präzise Antworten + Quellen-Zitation verlangt
- [x] **QUAL-02**: Context-Filter reduziert den an `qwen3:8b` übergebenen Kontext auf nur Index + relevante Artikel (statt alle) — per Keyword-Matching aus Query
- [x] **QUAL-03**: Antworten von `tom-wiki` zitieren mindestens eine Quell-Datei explizit per Wiki-Link oder Dateiname
- [x] **QUAL-04**: Smoke-Test: `tom-wiki "Was ist TurboQuant?"` liefert präzisere Antwort als Baseline (nicht generisch, verweist auf `turboquant.md`)
- [x] **QUAL-05**: Patches sind in `claude-memory-compiler/TOM-PATCHES.md` dokumentiert
- [x] **QUAL-06**: Maximus_OS-Issue an CTO dokumentiert Quality-Pass + Before/After-Beispiel

### Eval-Framework-Erweiterung (EVAL)

- [x] **EVAL-01**: `Gemma/eval/` hat neuen Test-Corpus-Eintrag mit Brain-Artikeln aus `95_Gehirn/knowledge/`
- [x] **EVAL-02**: `run_eval.py` erweitert um Side-by-Side-Vergleich `tom-wiki` vs `tom-ask` (gleiche Query, beide Antworten, manuelle oder LLM-Score)
- [x] **EVAL-03**: Eval produziert Report-File unter `Gemma/eval/results/v1.3-baseline.md` mit Score-Vergleich
- [x] **EVAL-04**: Mindestens 10 Test-Queries im Corpus decken Wiki-Themen und Brain-Themen ab
- [x] **EVAL-05**: Maximus_OS-Issue an CTO dokumentiert Eval-Ergebnisse + Interpretation

### Doku + Schwellen-Update (DOC13)

- [x] **DOC13-01**: `CLAUDE.md` Wissens-Kaskade bestätigt Karpathy-Schwelle **500** (unverändert) und dokumentiert den expliziten Umstiegspfad auf RAG-Primary bei Überschreitung
- [x] **DOC13-02**: `$TOM_VAULT/CLAUDE.md` (Vault-Regeln) ist konsistent auf 500 (falls die Schwelle dort erwähnt wird) — auto-erfüllt, Vault-CLAUDE.md erwähnt die Schwelle nicht
- [x] **DOC13-03**: Neue Sektion "Skalierungs-Stufen" in `CLAUDE.md` skizziert: <500 = Index-first, 500–2000 = Hybrid, >2000 = RAG-Primary
- [x] **DOC13-04**: Maximus_OS-Issue an wiki-kurator dokumentiert Doku-Update (FAM-135)

### SDK-Clarification + Abschluss (CLOSE13)

- [x] **CLOSE13-01**: Anthropic-SDK-Clarification (Subscription-Quota-Frage für `tom-compile`) ist recherchiert und zusammengefasst in `claude-memory-compiler/TOM-PATCHES.md` (Abschnitt 8)
- [x] **CLOSE13-02**: CEO-Briefing `.planning/briefings/v1.3-CEO-Briefing.md` (Pfad angepasst auf v1.2-Konvention) dokumentiert alle Phasen 22–26 mit Commits und Outcomes
- [x] **CLOSE13-03**: `.planning/MILESTONES.md` um v1.3-Eintrag erweitert (Start, Ende, Phasen, Status, Commits)
- [x] **CLOSE13-04**: `.planning/PROJECT.md` Validated-Sektion um v1.3-Einträge erweitert
- [x] **CLOSE13-05**: Maximus_OS-Issue an CEO schließt Milestone v1.3 offiziell ab (FAM-139)
- [x] **CLOSE13-06**: `$TOM_VAULT/log.md` bekommt v1.3-Eintrag nach v1.1/v1.2-Schema (Phasen-Zusammenfassung, neue Werkzeuge, Architektur-Notizen, Offen-Block)
- [x] **CLOSE13-07**: `$TOM_VAULT/30_Projekte/Tom.md` als Meta-Projekt-Seite einmalig angelegt (Frontmatter, Current Milestone, Werkzeug-Liste, Doku-Kaskade-Tabelle, Milestones-Kurz-Historie)
- [x] **CLOSE13-08**: `$TOM_VAULT/index.md` Sektion "Laufende Projekte" um `[[30_Projekte/Tom]]` erweitert, damit Tom selbst vom Hub-Dashboard aus auffindbar ist
- [x] **CLOSE13-09**: `/Users/maxim/Claude/CLAUDE.md` hat neue Sektion "Mandatory bei jedem Milestone-Close" mit 7-Punkte-Checklist, damit die Doku-Lücke für v1.4+ dauerhaft geschlossen ist

## v1.2 Requirements (Shipped)

Requirements für Karpathy-Wiki-Methode, automatisches Konversations-Capture via `claude-memory-compiler`, Hybrid RAG + Index-first Retrieval, Multi-Projekt-Nutzung. Jeder Eintrag mappt auf genau eine Phase im Roadmap.

### Tool-Install (TOOL)

- ✓ **TOOL-01**: `claude-memory-compiler` ist nach `/Users/maxim/Claude/claude-memory-compiler/` geklont und in Git getrackt
- ✓ **TOOL-02**: `uv sync` im Tool-Repo läuft erfolgreich, Dependencies sind installiert
- ✓ **TOOL-03**: `scripts/config.py` ist gepatcht — `TOM_VAULT`-Env-Var, Pfade zeigen auf `$TOM_VAULT/95_Gehirn/`
- ✓ **TOOL-04**: Smoke-Test: `uv run scripts/lint.py --structural-only` läuft gegen leere Struktur fehlerfrei
- ✓ **TOOL-05**: Maximus_OS-Issue an CTO dokumentiert Tool-Install + Config-Patch mit Commit-Hash

### Brain-Struktur (BRAIN)

- ✓ **BRAIN-01**: `$TOM_VAULT/95_Gehirn/{daily,knowledge/{concepts,connections,qa},reports}/` ist angelegt
- ✓ **BRAIN-02**: `$TOM_VAULT/95_Gehirn/CLAUDE.md` dokumentiert Privacy-Regeln (was rein darf, was nicht), Compile-Trigger, Lint-Regeln
- ✓ **BRAIN-03**: `$TOM_VAULT/95_Gehirn/index.md` Initial-Gerüst mit Sektionen "Recent", "Topics", "Connections"
- ✓ **BRAIN-04**: `$TOM_VAULT/95_Gehirn/log.md` enthält Initial-Eintrag "Brain angelegt"
- ✓ **BRAIN-05**: `$TOM_VAULT/mkdocs.yml` ist verifiziert — `95_Gehirn/` ist NICHT im MkDocs-Scope
- ✓ **BRAIN-06**: Maximus_OS-Issue an archivarius dokumentiert Brain-Struktur + Privacy-Regeln

### Hooks (HOOK)

- ✓ **HOOK-01**: `/Users/maxim/Claude/.claude/settings.json` ist angelegt (Projekt-lokal, nicht global)
- ✓ **HOOK-02**: Drei Hooks sind eingetragen: `SessionStart`, `SessionEnd`, `PreCompact`, alle zeigen auf `claude-memory-compiler/hooks/*.py` via `uv run`
- ✓ **HOOK-03**: Smoke-Test: Claude-Code-Session schreibt bei SessionEnd einen Entry nach `$TOM_VAULT/95_Gehirn/daily/YYYY-MM-DD.md`
- ✓ **HOOK-04**: Verifiziert: bestehende GSD + RTK Hooks aus globaler Config funktionieren weiterhin (Merge-Verhalten OK)
- ✓ **HOOK-05**: `/Users/maxim/Claude/CLAUDE.md` dokumentiert aktive Hooks + Auto-Capture
- ✓ **HOOK-06**: Maximus_OS-Issue an CTO dokumentiert Hook-Aktivierung

### Karpathy-Index (KIDX)

- ✓ **KIDX-01**: Aktueller `$TOM_VAULT/90_Wiki/index.md` ist nach `90_Wiki/history.md` verschoben (Changelog bewahrt)
- ✓ **KIDX-02**: Neuer `90_Wiki/index.md` ist im Karpathy-Retrieval-Format geschrieben mit Nutzungshinweis "zuerst Index, dann 3–5 relevante Artikel lesen, dann synthetisieren"
- ✓ **KIDX-03**: Alle bestehenden `90_Wiki/`-Artikel sind im Index mit 1–2-Zeilen-Beschreibung gelistet, gruppiert nach Kategorie (Konzepte, Themen, Projekte, Personen, Quellen)
- ✓ **KIDX-04**: Smoke-Test: Eine typische Frage (z.B. "Was ist Turboquant?") wird nur via Index → direkte Reads beantwortet, ohne RAG
- ✓ **KIDX-05**: Maximus_OS-Issue an wiki-kurator dokumentiert Index-Umschreibung

### RAG-Erweiterung (RAG2)

- ✓ **RAG2-01**: `Gemma/rag/config.py` enthält `GEHIRN_PATH = TOM_VAULT / "95_Gehirn" / "knowledge"`
- ✓ **RAG2-02**: `Gemma/rag/index.py` indiziert dritte Collection `gehirn` additiv in `index_all()`
- ✓ **RAG2-03**: `Gemma/rag/query.py` durchsucht alle drei Collections (wiki, clippings, gehirn)
- ✓ **RAG2-04**: Reindex-Smoke-Test gegen leeres `gehirn/knowledge/` meldet 0 Chunks ohne Fehler
- ✓ **RAG2-05**: Maximus_OS-Issue an CTO dokumentiert RAG-Erweiterung

### Neue Wrapper (WRAP)

- ✓ **WRAP-01**: `bin/tom-wiki` Bash-Wrapper unterstützt `tom-wiki [--brain] "Frage"` und ruft Index-first-Query auf `90_Wiki/index.md` bzw. `95_Gehirn/index.md`
- ✓ **WRAP-02**: `bin/tom-compile` triggert `uv run scripts/compile.py` im Tool-Repo (optional Flags durchgereicht)
- ✓ **WRAP-03**: `bin/tom-lint` triggert `uv run scripts/lint.py` (optional `--structural-only` durchgereicht)
- ✓ **WRAP-04**: Symlinks für `tom-wiki`, `tom-compile`, `tom-lint` in `~/bin/` sind angelegt und ausführbar
- ✓ **WRAP-05**: Smoke-Test: `tom-wiki "Was ist Ollama?"` liefert Antwort via Index; `tom-lint --structural-only` läuft fehlerfrei
- ✓ **WRAP-06**: `CLAUDE.md` + `AGENTS.md` dokumentieren Wissens-Kaskade: (1) Direct-Read, (2) tom-wiki, (3) tom-ask (RAG-Fallback)
- ✓ **WRAP-07**: Maximus_OS-Issue an CTO dokumentiert neue CLI-Tools

### Multi-Projekt (MULTI)

- ✓ **MULTI-01**: Template `wiki_path`-Konvention ist dokumentiert (in `claude-memory-compiler/docs/multi-project.md` oder `CLAUDE.md`-Anhang)
- ✓ **MULTI-02**: Mindestens ein zweites Projekt auf dem Mac hat die `wiki_path`-Sektion in seiner `CLAUDE.md` eingebettet
- ✓ **MULTI-03**: Smoke-Test: `tom-wiki "Frage"` funktioniert aus einem zweiten Projekt-Verzeichnis
- ✓ **MULTI-04**: `$TOM_VAULT/95_Gehirn/CLAUDE.md` erwähnt dass Brain shared über alle Projekte ist, pro Projekt eigene Daily-Logs möglich
- ✓ **MULTI-05**: Maximus_OS-Issue an wiki-kurator dokumentiert Multi-Projekt-Konvention

### Dokumentation v1.2 (DOC12)

- ✓ **DOC12-01**: `$TOM_VAULT/log.md` enthält v1.2 Abschluss-Eintrag
- ✓ **DOC12-02**: `$TOM_VAULT/90_Wiki/projekte/claude-memory-compiler.md` Artikel über das Tool existiert
- ✓ **DOC12-03**: `$TOM_VAULT/90_Wiki/konzepte/karpathy-wiki-methode.md` Konzept-Artikel existiert
- ✓ **DOC12-04**: `/Users/maxim/Claude/claude-memory-compiler/TOM-PATCHES.md` dokumentiert alle Config-Änderungen gegen Upstream
- ✓ **DOC12-05**: Finales Milestone-Close-Issue an CEO (priority=high) mit Commit-Hashes und Verification-Summary
- ✓ **DOC12-06**: `REQUIREMENTS.md` / `STATE.md` / `MILESTONES.md` / `PROJECT.md` sind für v1.2 Close aktualisiert

## v1.1 Requirements (Shipped)

Komplett shipped in v1.1 (Phases 8–13). Siehe Traceability unten + `MILESTONES.md`.

Kategorien: VCLEAN, MOS, OLL, GEM, WIRE, DOC11 — alle Complete.

## v1.0 Requirements (Shipped — Commit `525c073`)

Komplett shipped in v1.0 (Phases 1–7). Kategorien: IDENT, VAULT, PERS, DOC, TMPL, BOOT, WF — alle Complete.

## v1.3+ Requirements (Deferred)

### Fine-Tuning (FT)

- **FT-01**: Gemma Fine-Tuning via externem Runner (MLX-LM oder Unsloth) — deferred from v1.2
- **FT-02**: Training-Pipeline aus `qa_pairs.jsonl` in echtes Gewichts-Update
- **FT-03**: A/B-Eval zwischen Base- und Fine-Tuned-Model

### Automatisierung

- **AUTO-01**: Templater-Plugin für automatische Frontmatter-Befüllung
- **AUTO-02**: Dataview-Queries für Dashboard statt statischer Listen
- **AUTO-03**: Automatischer Digest ("was steht heute an?") via Hook
- **AUTO-04**: Maximus_OS Tom-Agent kann eigenständig `tom-ask` aufrufen

### Skalierung

- **SCALE-01**: Umstieg von Index-first Karpathy auf RAG-Primary wenn Wiki > 500 Artikel

## Out of Scope

| Feature | Grund |
|---------|-------|
| Fine-Tuning in v1.2 | Fokus-Shift auf Wiki-Struktur + Auto-Memory; Q&A-Pairs wachsen weiter, FT kommt v1.3+ |
| `95_Gehirn/` publizieren | Enthält PII aus Claude-Code-Konversationen, darf NIE öffentlich werden |
| Rohe daily-logs in RAG indexieren | Zu verrauscht; nur kompilierte `knowledge/`-Artikel gehen ins RAG |
| Globale Claude-Code-Hooks ändern | Würde GSD/RTK brechen; nur Projekt-lokal ergänzen |
| Automatische `90_Wiki/index.md`-Pflege durch Compiler | compile.py arbeitet nur auf `95_Gehirn/` (internal data); `90_Wiki/index.md` bleibt manuell via WF-07 |
| Eigener Memory-Compiler-Fork | Upstream-Clone + Patches in `TOM-PATCHES.md` reichen |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOOL-01 | Phase 14 | Complete |
| TOOL-02 | Phase 14 | Complete |
| TOOL-03 | Phase 14 | Complete |
| TOOL-04 | Phase 14 | Complete |
| TOOL-05 | Phase 14 | Complete |
| BRAIN-01 | Phase 15 | Complete |
| BRAIN-02 | Phase 15 | Complete |
| BRAIN-03 | Phase 15 | Complete |
| BRAIN-04 | Phase 15 | Complete |
| BRAIN-05 | Phase 15 | Complete |
| BRAIN-06 | Phase 15 | Complete |
| HOOK-01 | Phase 16 | Complete |
| HOOK-02 | Phase 16 | Complete |
| HOOK-03 | Phase 16 | Complete |
| HOOK-04 | Phase 16 | Complete |
| HOOK-05 | Phase 16 | Complete |
| HOOK-06 | Phase 16 | Complete |
| KIDX-01 | Phase 17 | Complete |
| KIDX-02 | Phase 17 | Complete |
| KIDX-03 | Phase 17 | Complete |
| KIDX-04 | Phase 17 | Complete |
| KIDX-05 | Phase 17 | Complete |
| RAG2-01 | Phase 18 | Complete |
| RAG2-02 | Phase 18 | Complete |
| RAG2-03 | Phase 18 | Complete |
| RAG2-04 | Phase 18 | Complete |
| RAG2-05 | Phase 18 | Complete |
| WRAP-01 | Phase 19 | Complete |
| WRAP-02 | Phase 19 | Complete |
| WRAP-03 | Phase 19 | Complete |
| WRAP-04 | Phase 19 | Complete |
| WRAP-05 | Phase 19 | Complete |
| WRAP-06 | Phase 19 | Complete |
| WRAP-07 | Phase 19 | Complete |
| MULTI-01 | Phase 20 | Complete |
| MULTI-02 | Phase 20 | Complete |
| MULTI-03 | Phase 20 | Complete |
| MULTI-04 | Phase 20 | Complete |
| MULTI-05 | Phase 20 | Complete |
| DOC12-01 | Phase 21 | Complete |
| DOC12-02 | Phase 21 | Complete |
| DOC12-03 | Phase 21 | Complete |
| DOC12-04 | Phase 21 | Complete |
| DOC12-05 | Phase 21 | Complete |
| DOC12-06 | Phase 21 | Complete |

| CRON-01 | Phase 22 | Complete |
| CRON-02 | Phase 22 | Complete |
| CRON-03 | Phase 22 | Complete |
| CRON-04 | Phase 22 | Complete |
| CRON-05 | Phase 22 | Complete |
| CRON-06 | Phase 22 | Complete |
| QUAL-01 | Phase 23 | Complete |
| QUAL-02 | Phase 23 | Complete |
| QUAL-03 | Phase 23 | Complete |
| QUAL-04 | Phase 23 | Complete |
| QUAL-05 | Phase 23 | Complete |
| QUAL-06 | Phase 23 | Complete |
| EVAL-01 | Phase 24 | Complete |
| EVAL-02 | Phase 24 | Complete |
| EVAL-03 | Phase 24 | Complete |
| EVAL-04 | Phase 24 | Complete |
| EVAL-05 | Phase 24 | Complete |
| DOC13-01 | Phase 25 | Complete |
| DOC13-02 | Phase 25 | Complete |
| DOC13-03 | Phase 25 | Complete |
| DOC13-04 | Phase 25 | Complete |
| CLOSE13-01 | Phase 26 | Complete |
| CLOSE13-02 | Phase 26 | Complete |
| CLOSE13-03 | Phase 26 | Complete |
| CLOSE13-04 | Phase 26 | Complete |
| CLOSE13-05 | Phase 26 | Complete |
| CLOSE13-06 | Phase 26 | Complete |
| CLOSE13-07 | Phase 26 | Complete |
| CLOSE13-08 | Phase 26 | Complete |
| CLOSE13-09 | Phase 26 | Complete |
| DOC14-01 | Phase 27 | Complete |
| DOC14-02 | Phase 27 | Complete |
| DOC14-03 | Phase 27 | Complete |
| DOC14-04 | Phase 27 | Complete |
| DOC14-05 | Phase 27 | Complete |
| DOC14-06 | Phase 27 | Complete |
| TDOC-01 | Phase 28 | Complete |
| TDOC-02 | Phase 28 | Complete |
| TDOC-03 | Phase 28 | Complete |
| TDOC-04 | Phase 28 | Complete |
| TDOC-05 | Phase 28 | Complete |
| TDOC-06 | Phase 28 | Complete |
| TDOC-07 | Phase 28 | Complete |
| OBPL-01 | Phase 29 | Complete |
| OBPL-02 | Phase 29 + Hotfix | Complete (v2 after Hotfix) |
| OBPL-03 | Phase 29 | Pending Maxim Re-Index after UI-Reconfig |
| OBPL-04 | Phase 29 + Hotfix | Complete (UI-Exclude, nicht .scignore) |
| OBPL-05 | Phase 29 | Complete |
| OBPL-06 | Phase 29-Hotfix | Complete (cache clean) |
| OBPL-07 | Phase 29-Hotfix | Complete |
| CLIP-01 | Phase 30 | Complete |
| CLIP-02 | Phase 30 | Complete |
| CLIP-03 | Phase 30 | Complete |
| CLIP-04 | Phase 30 | Complete |
| CLIP-05 | Phase 30 | Complete |
| CLIP-06 | Phase 30 | Deferred v1.5 |
| CLIP-07 | Phase 30 | Complete |
| CLIP-08 | Phase 30 | Complete |
| LOCAL-01 | Phase 31 | Complete |
| LOCAL-02 | Phase 31 | Complete |
| LOCAL-03 | Phase 31 | Complete |
| LOCAL-04 | Phase 31 | Complete |
| CLOSE14-01 | Phase 32 | Complete |
| CLOSE14-02 | Phase 32 | Complete |
| CLOSE14-03 | Phase 32 | Complete |
| CLOSE14-04 | Phase 32 | Complete |
| CLOSE14-05 | Phase 32 | Complete |
| CLOSE14-06 | Phase 32 | Complete |
| CLOSE14-07 | Phase 32 | Complete |
| CLOSE14-08 | Phase 32 | Complete |
| CLOSE14-09 | Phase 32 | Complete |
| CLOSE14-10 | Phase 32 | Complete |
| DOC141-01 | Phase 33 | Complete |
| DOC141-02 | Phase 33 | Complete |
| DOC141-03 | Phase 33 | Complete |
| DOC141-04 | Phase 33 | Complete |
| DOC141-05 | Phase 33 | Complete |
| DOC141-06 | Phase 33 | Complete |

**Coverage:**
- v1.4.1 requirements: DOC141-01..06 (Phase 33) + OBPL141-01..05 (Phase 34) + CLIP141-01..06 (Phase 35) + CLIP141-07..13 (Phase 35-Hotfix)
- v1.4 requirements: 42 total (6 DOC14 + 7 TDOC + 7 OBPL inkl. Hotfix OBPL-06/07 + 8 CLIP + 4 LOCAL + 10 CLOSE14 inkl. Plugin-Landscape 08/09/10), mapped to phases: 42, unmapped: 0 ✓
- v1.3 requirements: 30 total (shipped)
- v1.2 requirements: 43 total (shipped)

## v1.4.1 Requirements (Bridge-Patch)

Kleine Bridge-Phase zwischen v1.4-Close und v1.5-Kickoff. Drei Themen: Obsidian-Doku-Routine, Plugin-Audit (17 neue Plugins), Web-Clipper-Template-System.

### Obsidian-Projekt-Doku-Backfill (DOC141)

- [x] **DOC141-01**: `$TOM_VAULT/30_Projekte/Tom/Phasen/` mit 7 Backfill-Phase-Notes (Phase 27, 28, 29, 29-Hotfix, 30, 31, 32)
- [x] **DOC141-02**: `$TOM_VAULT/30_Projekte/Tom/Journal/2026-04-10.md` Backfill-Eintrag
- [x] **DOC141-03**: `$TOM_VAULT/30_Projekte/Tom/Entscheidungen.md` mit 5–7 retroaktiven Key-Decisions aus v1.4
- [x] **DOC141-04**: `$TOM_VAULT/index.md` Tom-Status-Dashboard-Sektion
- [x] **DOC141-05**: `$TOM_VAULT/99_Vorlagen/Tom-Phase.md` + `Tom-Journal.md` Templates
- [x] **DOC141-06**: `/Users/maxim/Claude/CLAUDE.md` Sektion "Mandatory pro GSD-Phase" mit 4-Punkte-Checklist

### Obsidian Plugin-Audit v1.4.1 (OBPL141)

- [x] **OBPL141-01**: `.planning/obsidian-plugin-config/plugin-audit-v1.4.1.md` mit allen 17 neuen Plugins (Klassifikation, URL, Empfehlung)
- [x] **OBPL141-02**: Config-Backup-Stubs in `.planning/obsidian-plugin-config/<plugin-id>.json` für Setup-Kandidaten (`eml-reader`, `obsidian-apple-reminders-plugin`) — Status `prepared-pending-maxim-activation`
- [x] **OBPL141-03**: `CLAUDE.md` "Obsidian Plugin Landscape" auf 52 Plugins erweitert (neue Kategorie LLM-Alternativen, Email/Messaging-Box, Warnings obsidian-ocr, Empfehlung mcp-tools)
- [x] **OBPL141-04**: ADR-003 `obsidian-ocr` vs `tom-doc` Koexistenz-Entscheidung
- [x] **OBPL141-05**: ADR-004 `mcp-tools` als v1.5-Kandidat (nur Dokumentation, keine Integration)

### Web-Clipper-Template-System (CLIP141)

- [x] **CLIP141-01**: `$TOM_VAULT/99_Vorlagen/web-clipper/` mit 7 Templates (Artikel, Paper, Video, Dokument, Social-Post, Rezept, Werkzeug) + README.md
- [x] **CLIP141-02**: `$TOM_VAULT/Clippings/{Artikel,Paper,Videos,Dokumente,Social,Rezepte,Werkzeuge}/` Zielordner (mit README-Stubs)
- [x] **CLIP141-03**: Browser-Extension-Konfigurations-Doku in `web-clipper/README.md`
- [~] **CLIP141-04**: ~~Smoke-Test (1 echter Clip + `tom-clip-enrich`-Lauf + Idempotenz-Check)~~ **ersetzt durch CLIP141-13** im Phase-35-Hotfix (Interpreter-Pfad statt Post-hoc)
- [x] **CLIP141-05**: `CLAUDE.md` "Ingesting New Sources" um Web-Clipper-Flow-Subsektion ergänzt
- [x] **CLIP141-06**: `tom-clip-enrich`-Anleitung in `web-clipper/README.md` referenziert

### Web-Clipper-Interpreter-Integration — Phase 35-Hotfix (CLIP141-07..13)

- [x] **CLIP141-07**: `OLLAMA_ORIGINS` persistent via `launchctl setenv` auf `chrome-extension://*,moz-extension://*,safari-web-extension://*` gesetzt; CORS-Preflight im README dokumentiert
- [x] **CLIP141-08**: Interpreter-Provider-Setup dokumentiert in `web-clipper/README.md` Abschnitt 2 (Endpoint `http://127.0.0.1:11434/api/chat`, Model `qwen3:8b`)
- [x] **CLIP141-09**: Alle 7 Templates mit 3 Interpreter-Prompts (`summary`, `tags`-Ergänzung, `konzepte_vorschlaege`) refaktoriert inkl. typ-spezifischer Prompt-Formulierung und "Betrachte nur die ersten X Zeichen"-Hinweis. **Schritt 2:** Zusätzlich 7 importable JSON-Templates in `99_Vorlagen/web-clipper/json/Tom-*.json` (Schema `0.1.0`, Properties + noteContentFormat + path), weil die Browser-Extension nur JSON liest, nicht die Vault-Markdown-Files. Modell-Label konsistent `qwen25-interpreter`
- [x] **CLIP141-10**: ADR-005 `adr-005-web-clipper-interpreter-vs-clip-enrich.md` in `.planning/obsidian-plugin-config/` angelegt
- [x] **CLIP141-11**: `web-clipper/README.md` überarbeitet — Interpreter-Setup als Primary, CORS-Troubleshooting, `tom-clip-enrich` auf Fallback-Rolle + `--queue-only` dokumentiert
- [x] **CLIP141-12**: `CLAUDE.md` Web-Clipper-Flow-Sektion aktualisiert — Interpreter-Primary, `--queue-only` erwähnt, ADR-005-Verweis
- [x] **CLIP141-13a**: Ollama-Pipeline (Origin → CORS → `qwen3:8b` → deutsche Antwort) verifiziert via direktem POST gegen `/api/chat` mit Browser-Extension-Origin
- [x] **CLIP141-13b**: 7 Tom-Templates direkt in Chrome-Extension-LevelDB-Storage importiert (Sync Extension Settings, lz-string-UTF16-komprimiert) inkl. Vault-Eintrag `Obsidian_Zentralw`
- [~] **CLIP141-13c**: Echter Browser-Clip mit Frontmatter-Befüllung + `--queue-only`-Test + Fallback-Test — Maxim klickt einmal auf einen echten Wikipedia-Artikel und prüft das Ergebnis (siehe Phase-35-Hotfix-Note)
- [x] **CLIP141-14**: tuan3w-Template-Adaption (Schritt 4) — 6 neue Wiki/Personal-Templates (`Konzept`, `Thema`, `Person-Wiki`, `Buch`, `Zitat`, `Gedanke`) mit Templater-Syntax + Tom-Frontmatter, Templater Folder-Routing für 6 Ordner, 2 Reading-Kanbans in `30_Projekte/Lesen/`, neue Wiki-Subfolder `zitate/` + `werkzeuge/`, README komplett überarbeitet, Entscheidung dokumentiert (Templater statt Auto Note Mover)
- [x] **CLIP141-15**: Interpret-Button-Aktivierung (Schritt 5) — `interpreter_settings` in Chrome-Extension-LevelDB gepatcht: `interpreterModel` auf gemma4-Model-ID `1775722457516` gesetzt (war leer), `interpreterAutoRun` auf `false` gesetzt (war `true`), damit Popup den separaten "interpret"-Button zeigt statt stiller Auto-Ausführung. Node-Script `/tmp/cliplev/patch-interpreter.mjs`, Chrome-quit → patch → reopen Pattern aus Schritt 3 wiederverwendet. Re-Read verifiziert: `interpreterModel == "1775722457516"`, `interpreterAutoRun == false`, Models + Providers unverändert.
  - **Schritt 5-Repair 2026-04-10:** LevelDB-Direktpatch wirkungslos — Button blieb bei Maxim unsichtbar. Read-only Diagnose via `/tmp/cliplev/read-interpreter.mjs` nach Chrome-Restart ergab `interpreterModel == ""` und `interpreterAutoRun == true` ⇒ **Cloud-Overwrite (Ursache #1)**: Chrome Sync pullt `storage.sync` beim Start und überschreibt Updates an bestehenden Keys (ADD-Operationen für `template_list`/`vaults` in Schritt 3 überlebten, UPDATE an `interpreter_settings` nicht). `models` + `providers` (die in Schritt 3 als neue Felder dazugeschrieben wurden) blieben erhalten. **Fix via Extension-Settings-UI durch Maxim** (`chrome-extension://cnjifjpddelmedmihgijeibhnjfabmlf/settings.html` → Interpreter-Tab → Default model = gemma4 + Auto-run aus). Schreibt über offiziellen `saveSettings()`-Pfad, triggert `storage.sync.set` mit korrekter Sync-Propagation. Lesson-Learned → `30_Projekte/Tom/Entscheidungen.md`.

**Code-Patch (v1.4.1 Phase 35-Hotfix):** `claude-memory-compiler/tom_tools/clip_enrich.py` mit `--queue-only`-Flag + erweitertes Skip-Gate für `enriched in (clip-time | tom-clip-enrich)` + `enriched_by`-Feld im Standard-Pfad. Rückwärts-kompatibel zu Phase-30-Legacy-Clippings.

---

## v1.5 Requirements (Current)

Requirements für die v1.5 "Lifecycle + Integration"-Phase: stabiler lokaler Research-/Assistant-Modus auf `qwen3:8b` + `BAAI/bge-small-en-v1.5`, Vault-Hygiene-Cleanup, MCP-Bridge für Tom-CLIs in Obsidian, projekt-übergreifende Lebens-State-Machine für 6 Lebens-Bereiche, Milestone-Close. Phasen 36–44 (Phase 36 ist out-of-band-shipped am 2026-04-11 als Opener und wird retroaktiv aufgenommen).

### Lokaler Claude-Code-Modus — Phase 36 (LOCAL-05) — out-of-band shipped

- [x] **LOCAL-05-01**: Claude Code Router (`@musistudio/claude-code-router`) installiert via `npm -g`, `~/.claude-code-router/config.json` mit Ollama-Provider + Model-Aliasing (`opus/background/haiku → qwen3:8b`), CCR-Daemon läuft auf Port 3456
- [x] **LOCAL-05-02**: `bin/nutze-ollama.sh` Sourced Shell-Library mit Funktionen `nutze-ollama` / `nutze-claude` / `ollama-status`, Preflight für ollama+ccr+modelle, `eval $(ccr activate)`-Pattern statt Hardcoding
- [x] **LOCAL-05-03**: `bin/tom-local` Wrapper-Script (Subshell-Spawn ohne Argument, One-Shot mit Argument), `~/bin/tom-local`-Symlink analog `tom-*`-Konvention
- [x] **LOCAL-05-04**: `~/.zshrc` enthält guarded Source-Line `[[ -f "$HOME/Claude/bin/nutze-ollama.sh" ]] && source ...`, Funktionen sind in jeder neuen Shell verfügbar
- [x] **LOCAL-05-05**: `CLAUDE.md` neue Sektion "Lokaler Ollama-Modus für Claude Code (seit v1.5 Phase 36)" mit Kommando-Referenz, Architektur-Diagramm, prominentem Chat-Only-Warning, Use-Cases-Tabelle, Rollback-Anleitung, VSCode-Extension-Koexistenz
- [x] **LOCAL-05-06**: VSCode Ollama Extension `warm3snow.vscode-ollama-1.2.1` identifiziert (reines Chat-Panel, kein File-I/O, kein Privacy-Risiko) + dokumentiert in CLAUDE.md
- [x] **LOCAL-05-07**: 7-stufige Smoke-Tests durchgeführt: Cloud-Default ✓, Switch ✓, Status ✓, Reset ✓, CCR-Endpoint Chat ✓, tom-local Subshell+One-Shot ✓ — Fokus ist jetzt stabiler Chat/Research auf `qwen3:8b`; fragiler lokaler Tool-Use bleibt bewusst kein Gate

### Vault-Hygiene & Cleanup — Phase 37 (HYG)

- [x] **HYG-01**: Smart Connections `data.json`-Defekt repariert (war 62 Bytes, Phase-29-Playbook re-anwenden, UI-Exclude-Liste verifiziert nach ADR-001) — **Milestone v1.5 Close: akzeptiert als Known Gap** (Maxim-Handoff / Obsidian-UI); siehe `.planning/MILESTONES.md` Known Gaps
- [x] **HYG-02**: 6 unused LLM-Plugins (`cao`, `tars`, `large-language-models`, `llm-summary`, `llm-test-gen`, `ai-latex-generator`) in `community-plugins.json` disabled, in CLAUDE.md Plugin-Landscape als "disabled" markiert — entfernt 2026-04-12
- [x] **HYG-03**: `OLLAMA_ORIGINS` dauerhaft via LaunchAgent `com.maxim.ollama-origins.plist` auf `chrome-extension://*,moz-extension://*,safari-web-extension://*` gesetzt, persistent über Reboot — LaunchAgent erstellt 2026-04-12
- [x] **HYG-04**: `eml-reader` Plugin konfiguriert, Smoke-Test mit `.eml`-Test-Datei in `20_Dokumente/13_Betreuung/` (Preview öffnet sich in Obsidian) — **Milestone v1.5 Close: akzeptiert als Known Gap** (Maxim-Handoff); siehe MILESTONES.md
- [x] **HYG-05**: `obsidian-apple-reminders-plugin` konfiguriert mit Apple-Reminders.app, erste bidirektionale Sync-Probe (1 Reminder rein, 1 raus), Privacy-Boundary dokumentiert — **Milestone v1.5 Close: akzeptiert als Known Gap** (Maxim-Handoff); siehe MILESTONES.md
- [x] **HYG-06**: 5 offene Plugin-Audit-Fragen (Q1–Q5 aus `plugin-audit-v1.4.1.md`) beantwortet, Audit-Doc auf Stand "answered" — beantwortet 2026-04-12
- [x] **HYG-07**: CLIP141-04 Web-Clipper-Smoke-Test durchgeführt mit echtem Browser-Clip und Frontmatter-Verifikation (carryover aus v1.4.1) — **Milestone v1.5 Close: akzeptiert als Known Gap** (Maxim-Handoff); siehe MILESTONES.md
- [x] **HYG-08**: CLIP141-13c Phase-35-Hotfix Interpreter-Smoke-Test durchgeführt ODER Ollama-Models-Path-Defekt (FAM-154) als Blocker gefixt (carryover aus v1.4.1) — **Milestone v1.5 Close: akzeptiert als Known Gap** (Maxim-Handoff); siehe MILESTONES.md
- [x] **HYG-09**: OBPL-03 Smart Connections "TurboQuant"-Smoke-Test nach UI-Reconfig + Re-Index durchgeführt (carryover aus v1.4) — **Milestone v1.5 Close: akzeptiert als Known Gap** (Maxim-Handoff); siehe MILESTONES.md

### Local Tool-Use Modell-Upgrade — Phase 38 (LOCAL-06)

- [x] **LOCAL-06-01**: `qwen3:8b` (bereits installiert, 1.9 GB) hat native Tool-Calls — überraschend besser als `qwen2.5-coder` (das Tool-Calls nur als Text-String liefert). Kein neues Modell nötig. Verifiziert 2026-04-12.
- [x] **LOCAL-06-02**: `~/.claude-code-router/config.json` aktualisiert: Provider `ollama` → `qwen3:8b` als Default. Reference-Copy in `.planning/phases/38-local-toolupgrade/ccr-config.reference.json` — 2026-04-12
- [x] **LOCAL-06-03**: Tool-Use-Gate PASS: CCR-Proxy `/v1/messages` liefert `content[].type == "tool_use"` mit `stop_reason: tool_use` + korrektem Tool-Name/Input — 2026-04-12
- [x] **LOCAL-06-04**: Real-Use-Test PASS: Read-Tool + Shell-Tool korrekt selektiert aus 3-Tool-Set (Read/Shell/Write) via CCR-Proxy im Anthropic-Format — 2026-04-12
- [x] **LOCAL-06-05**: CLAUDE.md "Lokaler Ollama-Modus" Limitations-Sektion updated: Tool-Use FAIL→PASS, Use-Cases erweitert um einfache Tool-Calls — 2026-04-12
- [x] **LOCAL-06-06**: `tom-compile --local` Regression PASS (12s, 1 Artikel generiert, Parse OK), bestehender Compile-Pfad unbeschädigt — 2026-04-12

### MCP-Bridge für Tom-CLIs — Phase 39 (MCP)

- [x] **MCP-01**: MCP-Server-Architektur entschieden + dokumentiert — FastMCP v3 standalone mit stdio-Transport, ADR-006 in `.planning/obsidian-plugin-config/adr-006-mcp-architecture.md` — 2026-04-12
- [x] **MCP-02**: MCP-Server `tom-doc` als 3 separate Tools exposed (`tom_doc_search`, `tom_doc_list`, `tom_doc_show`), async subprocess mit Timeout — 2026-04-12
- [x] **MCP-03**: MCP-Server `tom-wiki` als `tom_wiki_query` Tool exposed, Karpathy-Index-first via qwen3:8b, 120s Timeout — 2026-04-12
- [x] **MCP-04**: MCP-Server `tom-ask` als `tom_ask` Tool exposed, RAG-Query über 3 Collections (wiki/clippings/gehirn), 120s Timeout — 2026-04-12
- [x] **MCP-05**: `tom-clip-enrich` bewusst **nicht** exposed — Write-Zugriff über MCP ist Privacy-Risiko (ADR-006, Entscheidung dokumentiert). CLI bleibt einziger Schreibpfad — 2026-04-12
- [x] **MCP-06**: Privacy-Boundary explizit definiert pro Tool in ADR-006: alle 5 Tools Read-only, kein Write-Zugriff über MCP, persönliche Daten nur bei tom_doc_* und teilweise tom_ask (gehirn) — 2026-04-12
- [x] **MCP-07**: MCP-Server in **Cursor** registriert via `.cursor/mcp.json` (re-scoped: Obsidian `mcp-tools` ist kein generischer MCP-Client, ADR-006). Server startet automatisch via `uv run` bei Cursor-Launch — 2026-04-12
- [x] **MCP-08**: End-to-End-Test: `tom_doc_search("Arbeitsvertrag")` liefert Treffer via MCP-Tool-Call, Timeout-Test bestanden (re-scoped auf Cursor statt Obsidian MCP-Panel) — 2026-04-12
- [x] **MCP-09**: `CLAUDE.md` neue Sektion "MCP-Bridge für Tom-CLIs (seit v1.5 Phase 39)" mit Use-Cases, Privacy-Boundary-Tabelle, Troubleshooting — 2026-04-12

### Lifecycle Foundation — Dokumente — Phase 40 (LCY-01..06)

- [x] **LCY-01**: `state`-Frontmatter-Schema definiert mit 5 Werten für Dokumente (`Eingang`, `In-Bearbeitung`, `Antwort-formuliert`, `Warte-auf-Rückmeldung`, `Erledigt`), dokumentiert in CLAUDE.md + `99_Vorlagen/state-schema.md` — 2026-04-12
- [x] **LCY-02**: `99_Vorlagen/Dokument.md` Template um `state: Eingang` Default + Templater `<% tp.date.now("YYYY-MM-DD") %>` für `state_changed` + Meta Bind Buttons erweitert — 2026-04-12
- [x] **LCY-03**: **Re-scoped**: Statt Templater-Transition-Snippet → Meta Bind Buttons mit `updateMetadata` actions-Array. Jeder Button setzt `state` UND `state_changed` atomar. Grund: `inlineSelect` kann nur 1 Feld updaten, Buttons können via `actions` mehrere Felder atomar setzen — 2026-04-12
- [x] **LCY-04**: Dataview-View `20_Dokumente/Dashboard.md` mit TABLE + 5 Sektionen (Offene, Eingang, In-Bearbeitung, Warte, Kürzlich erledigt, Fällige Fristen), sortiert nach `state_changed` desc, Frist-Highlighting — 2026-04-12
- [x] **LCY-05**: 3 echte Betreuungs-Dokumente in `20_Dokumente/13_Betreuung/` (Vorsorgevollmacht-Waldemar state:Eingang, Pflegegrad-Antrag-Nina state:Warte-auf-Rueckmeldung, Schwerbehindertenausweis-Waldemar state:Erledigt) — End-to-End-Beweis — 2026-04-12
- [x] **LCY-06**: `bin/tom-state migrate-dokumente` migriert 15 Kategorie-Index-Dateien, idempotent (2. Lauf: 0 Migrationen), `--dry-run` Flag, YAML-aware Parser, Symlink in `~/bin/` — 2026-04-12

### Lifecycle — Aufgaben & Termine — Phase 41 (LCY-07..12)

- [x] **LCY-07**: `state`-Schema für `40_Aufgaben/` definiert (`Open`, `Doing`, `Blocked`, `Done`) + `99_Vorlagen/Aufgabe.md` Template entsprechend angepasst — shipped Phase 41a (universelle Lifecycle-Engine, Aufgabe.md mit 4 States + Meta Bind Buttons) + Phase 41b (KI-Intake-Erweiterung)
- [x] **LCY-08**: `state`-Schema für `50_Gesundheit/` Termine definiert (`Geplant`, `Heute`, `Wahrgenommen`, `Verpasst`) + `99_Vorlagen/Arzttermin.md` Template angepasst — shipped Phase 41a (Termin.md mit 5 States inkl. Bestaetigt) + Phase 41b (3 kategorie-spezifische QuickAdd AI Prompts)
- [x] **LCY-09**: Frist-Auto-Highlight via Dataview Universal-Snippet (`due_date < today + 14d → "🔥 Frist naht"-Markierung`), wiederverwendbar in allen Bereichen — shipped Phase 42 (Fristen.md Dashboard mit Countdown + Farbcodierung) + Phase 43 (auto-transition Vertraege aktiv→Frist-naht)
- [x] **LCY-10**: Templater-Transitions für Aufgaben (`Open → Doing → Done`) und Termine (`Geplant → Heute → Wahrgenommen/Verpasst`) — shipped Phase 41a (Meta Bind Buttons statt Templater, atomare state+state_changed Transitions) + Phase 43 (auto-transition CLI)
- [x] **LCY-11**: Dataview-View `40_Aufgaben/Heute.md` zeigt Aufgaben mit `state == Doing` ODER `due_date <= today + 1d` — shipped Phase 43 (Heute.md erweitert mit Dataview-Sektionen fuer Aufgaben, Projekte, Vertraege, Social + Verpasste Termine)
- [x] **LCY-12**: Dataview-View `50_Gesundheit/Heute.md` zeigt Termine mit `date == today` ODER `state == Heute` — shipped Phase 43 (Heute.md zeigt Termine heute + Verpasste Termine vault-weit, tom-status CLI zeigt Termine heute/Woche/Verpasst)

### Lifecycle — Projekte / Finanzen / Social Media — Phase 42 (LCY-13..18)

- [x] **LCY-13**: `state`-Schema für `30_Projekte/` formalisiert (`aktiv`, `pausiert`, `abgeschlossen`) — shipped Phase 41b (Projekt.md Template) + Phase 42 (Aktive.md Dashboard)
- [x] **LCY-14**: `state`-Schema für `60_Finanzen/` definiert (`aktiv`, `Frist-naht`, `Verlaengert`, `Gekuendigt`, `Versaeumt`) — shipped Phase 41b (Vertrag.md Template) + Phase 42 (Fristen.md Dashboard mit Countdown + Farbcodierung)
- [x] **LCY-15**: `state`-Schema für `80_Social_Media/` definiert (`Draft`, `Geplant`, `Live`, `Archiv`) — shipped Phase 41b (Social-Post.md Template) + Phase 42 (Pipeline.md Dashboard)
- [x] **LCY-16**: `99_Vorlagen` um 3 neue Templates erweitert (`Projekt.md`, `Vertrag.md`, `Social-Post.md`) mit state-Defaults — shipped Phase 41b
- [x] **LCY-17**: Dataview-Views in den 3 Bereichen (`30_Projekte/Aktive.md`, `60_Finanzen/Fristen.md`, `80_Social_Media/Pipeline.md`) — shipped Phase 42
- [x] **LCY-18**: Cross-Area-Verlinkung via automatische Backlink-Sektionen in allen 3 Dashboards + `abhaengigkeiten`-Feld in Vertrag.md — shipped Phase 42

### Lifecycle Dashboards + Auto-Routing — Phase 43 (LCY-19..25)

- [x] **LCY-19**: `$TOM_VAULT/index.md` Tom-Hub erweitert um "Heute"-Sektion mit DataviewJS Inline-Queries fuer Live-Zahlen across alle 6 Bereiche + Link auf Morgen-Briefing — 2026-04-12
- [x] **LCY-20**: `40_Aufgaben/Heute.md` um 4 Sektionen erweitert (Verpasste Termine, Aktive Projekte, Vertraege mit Frist, Geplante Social Posts) — re-scoped: bestehendes Dashboard erweitert statt neues Root-Dashboard — 2026-04-12
- [x] **LCY-21**: launchd-Job `com.maxim.tom-state-transitions` taeglich 07:00 + `tom-state auto-transition` Subcommand (Termine Geplant->Heute->Verpasst, Vertraege aktiv->Frist-naht->Versaeumt) + Verpasst-Termin-Handling mit tel:/App-Links — 2026-04-12
- [x] **LCY-22**: Reminders-Sync Templates vorbereitet (`sync_reminders: true` in Aufgabe.md + Termin.md). BRAT-Installation von `obsidian-reminders-sync` als Maxim-Handoff dokumentiert — 2026-04-12
- [x] **LCY-23**: Notification-Pfad: Reminders-Sync Plugin erstellt Apple Reminders mit Due-Date, macOS Notification Center zeigt Erinnerung. Smoke-Test als Maxim-Handoff — 2026-04-12
- [x] **LCY-24**: `bin/tom-status` CLI zeigt Vault-weite Zusammenfassung im Terminal mit Zahlen pro Bereich + Top-5 dringend (inkl. Verpasst-Termine mit tel:-Nummer), `--json` Flag — 2026-04-12
- [x] **LCY-25**: Idempotenz verifiziert: auto-transition prueft `current_state == expected_from_state` vor Write, Verpasst-Empfehlung nur bei fehlendem `<!-- verpasst-empfehlung -->` Marker, Dry-Run bestanden (0 Transitionen bei 2. Lauf) — 2026-04-12

### Milestone-Close v1.5 — Phase 44 (CLOSE15)

- [x] **CLOSE15-01**: `.planning/MILESTONES.md` enthält v1.5-Eintrag nach v1.4-Schema (Start/Ende/Phasen 36–44/Commits/Status/FAMs) — 2026-04-12
- [x] **CLOSE15-02**: `.planning/PROJECT.md` Validated-Sektion enthält v1.5-Deliverables, `Active:` auf `—` — 2026-04-12
- [x] **CLOSE15-03**: `.planning/briefings/v1.5-CEO-Briefing.md` existiert mit ≥150 Zeilen nach v1.3-Template (6 Teile + Anhänge A/B/C) — 281 Zeilen, 2026-04-12
- [x] **CLOSE15-04**: `$TOM_VAULT/log.md` enthält datierten v1.5-Abschluss-Eintrag nach v1.3-Schema — 2026-04-12
- [x] **CLOSE15-05**: `$TOM_VAULT/30_Projekte/Tom.md` aktualisiert (Current Milestone, Werkzeug-Liste, Milestones-Kurz-Historie) — 2026-04-12
- [x] **CLOSE15-06**: Maximus_OS Close-Issue an CEO-Agent (`priority=high`) — **Handoff:** `.planning/phases/44-milestone-close/run-tom-issue-ceo.sh` ausführen sobald Paperclip API erreichbar (`localhost:3100`); bei laufendem Server: `tom-issue` postet FAM/Identifier — 2026-04-12
- [x] **CLOSE15-07**: Alle v1.5-Requirements in REQUIREMENTS.md als `[x]`; HYG-01/04/05/07/08/09 als **Known Gaps** dokumentiert (Milestone-Close akzeptiert, nicht blockierend) — 2026-04-12

---

## v1.6 Requirements

Requirements für v1.6 "Expansion": externe Open-Source-Tools integrieren, Token-Optimierung, Eval-Verbesserung, Skill-Engine. Phasen 47–53.

### Plugin-Installationen + Raw/Vault-Bereinigung — Phase 47 (PLUG16) — Done

- [x] **PLUG16-01**: Security Guidance Skill installiert und aktiv (9 Pattern-Checks als PreToolUse-Hook)
- [x] **PLUG16-02**: claude-mem evaluiert und bewusst übersprungen (funktional redundant mit claude-memory-compiler + 95_Gehirn)
- [x] **PLUG16-03**: 122 leere Raw-Ordner gelöscht (160→38 Ordner), `bin/tom-raw-cleanup` Tool erstellt
- [x] **PLUG16-04**: Raw-Inventar + Triage dokumentiert in `.planning/phases/47-plugins-raw-cleanup/raw-inventar.md`
- [x] **PLUG16-05**: 00_Inbox-Herkunft geklärt (207 Notes von Apple Intelligence Raw Watcher + tom-raw-inject, nicht Cursor)

### RAG-Anything Multimodal — Phase 48 (RAG16) — Done

- [x] **RAG16-01**: RAG-Anything lokal installiert (`rag-anything-env`, MinerU, LightRAG, Python 3.13) — siehe `48-01-SUMMARY.md`
- [x] **RAG16-02**: Eval-Spezifikation + Ergebnis-Vorlage + `scripts/rag_anything_eval_run.py` (10-Dok-Lauf: privat ausfüllen, siehe `48-02-EVAL-SPEC.md`)
- [x] **RAG16-03**: Subcommand `tom-doc multi-search` + `scripts/tom_doc_multi_search.py` (Opt-in-Manifest, parallel zu FTS5)
- [x] **RAG16-04**: MCP-Tool `tom_doc_multi_search` in `mcp-server/tom_mcp.py`
- [x] **RAG16-05**: `tom-doc search` (FTS5) Regression verifiziert; Tabellen-Zahlen-Query: manuell nach Indexierung laut Eval-Protokoll
- [x] **RAG16-06**: Privacy — nur `127.0.0.1:11434` / lokales Ollama im neuen Pfad; MCP Read-only (siehe `VERIFICATION.md`)

### Codex-Plugin Token-Optimierung — Phase 49 (CDX16)

- [x] **CDX16-01**: OpenAI-Account Free-Tier-Limits geklärt (Referenz: `.planning/phases/49-codex-plugin-token-opt/49-OPENAI-CODEX-LIMITS.md`; Dashboard bleibt Source of Truth)
- [x] **CDX16-02**: Codex-Plugin (`openai/codex-plugin-cc`) in **Claude Code** installiert (manuell) — Maxim 2026-04-16
- [x] **CDX16-03**: Smoke-Test `/codex:review` gegen `bin/tom-raw-batch` erfolgreich (manuell) — Maxim 2026-04-16
- [x] **CDX16-04**: Privacy-Grenzen definiert (`.planning/phases/49-codex-plugin-token-opt/PRIVACY.md`)
- [x] **CDX16-05**: CLAUDE.md Update mit Wann-Codex-statt-Claude-Regel

### Autoresearch Eval-Pipeline — Phase 50 (ARES16)

- [x] **ARES16-01**: karpathy/autoresearch analysiert, übertragbare Konzepte identifiziert (`50-RESEARCH.md`)
- [x] **ARES16-02**: `Gemma/eval/run_eval.py` um automatische Fragengenerierung erweitert (`generate-questions` + `questiongen.py`)
- [x] **ARES16-03**: Pro Eval-Tool-Aufruf messbar: Wall-Zeit + stdout-Länge → `Gemma/eval/results/eval_run_metrics.jsonl` (Compile-Token in `collector.py`: später / separat)
- [x] **ARES16-04**: Neue Testfragen aus Wiki-Index (Wikilinks), reproduzierbar via `--seed`
- [x] **ARES16-05**: Eval-Reports mit Baseline-Vergleich zu `v1.3-baseline.md` (Avg/Wins); keine automatische Score-Garantie

### OpenSpace Skill-Engine — Phase 51 (OSP16)

- [x] **OSP16-01**: Privacy-Check: Cloud-Skill-Sharing evaluiert (falls ja: NUR lokale Teile)
- [x] **OSP16-02**: Bestehende Superpowers-Skills bewertet (Nutzung, Redundanz, Lücken)
- [x] **OSP16-03**: 3 Tom-Workflow-Skills entwickelt (Dokument-Intake, Wiki-Query, Status-Check)
- [x] **OSP16-04**: Token-Messung Vorher/Nachher mit `rtk gain` — Projekt-Baseline + Follow-up: `51-RTK-NOTES.md`
- [x] **OSP16-05**: Abbruch-Bedingung dokumentiert falls Cloud-Skill-Sharing → Phase auf Analyse reduziert

### Clicky Lokal-Build — Phase 52 (CLK16)

- [x] **CLK16-01**: Fork + Xcode-Build (Swift, macOS 14.2+ Target) — `./bin/tom-clicky-build`, Debug **Clicky.app** (DerivedData), 2026-04-15/16
- [ ] **CLK16-02**: Minimal-Build: Screenshot + Ollama-Query (ohne Voice als MVP)
- [ ] **CLK16-03**: Lokalisierung: AssemblyAI→Whisper.cpp, ElevenLabs→weglassen, Claude API→Ollama/qwen3:8b
- [ ] **CLK16-04**: CLAUDE.md + AGENTS.md in Clicky-Kontext eingebunden
- [ ] **CLK16-05**: Menu-Bar-App startet + Screenshot-Analyse über Ollama funktioniert — App-Start aus Debug-Build möglich; Ollama-Ende offen bis CLK16-02/03

> **Repo geliefert (ohne E2E-Abnahme):** Patch `artifacts/companion-manager-local-ollama.patch`, `bin/tom-clicky-apply-local-proxy`, `bin/tom-clicky-ollama-smoke`, `52-OLLAMA-PROXY.md` (curl), `52-TOM-CONTEXT-CLICKY.md` (CLK16-04). Checkboxen CLK16-02..05 bleiben bis Screenshot→Ollama wirklich getestet.

### audiobridge Transkription — Phase 53 (AUD16)

- [ ] **AUD16-01**: Browser-Extension installiert (Chrome/Safari dev-mode)
- [ ] **AUD16-02**: API-Backend konfiguriert (OpenAI-kompatibel oder Ollama-Whisper-Endpoint)
- [ ] **AUD16-03**: Plaud-Note-Pro-Koexistenz geprüft (Export-Format, Transkript-Verbesserung)
- [ ] **AUD16-04**: Transkripte als Markdown-Notes in `$TOM_VAULT/raw/transkripte/` nutzbar

> **Repo geliefert:** `bin/tom-vault-transkripte-dir` (legt `raw/transkripte/` an, wenn `TOM_VAULT` gesetzt) + `53-RUNBOOK.md`. AUD16-Checkboxen bleiben bis Extension/API/Export von dir verifiziert.

### Shortcuts-Forge — AI→Apple-Shortcuts-Pipeline — Phase 61 (SCF16)

- [x] **SCF16-01**: Ablage + Setup: `~/Documents/Tom-Shortcuts/{drafts,signed,helpers,archive}`; `tom-shortcut setup` idempotent; `CLAUDE_PLUGIN_OPTION_OUTPUT_DIR` via settings.json-env persistiert; manueller `/plugin`-userConfig-Weg dokumentiert — verifiziert 2026-07-19
- [x] **SCF16-02**: Helper-Bibliothek: je 1 Python/AppleScript/Swift-Helper nach dokumentiertem Helper-Vertrag; `bin/build-shortcut-helpers` (swiftc + ad-hoc codesign + Smoke-Tests); Symlink-Deploy mit `--copy`-Fallback — Smoke-Tests grün
- [x] **SCF16-03**: CLI `bin/tom-shortcut`: build (headless `claude --print` + Fallback-Prompt + Artefakt-Verifikation + tidy), list, run, import, helpers deploy, setup — „Hallo Tom" E2E (Build+Import+Run), „Uhrzeit-Test" via `--fallback-prompt`
- [ ] **SCF16-04**: Stream-Deck-Button `bin/streamdeck/tom-shortcut-build.command` (prompt_text → build → pause_terminal) — Repo shipped; Doppelklick-Test + Elgato-Registrierung manuell offen
- [x] **SCF16-05**: Doku: `shortcuts-forge/README.md` (Helper-Vertrag, Cherri-Sektion, Troubleshooting, Privacy) + CLAUDE.md-Sektion `tom-shortcut`
- [ ] **SCF16-06**: E2E-Verifikation: „Hallo Tom" Build+Import+Run ✓; „Helper-Test" Run ✓ (Kette Kurzbefehl→zsh→Symlink→Python-Helper, 2026-07-20); „Uhrzeit-Test" Fallback+Run ✓; „Batterie-Status" Regression Plugin 1.2.1 ✓; Session-Pfad **offen** (nach Session-Neustart)

> **Repo geliefert:** Pipeline komplett + 2 signierte Test-Shortcuts verifiziert. SCF16-04/-06-Checkboxen bleiben bis Maxim Helper-Test-Run, Session-Probe und Stream-Deck-Klick bestätigt (siehe `61-shortcuts-forge/VERIFICATION.md`).

---

## Coverage: v1.6

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLUG16-01 | 47 | Complete |
| PLUG16-02 | 47 | Complete |
| PLUG16-03 | 47 | Complete |
| PLUG16-04 | 47 | Complete |
| PLUG16-05 | 47 | Complete |
| RAG16-01 | 48 | Complete |
| RAG16-02 | 48 | Complete |
| RAG16-03 | 48 | Complete |
| RAG16-04 | 48 | Complete |
| RAG16-05 | 48 | Complete |
| RAG16-06 | 48 | Complete |
| CDX16-01 | 49 | Complete |
| CDX16-02 | 49 | Complete |
| CDX16-03 | 49 | Complete |
| CDX16-04 | 49 | Complete |
| CDX16-05 | 49 | Complete |
| ARES16-01 | 50 | Complete |
| ARES16-02 | 50 | Complete |
| ARES16-03 | 50 | Complete |
| ARES16-04 | 50 | Complete |
| ARES16-05 | 50 | Complete |
| OSP16-01 | 51 | Complete |
| OSP16-02 | 51 | Complete |
| OSP16-03 | 51 | Complete |
| OSP16-04 | 51 | Complete |
| OSP16-05 | 51 | Complete |
| CLK16-01 | 52 | Complete |
| CLK16-02 | 52 | Pending |
| CLK16-03 | 52 | Pending |
| CLK16-04 | 52 | Pending |
| CLK16-05 | 52 | Pending |
| AUD16-01 | 53 | Pending |
| AUD16-02 | 53 | Pending |
| AUD16-03 | 53 | Pending |
| AUD16-04 | 53 | Pending |
| SCF16-01 | 61 | Pending |
| SCF16-02 | 61 | Pending |
| SCF16-03 | 61 | Pending |
| SCF16-04 | 61 | Pending |
| SCF16-05 | 61 | Pending |
| SCF16-06 | 61 | Pending |

**Coverage:**
- v1.6 requirements: 40 total (5 PLUG16 + 6 RAG16 + 5 CDX16 + 5 ARES16 + 5 OSP16 + 5 CLK16 + 4 AUD16 + 6 SCF16 - 1 abzgl. Phase 46 nicht in v1.6), mapped to phases: 40, unmapped: 0 ✓

---
*Requirements defined: 2026-04-10*
*Last updated: 2026-07-19 — Phase 61 shortcuts-forge: SCF16-01..06 hinzugefügt (AI→Apple-Shortcuts-Pipeline)*
