# Requirements: Tom — Persönlicher Lebens-Assistent

**Defined:** 2026-04-10
**Current Milestone:** v1.4 — Aktive KI + Dokumenten-Fundament
**Core Value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles, was in seinem Leben wichtig ist — Tom weiß, wo was liegt, und unterstützt proaktiv.

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

- [ ] **TDOC-01**: `bin/tom-doc` Wrapper mit Subcommands `index`, `search`, `list`, `show`
- [ ] **TDOC-02**: `tom-doc index [kategorie]` — scant Archiv-Kategorie, OCR'd neue PDFs, aktualisiert FTS5-Index
- [ ] **TDOC-03**: `tom-doc search "query"` — FTS5-Query mit Trefferliste `kategorie/dateiname + Snippet`
- [ ] **TDOC-04**: `tom-doc show <pfad>` — zeigt Metadaten + OCR-Text-Auszug
- [ ] **TDOC-05**: `tom-doc list [kategorie]` — listet alle indizierten Dokumente einer Kategorie
- [ ] **TDOC-06**: Symlink in `~/bin/tom-doc` angelegt
- [ ] **TDOC-07**: `CLAUDE.md` Wissens-Kaskade um Dokumenten-Fragen (`tom-doc search`) erweitert

### Gemma-in-Obsidian via Community-Plugin (OBPL)

- [ ] **OBPL-01**: Smart Connections Plugin installiert + mit Ollama-Backend konfiguriert (Embedding: `nomic-embed-text`, Chat: `gemme`); Fallback-Option Obsidian Copilot dokumentiert
- [ ] **OBPL-02**: Plugin-Settings als JSON-Backup in `.planning/obsidian-plugin-config/smart-connections.json`
- [ ] **OBPL-03**: Smoke-Test: Semantic-Search findet `konzepte/turboquant.md` bei Query "TurboQuant"
- [ ] **OBPL-04**: Smart Connections indexiert NUR `90_Wiki/` + `95_Gehirn/knowledge/` — NICHT `10_Personen/`, `20_Dokumente/`, `40_Aufgaben/`, `50_Gesundheit/`, `60_Finanzen/` (Privacy via `.scignore` oder Exclude-Liste)
- [ ] **OBPL-05**: `CLAUDE.md` Wissens-Kaskade dokumentiert neue Option (6) "Ad-hoc im Editor → Smart Connections Panel"

### Clipper Auto-Enrichment (CLIP)

- [ ] **CLIP-01**: `bin/tom-clip-enrich` liest Clipping-Datei, ruft `gemme` lokal, schreibt angereicherte Version zurück; idempotent via `enriched: true` Frontmatter-Flag
- [ ] **CLIP-02**: Enrichment — **Summary**: 3–5 Sätze in Frontmatter-Feld `summary`
- [ ] **CLIP-03**: Enrichment — **Auto-Tags**: 3–5 gemme-Tags an existierende `tags` appended (dedupliziert)
- [ ] **CLIP-04**: Enrichment — **Konzept-Extraktion**: 2–4 Begriffe als Zeilen in `$TOM_VAULT/90_Wiki/konzepte-vorschlaege.md` (Review-Schleife, NICHT direkt als Stub-Pages)
- [ ] **CLIP-05**: Enrichment — **Wiki-Kategorie-Vorschlag**: `gemme` wählt eine `90_Wiki/`-Subkategorie (themen/konzepte/personen/projekte/quellen) → Frontmatter-Feld `suggested_wiki_category`
- [ ] **CLIP-06**: `tom-clip-enrich --watch` optional (deferrable) — `fswatch` auf `$TOM_VAULT/Clippings/`
- [ ] **CLIP-07**: Smoke-Test mit `Mannheim – Wikipedia.md` — alle 4 Enrichment-Felder gefüllt, keine Halluzinationen
- [ ] **CLIP-08**: `tom-clip-enrich` als Hook in `tom-compile-safe` ODER separater launchd-Job (Entscheidung in Phase 30)

### Token-Spar-Lokalisierung (LOCAL)

- [ ] **LOCAL-01**: `tom-compile --local` Alternative-Pfad über `gemme` statt `claude_agent_sdk`; Default bleibt `claude_agent_sdk`
- [ ] **LOCAL-02**: Eval-Vergleich `tom-compile` vs `tom-compile --local` auf 3 daily-logs in `Gemma/eval/results/v1.4-compile-local-vs-claude.md`
- [ ] **LOCAL-03**: `tom-lint --no-llm` (oder existierendes `--structural-only`) als launchd-tauglicher Default dokumentiert
- [ ] **LOCAL-04**: Maximus_OS-Issue dokumentiert Token-Ersparnis-Entscheidungsstand

### Milestone-Close v1.4 (CLOSE14)

- [ ] **CLOSE14-01**: `.planning/MILESTONES.md` v1.4-Eintrag nach v1.1/v1.2/v1.3-Schema
- [ ] **CLOSE14-02**: `.planning/PROJECT.md` Validated-Sektion um v1.4-Deliverables erweitert
- [ ] **CLOSE14-03**: `.planning/briefings/v1.4-CEO-Briefing.md` nach v1.3-Template (6 Teile + Anhänge)
- [ ] **CLOSE14-04**: `$TOM_VAULT/log.md` v1.4-Eintrag nach v1.3-Schema
- [ ] **CLOSE14-05**: `$TOM_VAULT/30_Projekte/Tom.md` Current-Milestone + Werkzeug-Liste um `tom-doc`, `tom-clip-enrich` ergänzt
- [ ] **CLOSE14-06**: Maximus_OS-Issue an CEO (`priority=high`) schließt v1.4 offiziell ab
- [ ] **CLOSE14-07**: Alle v1.4-Requirements in REQUIREMENTS.md als [x]

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
- [x] **QUAL-02**: Context-Filter reduziert den an `gemme` übergebenen Kontext auf nur Index + relevante Artikel (statt alle) — per Keyword-Matching aus Query
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
| TDOC-01 | Phase 28 | Pending |
| TDOC-02 | Phase 28 | Pending |
| TDOC-03 | Phase 28 | Pending |
| TDOC-04 | Phase 28 | Pending |
| TDOC-05 | Phase 28 | Pending |
| TDOC-06 | Phase 28 | Pending |
| TDOC-07 | Phase 28 | Pending |
| OBPL-01 | Phase 29 | Pending |
| OBPL-02 | Phase 29 | Pending |
| OBPL-03 | Phase 29 | Pending |
| OBPL-04 | Phase 29 | Pending |
| OBPL-05 | Phase 29 | Pending |
| CLIP-01 | Phase 30 | Pending |
| CLIP-02 | Phase 30 | Pending |
| CLIP-03 | Phase 30 | Pending |
| CLIP-04 | Phase 30 | Pending |
| CLIP-05 | Phase 30 | Pending |
| CLIP-06 | Phase 30 | Pending |
| CLIP-07 | Phase 30 | Pending |
| CLIP-08 | Phase 30 | Pending |
| LOCAL-01 | Phase 31 | Pending |
| LOCAL-02 | Phase 31 | Pending |
| LOCAL-03 | Phase 31 | Pending |
| LOCAL-04 | Phase 31 | Pending |
| CLOSE14-01 | Phase 32 | Pending |
| CLOSE14-02 | Phase 32 | Pending |
| CLOSE14-03 | Phase 32 | Pending |
| CLOSE14-04 | Phase 32 | Pending |
| CLOSE14-05 | Phase 32 | Pending |
| CLOSE14-06 | Phase 32 | Pending |
| CLOSE14-07 | Phase 32 | Pending |

**Coverage:**
- v1.4 requirements: 37 total (6 DOC14 + 7 TDOC + 5 OBPL + 8 CLIP + 4 LOCAL + 7 CLOSE14), mapped to phases: 37, unmapped: 0 ✓
- v1.3 requirements: 30 total (shipped)
- v1.2 requirements: 43 total (shipped)

---
*Requirements defined: 2026-04-10*
*Last updated: 2026-04-10 after v1.4 milestone start*
