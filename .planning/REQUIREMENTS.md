# Requirements: Tom — Persönlicher Lebens-Assistent

**Defined:** 2026-04-10
**Current Milestone:** v1.1 — Maximus_OS Integration + Ollama Gemma Revival
**Core Value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles, was in seinem Leben wichtig ist — Tom weiß, wo was liegt, und unterstützt proaktiv.

## v1.1 Requirements (Current)

Requirements für Single-Source-Vault, Maximus_OS Hybrid-Integration und Ollama Gemma Revival. Jeder Eintrag mappt auf genau eine Phase im Roadmap.

### Vault-Cleanup (VCLEAN)

- [ ] **VCLEAN-01**: iCloud-Vault wird als canonical bestätigt (md-Count + stichprobenhafter Content-Diff gegen lokales Duplikat)
- [ ] **VCLEAN-02**: Lokaler `Obsidian_Zentralw/` ist aus Git entfernt (`git rm -r --cached`) und physisch gelöscht
- [ ] **VCLEAN-03**: `.gitignore` verhindert Wiederaufnahme des lokalen Pfades mit Kommentar zur iCloud-Canonical-Entscheidung
- [ ] **VCLEAN-04**: `CLAUDE.md` + `AGENTS.md` zeigen auf iCloud-Vault-Pfad (Variable `$TOM_VAULT` empfohlen)
- [ ] **VCLEAN-05**: Maximus_OS-Issue dokumentiert Vault-Cleanup mit Commit-Hash

### Maximus_OS Integration (MOS)

- [ ] **MOS-01**: `bin/tom-issue` Wrapper-Skript existiert, kapselt Company-ID, unterstützt `--title`/`--description`/`--priority`/`--agent` Flags
- [ ] **MOS-02**: `tom-issue` kennt Agent-Aliase (tom, wiki-kurator, archivarius, cto) mit hinterlegten Agent-IDs
- [ ] **MOS-03**: Smoke-Test: `tom-issue` erstellt erfolgreich ein Test-Issue im Maximus_OS-Dashboard
- [ ] **MOS-04**: `CLAUDE.md` + `AGENTS.md` dokumentieren Kommunikationsregeln (Milestones/Architektur/Tools → Issue; Kleinkram → kein Issue)
- [ ] **MOS-05**: `Obsidian_Zentralw/CLAUDE.md` Workflow WF-06 "Issue an Maximus_OS schreiben" ist dokumentiert
- [ ] **MOS-06**: Abschluss-Issue für Maximus_OS Integration Layer mit Referenz auf `bin/tom-issue`

### Ollama Installation (OLL)

- [ ] **OLL-01**: `ollama` Binary ist installiert und verifiziert (`which ollama`, `ollama --version`)
- [ ] **OLL-02**: `OLLAMA_MODELS=/Users/maxim/Ollama` ist persistent in `~/.zshrc` und Verzeichnis existiert
- [ ] **OLL-03**: Ollama-Server läuft und `ollama list` funktioniert
- [ ] **OLL-04**: `gemma4:e4b` ist geladen (via `ollama pull`) und physisch in `/Users/maxim/Ollama`
- [ ] **OLL-05**: Smoke-Test: `ollama run gemma4:e4b "Hallo"` liefert plausible Antwort
- [ ] **OLL-06**: Abschluss-Issue dokumentiert Ollama-Reinstall mit Pfad + Version

### Gemma Custom Model + RAG (GEM)

- [ ] **GEM-01**: `Gemma/modelfile/Modelfile` verweist auf `gemma4:e4b` (statt ungültigem `gemma4:latest`)
- [ ] **GEM-02**: Custom-Model `gemme` ist via `ollama create` gebaut und in `ollama list` sichtbar
- [ ] **GEM-03**: `Gemma/rag/config.py` zeigt auf iCloud-Vault-Pfade (`90_Wiki`, `Clippings`)
- [ ] **GEM-04**: ChromaDB ist gegen neuen Vault reindiziert, Chunk-Count ist geloggt
- [ ] **GEM-05**: `eval/run_eval.py` liefert dokumentierten Baseline-Score > 0
- [ ] **GEM-06**: `query.py "Was ist in 90_Wiki/index.md dokumentiert?"` liefert plausible Antwort
- [ ] **GEM-07**: `training/collector.py` hat ≥10 Q&A-Pairs in `training/data/qa_pairs.jsonl` gesammelt
- [ ] **GEM-08**: Abschluss-Issue dokumentiert Gemma RAG mit Eval-Score

### Tom ↔ Gemma Wiring (WIRE)

- [ ] **WIRE-01**: `bin/tom-ask` Wrapper ruft `Gemma/rag/query.py` auf und gibt Antwort + Quellen zurück
- [ ] **WIRE-02**: `tom-ask` ist im `PATH` verfügbar (Symlink oder PATH-Extension)
- [ ] **WIRE-03**: `CLAUDE.md` Sektion "Lokale Wiki-Queries" dokumentiert wann Tom `tom-ask` statt Obsidian-Suche nutzt
- [ ] **WIRE-04**: Maximus_OS Tom-Agent-Konfiguration ist geprüft (entweder kann Agent `ollama run gemme` nutzen → dokumentiert, oder Issue an CTO eröffnet)
- [ ] **WIRE-05**: Abschluss-Issue dokumentiert `tom-ask` Live-Status

### Dokumentation (DOC11)

- [ ] **DOC11-01**: `Obsidian_Zentralw/log.md` hat v1.1 Abschluss-Eintrag
- [ ] **DOC11-02**: `Obsidian_Zentralw/70_Hardware/ollama-setup.md` dokumentiert Ollama-Setup via Hardware-Template
- [ ] **DOC11-03**: `Obsidian_Zentralw/90_Wiki/projekte/paperclipai.md` ist mit v1.1 Integration-Layer aktualisiert
- [ ] **DOC11-04**: `Gemma/README.md` enthält komplette Setup-Doku (Install, Modelfile, Config, RAG-Run, Training, Eval, Fine-Tuning-Roadmap)
- [ ] **DOC11-05**: Finales Milestone-Abschluss-Issue in Maximus_OS mit Commit-Hashes und Roadmap-Link

## v1.0 Requirements (Shipped — Commit `525c073`)

Requirements für das initiale Tom-Setup. Komplett shipped in Commit `525c073` (Phases 1–7).

### Identität (IDENT)

- ✓ **IDENT-01**: Claude nimmt in diesem Repo die Rolle "Tom" als persönlicher Lebens-Assistent an
- ✓ **IDENT-02**: Tom kennt die Personen in Maxims Leben (Familie + Eltern) und deren Rollen
- ✓ **IDENT-03**: Tom kennt seine Aufgabenbereiche (Familie, Eltern-Betreuung, Dokumente, Hardware, Social Media, Wiki)
- ✓ **IDENT-04**: `CLAUDE.md`, `AGENTS.md`, `Obsidian/CLAUDE.md` sind konsistent auf Tom-Rolle umgeschrieben

### Vault-Struktur (VAULT)

- ✓ **VAULT-01..07**: Vault-Gerüst mit 00–99 Ordnern, Migration, Symlink, Dashboard, Log, mkdocs-Scope

### Personen (PERS)

- ✓ **PERS-01..08**: 6 Personen-Seiten + Kontakte-Ordner, Eltern mit Betreuungs-Sektion, Vernetzung

### Dokumente-Mapping (DOC)

- ✓ **DOC-01..05**: 15 Kategorie-Metadaten-Seiten, Verknüpfung mit Personen, einheitliches Frontmatter

### Templates (TMPL)

- ✓ **TMPL-01..09**: 9 Vorlagen für Person, Dokument, Termin, Projekt, Arzttermin, Vertrag, Social-Post, Hardware, Quelle

### Bootstrap (BOOT)

- ✓ **BOOT-01..03**: Gerüst-Seiten + Dashboard + Log final

### Workflows (WF)

- ✓ **WF-01..05**: 5 Workflows in Vault-CLAUDE.md dokumentiert

## v1.2+ Requirements (Deferred)

### Fine-Tuning (FT)

- **FT-01**: Gemma Fine-Tuning via externem Runner (MLX-LM oder Unsloth)
- **FT-02**: Training-Pipeline aus `qa_pairs.jsonl` in echtes Gewichts-Update
- **FT-03**: A/B-Eval zwischen Base- und Fine-Tuned-Model

### Automatisierung

- **AUTO-01**: Templater-Plugin für automatische Frontmatter-Befüllung
- **AUTO-02**: Dataview-Queries für Dashboard statt statischer Listen
- **AUTO-03**: Automatischer Digest ("was steht heute an?") via Hook
- **AUTO-04**: Maximus_OS Tom-Agent kann eigenständig `tom-ask` aufrufen

## Out of Scope

| Feature | Grund |
|---------|-------|
| Echtes Fine-Tuning in v1.1 | Ollama kann keine Gemma-FT direkt; externer Runner kommt in v1.2+ |
| Lokaler Vault bleibt git-versioniert | iCloud Canonical-Entscheidung; Backup via iCloud + Time Machine |
| Maximus_OS führt interaktive Arbeit aus | Tom-Agent in error-State; Hybrid-Modell (Tom direkt, Maximus_OS für Audit/Background) |
| Automatisches Fine-Tuning im CI | Zu komplex für lokales Setup, kommt ggf. v1.3+ |
| Mobile-RAG via Obsidian | Obsidian kann nicht direkt Ollama ansteuern |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| VCLEAN-01 | Phase 8 | Pending |
| VCLEAN-02 | Phase 8 | Pending |
| VCLEAN-03 | Phase 8 | Pending |
| VCLEAN-04 | Phase 8 | Pending |
| VCLEAN-05 | Phase 8 | Pending |
| MOS-01 | Phase 9 | Pending |
| MOS-02 | Phase 9 | Pending |
| MOS-03 | Phase 9 | Pending |
| MOS-04 | Phase 9 | Pending |
| MOS-05 | Phase 9 | Pending |
| MOS-06 | Phase 9 | Pending |
| OLL-01 | Phase 10 | Pending |
| OLL-02 | Phase 10 | Pending |
| OLL-03 | Phase 10 | Pending |
| OLL-04 | Phase 10 | Pending |
| OLL-05 | Phase 10 | Pending |
| OLL-06 | Phase 10 | Pending |
| GEM-01 | Phase 11 | Pending |
| GEM-02 | Phase 11 | Pending |
| GEM-03 | Phase 11 | Pending |
| GEM-04 | Phase 11 | Pending |
| GEM-05 | Phase 11 | Pending |
| GEM-06 | Phase 11 | Pending |
| GEM-07 | Phase 11 | Pending |
| GEM-08 | Phase 11 | Pending |
| WIRE-01 | Phase 12 | Pending |
| WIRE-02 | Phase 12 | Pending |
| WIRE-03 | Phase 12 | Pending |
| WIRE-04 | Phase 12 | Pending |
| WIRE-05 | Phase 12 | Pending |
| DOC11-01 | Phase 13 | Pending |
| DOC11-02 | Phase 13 | Pending |
| DOC11-03 | Phase 13 | Pending |
| DOC11-04 | Phase 13 | Pending |
| DOC11-05 | Phase 13 | Pending |

**Coverage:**
- v1.1 requirements: 35 total
- Mapped to phases: 35
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-10*
*Last updated: 2026-04-10 after v1.1 milestone start*
