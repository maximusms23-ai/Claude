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

## v1.1 — Maximus_OS Integration + Ollama Gemma Revival

**Goal:** Vault-Single-Source (iCloud), Hybrid-Integration mit Maximus_OS/PaperclipAI, lokales Gemma-Model gegen neuen Vault mit RAG.

### Phases

- [ ] **Phase 8: Vault-Cleanup** — iCloud als Single Source of Truth, lokales Duplikat entfernen
- [ ] **Phase 9: Maximus_OS Integration Tooling** — `tom-issue` Wrapper + Kommunikationsregeln
- [ ] **Phase 10: Ollama Installation** — Ollama unter `/Users/maxim/Ollama` mit `gemma2:9b` bereit
- [ ] **Phase 11: Gemma Custom Model + RAG Pipeline** — `gemme`-Model gebaut, ChromaDB reindiziert, Eval dokumentiert
- [ ] **Phase 12: Tom ↔ Gemma Wiring** — `tom-ask` Wrapper live, Nutzungsregeln in CLAUDE.md
- [ ] **Phase 13: Dokumentation + Abschluss** — Vault-Log, Hardware-Doku, Gemma-README, Milestone-Close

### Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 8. Vault-Cleanup | 0/? | Not started | — |
| 9. Maximus_OS Integration Tooling | 0/? | Not started | — |
| 10. Ollama Installation | 0/? | Not started | — |
| 11. Gemma Custom Model + RAG Pipeline | 0/? | Not started | — |
| 12. Tom ↔ Gemma Wiring | 0/? | Not started | — |
| 13. Dokumentation + Abschluss | 0/? | Not started | — |

---

## Phase Details

### Phase 8: Vault-Cleanup

**Goal**: Der iCloud-Vault ist als einzige Quelle der Wahrheit bestätigt und das lokale Duplikat ist vollständig aus Git und Dateisystem entfernt.

**Depends on**: Nothing (first phase of v1.1)

**Requirements**: VCLEAN-01, VCLEAN-02, VCLEAN-03, VCLEAN-04, VCLEAN-05

**Success Criteria** (what must be TRUE):
1. `git ls-files` zeigt keine Dateien unter `Obsidian_Zentralw/` mehr an
2. `ls /Users/maxim/Claude/Obsidian_Zentralw` schlägt fehl — Verzeichnis existiert nicht lokal
3. `.gitignore` enthält expliziten Eintrag für den lokalen Vault-Pfad mit erklärendem Kommentar zur iCloud-Canonical-Entscheidung
4. `CLAUDE.md` und `AGENTS.md` referenzieren den iCloud-Pfad als `$TOM_VAULT`
5. Ein Maximus_OS-Issue belegt den Cleanup mit Commit-Hash

**Plans**: TBD

---

### Phase 9: Maximus_OS Integration Tooling

**Goal**: Tom kann über einen lokalen Wrapper strukturierte Issues an Maximus_OS schicken, Agent-Aliase sind hinterlegt, und die Kommunikationsregeln sind in allen relevanten Quellen dokumentiert.

**Depends on**: Phase 8 (CLAUDE.md-Pfade müssen bereits aktualisiert sein)

**Requirements**: MOS-01, MOS-02, MOS-03, MOS-04, MOS-05, MOS-06

**Success Criteria** (what must be TRUE):
1. `bin/tom-issue --title "Test" --description "Smoke" --agent tom` erstellt ein Issue im Maximus_OS-Dashboard ohne Fehler
2. `--agent wiki-kurator`, `--agent archivarius` und `--agent cto` routen an die jeweils richtigen Agent-IDs
3. `CLAUDE.md` und `AGENTS.md` beschreiben klar, wann ein Issue nötig ist (Milestones, Architektur, Handoffs) und wann nicht (Kleinkram < 5 Min)
4. `Obsidian_Zentralw/CLAUDE.md` enthält Workflow WF-06 "Issue an Maximus_OS schreiben" mit Beispielen

**Plans**: TBD

---

### Phase 10: Ollama Installation

**Goal**: Ollama ist sauber unter `/Users/maxim/Ollama` installiert, `gemma2:9b` ist geladen und eine einfache Prompt-Anfrage liefert eine plausible Antwort.

**Depends on**: Nothing (kann parallel zu Phase 9 laufen; Phase 11 hängt von Phase 10 ab)

**Requirements**: OLL-01, OLL-02, OLL-03, OLL-04, OLL-05, OLL-06

**Success Criteria** (what must be TRUE):
1. `which ollama` und `ollama --version` liefern gültige Ausgaben in einer frischen Shell
2. `echo $OLLAMA_MODELS` gibt `/Users/maxim/Ollama` zurück — auch nach Shell-Neustart (persistent in `~/.zshrc`)
3. `ollama list` zeigt `gemma2:9b` und das Modell liegt physisch in `/Users/maxim/Ollama`
4. `ollama run gemma2:9b "Hallo"` gibt eine sinnvolle Antwort zurück
5. Ein Maximus_OS-Issue dokumentiert den Reinstall mit Pfad und Version

**Plans**: TBD

---

### Phase 11: Gemma Custom Model + RAG Pipeline

**Goal**: Das Custom-Model `gemme` ist auf Basis von `gemma2:9b` gebaut, ChromaDB ist gegen den iCloud-Vault reindiziert, und eine RAG-Query liefert inhaltlich plausible Antworten mit dokumentiertem Eval-Baseline.

**Depends on**: Phase 10 (Ollama + `gemma2:9b` muss verfügbar sein), Phase 8 (iCloud-Vault-Pfade müssen final sein)

**Requirements**: GEM-01, GEM-02, GEM-03, GEM-04, GEM-05, GEM-06, GEM-07, GEM-08

**Success Criteria** (what must be TRUE):
1. `ollama list` zeigt `gemme` als eigenes Model
2. `python3 Gemma/rag/query.py "Was ist in 90_Wiki/index.md dokumentiert?"` gibt eine inhaltlich plausible Antwort mit Quellenangabe zurück
3. `eval/run_eval.py` läuft durch und gibt einen dokumentierten Baseline-Score > 0 aus
4. `Gemma/training/data/qa_pairs.jsonl` enthält mindestens 10 Q&A-Paare
5. `Gemma/rag/config.py` verweist ausschließlich auf iCloud-Vault-Pfade

**Plans**: TBD

---

### Phase 12: Tom ↔ Gemma Wiring

**Goal**: `tom-ask` ist als Shell-Wrapper im PATH verfügbar, leitet Fragen an das lokale RAG weiter und gibt Antwort plus Quellen zurück; die Nutzungsregeln sind in `CLAUDE.md` dokumentiert.

**Depends on**: Phase 11 (RAG-Pipeline muss funktionieren)

**Requirements**: WIRE-01, WIRE-02, WIRE-03, WIRE-04, WIRE-05

**Success Criteria** (what must be TRUE):
1. `tom-ask "Was hat Maxim über PaperclipAI dokumentiert?"` gibt eine Antwort mit Quellenangabe direkt im Terminal aus
2. `which tom-ask` findet das Binary (Symlink oder PATH-Erweiterung aktiv nach Shell-Neustart)
3. `CLAUDE.md` enthält eine Sektion "Lokale Wiki-Queries" mit konkreten Beispielen wann `tom-ask` vs. Obsidian-Suche sinnvoll ist
4. Maximus_OS-Agent-Konfiguration für `ollama run gemme` ist entweder aktiviert und dokumentiert, oder ein Issue an CTO ist eröffnet

**Plans**: TBD

---

### Phase 13: Dokumentation + Abschluss

**Goal**: Alle Installationen und Entscheidungen aus v1.1 sind im Vault und in Maximus_OS nachvollziehbar dokumentiert, und das Milestone-Abschluss-Issue schließt v1.1 formal ab.

**Depends on**: Phase 12 (alles live bevor dokumentiert wird)

**Requirements**: DOC11-01, DOC11-02, DOC11-03, DOC11-04, DOC11-05

**Success Criteria** (what must be TRUE):
1. `Obsidian_Zentralw/log.md` enthält einen datierten v1.1-Abschluss-Eintrag mit den wichtigsten Änderungen
2. `Obsidian_Zentralw/70_Hardware/ollama-setup.md` existiert und beschreibt vollständig den Ollama-Setup (Pfad, Env-Var, Model, Befehle)
3. `Gemma/README.md` erlaubt einen vollständigen Setup-Nachvollzug ohne externe Hilfe (Install, Modelfile, Config, RAG-Run, Training, Eval)
4. `90_Wiki/projekte/paperclipai.md` ist mit dem v1.1 Integration Layer aktualisiert
5. Ein finales Milestone-Abschluss-Issue in Maximus_OS referenziert alle relevanten Commit-Hashes und den Roadmap-Link

**Plans**: TBD

---

## Coverage: v1.1

| Requirement | Phase | Status |
|-------------|-------|--------|
| VCLEAN-01 | 8 | Pending |
| VCLEAN-02 | 8 | Pending |
| VCLEAN-03 | 8 | Pending |
| VCLEAN-04 | 8 | Pending |
| VCLEAN-05 | 8 | Pending |
| MOS-01 | 9 | Pending |
| MOS-02 | 9 | Pending |
| MOS-03 | 9 | Pending |
| MOS-04 | 9 | Pending |
| MOS-05 | 9 | Pending |
| MOS-06 | 9 | Pending |
| OLL-01 | 10 | Pending |
| OLL-02 | 10 | Pending |
| OLL-03 | 10 | Pending |
| OLL-04 | 10 | Pending |
| OLL-05 | 10 | Pending |
| OLL-06 | 10 | Pending |
| GEM-01 | 11 | Pending |
| GEM-02 | 11 | Pending |
| GEM-03 | 11 | Pending |
| GEM-04 | 11 | Pending |
| GEM-05 | 11 | Pending |
| GEM-06 | 11 | Pending |
| GEM-07 | 11 | Pending |
| GEM-08 | 11 | Pending |
| WIRE-01 | 12 | Pending |
| WIRE-02 | 12 | Pending |
| WIRE-03 | 12 | Pending |
| WIRE-04 | 12 | Pending |
| WIRE-05 | 12 | Pending |
| DOC11-01 | 13 | Pending |
| DOC11-02 | 13 | Pending |
| DOC11-03 | 13 | Pending |
| DOC11-04 | 13 | Pending |
| DOC11-05 | 13 | Pending |

**v1.1 total: 35 — Mapped: 35 — Unmapped: 0**

---

*Roadmap created: 2026-04-10*
*Milestone: v1.1 — Maximus_OS Integration + Ollama Gemma Revival*
