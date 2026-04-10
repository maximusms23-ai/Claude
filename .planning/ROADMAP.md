# Roadmap: Tom v1.0 — Persönlicher Lebens-Assistent

**Milestone:** v1.0 — Tom Bootstrap
**Created:** 2026-04-10
**Phases:** 7
**Requirements mapped:** 40 / 40 ✓

## Overview

| # | Phase | Goal | Requirements | Criteria |
|---|-------|------|--------------|----------|
| 1 | Identität Tom | Claude-Rolle auf Tom umstellen, Familie + Aufgabenbereiche dokumentieren | IDENT-01..04 | 3 |
| 2 | Vault-Struktur | Neuen Vault mit 00–99 Ordnern aufsetzen, Migration, Symlink, mkdocs-Scope | VAULT-01..07 | 5 |
| 3 | Personen-Seiten | 6 Personen-Seiten + Kontakte-Ordner anlegen, vernetzen | PERS-01..08 | 4 |
| 4 | Dokumente-Mapping | 15 Kategorie-Metadaten-Seiten anlegen, mit Personen verlinken | DOC-01..05 | 3 |
| 5 | Templates | 9 Vorlagen in `99_Vorlagen/` anlegen | TMPL-01..09 | 3 |
| 6 | Bootstrap | Leere Gerüst-Seiten + Dashboard + Log final | BOOT-01..03 | 3 |
| 7 | Workflows | 5 Workflow-Dokumentationen in `CLAUDE.md` des Vaults | WF-01..05 | 3 |

## Phase Details

### Phase 1: Identität Tom

**Goal:** Claude übernimmt in diesem Repo die Rolle "Tom" als persönlicher Lebens-Assistent; alle relevanten CLAUDE.md/AGENTS.md-Dateien sind konsistent aktualisiert.

**Requirements:** IDENT-01, IDENT-02, IDENT-03, IDENT-04

**Success Criteria:**
1. `/Users/maxim/Claude/CLAUDE.md` beschreibt Tom-Rolle, Familie (Olga, Karina, Elina), Eltern (Waldemar, Nina), Aufgabenbereiche
2. `/Users/maxim/Claude/AGENTS.md` ist konsistent aus Codex-Sicht aktualisiert
3. `/Users/maxim/Claude/Obsidian/CLAUDE.md` ist vom Research-Wiki zum Lebens-Vault umgeschrieben (inkl. neuer Ordner 00–99)

### Phase 2: Vault-Struktur

**Goal:** Neuer Vault unter `/Users/maxim/Claude/Obsidian_Zentralw/` mit kompletter Ordnerstruktur 00–99 existiert, `wiki/` ist migriert, Archiv-Symlink funktioniert, `mkdocs.yml` publiziert nur `90_Wiki/`.

**Requirements:** VAULT-01..07

**Success Criteria:**
1. Ordner 00_Inbox, 10_Personen/{Familie,Eltern,Kontakte}, 20_Dokumente, 30_Projekte, 40_Aufgaben, 50_Gesundheit, 60_Finanzen, 70_Hardware, 80_Social_Media, 90_Wiki, 99_Vorlagen existieren
2. Alle `*.md`-Dateien aus altem `Obsidian/wiki/` sind in `Obsidian_Zentralw/90_Wiki/` verfügbar (Anzahl stimmt überein)
3. `Obsidian_Zentralw/Archiv` ist ein Symlink auf `~/Downloads/Archiv`, `ls` zeigt alle 15 Kategorien
4. `Obsidian_Zentralw/index.md` rendert Dashboard-Struktur (Heute, Aufgaben, Eltern, Projekte, Clippings)
5. `Obsidian_Zentralw/mkdocs.yml` Build zeigt ausschließlich Seiten aus `90_Wiki/` in der Site-Navigation

### Phase 3: Personen-Seiten

**Goal:** Alle 6 Personen haben eigene Seiten mit konsistentem Frontmatter; Eltern-Seiten enthalten Betreuungs-Sektion; alle sind aus `index.md` und untereinander verlinkt.

**Requirements:** PERS-01..08

**Success Criteria:**
1. 6 Personen-Seiten existieren mit Frontmatter (`title`, `created`, `type: person`, `tags`)
2. Waldemar und Nina Schmidt haben Betreuungs-Sektion (Ämter, Vollmachten, Anträge — Platzhalter)
3. `Kontakte/README.md` erklärt den Ordner für zukünftige Ärzte/Ämter/Handwerker
4. Graph-View (manuell prüfbar in Obsidian) zeigt alle 6 Personen als verknüpftes Cluster mit `index.md`

### Phase 4: Dokumente-Mapping

**Goal:** Jede der 15 Archiv-Kategorien hat eine Metadaten-Seite in `20_Dokumente/`, die den Archivpfad referenziert und mit relevanten Personen verlinkt ist.

**Requirements:** DOC-01..05

**Success Criteria:**
1. 15 Kategorie-Seiten (`01_Arbeitgeber_Arbeitsamt.md` … `15_Sonstiges.md`) existieren
2. Jede Seite hat Frontmatter `type: dokumenten-index`, Pfad-Referenz auf `Archiv/<Kategorie>/`, Platzhalter für Dateien/Fristen/Ansprechpartner
3. `13_Betreuung.md` verlinkt Waldemar/Nina, `12_Uni.md` verlinkt Maxim

### Phase 5: Templates

**Goal:** 9 Vorlagen in `99_Vorlagen/` ermöglichen schnelles Anlegen neuer Personen, Dokumente, Termine, Projekte, Arzttermine, Verträge, Social-Posts, Hardware-Geräte, Quellen.

**Requirements:** TMPL-01..09

**Success Criteria:**
1. 9 Template-Dateien existieren in `99_Vorlagen/`
2. Jedes Template enthält vollständiges YAML-Frontmatter + kommentierte Platzhalter-Sektionen
3. README in `99_Vorlagen/` erklärt Nutzung (Copy-Paste oder Templater-Plugin)

### Phase 6: Bootstrap

**Goal:** Leere Gerüst-Seiten, Dashboard und Log sind final; der Vault ist "Tom-bereit" — d. h. Maxim kann Obsidian öffnen und sofort loslegen, ohne Broken Links.

**Requirements:** BOOT-01..03

**Success Criteria:**
1. `30_Projekte/`, `50_Gesundheit/`, `60_Finanzen/`, `70_Hardware/`, `80_Social_Media/` enthalten jeweils README + ersten Platzhalter-Eintrag
2. `log.md` listet alle leeren Seiten als "zu füllen beim ersten Use-Case"
3. `index.md` Dashboard rendert ohne Broken Links (`grep -r '\[\[' | check`)

### Phase 7: Workflows

**Goal:** `Obsidian_Zentralw/CLAUDE.md` dokumentiert 5 konkrete Workflows, die Tom bei typischen Aufgaben folgen soll.

**Requirements:** WF-01..05

**Success Criteria:**
1. Alle 5 Workflows sind in `Obsidian_Zentralw/CLAUDE.md` dokumentiert mit klarem Input → Output
2. Jeder Workflow referenziert die passenden Ordner/Templates
3. Testfall dokumentiert: "was steht bei Papa an?" → Tom weiß, welche Dateien zu lesen sind

## Verification (Milestone-Level)

Am Ende aller 7 Phasen:

1. **Graph-Check**: Obsidian-Graph zeigt alle 6 Personen verlinkt, keine Orphan-Pages
2. **Dashboard-Check**: `index.md` zeigt Heute/Aufgaben/Eltern/Projekte/Clippings ohne Broken Links
3. **Testfall 1**: Neuen Arztbrief in `00_Inbox/` ablegen → Tom kategorisiert, erstellt Metadaten-Seite, verlinkt Person + Dokument
4. **Testfall 2**: Frage "was steht bei Papa an?" → Tom liest `Waldemar-Schmidt.md` + `13_Betreuung.md` und antwortet
5. **Testfall 3**: `mkdocs build` zeigt nur `90_Wiki/`, keine persönlichen Ordner
6. **Testfall 4**: Web-Clipper-Artikel landet in `Clippings/`, Tom ingestet ihn in `90_Wiki/` nach bestehendem Workflow

---
*Roadmap created: 2026-04-10*
