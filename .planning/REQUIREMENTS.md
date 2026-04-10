# Requirements: Tom — Persönlicher Lebens-Assistent

**Defined:** 2026-04-10
**Current Milestone:** v1.2 — Karpathy Wiki + claude-memory-compiler
**Core Value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles, was in seinem Leben wichtig ist — Tom weiß, wo was liegt, und unterstützt proaktiv.

## v1.2 Requirements (Current)

Requirements für Karpathy-Wiki-Methode, automatisches Konversations-Capture via `claude-memory-compiler`, Hybrid RAG + Index-first Retrieval, Multi-Projekt-Nutzung. Jeder Eintrag mappt auf genau eine Phase im Roadmap.

### Tool-Install (TOOL)

- [ ] **TOOL-01**: `claude-memory-compiler` ist nach `/Users/maxim/Claude/claude-memory-compiler/` geklont und in Git getrackt
- [ ] **TOOL-02**: `uv sync` im Tool-Repo läuft erfolgreich, Dependencies sind installiert
- [ ] **TOOL-03**: `scripts/config.py` ist gepatcht — `TOM_VAULT`-Env-Var, Pfade zeigen auf `$TOM_VAULT/95_Gehirn/`
- [ ] **TOOL-04**: Smoke-Test: `uv run scripts/lint.py --structural-only` läuft gegen leere Struktur fehlerfrei
- [ ] **TOOL-05**: Maximus_OS-Issue an CTO dokumentiert Tool-Install + Config-Patch mit Commit-Hash

### Brain-Struktur (BRAIN)

- [ ] **BRAIN-01**: `$TOM_VAULT/95_Gehirn/{daily,knowledge/{concepts,connections,qa},reports}/` ist angelegt
- [ ] **BRAIN-02**: `$TOM_VAULT/95_Gehirn/CLAUDE.md` dokumentiert Privacy-Regeln (was rein darf, was nicht), Compile-Trigger, Lint-Regeln
- [ ] **BRAIN-03**: `$TOM_VAULT/95_Gehirn/index.md` Initial-Gerüst mit Sektionen "Recent", "Topics", "Connections"
- [ ] **BRAIN-04**: `$TOM_VAULT/95_Gehirn/log.md` enthält Initial-Eintrag "Brain angelegt"
- [ ] **BRAIN-05**: `$TOM_VAULT/mkdocs.yml` ist verifiziert — `95_Gehirn/` ist NICHT im MkDocs-Scope
- [ ] **BRAIN-06**: Maximus_OS-Issue an archivarius dokumentiert Brain-Struktur + Privacy-Regeln

### Hooks (HOOK)

- [ ] **HOOK-01**: `/Users/maxim/Claude/.claude/settings.json` ist angelegt (Projekt-lokal, nicht global)
- [ ] **HOOK-02**: Drei Hooks sind eingetragen: `SessionStart`, `SessionEnd`, `PreCompact`, alle zeigen auf `claude-memory-compiler/hooks/*.py` via `uv run`
- [ ] **HOOK-03**: Smoke-Test: Claude-Code-Session schreibt bei SessionEnd einen Entry nach `$TOM_VAULT/95_Gehirn/daily/YYYY-MM-DD.md`
- [ ] **HOOK-04**: Verifiziert: bestehende GSD + RTK Hooks aus globaler Config funktionieren weiterhin (Merge-Verhalten OK)
- [ ] **HOOK-05**: `/Users/maxim/Claude/CLAUDE.md` dokumentiert aktive Hooks + Auto-Capture
- [ ] **HOOK-06**: Maximus_OS-Issue an CTO dokumentiert Hook-Aktivierung

### Karpathy-Index (KIDX)

- [ ] **KIDX-01**: Aktueller `$TOM_VAULT/90_Wiki/index.md` ist nach `90_Wiki/history.md` verschoben (Changelog bewahrt)
- [ ] **KIDX-02**: Neuer `90_Wiki/index.md` ist im Karpathy-Retrieval-Format geschrieben mit Nutzungshinweis "zuerst Index, dann 3–5 relevante Artikel lesen, dann synthetisieren"
- [ ] **KIDX-03**: Alle bestehenden `90_Wiki/`-Artikel sind im Index mit 1–2-Zeilen-Beschreibung gelistet, gruppiert nach Kategorie (Konzepte, Themen, Projekte, Personen, Quellen)
- [ ] **KIDX-04**: Smoke-Test: Eine typische Frage (z.B. "Was ist Turboquant?") wird nur via Index → direkte Reads beantwortet, ohne RAG
- [ ] **KIDX-05**: Maximus_OS-Issue an wiki-kurator dokumentiert Index-Umschreibung

### RAG-Erweiterung (RAG2)

- [ ] **RAG2-01**: `Gemma/rag/config.py` enthält `GEHIRN_PATH = TOM_VAULT / "95_Gehirn" / "knowledge"`
- [ ] **RAG2-02**: `Gemma/rag/index.py` indiziert dritte Collection `gehirn` additiv in `index_all()`
- [ ] **RAG2-03**: `Gemma/rag/query.py` durchsucht alle drei Collections (wiki, clippings, gehirn)
- [ ] **RAG2-04**: Reindex-Smoke-Test gegen leeres `gehirn/knowledge/` meldet 0 Chunks ohne Fehler
- [ ] **RAG2-05**: Maximus_OS-Issue an CTO dokumentiert RAG-Erweiterung

### Neue Wrapper (WRAP)

- [ ] **WRAP-01**: `bin/tom-wiki` Bash-Wrapper unterstützt `tom-wiki [--brain] "Frage"` und ruft Index-first-Query auf `90_Wiki/index.md` bzw. `95_Gehirn/index.md`
- [ ] **WRAP-02**: `bin/tom-compile` triggert `uv run scripts/compile.py` im Tool-Repo (optional Flags durchgereicht)
- [ ] **WRAP-03**: `bin/tom-lint` triggert `uv run scripts/lint.py` (optional `--structural-only` durchgereicht)
- [ ] **WRAP-04**: Symlinks für `tom-wiki`, `tom-compile`, `tom-lint` in `~/bin/` sind angelegt und ausführbar
- [ ] **WRAP-05**: Smoke-Test: `tom-wiki "Was ist Ollama?"` liefert Antwort via Index; `tom-lint --structural-only` läuft fehlerfrei
- [ ] **WRAP-06**: `CLAUDE.md` + `AGENTS.md` dokumentieren Wissens-Kaskade: (1) Direct-Read, (2) tom-wiki, (3) tom-ask (RAG-Fallback)
- [ ] **WRAP-07**: Maximus_OS-Issue an CTO dokumentiert neue CLI-Tools

### Multi-Projekt (MULTI)

- [ ] **MULTI-01**: Template `wiki_path`-Konvention ist dokumentiert (in `claude-memory-compiler/docs/multi-project.md` oder `CLAUDE.md`-Anhang)
- [ ] **MULTI-02**: Mindestens ein zweites Projekt auf dem Mac hat die `wiki_path`-Sektion in seiner `CLAUDE.md` eingebettet
- [ ] **MULTI-03**: Smoke-Test: `tom-wiki "Frage"` funktioniert aus einem zweiten Projekt-Verzeichnis
- [ ] **MULTI-04**: `$TOM_VAULT/95_Gehirn/CLAUDE.md` erwähnt dass Brain shared über alle Projekte ist, pro Projekt eigene Daily-Logs möglich
- [ ] **MULTI-05**: Maximus_OS-Issue an wiki-kurator dokumentiert Multi-Projekt-Konvention

### Dokumentation v1.2 (DOC12)

- [ ] **DOC12-01**: `$TOM_VAULT/log.md` enthält v1.2 Abschluss-Eintrag
- [ ] **DOC12-02**: `$TOM_VAULT/90_Wiki/projekte/claude-memory-compiler.md` Artikel über das Tool existiert
- [ ] **DOC12-03**: `$TOM_VAULT/90_Wiki/konzepte/karpathy-wiki-methode.md` Konzept-Artikel existiert
- [ ] **DOC12-04**: `/Users/maxim/Claude/claude-memory-compiler/TOM-PATCHES.md` dokumentiert alle Config-Änderungen gegen Upstream
- [ ] **DOC12-05**: Finales Milestone-Close-Issue an CEO (priority=high) mit Commit-Hashes und Verification-Summary
- [ ] **DOC12-06**: `REQUIREMENTS.md` / `STATE.md` / `MILESTONES.md` / `PROJECT.md` sind für v1.2 Close aktualisiert

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

Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TOOL-01..05 | Phase 14 | Pending |
| BRAIN-01..06 | Phase 15 | Pending |
| HOOK-01..06 | Phase 16 | Pending |
| KIDX-01..05 | Phase 17 | Pending |
| RAG2-01..05 | Phase 18 | Pending |
| WRAP-01..07 | Phase 19 | Pending |
| MULTI-01..05 | Phase 20 | Pending |
| DOC12-01..06 | Phase 21 | Pending |

**Coverage:**
- v1.2 requirements: 43 total
- Mapped to phases: 43
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-10*
*Last updated: 2026-04-10 after v1.2 milestone start*
