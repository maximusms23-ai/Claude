# Roadmap: Tom — Persönlicher Lebens-Assistent

## v1.0 Complete

Phases 1–7 shipped in commit `525c073` (2026-04-10). See git history for v1.0 phase details.

| Phase | Goal | Status |
|-------|------|--------|
| 1 — Identität Tom | Claude-Rolle auf Tom umstellen | ✓ Done |
| 2 — Vault-Struktur | 00–99 Ordner, Migration, Symlink, mkdocs | ✓ Done |
| 3 — Personen-Seiten | 6 Personen-Seiten anlegen + vernetzen | ✓ Done |
| 4 — Dokumente-Mapping | 15 Kategorie-Metadaten-Seiten | ✓ Done |
| 5 — Templates | 9 Vorlagen in 99_Vorlagen/ | ✓ Done |
| 6 — Bootstrap | Gerüst-Seiten + Dashboard + Log | ✓ Done |
| 7 — Workflows | WF-01..05 in Vault-CLAUDE.md | ✓ Done |

---

## v1.1 — Maximus_OS Integration + Ollama Gemma Revival (Complete)

**Goal:** Vault-Single-Source (iCloud), Hybrid-Integration mit Maximus_OS/PaperclipAI, lokales Gemma-Model gegen neuen Vault mit RAG.

### Phases

- [x] **Phase 8: Vault-Cleanup** — iCloud als Single Source of Truth, lokales Duplikat entfernt
- [x] **Phase 9: Maximus_OS Integration Tooling** — `tom-issue` Wrapper + Kommunikationsregeln
- [x] **Phase 10: Ollama Installation** — Ollama unter `/Users/maxim/Ollama` mit `gemma4:e4b`
- [x] **Phase 11: Gemma Custom Model + RAG Pipeline** — `gemme`-Model, ChromaDB, Eval
- [x] **Phase 12: Tom ↔ Gemma Wiring** — `tom-ask` Wrapper live
- [x] **Phase 13: Dokumentation + Abschluss** — v1.1 Milestone-Close

Commit-Trail siehe `MILESTONES.md`.

---

## v1.2 — Karpathy Wiki + claude-memory-compiler

**Goal:** Hybrid Wissens-System: Karpathy Index-first Retrieval für `90_Wiki/` (external), neues privates `95_Gehirn/` (internal) mit automatischem Capture aus Claude-Code-Konversationen via `claude-memory-compiler`, RAG bleibt als Fallback und wächst um dritte Collection.

### Phases

- [ ] **Phase 14: Tool-Install** — `claude-memory-compiler` geklont, gepatcht, Smoke-Test grün
- [ ] **Phase 15: Brain-Struktur** — `$TOM_VAULT/95_Gehirn/` Ordner, Privacy-Regeln, MkDocs-Ausschluss
- [ ] **Phase 16: Hook-Integration** — Projekt-lokale Claude-Code Hooks für Auto-Capture
- [ ] **Phase 17: Karpathy-Index für 90_Wiki** — `90_Wiki/index.md` neu im Karpathy-Retrieval-Stil
- [ ] **Phase 18: RAG-Erweiterung um gehirn-Collection** — Dritte ChromaDB-Collection additiv
- [ ] **Phase 19: Neue Wrapper tom-wiki/tom-compile/tom-lint** — CLI-Tools + Wissens-Kaskade
- [ ] **Phase 20: Multi-Projekt-Konvention** — `wiki_path`-Konvention über mehrere Projekte
- [ ] **Phase 21: Abschluss-Doku + Milestone-Close** — v1.2 Doku, Artikel, Close-Issue

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 14. Tool-Install | 0/? | Not started | — |
| 15. Brain-Struktur | 0/? | Not started | — |
| 16. Hook-Integration | 0/? | Not started | — |
| 17. Karpathy-Index für 90_Wiki | 0/? | Not started | — |
| 18. RAG-Erweiterung um gehirn-Collection | 0/? | Not started | — |
| 19. Neue Wrapper tom-wiki/tom-compile/tom-lint | 0/? | Not started | — |
| 20. Multi-Projekt-Konvention | 0/? | Not started | — |
| 21. Abschluss-Doku + Milestone-Close | 0/? | Not started | — |

---

## Phase Details (v1.2)

### Phase 14: Tool-Install

**Goal**: `claude-memory-compiler` ist lokal installiert, gegen `$TOM_VAULT/95_Gehirn/` konfiguriert, und ein Struktur-Lint läuft grün.

**Depends on**: Nothing (erste v1.2-Phase, parallel zu Phase 15 möglich)

**Requirements**: TOOL-01, TOOL-02, TOOL-03, TOOL-04, TOOL-05

**Success Criteria** (what must be TRUE):
1. `/Users/maxim/Claude/claude-memory-compiler/` existiert als geklontes Git-Repo und ist im Parent-Repo getrackt
2. `uv sync` im Tool-Repo läuft ohne Fehler durch, `uv run scripts/lint.py --structural-only` terminiert mit Exit-Code 0
3. `scripts/config.py` referenziert `TOM_VAULT` per Env-Var und zeigt auf `$TOM_VAULT/95_Gehirn/`
4. Ein Maximus_OS-Issue an CTO dokumentiert Tool-Install + Config-Patch mit Commit-Hash

**Plans**: TBD

---

### Phase 15: Brain-Struktur

**Goal**: Der neue private `95_Gehirn/`-Raum ist im Vault angelegt, dokumentiert Privacy-Regeln und ist verifiziert vom MkDocs-Publish-Scope ausgeschlossen.

**Depends on**: Nothing (parallel zu Phase 14 möglich)

**Requirements**: BRAIN-01, BRAIN-02, BRAIN-03, BRAIN-04, BRAIN-05, BRAIN-06

**Success Criteria** (what must be TRUE):
1. `$TOM_VAULT/95_Gehirn/` enthält Unterordner `daily/`, `knowledge/{concepts,connections,qa}/`, `reports/`
2. `95_Gehirn/CLAUDE.md` dokumentiert was rein darf, was nicht, Compile-Trigger und Lint-Regeln
3. `95_Gehirn/index.md` und `log.md` existieren mit Initial-Inhalt
4. `mkdocs.yml` ist verifiziert — ein Build-Dry-Run enthält keine `95_Gehirn/`-Pfade
5. Ein Maximus_OS-Issue an archivarius dokumentiert Struktur + Privacy-Regeln

**Plans**: TBD

---

### Phase 16: Hook-Integration

**Goal**: Projekt-lokale Claude-Code-Hooks schreiben bei SessionEnd automatisch Daily-Entries nach `95_Gehirn/daily/`, ohne bestehende globale GSD/RTK-Hooks zu brechen.

**Depends on**: Phase 14 (Tool installiert), Phase 15 (Brain-Struktur existiert)

**Requirements**: HOOK-01, HOOK-02, HOOK-03, HOOK-04, HOOK-05, HOOK-06

**Success Criteria** (what must be TRUE):
1. `/Users/maxim/Claude/.claude/settings.json` existiert und enthält `SessionStart`, `SessionEnd`, `PreCompact` Hooks via `uv run` auf `claude-memory-compiler/hooks/*.py`
2. Nach einer Claude-Code-Session existiert ein Entry in `$TOM_VAULT/95_Gehirn/daily/YYYY-MM-DD.md`
3. Globale GSD + RTK Hooks sind nach dem Merge noch funktional (Smoke-Test: `rtk --version`, GSD-Hook-Trigger)
4. `/Users/maxim/Claude/CLAUDE.md` dokumentiert aktive Hooks + Auto-Capture-Verhalten
5. Ein Maximus_OS-Issue an CTO dokumentiert Hook-Aktivierung

**Plans**: TBD

---

### Phase 17: Karpathy-Index für 90_Wiki

**Goal**: `90_Wiki/index.md` ist nach Karpathy-Retrieval-Methode neu geschrieben — Index-first, gruppiert, mit Nutzungshinweis — und beantwortet typische Fragen ohne RAG.

**Depends on**: Nothing (unabhängig von Tool-Install)

**Requirements**: KIDX-01, KIDX-02, KIDX-03, KIDX-04, KIDX-05

**Success Criteria** (what must be TRUE):
1. Alter `index.md` ist als `90_Wiki/history.md` erhalten (Changelog bewahrt)
2. Neuer `90_Wiki/index.md` beginnt mit Nutzungshinweis "zuerst Index, dann 3–5 relevante Artikel lesen, dann synthetisieren"
3. Alle bestehenden `90_Wiki/`-Artikel sind gelistet mit 1–2-Zeilen-Beschreibung, gruppiert nach Konzepte/Themen/Projekte/Personen/Quellen
4. Smoke-Test: "Was ist Turboquant?" wird via Index → direkte Reads beantwortet, ohne RAG
5. Ein Maximus_OS-Issue an wiki-kurator dokumentiert die Index-Umschreibung

**Plans**: TBD

---

### Phase 18: RAG-Erweiterung um gehirn-Collection

**Goal**: Die Gemma-RAG-Pipeline indiziert additiv eine dritte Collection `gehirn` aus `95_Gehirn/knowledge/` und durchsucht sie zusammen mit `wiki` und `clippings`.

**Depends on**: Phase 15 (`95_Gehirn/knowledge/` muss existieren, ggf. leer)

**Requirements**: RAG2-01, RAG2-02, RAG2-03, RAG2-04, RAG2-05

**Success Criteria** (what must be TRUE):
1. `Gemma/rag/config.py` definiert `GEHIRN_PATH = TOM_VAULT / "95_Gehirn" / "knowledge"`
2. `index.py` indiziert die dritte Collection `gehirn` additiv in `index_all()`; gegen leeres Verzeichnis meldet es 0 Chunks fehlerfrei
3. `query.py` durchsucht alle drei Collections (wiki, clippings, gehirn) in einem Call
4. Ein Maximus_OS-Issue an CTO dokumentiert die RAG-Erweiterung

**Plans**: TBD

---

### Phase 19: Neue Wrapper tom-wiki/tom-compile/tom-lint

**Goal**: Drei neue CLI-Wrapper sind live: `tom-wiki` (Index-first Query), `tom-compile` (Memory-Compile), `tom-lint` (Brain-Struktur-Lint). Die Wissens-Kaskade Direct-Read → tom-wiki → tom-ask ist dokumentiert.

**Depends on**: Phase 14 (compile/lint-Scripts vorhanden), Phase 17 (`90_Wiki/index.md` neu)

**Requirements**: WRAP-01, WRAP-02, WRAP-03, WRAP-04, WRAP-05, WRAP-06, WRAP-07

**Success Criteria** (what must be TRUE):
1. `bin/tom-wiki`, `bin/tom-compile`, `bin/tom-lint` sind ausführbar und nach `~/bin/` symlinked
2. `tom-wiki "Was ist Ollama?"` liefert eine Antwort via Index ohne RAG-Aufruf
3. `tom-lint --structural-only` läuft fehlerfrei gegen den aktuellen `95_Gehirn/`-Stand
4. `CLAUDE.md` + `AGENTS.md` dokumentieren die dreistufige Wissens-Kaskade (Direct-Read → tom-wiki → tom-ask)
5. Ein Maximus_OS-Issue an CTO dokumentiert die neuen CLI-Tools

**Plans**: TBD

---

### Phase 20: Multi-Projekt-Konvention

**Goal**: Die `wiki_path`-Konvention erlaubt es fremden Projekten auf demselben Mac, dasselbe `95_Gehirn/` und `90_Wiki/` zu nutzen. Ein zweites Projekt verifiziert das End-to-End.

**Depends on**: Phase 19 (Wrapper müssen existieren)

**Requirements**: MULTI-01, MULTI-02, MULTI-03, MULTI-04, MULTI-05

**Success Criteria** (what must be TRUE):
1. Die `wiki_path`-Template-Konvention ist entweder in `claude-memory-compiler/docs/multi-project.md` oder als CLAUDE.md-Anhang dokumentiert
2. Mindestens ein zweites Projekt auf dem Mac hat die `wiki_path`-Sektion eingebettet
3. Smoke-Test: `tom-wiki "Frage"` aus dem zweiten Projekt-Verzeichnis liefert eine Antwort
4. `95_Gehirn/CLAUDE.md` erwähnt dass Brain shared ist, pro Projekt eigene Daily-Logs möglich
5. Ein Maximus_OS-Issue an wiki-kurator dokumentiert die Multi-Projekt-Konvention

**Plans**: TBD

---

### Phase 21: Abschluss-Doku + Milestone-Close

**Goal**: v1.2 ist in Vault, Wiki und Planning-Artefakten vollständig dokumentiert; ein Milestone-Close-Issue an CEO schließt v1.2 formal ab.

**Depends on**: Phases 14–20 (alles live bevor dokumentiert)

**Requirements**: DOC12-01, DOC12-02, DOC12-03, DOC12-04, DOC12-05, DOC12-06

**Success Criteria** (what must be TRUE):
1. `$TOM_VAULT/log.md` enthält einen datierten v1.2-Abschluss-Eintrag
2. `90_Wiki/projekte/claude-memory-compiler.md` und `90_Wiki/konzepte/karpathy-wiki-methode.md` existieren als publizierbare Artikel
3. `claude-memory-compiler/TOM-PATCHES.md` dokumentiert alle Config-Änderungen gegen Upstream
4. `REQUIREMENTS.md`, `STATE.md`, `MILESTONES.md`, `PROJECT.md` sind auf v1.2 Close aktualisiert
5. Ein finales Maximus_OS Milestone-Close-Issue an CEO (`priority=high`) referenziert alle Commit-Hashes und die Verification-Summary

**Plans**: TBD

---

## Coverage: v1.2

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOOL-01 | 14 | Pending |
| TOOL-02 | 14 | Pending |
| TOOL-03 | 14 | Pending |
| TOOL-04 | 14 | Pending |
| TOOL-05 | 14 | Pending |
| BRAIN-01 | 15 | Pending |
| BRAIN-02 | 15 | Pending |
| BRAIN-03 | 15 | Pending |
| BRAIN-04 | 15 | Pending |
| BRAIN-05 | 15 | Pending |
| BRAIN-06 | 15 | Pending |
| HOOK-01 | 16 | Pending |
| HOOK-02 | 16 | Pending |
| HOOK-03 | 16 | Pending |
| HOOK-04 | 16 | Pending |
| HOOK-05 | 16 | Pending |
| HOOK-06 | 16 | Pending |
| KIDX-01 | 17 | Pending |
| KIDX-02 | 17 | Pending |
| KIDX-03 | 17 | Pending |
| KIDX-04 | 17 | Pending |
| KIDX-05 | 17 | Pending |
| RAG2-01 | 18 | Pending |
| RAG2-02 | 18 | Pending |
| RAG2-03 | 18 | Pending |
| RAG2-04 | 18 | Pending |
| RAG2-05 | 18 | Pending |
| WRAP-01 | 19 | Pending |
| WRAP-02 | 19 | Pending |
| WRAP-03 | 19 | Pending |
| WRAP-04 | 19 | Pending |
| WRAP-05 | 19 | Pending |
| WRAP-06 | 19 | Pending |
| WRAP-07 | 19 | Pending |
| MULTI-01 | 20 | Pending |
| MULTI-02 | 20 | Pending |
| MULTI-03 | 20 | Pending |
| MULTI-04 | 20 | Pending |
| MULTI-05 | 20 | Pending |
| DOC12-01 | 21 | Pending |
| DOC12-02 | 21 | Pending |
| DOC12-03 | 21 | Pending |
| DOC12-04 | 21 | Pending |
| DOC12-05 | 21 | Pending |
| DOC12-06 | 21 | Pending |

**v1.2 total: 43 — Mapped: 43 — Unmapped: 0 ✓**

---

## v1.3 — Compile-Automation + Quality-Pass

**Goal:** Den in v1.2 gebauten Brain- und Wiki-Flow in den Dauerbetrieb bringen — launchd-Automation für `tom-compile`, Quality-Pass für `tom-wiki`, erweitertes Eval-Framework, bestätigte Karpathy-Schwelle (500, v1.3-Entscheidung: keine Anhebung) inkl. Skalierungs-Stufen und Anthropic-SDK-Clarification. Keine Architektur-Änderungen.

### Phases

- [x] **Phase 22: Compile-Automation** — launchd Daily-Job + fehlertoleranter `tom-compile-safe` Wrapper (completed 2026-04-10)
- [x] **Phase 23: tom-wiki Quality-Pass** — stärkerer Prompt, Context-Filter, Quellen-Zitation (completed 2026-04-10)
- [x] **Phase 24: Eval-Framework-Erweiterung** — Brain-Corpus + Side-by-Side-Vergleich tom-wiki vs tom-ask (completed 2026-04-10)
- [x] **Phase 25: Doku + Schwellen-Update** — Karpathy-Schwelle bleibt 500 + Skalierungs-Stufen in CLAUDE.md (completed 2026-04-10)
- [ ] **Phase 26: SDK-Clarification + Milestone-Close** — Anthropic-SDK-Recherche + v1.3 formal abschließen

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 22. Compile-Automation | 2/2 | Complete    | 2026-04-10 |
| 23. tom-wiki Quality-Pass | 1/1 | Complete    | 2026-04-10 |
| 24. Eval-Framework-Erweiterung | 1/1 | Complete    | 2026-04-10 |
| 25. Doku + Schwellen-Update | 0/? | Complete    | 2026-04-10 |
| 26. SDK-Clarification + Milestone-Close | 0/? | Not started | — |

---

## Phase Details (v1.3)

### Phase 22: Compile-Automation

**Goal**: `tom-compile` läuft täglich automatisch via launchd — ein fehlertoleranter Wrapper prüft Voraussetzungen, loggt jeden Lauf, und der Job ist per `launchctl` verifizierbar aktiv.

**Depends on**: Phase 19 (`bin/tom-compile` muss existieren)

**Requirements**: CRON-01, CRON-02, CRON-03, CRON-04, CRON-05, CRON-06

**Success Criteria** (what must be TRUE):
1. `launchctl list | grep tom-compile` zeigt den aktiven Job-Eintrag
2. `~/Library/Logs/tom-compile.log` enthält nach einem Lauf Timestamp, Exit-Code und Duration
3. `bin/tom-compile-safe` exitet mit Log-Eintrag sauber, wenn `ollama serve` nicht läuft oder `$TOM_VAULT` nicht erreichbar ist
4. Manueller Trigger via `launchctl start com.maxim.tom-compile` läuft ohne Fehler durch
5. Ein Maximus_OS-Issue an CTO dokumentiert launchd-Job, Plist-Pfad und Log-Location

**Plans:** 2/2 plans complete
- [ ] 22-01-PLAN.md — bin/tom-compile-safe Wrapper mit Preflight + Logging (CRON-02, CRON-03)
- [ ] 22-02-PLAN.md — launchd-Plist, Registrierung, Smoke-Test, CLAUDE.md-Doku, Maximus_OS-Issue (CRON-01, CRON-04, CRON-05, CRON-06)

---

### Phase 23: tom-wiki Quality-Pass

**Goal**: `tom-wiki`-Antworten sind präziser und nachvollziehbarer — stärkerer System-Prompt, schmalerer Kontext-Filter und explizite Quellen-Zitation sind implementiert und verifiziert.

**Depends on**: Phase 19 (`wiki_query.py` in `claude-memory-compiler/tom_tools/` muss existieren)

**Requirements**: QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06

**Success Criteria** (what must be TRUE):
1. `tom-wiki "Was ist TurboQuant?"` verweist in der Antwort explizit auf `turboquant.md` (oder äquivalenten Dateinamen)
2. Antworten enthalten mindestens eine Quell-Zitation als Wiki-Link oder Dateiname (nicht generisch)
3. Context-Filter übergibt `gemme` nur Index + per Keyword selektierte Artikel, nicht den gesamten Wiki-Inhalt
4. `claude-memory-compiler/TOM-PATCHES.md` dokumentiert den neuen System-Prompt + Filter-Logik
5. Ein Maximus_OS-Issue an CTO dokumentiert Quality-Pass mit Before/After-Beispiel

**Plans:** 1/1 plans complete
- [ ] 23-01-PLAN.md — wiki_query.py Quality-Pass: System-Prompt + Keyword-Filter + Top-K + TOM-PATCHES + Maximus_OS-Issue (QUAL-01..06)

---

### Phase 24: Eval-Framework-Erweiterung

**Goal**: `Gemma/eval/` kann `tom-wiki` und `tom-ask` gegeneinander vergleichen — ein Baseline-Report mit mindestens 10 Queries über Wiki- und Brain-Themen liegt unter `Gemma/eval/results/v1.3-baseline.md`.

**Depends on**: Phase 23 (tom-wiki Quality-Pass sollte vorher abgeschlossen sein für aussagekräftige Baseline)

**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05

**Success Criteria** (what must be TRUE):
1. `Gemma/eval/` enthält Test-Corpus-Einträge mit Brain-Artikeln aus `95_Gehirn/knowledge/`
2. `run_eval.py` führt Side-by-Side-Vergleich durch: gleiche Query, Antwort von `tom-wiki` und `tom-ask`, Score
3. `Gemma/eval/results/v1.3-baseline.md` existiert mit Score-Vergleich über mindestens 10 Queries
4. Mindestens 5 Queries decken Wiki-Themen ab, mindestens 5 Brain-Themen
5. Ein Maximus_OS-Issue an CTO dokumentiert Eval-Ergebnisse und Interpretation

**Plans:** 1/1 plans complete

Plans:
- [ ] 24-01-PLAN.md — questions.yaml erweitern + run_eval.py Side-by-Side-Comparator + Baseline-Report + CTO-Issue (EVAL-01..05)

---

### Phase 25: Doku + Schwellen-Update

**Goal**: Die Karpathy-Schwelle bleibt bei **500** und der Umstiegspfad auf RAG-Primary ist in `CLAUDE.md` (Repo) und `$TOM_VAULT/CLAUDE.md` (Vault) klar dokumentiert. v1.3-Entscheidung: **keine Anhebung** — 500 bleibt verbindlich.

**Depends on**: Nothing (reine Dokumentationsphase, unabhängig)

**Requirements**: DOC13-01, DOC13-02, DOC13-03, DOC13-04

**Success Criteria** (what must be TRUE):
1. `/Users/maxim/Claude/CLAUDE.md` Wissens-Kaskade-Sektion bestätigt die Schwelle **500** (unverändert) und beschreibt den Umstiegspfad auf RAG-Primary
2. Eine neue Sektion "Skalierungs-Stufen" beschreibt: <500 = Index-first, 500–2000 = Hybrid, >2000 = RAG-Primary
3. `$TOM_VAULT/CLAUDE.md` ist konsistent auf 500 (falls dort die Schwelle erwähnt wird)
4. Ein Maximus_OS-Issue an wiki-kurator dokumentiert das Doku-Update

**Plans**: TBD

---

### Phase 26: SDK-Clarification + Milestone-Close

**Goal**: Die Anthropic-SDK-Frage (Subscription-Quota für `tom-compile`) ist recherchiert und dokumentiert; v1.3 ist in allen Planning-Artefakten und Maximus_OS formal geschlossen.

**Depends on**: Phases 22–25 (alles live bevor abgeschlossen)

**Requirements**: CLOSE13-01, CLOSE13-02, CLOSE13-03, CLOSE13-04, CLOSE13-05

**Success Criteria** (what must be TRUE):
1. `claude-memory-compiler/TOM-PATCHES.md` enthält einen datierten Abschnitt zur Anthropic-SDK-Clarification (Subscription-Quota-Frage beantwortet oder mit Quelle verlinkt)
2. `Obsidian/Projekte/Paperclip-v1.3-CEO-Briefing.md` existiert mit allen Phasen 22–26, Commits und Outcomes
3. `.planning/MILESTONES.md` enthält den v1.3-Eintrag mit Start, Ende, Phasen, Status und Commits
4. `.planning/PROJECT.md` Validated-Sektion listet v1.3-Deliverables
5. Ein Maximus_OS-Issue an CEO (`priority=high`) schließt Milestone v1.3 offiziell ab

**Plans**: TBD

---

## Coverage: v1.3

| Requirement | Phase | Status |
|-------------|-------|--------|
| CRON-01 | 22 | Pending |
| CRON-02 | 22 | Pending |
| CRON-03 | 22 | Pending |
| CRON-04 | 22 | Pending |
| CRON-05 | 22 | Pending |
| CRON-06 | 22 | Pending |
| QUAL-01 | 23 | Pending |
| QUAL-02 | 23 | Pending |
| QUAL-03 | 23 | Pending |
| QUAL-04 | 23 | Pending |
| QUAL-05 | 23 | Pending |
| QUAL-06 | 23 | Pending |
| EVAL-01 | 24 | Pending |
| EVAL-02 | 24 | Pending |
| EVAL-03 | 24 | Pending |
| EVAL-04 | 24 | Pending |
| EVAL-05 | 24 | Pending |
| DOC13-01 | 25 | Pending |
| DOC13-02 | 25 | Pending |
| DOC13-03 | 25 | Pending |
| DOC13-04 | 25 | Pending |
| CLOSE13-01 | 26 | Pending |
| CLOSE13-02 | 26 | Pending |
| CLOSE13-03 | 26 | Pending |
| CLOSE13-04 | 26 | Pending |
| CLOSE13-05 | 26 | Pending |

**v1.3 total: 26 — Mapped: 26 — Unmapped: 0 ✓**

---

## v1.4 — Aktive KI + Dokumenten-Fundament

**Goal:** Tom bekommt ein Volltext-Dokumenten-Fundament (OCR + FTS5), eine Obsidian-native aktive-KI-Integration via Community-Plugin, automatisches Clipper-Enrichment und einen dokumentierten Token-Spar-Pfad für compile/lint. Die Document-Lifecycle-State-Machine wird bewusst nach v1.5 deferred.

### Phases

- [ ] **Phase 27: OCR-Toolkette + Archiv-Fundament** — tesseract + ocrmypdf + deu, archivum/ Ordner, SQLite FTS5 Schema, erstes echtes PDF indiziert
- [ ] **Phase 28: tom-doc CLI** — index/search/list/show Wrapper + CLAUDE.md-Integration
- [ ] **Phase 29: Gemma-in-Obsidian via Smart Connections** — Plugin installiert, Ollama-Backend, Privacy-Exclude, Smoke-Test
- [ ] **Phase 30: Clipper Auto-Enrichment** — tom-clip-enrich mit Summary/Tags/Konzepte/Wiki-Kategorie
- [ ] **Phase 31: Token-Spar-Lokalisierung** — tom-compile --local + Eval; tom-lint --structural-only als Default
- [ ] **Phase 32: Milestone-Close v1.4** — 6 Doku-Kanäle nach v1.3-Close-Checklist

### Wave-Dependencies

- **Phase 27 → Phase 28** (tom-doc braucht das SQLite-Schema)
- **Phase 29 || Phase 30** parallelisierbar (Obsidian-Plugin unabhängig von tom-clip-enrich)
- **Phase 31** unabhängig von 27–30
- **Phase 32** zuletzt (Close braucht alle Phasen shipped)

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 27. OCR-Toolkette + Archiv-Fundament | 0/? | Not started | — |
| 28. tom-doc CLI | 0/? | Not started | — |
| 29. Gemma-in-Obsidian via Smart Connections | 0/? | Not started | — |
| 30. Clipper Auto-Enrichment | 0/? | Not started | — |
| 31. Token-Spar-Lokalisierung | 0/? | Not started | — |
| 32. Milestone-Close v1.4 | 0/? | Not started | — |

---

## Phase Details (v1.4)

### Phase 27: OCR-Toolkette + Archiv-Fundament

**Goal**: OCR-Stack ist installiert, `archivum/` existiert mit SQLite-FTS5-Schema, `$TOM_VAULT/Archiv/` Symlink ist angelegt, und mindestens ein echtes Maxim-PDF ist per Volltext abfragbar.

**Depends on**: Nothing (erste v1.4-Phase)

**Requirements**: DOC14-01, DOC14-02, DOC14-03, DOC14-04, DOC14-05, DOC14-06

**Success Criteria**:
1. `which tesseract ocrmypdf` liefert Pfade; `tesseract --list-langs` enthält `deu`
2. `test -L "$TOM_VAULT/Archiv"` → Symlink auf `~/Downloads/Archiv/` existiert
3. `/Users/maxim/Claude/archivum/{db,ocr-cache,logs,README.md}` angelegt
4. `sqlite3 archivum/db/archivum.db ".schema documents_fts"` zeigt FTS5-Schema
5. `archivum/ocr_pipeline.py` verarbeitet mindestens 1 echtes PDF idempotent; zweiter Lauf skippt bereits verarbeitete Files
6. Volltext-Query gegen FTS5 liefert den Inhalt dieses PDFs zurück

**Vorbedingung (Maxim)**: Mindestens **1 echtes PDF** in einer Kategorie unter `~/Downloads/Archiv/` hinterlegen, damit Smoke-Test laufen kann.

**Plans**: TBD

---

### Phase 28: tom-doc CLI

**Goal**: `bin/tom-doc` bietet einen vollständigen CLI-Wrapper (`index`, `search`, `list`, `show`) über den FTS5-Dokumenten-Index und ist in der CLAUDE.md-Wissens-Kaskade verankert.

**Depends on**: Phase 27 (SQLite-Schema + OCR-Pipeline müssen existieren)

**Requirements**: TDOC-01, TDOC-02, TDOC-03, TDOC-04, TDOC-05, TDOC-06, TDOC-07

**Success Criteria**:
1. `bin/tom-doc` ausführbar mit 4 Subcommands, Symlink in `~/bin/`
2. `tom-doc index 06` scant Kategorie 06_Arzt, triggert OCR neuer PDFs, aktualisiert FTS5
3. `tom-doc search "..."` liefert Trefferliste mit Snippet + Kategorie/Dateiname
4. `tom-doc show <pfad>` zeigt Metadaten + OCR-Text-Auszug
5. `tom-doc list 06` listet alle indizierten Dokumente der Kategorie
6. `CLAUDE.md` Wissens-Kaskade enthält neuen Punkt "Dokumenten-Fragen → `tom-doc search`"

**Plans**: TBD

---

### Phase 29: Gemma-in-Obsidian via Smart Connections

**Goal**: Smart Connections Community-Plugin läuft mit Ollama-Backend (`nomic-embed-text` Embeddings + `gemme` Chat), indexiert NUR `90_Wiki/` + `95_Gehirn/knowledge/` (Privacy-Exclude für persönliche Ordner), Semantic-Search funktioniert im Editor.

**Depends on**: Nothing (parallel zu Phase 30)

**Requirements**: OBPL-01, OBPL-02, OBPL-03, OBPL-04, OBPL-05

**Success Criteria**:
1. `ls "$TOM_VAULT/.obsidian/plugins/smart-connections/"` → Plugin-Dateien vorhanden
2. Plugin-Settings zeigen auf lokales Ollama, Embedding-Modell `nomic-embed-text`, Chat-Modell `gemme`
3. Privacy-Exclude (`.scignore` oder Plugin-Setting) schließt `10_Personen`, `20_Dokumente`, `40_Aufgaben`, `50_Gesundheit`, `60_Finanzen` aus
4. Smoke-Test: Semantic-Search nach "TurboQuant" liefert `90_Wiki/konzepte/turboquant.md` im Smart-Connections-Panel
5. `.planning/obsidian-plugin-config/smart-connections.json` enthält Config-Backup
6. `CLAUDE.md` Wissens-Kaskade (6) dokumentiert die Editor-native Option

**Fallback**: Falls Smart Connections unbrauchbar ist → Obsidian Copilot als dokumentierte Alternative. Time-Box: max 2h Debugging bevor Switch.

**Plans**: TBD

---

### Phase 30: Clipper Auto-Enrichment

**Goal**: `bin/tom-clip-enrich` reichert Clipping-Dateien idempotent an — Summary, Auto-Tags, Konzept-Vorschläge (in separater Review-Datei, nicht direkt Stub-Pages), Wiki-Kategorie-Vorschlag via `gemme`.

**Depends on**: Nothing (parallel zu Phase 29; nutzt existierendes `gemme` + `ollama` aus v1.1)

**Requirements**: CLIP-01, CLIP-02, CLIP-03, CLIP-04, CLIP-05, CLIP-06, CLIP-07, CLIP-08

**Success Criteria**:
1. `tom-clip-enrich <file>` schreibt `summary`, `tags` (appended+dedupliziert), `suggested_wiki_category`, `enriched: true` ins Frontmatter
2. Konzept-Vorschläge landen als Zeilen in `$TOM_VAULT/90_Wiki/konzepte-vorschlaege.md` — keine neuen Stub-Pages ohne Review
3. Zweiter Lauf über dieselbe Datei ist Noop (idempotent via `enriched: true`)
4. Smoke-Test mit `Mannheim – Wikipedia.md` — alle 4 Felder plausibel gefüllt, manuell verifiziert
5. CLIP-08: Entscheidung dokumentiert (Hook in `tom-compile-safe` ODER separater launchd-Job)

**Wiederverwendung**: `claude-memory-compiler/tom_tools/wiki_query.py` als Template (gleicher `ollama.chat`-Stil); `bin/tom-wiki` als Bash-Template.

**Plans**: TBD

---

### Phase 31: Token-Spar-Lokalisierung

**Goal**: `tom-compile --local` nutzt `gemme` statt `claude_agent_sdk` (opt-in), ein Eval-Vergleich entscheidet ob Default-Switch sinnvoll wäre, und `tom-lint --structural-only` ist als launchd-tauglicher Default dokumentiert.

**Depends on**: Nothing (unabhängig von 27–30)

**Requirements**: LOCAL-01, LOCAL-02, LOCAL-03, LOCAL-04

**Success Criteria**:
1. `tom-compile --local` läuft mindestens 1x erfolgreich über 3 daily-logs und schreibt Brain-Artikel
2. `Gemma/eval/results/v1.4-compile-local-vs-claude.md` enthält Score-Vergleich der beiden Modi
3. `claude_agent_sdk` bleibt Default in `bin/tom-compile`; `--local` ist opt-in
4. `tom-lint --structural-only` ist in CLAUDE.md als launchd-Default dokumentiert (oder neues `--no-llm` Flag existiert und ist dokumentiert)
5. Maximus_OS-Issue dokumentiert Entscheidungsstand (Token-Ersparnis-Kontext: ca. $0.04/Monat — primär prinzipiell)

**Plans**: TBD

---

### Phase 32: Milestone-Close v1.4

**Goal**: v1.4 ist in allen 6 Doku-Kanälen nach v1.3-Close-Checklist geschlossen: MILESTONES.md, PROJECT.md, CEO-Briefing, vault-log.md, Tom-Projektseite, Maximus_OS Close-Issue.

**Depends on**: Phases 27–31 (alles live bevor geschlossen)

**Requirements**: CLOSE14-01, CLOSE14-02, CLOSE14-03, CLOSE14-04, CLOSE14-05, CLOSE14-06, CLOSE14-07

**Success Criteria**:
1. `.planning/MILESTONES.md` enthält v1.4-Eintrag nach v1.1/v1.2/v1.3-Schema (Start/Ende/Phasen/Commits/Status/FAMs)
2. `.planning/PROJECT.md` Validated-Sektion enthält v1.4-Deliverables, `Active:` auf v1.5 oder `—`
3. `.planning/briefings/v1.4-CEO-Briefing.md` existiert mit ≥150 Zeilen nach v1.3-Template (6 Teile + Anhänge A/B/C)
4. `$TOM_VAULT/log.md` enthält datierten v1.4-Abschluss-Eintrag nach v1.3-Schema
5. `$TOM_VAULT/30_Projekte/Tom.md` ist aktualisiert (Current Milestone, Werkzeug-Liste inkl. `tom-doc`, `tom-clip-enrich`, Milestones-Kurz-Historie)
6. Maximus_OS Close-Issue an CEO (`priority=high`) mit Link auf CEO-Briefing und Phasen-Commits
7. Alle v1.4-Requirements in REQUIREMENTS.md als `[x]` markiert

**Plans**: TBD

---

## Coverage: v1.4

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOC14-01..06 | 27 | Pending |
| TDOC-01..07 | 28 | Pending |
| OBPL-01..05 | 29 | Pending |
| CLIP-01..08 | 30 | Pending |
| LOCAL-01..04 | 31 | Pending |
| CLOSE14-01..07 | 32 | Pending |

**v1.4 total: 37 — Mapped: 37 — Unmapped: 0 ✓**

Details in `.planning/REQUIREMENTS.md` Traceability-Tabelle.

---

## v1.5 — Lifecycle + Integration

**Goal:** Tom bekommt eine projekt-übergreifende **Lebens-State-Machine** für seine 6 Lebens-Bereiche (Dokumente, Aufgaben, Termine, Projekte, Finanzen, Social Media), eine Obsidian-native **MCP-Bridge** für die wichtigsten Tom-CLIs (`tom-doc`/`tom-wiki`/`tom-ask`/`tom-clip-enrich`) im Editor, einen **lokalen Claude-Code-Modus mit funktionierendem Tool-Use** (Phase 36 Chat-Only-Opener + Phase 38 Modell-Upgrade) und eine vorgeschaltete **Vault-Hygiene-Phase**, die alle prepared-pending Handoffs aus v1.4/v1.4.1 schließt.

### Phases

- [x] **Phase 36: Lokaler Ollama-Switch (out-of-band shipped 2026-04-11)** — Claude Code Router + `nutze-ollama` Shell-Funktionen + `tom-local` Wrapper, Chat-Only-Modus dokumentiert (4 commits: `0cda951`, `f842a63`, `67f4d80`, `11a6ffc`)
- [ ] **Phase 37: Vault-Hygiene & Cleanup** — Smart Connections Repair + 6 LLM-Plugins disablen + eml-reader/apple-reminders Setup + OLLAMA_ORIGINS persistent + 3 prepared-pending Handoffs aus v1.4/v1.4.1 schließen
- [ ] **Phase 38: Local Tool-Use Modell-Upgrade** — qwen3-coder oder glm-4.5-air pullen, CCR-Config umstellen, Tool-Use-Gate retesten, tom-compile --local Eval-Sanity-Check
- [ ] **Phase 39: MCP-Bridge für Tom-CLIs** — FastMCP-Server der tom-doc/tom-wiki/tom-ask/tom-clip-enrich als MCP-Tools im Obsidian-Editor verfügbar macht, mcp-tools-Plugin v0.2.27 konfiguriert, Privacy-Boundaries definiert
- [ ] **Phase 40: Lifecycle Foundation — Dokumente** — `state`-Frontmatter-Schema für 20_Dokumente, Templater-Transitions, Dataview-Dashboard, Eltern-Betreuung als End-to-End-Beispiel, Schema-Migration-Strategie
- [ ] **Phase 41: Lifecycle — Aufgaben & Termine** — `state`-Schema für 40_Aufgaben + 50_Gesundheit, Frist-Auto-Highlight, Heute-Views pro Bereich
- [ ] **Phase 42: Lifecycle — Projekte / Finanzen / Social Media** — `state`-Schema für 30_Projekte + 60_Finanzen + 80_Social_Media, Cross-Area-Verlinkung, Templater-Updates
- [ ] **Phase 43: Lifecycle Dashboards + Auto-Routing** — Vault-weites Heute-Dashboard, launchd-Job für tägliche state-Auto-Transitions, Apple-Reminders-Sync, `bin/tom-status`-CLI
- [ ] **Phase 44: Milestone-Close v1.5** — 6 Doku-Kanäle nach v1.3-Schema + CEO-Briefing

### Wave-Dependencies (v1.5)

- **Phase 36 ✓** ist Pre-Roadmap-Opener und blockiert nichts
- **Phase 37 (Cleanup)** sollte zuerst, weil es CCR-Daemon, Smart Connections, Plugin-Setup für nachfolgende Phasen sauber macht
- **Phase 38 (Tool-Use-Upgrade)** braucht Phase 37 (CCR muss laufen + Health-Check ok)
- **Phase 39 (MCP-Bridge)** braucht Phase 38 (mcp-tools profitiert vom besseren lokalen Modell, ist aber nicht hard-blocked) — kann **parallel zu 38** wenn Maxim Cloud-Claude für MCP-Test akzeptiert
- **Phase 40 (Lifecycle Dokumente)** braucht Phase 37 (Templater-Setup aus v1.4.1 muss vollständig sein) — kann nach 37 parallel zu 38/39 starten
- **Phase 41 (Aufgaben/Termine)** braucht Phase 40 (state-Schema-Konvention) und Phase 37 (apple-reminders-plugin)
- **Phase 42 (Projekte/Finanzen/Social)** braucht Phase 40 (state-Schema-Konvention)
- **Phase 43 (Dashboards + Auto-Routing)** braucht Phasen 40+41+42 alle shipped
- **Phase 44 (Close)** zuletzt, braucht alle anderen shipped

```text
36 ✓
   ↓
  37  →  38  →  39
   ↓             ↓
  40  →  41  →  43  →  44
   ↓     ↓      ↑
  42 ────┴──────┘
```

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 36. Lokaler Ollama-Switch (out-of-band) | 1/1 | ✓ Done | 2026-04-11 |
| 37. Vault-Hygiene & Cleanup | 0/? | Not started | — |
| 38. Local Tool-Use Modell-Upgrade | 0/? | Not started | — |
| 39. MCP-Bridge für Tom-CLIs | 0/? | Not started | — |
| 40. Lifecycle Foundation — Dokumente | 0/? | Not started | — |
| 41. Lifecycle — Aufgaben & Termine | 0/? | Not started | — |
| 42. Lifecycle — Projekte / Finanzen / Social | 0/? | Not started | — |
| 43. Lifecycle Dashboards + Auto-Routing | 0/? | Not started | — |
| 44. Milestone-Close v1.5 | 0/? | Not started | — |

---

## Phase Details (v1.5)

### Phase 36: Lokaler Ollama-Switch (out-of-band shipped)

**Goal**: Maxim kann per Shell-Kommando (`nutze-ollama`) Claude Code's Backend auf lokales Ollama umleiten, mit beiden Modellen (`gemme` Chat, `qwen2.5-coder` Tool-Use-Versuch) verfügbar via `/model`-Picker. Default bleibt Cloud, Switch ist opt-in pro Shell. Real-Use-Smoke-Test bleibt Maxim-Handoff.

**Depends on**: Nothing (Pre-Roadmap-Opener am 2026-04-11)

**Requirements**: LOCAL-05-01..07 (alle ✓ shipped)

**Success Criteria**:

1. `which ccr` → `/opt/homebrew/bin/ccr`, `ccr status` → Running
2. `nutze-ollama` setzt `ANTHROPIC_BASE_URL=http://127.0.0.1:3456` mit Warning-Echo
3. `nutze-claude` unsetet alle CCR-env-vars
4. `ollama-status` zeigt Modus + Daemons + Modelle + Aliasing
5. `tom-local` spawnt Subshell mit env, `tom-local <cmd>` führt Single-Command aus
6. CCR-Endpoint `/v1/messages` antwortet im Anthropic-Format mit qwen2.5-coder-Response
7. Tool-Use-Gate ist als documented expected-fail markiert (Phase 38 wird das fixen)

**Plans**: `36-01-PLAN.md` ✓ + `SUMMARY.md` ✓ + `VERIFICATION.md` ✓

**Commits**: `0cda951`, `f842a63`, `67f4d80`, `11a6ffc`

---

### Phase 37: Vault-Hygiene & Cleanup

**Goal**: Alle prepared-pending Handoffs aus v1.4/v1.4.1 sind geschlossen, Smart Connections funktioniert wieder, die 6 unused LLM-Plugins sind disabled, eml-reader und apple-reminders-plugin sind konfiguriert und smoke-tested, OLLAMA_ORIGINS ist persistent gesetzt.

**Depends on**: Phase 36 (CCR-Daemon muss erreichbar sein für Hygiene-Verifikation)

**Requirements**: HYG-01..09

**Success Criteria**:

1. `wc -c $TOM_VAULT/.obsidian/plugins/smart-connections/data.json` ist > 1 KB (war 62 B), Smart-Connections-Index regeneriert nach Phase-29-Playbook + UI-Excludes verifiziert
2. `community-plugins.json` enthält 6 LLM-Plugins NICHT mehr (cao, tars, large-language-models, llm-summary, llm-test-gen, ai-latex-generator)
3. `launchctl getenv OLLAMA_ORIGINS` liefert `chrome-extension://*,moz-extension://*,safari-web-extension://*` und überlebt Reboot
4. `eml-reader` öffnet eine Test-`.eml`-Datei in Obsidian-Preview ohne Fehler
5. `obsidian-apple-reminders-plugin` syncht ein Test-Reminder in beide Richtungen (Vault → Apple-Reminders → Vault)
6. `plugin-audit-v1.4.1.md` ist auf Status "answered" (alle 5 Q1–Q5 beantwortet)
7. CLIP141-04 + CLIP141-13c + OBPL-03 sind in REQUIREMENTS.md auf `[x]` markiert

**Plans**: TBD

---

### Phase 38: Local Tool-Use Modell-Upgrade

**Goal**: Der lokale Claude-Code-Modus aus Phase 36 wird vom Chat-Only-Modus zu einem vollwertigen Agentic-Modus, indem ein Tool-Use-fähiges Ollama-Modell (qwen3-coder, glm-4.5-air oder ein verifizierter Ersatz) installiert und in CCR konfiguriert wird. Tool-Use-Gate wird als PASS verifiziert oder Phase endet als dokumentierter Wechsel auf bessere Cloud-Modelle.

**Depends on**: Phase 37 (CCR + Smart Connections + Ollama müssen sauber laufen)

**Requirements**: LOCAL-06-01..06

**Success Criteria**:

1. `ollama list` enthält das neue Modell mit Größe + Hash
2. `~/.claude-code-router/config.json` Router-Mapping aktualisiert + Reference-Copy in Phase-Dir
3. Curl gegen `/v1/messages` mit Tool-Schema → Response enthält `content[].type == "tool_use"` (NICHT text)
4. Real-Use: `tom-local claude` → `/model opus` → "Liste die Dateien in /tmp" → echter LS-Tool-Call mit Verzeichnis-Inhalt
5. Phase 36 SUMMARY/VERIFICATION + CLAUDE.md-Limitations-Sektion auf neuen Stand
6. `tom-compile --local` Eval gegen das neue Modell zeigt keine Regression vs Phase-31-Baseline (Ergebnis in `Gemma/eval/results/v1.5-local-toolupgrade.md`)

**Plans**: TBD

---

### Phase 39: MCP-Bridge für Tom-CLIs

**Goal**: Maxim kann die 4 wichtigsten Tom-Lese-Tools (`tom-doc`, `tom-wiki`, `tom-ask`, `tom-clip-enrich`) direkt aus Obsidian heraus aufrufen — über das `mcp-tools`-Plugin (v0.2.27, ADR-004). Privacy-Boundaries sind explizit definiert pro Tool. End-to-End-Test: User klickt im Obsidian-MCP-Panel auf `tom-doc-search "Arbeitsvertrag"` und bekommt Treffer + Quellen im Editor.

**Depends on**: Phase 37 (mcp-tools Plugin muss konfigurationsfähig sein), kann **parallel zu Phase 38** laufen wenn Maxim für MCP-Tests Cloud-Claude akzeptiert

**Requirements**: MCP-01..09

**Success Criteria**:

1. ADR-006 dokumentiert MCP-Server-Architektur-Entscheidung (FastMCP vs stdio-shell-wrap)
2. MCP-Server läuft als Daemon (launchd oder Plugin-managed) und exposed mindestens 4 Tools (tom-doc-search, tom-wiki-query, tom-ask, tom-clip-enrich-current-note)
3. Privacy-Boundary-Tabelle dokumentiert pro Tool: read-only by default, persönliche Ordner-Zugriff explizit gewhitelisted
4. mcp-tools-Plugin in Obsidian zeigt die 4 Tom-Tools im MCP-Panel
5. End-to-End-Test: tom-doc-search via MCP-Panel liefert Treffer + Quellen im aktiven Editor
6. CLAUDE.md neue Sektion "MCP-Bridge für Tom-CLIs" mit Use-Cases, Privacy-Boundary-Tabelle, Daemon-Lifecycle, Troubleshooting

**Plans**: TBD

---

### Phase 40: Lifecycle Foundation — Dokumente

**Goal**: Das `state`-Frontmatter-Schema für 20_Dokumente ist definiert, dokumentiert und im ersten echten Beispiel (Eltern-Betreuung Waldemar/Nina) verwendet. Templater-Transitions funktionieren, Dataview-Dashboard zeigt Dokumente nach State sortiert. Schema-Migration für existierende stateless Notes ist gelöst.

**Depends on**: Phase 37 (Templater-Setup muss vollständig sein)

**Requirements**: LCY-01..06

**Success Criteria**:

1. `99_Vorlagen/state-schema.md` dokumentiert die 5 Dokumente-States (Eingang, In-Bearbeitung, Antwort-formuliert, Warte-auf-Rückmeldung, Erledigt) mit Übergangs-Diagramm
2. `99_Vorlagen/Dokument.md` Template hat `state: Eingang` Default + `state_changed`-Field
3. Templater-Snippet `state-next-dokument.md` lässt User per Click den nächsten State wählen
4. `20_Dokumente/Dashboard.md` Dataview-View gruppiert nach state, sortiert nach state_changed, highlightet Frist-naht
5. `20_Dokumente/13_Betreuung.md` enthält 3 echte Eingang-Dokumente mit state-tracking
6. Migration-Script `bin/tom-state migrate-dokumente` läuft idempotent über existierende stateless Notes (Default-Inserter ODER Skip-Marker)

**Plans**: TBD

---

### Phase 41: Lifecycle — Aufgaben & Termine

**Goal**: Aufgaben und Termine bekommen ihr eigenes State-Schema, wiederverwendbar mit der Phase-40-Konvention. Frist-Auto-Highlight ist als Universal-Snippet verfügbar. Heute-Views pro Bereich aggregieren die wichtigsten Items.

**Depends on**: Phase 40 (state-Schema-Konvention) + Phase 37 (apple-reminders-plugin für spätere Sync-Vorbereitung)

**Requirements**: LCY-07..12

**Success Criteria**:

1. `99_Vorlagen/Aufgabe.md` Template mit `state: Open` Default + 4 möglichen Werten (Open, Doing, Blocked, Done)
2. `99_Vorlagen/Arzttermin.md` Template mit `state: Geplant` Default + 4 Werten (Geplant, Heute, Wahrgenommen, Verpasst)
3. Universal-Frist-Snippet (Dataview-Inline-Code) wiederverwendbar via Templater-Insert in jeder beliebigen Note
4. Templater-Transitions für Aufgaben + Termine funktionieren mit gleicher UX wie Phase 40
5. `40_Aufgaben/Heute.md` zeigt alle Aufgaben mit `state == Doing` ODER `due_date <= today + 1d`
6. `50_Gesundheit/Heute.md` zeigt alle Termine mit `date == today` ODER `state == Heute`

**Plans**: TBD

---

### Phase 42: Lifecycle — Projekte / Finanzen / Social Media

**Goal**: Die verbleibenden 3 Lebens-Bereiche bekommen ihr State-Schema. Verträge in 60_Finanzen sind Frist-driven. Cross-Area-Verlinkung wird mit einem echten Beispiel demonstriert (Vertrag verlinkt auf Frist-Termin).

**Depends on**: Phase 40 (state-Schema-Konvention)

**Requirements**: LCY-13..18

**Success Criteria**:

1. `30_Projekte/` state-Schema formalisiert (`aktiv`, `pausiert`, `abgeschlossen`), bestehende `PROJEKTE.md`-Struktur kompatibel
2. `60_Finanzen/` state-Schema (`Vertrag-aktiv`, `Frist-naht`, `Verlängert`, `Gekündigt`, `Versäumt`) mit `kuendigungsfrist`-Field
3. `80_Social_Media/` state-Schema (`Draft`, `Geplant`, `Live`, `Archiv`)
4. 3 neue Templates in `99_Vorlagen/` (`Projekt.md`, `Vertrag.md`, `Social-Post.md`)
5. 3 Dataview-Views (`30_Projekte/Aktive.md`, `60_Finanzen/Fristen.md`, `80_Social_Media/Pipeline.md`)
6. 1 Cross-Area-Beispiel: ein Vertrag in 60_Finanzen verlinkt auf einen Frist-Termin in 50_Gesundheit oder 40_Aufgaben

**Plans**: TBD

---

### Phase 43: Lifecycle Dashboards + Auto-Routing

**Goal**: Vault-weites "Was-steht-an?"-Dashboard aggregiert across alle 6 Bereiche. launchd-Job führt tägliche state-Auto-Transitions aus (idempotent). Apple-Reminders-Sync sendet Doing/Heute-Items in macOS-Notification-Center. `bin/tom-status` zeigt das gleiche aus dem Terminal.

**Depends on**: Phasen 40 + 41 + 42 (alle State-Schemas müssen existieren)

**Requirements**: LCY-19..25

**Success Criteria**:

1. `$TOM_VAULT/index.md` Tom-Hub hat "Heute"-Sektion mit Dataview-Aggregation aus allen 6 Bereichen
2. `$TOM_VAULT/Heute.md` Vault-Root-Dashboard sortiert nach Frist/Priorität, filterbar pro State
3. `~/Library/LaunchAgents/com.maxim.tom-state-transitions.plist` registriert + täglich um eine konfigurierte Uhrzeit aktiv
4. `bin/tom-state-safe` Wrapper mit Preflight + Logging analog `tom-compile-safe`
5. Apple-Reminders-Plugin syncht `state == Doing` Aufgaben + `state == Heute` Termine bidirektional
6. macOS-Notification-Center zeigt Reminder als Notification (smoke test)
7. `bin/tom-status` aus Terminal zeigt heute-Aggregation, läuft auf Maxims gewohnter Shell-Idiom-Konvention
8. Auto-Transition-Job ist idempotent: 3 aufeinanderfolgende Runs produzieren keine Doppel-Bumps oder Doppel-Reminders

**Plans**: TBD

---

### Phase 44: Milestone-Close v1.5

**Goal**: v1.5 ist nach v1.3-Schema komplett dokumentiert (6 Doku-Kanäle), CEO-Briefing geschrieben, Maximus_OS Close-Issue raus. Tom-Vault zeigt v1.5 als shipped, alle Requirements als `[x]` markiert.

**Depends on**: Phasen 36–43 (alle shipped — auch das Real-Use-Smoke-Test für Phase 36 sollte hier abgehakt sein)

**Requirements**: CLOSE15-01..07

**Success Criteria**:

1. `.planning/MILESTONES.md` enthält v1.5-Eintrag nach v1.4-Schema (Start/Ende/Phasen 36–44/Commits/Status/FAMs)
2. `.planning/PROJECT.md` Validated-Sektion enthält v1.5-Deliverables, `Active:` auf v1.6 oder `—`
3. `.planning/briefings/v1.5-CEO-Briefing.md` existiert mit ≥150 Zeilen nach v1.3-Template (6 Teile + Anhänge A/B/C)
4. `$TOM_VAULT/log.md` enthält datierten v1.5-Abschluss-Eintrag
5. `$TOM_VAULT/30_Projekte/Tom.md` aktualisiert (Current Milestone, Werkzeug-Liste mit `nutze-ollama`/`tom-local`/MCP-Server/`tom-state`/`tom-status`, Milestones-Kurz-Historie)
6. Maximus_OS Close-Issue an CEO (`priority=high`) mit Link auf v1.5-CEO-Briefing und Phasen-Commits
7. Alle 56 neuen v1.5-Requirements (HYG, LOCAL-06, MCP, LCY, CLOSE15) als `[x]` markiert + LOCAL-05 (7 retroaktive Phase-36) bereits `[x]`

**Plans**: TBD

---

## Coverage: v1.5

| Requirement | Phase | Status |
|-------------|-------|--------|
| LOCAL-05-01..07 | 36 | ✓ Done |
| HYG-01..09 | 37 | Pending |
| LOCAL-06-01..06 | 38 | Pending |
| MCP-01..09 | 39 | Pending |
| LCY-01..06 | 40 | Pending |
| LCY-07..12 | 41 | Pending |
| LCY-13..18 | 42 | Pending |
| LCY-19..25 | 43 | Pending |
| CLOSE15-01..07 | 44 | Pending |

**v1.5 total: 63 — Mapped: 63 — Unmapped: 0 ✓**

Details in `.planning/REQUIREMENTS.md` Traceability-Tabelle.

---

*Roadmap v1.1 created: 2026-04-10*
*Roadmap v1.2 appended: 2026-04-10*
*Roadmap v1.3 appended: 2026-04-10*
*Roadmap v1.4 appended: 2026-04-10*
*Roadmap v1.5 appended: 2026-04-11 (Sonnet roadmapper-subagent blockiert durch Limit, Roadmap manuell von Opus geschrieben)*
*Current milestone: v1.5 — Lifecycle + Integration*
