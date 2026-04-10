# Requirements: Tom — Persönlicher Lebens-Assistent

**Defined:** 2026-04-10
**Milestone:** v1.0 — Tom Bootstrap
**Core Value:** Maxim hat eine einzige, vertrauenswürdige Ablage für alles, was in seinem Leben wichtig ist — Tom weiß, wo was liegt, und unterstützt proaktiv.

## v1.0 Requirements

Requirements für das initiale Tom-Setup. Jeder Eintrag mappt auf genau eine Phase im Roadmap.

### Identität (IDENT)

- [ ] **IDENT-01**: Claude nimmt in diesem Repo die Rolle "Tom" als persönlicher Lebens-Assistent an (nicht Research-Wiki-Autor)
- [ ] **IDENT-02**: Tom kennt die Personen in Maxims Leben (Familie + Eltern) und deren Rollen
- [ ] **IDENT-03**: Tom kennt seine Aufgabenbereiche (Familie, Eltern-Betreuung, Dokumente, Hardware, Social Media, Wiki)
- [ ] **IDENT-04**: `CLAUDE.md`, `AGENTS.md`, `Obsidian/CLAUDE.md` sind konsistent auf Tom-Rolle umgeschrieben

### Vault-Struktur (VAULT)

- [ ] **VAULT-01**: Neuer Vault existiert mit Ordnern 00_Inbox, 10_Personen, 20_Dokumente, 30_Projekte, 40_Aufgaben, 50_Gesundheit, 60_Finanzen, 70_Hardware, 80_Social_Media, 90_Wiki, 99_Vorlagen, raw, Clippings, output
- [ ] **VAULT-02**: Bestehendes `wiki/` ist nach `90_Wiki/` migriert, keine Datei verloren
- [ ] **VAULT-03**: Bestehende `TODOS.md` und `PROJEKTE.md` sind in `40_Aufgaben/` verschoben (oder verlinkt)
- [ ] **VAULT-04**: Symlink `Archiv → ~/Downloads/Archiv` funktioniert und ist aus Obsidian verlinkbar
- [ ] **VAULT-05**: `index.md` (Tom-Hub Dashboard) zeigt Sektionen: Heute, Offene Aufgaben, Eltern-Status, Laufende Projekte, Letzte Clippings
- [ ] **VAULT-06**: `log.md` (chronologisches Ereignis-Log) existiert und wird bei Ingest/Query/Lint beschrieben
- [ ] **VAULT-07**: `mkdocs.yml` publiziert ausschließlich `90_Wiki/`, alle persönlichen Ordner sind explizit ausgeschlossen

### Personen (PERS)

- [ ] **PERS-01**: `10_Personen/Familie/Maxim-Schmidt.md` mit Frontmatter, Rollen, Links
- [ ] **PERS-02**: `10_Personen/Familie/Olga-Schmidt.md` mit Frontmatter, Rollen, Links
- [ ] **PERS-03**: `10_Personen/Familie/Karina-Schmidt.md` mit Frontmatter, Rollen, Links
- [ ] **PERS-04**: `10_Personen/Familie/Elina-Schmidt.md` mit Frontmatter, Rollen, Links
- [ ] **PERS-05**: `10_Personen/Eltern/Waldemar-Schmidt.md` inkl. Betreuungs-Sektion (Ämter, Vollmachten, laufende Anträge)
- [ ] **PERS-06**: `10_Personen/Eltern/Nina-Schmidt.md` inkl. Betreuungs-Sektion
- [ ] **PERS-07**: `10_Personen/Kontakte/` Ordner existiert für Ärzte/Ämter/Handwerker (leer, mit README)
- [ ] **PERS-08**: Alle Personen-Seiten sind aus `index.md` verlinkt und untereinander vernetzt

### Dokumente-Mapping (DOC)

- [ ] **DOC-01**: Für jede der 15 Archiv-Kategorien (01 Arbeitgeber … 15 Sonstiges) existiert eine Metadaten-Seite unter `20_Dokumente/`
- [ ] **DOC-02**: Jede Kategorie-Seite enthält: Pfad zum Archiv-Ordner, wichtige Dateien (Platzhalter), Fristen/Wiedervorlagen, Ansprechpartner
- [ ] **DOC-03**: Betreuungs-Dokumente (`13_Betreuung.md`) sind mit Waldemar/Nina verlinkt
- [ ] **DOC-04**: Universitäts-Dokumente (`12_Uni.md`) sind mit Maxim verlinkt
- [ ] **DOC-05**: Jede Kategorie-Seite hat einheitliches Frontmatter (`type: dokumenten-index`)

### Templates (TMPL)

- [ ] **TMPL-01**: `99_Vorlagen/Person.md` — Template für neue Personen
- [ ] **TMPL-02**: `99_Vorlagen/Dokument.md` — Template für neue Dokument-Metadaten
- [ ] **TMPL-03**: `99_Vorlagen/Termin.md` — Template für Termine (Arzt, Amt, etc.)
- [ ] **TMPL-04**: `99_Vorlagen/Projekt.md` — Template für Projekte/Vorhaben
- [ ] **TMPL-05**: `99_Vorlagen/Arzttermin.md` — spezialisiertes Template für medizinische Termine
- [ ] **TMPL-06**: `99_Vorlagen/Vertrag.md` — Template für Versicherungen/Verträge
- [ ] **TMPL-07**: `99_Vorlagen/Social-Post.md` — Template für Social-Media-Posts
- [ ] **TMPL-08**: `99_Vorlagen/Hardware-Geraet.md` — Template für Hardware-Setups
- [ ] **TMPL-09**: `99_Vorlagen/Quelle.md` — Template für Wiki-Quellen (Migration aus Altbestand)

### Bootstrap (BOOT)

- [ ] **BOOT-01**: Gerüst-Seiten in `30_Projekte/`, `50_Gesundheit/`, `60_Finanzen/`, `70_Hardware/`, `80_Social_Media/` existieren mit README + Frontmatter
- [ ] **BOOT-02**: `log.md` listet initial alle leeren Seiten, die später organisch gefüllt werden sollen
- [ ] **BOOT-03**: `index.md` Dashboard rendert ohne Broken Links, alle Sektionen haben mindestens Platzhalter-Inhalt

### Workflows (WF)

- [ ] **WF-01**: `Obsidian_Zentralw/CLAUDE.md` (neuer Vault-Stammordner) dokumentiert Workflow "Neues Dokument ablegen" (Scan → Inbox → kategorisieren → Archiv + Metadaten-Seite)
- [ ] **WF-02**: Workflow "Arzttermin erfassen" dokumentiert (Person → Termin-Template → Verknüpfung Gesundheit)
- [ ] **WF-03**: Workflow "Social-Media-Post erstellen" dokumentiert (Idee → Draft → Kanal → Tracking)
- [ ] **WF-04**: Workflow "Frist / Wiedervorlage anlegen" dokumentiert (40_Aufgaben + Verknüpfung auf Dokument/Person)
- [ ] **WF-05**: Workflow "Hardware-Setup dokumentieren" dokumentiert (Gerät → 70_Hardware → Seriennummer, Netzwerk, Config)

## v1.1+ Requirements (Deferred)

### Migration nach iCloud

- **MIG-01**: Vault von lokalem Pfad nach `/Volumes/Obsidian/.../Obsidian_Zentralw` verschieben
- **MIG-02**: iCloud-Sync verifizieren, Obsidian-App-Konfiguration anpassen

### Automatisierung

- **AUTO-01**: Templater-Plugin für automatische Frontmatter-Befüllung
- **AUTO-02**: Dataview-Queries für Dashboard statt statischer Listen
- **AUTO-03**: Automatischer Digest ("was steht heute an?") via Hook

### RAG-Integration

- **RAG-01**: Gemma/RAG-Pipeline auf neuen Vault-Pfad umziehen
- **RAG-02**: Getrennte ChromaDB-Collections für persönlich vs. wiki

## Out of Scope

| Feature | Grund |
|---------|-------|
| Eigene App/UI | Tom lebt in Claude Code + Obsidian, keine eigene Oberfläche |
| OCR-Pipeline für Scans | Zu komplex für v1.0, Scans kommen manuell |
| Proaktive Interview-Phasen | Inhalte wachsen organisch, keine Zwangsinterviews |
| Persönliche Daten public deployen | Privacy-Constraint — nur `90_Wiki/` geht auf die Website |
| Automatischer Sync zu Cloud-Diensten | Out-of-Scope für Bootstrap, später ggf. über GSD-Phase |
| Mobile-App-Integration | Obsidian Mobile reicht, keine Custom-Integration |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| IDENT-01 | Phase 1 | Pending |
| IDENT-02 | Phase 1 | Pending |
| IDENT-03 | Phase 1 | Pending |
| IDENT-04 | Phase 1 | Pending |
| VAULT-01 | Phase 2 | Pending |
| VAULT-02 | Phase 2 | Pending |
| VAULT-03 | Phase 2 | Pending |
| VAULT-04 | Phase 2 | Pending |
| VAULT-05 | Phase 2 | Pending |
| VAULT-06 | Phase 2 | Pending |
| VAULT-07 | Phase 2 | Pending |
| PERS-01 | Phase 3 | Pending |
| PERS-02 | Phase 3 | Pending |
| PERS-03 | Phase 3 | Pending |
| PERS-04 | Phase 3 | Pending |
| PERS-05 | Phase 3 | Pending |
| PERS-06 | Phase 3 | Pending |
| PERS-07 | Phase 3 | Pending |
| PERS-08 | Phase 3 | Pending |
| DOC-01 | Phase 4 | Pending |
| DOC-02 | Phase 4 | Pending |
| DOC-03 | Phase 4 | Pending |
| DOC-04 | Phase 4 | Pending |
| DOC-05 | Phase 4 | Pending |
| TMPL-01 | Phase 5 | Pending |
| TMPL-02 | Phase 5 | Pending |
| TMPL-03 | Phase 5 | Pending |
| TMPL-04 | Phase 5 | Pending |
| TMPL-05 | Phase 5 | Pending |
| TMPL-06 | Phase 5 | Pending |
| TMPL-07 | Phase 5 | Pending |
| TMPL-08 | Phase 5 | Pending |
| TMPL-09 | Phase 5 | Pending |
| BOOT-01 | Phase 6 | Pending |
| BOOT-02 | Phase 6 | Pending |
| BOOT-03 | Phase 6 | Pending |
| WF-01 | Phase 7 | Pending |
| WF-02 | Phase 7 | Pending |
| WF-03 | Phase 7 | Pending |
| WF-04 | Phase 7 | Pending |
| WF-05 | Phase 7 | Pending |

**Coverage:**
- v1.0 requirements: 40 total
- Mapped to phases: 40
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-10*
*Last updated: 2026-04-10 after initial definition*
