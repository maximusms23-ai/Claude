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

*Roadmap v1.1 created: 2026-04-10*
*Roadmap v1.2 appended: 2026-04-10*
*Current milestone: v1.2 — Karpathy Wiki + claude-memory-compiler*
