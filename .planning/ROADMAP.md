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

**Goal:** Den in v1.2 gebauten Brain- und Wiki-Flow in den Dauerbetrieb bringen — launchd-Automation für `tom-compile`, Quality-Pass für `tom-wiki`, erweitertes Eval-Framework, dokumentierte Karpathy-Schwelle (1500) und Anthropic-SDK-Clarification. Keine Architektur-Änderungen.

### Phases

- [x] **Phase 22: Compile-Automation** — launchd Daily-Job + fehlertoleranter `tom-compile-safe` Wrapper (completed 2026-04-10)
- [x] **Phase 23: tom-wiki Quality-Pass** — stärkerer Prompt, Context-Filter, Quellen-Zitation (completed 2026-04-10)
- [ ] **Phase 24: Eval-Framework-Erweiterung** — Brain-Corpus + Side-by-Side-Vergleich tom-wiki vs tom-ask
- [ ] **Phase 25: Doku + Schwellen-Update** — Karpathy-Schwelle 1500 in CLAUDE.md dokumentiert
- [ ] **Phase 26: SDK-Clarification + Milestone-Close** — Anthropic-SDK-Recherche + v1.3 formal abschließen

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 22. Compile-Automation | 2/2 | Complete    | 2026-04-10 |
| 23. tom-wiki Quality-Pass | 1/1 | Complete    | 2026-04-10 |
| 24. Eval-Framework-Erweiterung | 0/? | Not started | — |
| 25. Doku + Schwellen-Update | 0/? | Not started | — |
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

**Plans:** 1 plan

Plans:
- [ ] 24-01-PLAN.md — questions.yaml erweitern + run_eval.py Side-by-Side-Comparator + Baseline-Report + CTO-Issue (EVAL-01..05)

---

### Phase 25: Doku + Schwellen-Update

**Goal**: Die Karpathy-Schwelle ist auf 1500 aktualisiert und der Umstiegspfad auf RAG-Primary ist in `CLAUDE.md` (Repo) und `$TOM_VAULT/CLAUDE.md` (Vault) klar dokumentiert.

**Depends on**: Nothing (reine Dokumentationsphase, unabhängig)

**Requirements**: DOC13-01, DOC13-02, DOC13-03, DOC13-04

**Success Criteria** (what must be TRUE):
1. `/Users/maxim/Claude/CLAUDE.md` Wissens-Kaskade-Sektion nennt die Schwelle 1500 (nicht 500) und den Umstiegspfad auf RAG-Primary
2. Eine neue Sektion "Skalierungs-Stufen" beschreibt: <1500 = Index-first, 1500–5000 = Hybrid, >5000 = RAG-Primary
3. `$TOM_VAULT/CLAUDE.md` ist konsistent auf 1500 aktualisiert (falls dort die Schwelle erwähnt wird)
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

*Roadmap v1.1 created: 2026-04-10*
*Roadmap v1.2 appended: 2026-04-10*
*Roadmap v1.3 appended: 2026-04-10*
*Current milestone: v1.3 — Compile-Automation + Quality-Pass*
