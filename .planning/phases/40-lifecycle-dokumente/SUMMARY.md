# Phase 40: Lifecycle Foundation — Dokumente

## Goal

Dokument-Lifecycle-Schema für `20_Dokumente/` einführen mit 5 States im Frontmatter, Meta Bind Buttons für atomare Transitions, Dataview-Dashboard und Migration existierender Notes.

## Result: Done (2026-04-12)

All 6 requirements (LCY-01..06) completed.

## Actions Taken

1. **Meta Bind Plugin v1.4.6** manuell installiert (GitHub Release → `.obsidian/plugins/obsidian-meta-bind-plugin/`, community-plugins.json aktiviert)
2. **State-Schema** dokumentiert in `$TOM_VAULT/99_Vorlagen/state-schema.md` (5 States, Mermaid-Diagramm, Meta Bind Syntax-Referenz)
3. **Dokument-Template** erweitert (`99_Vorlagen/Dokument.md`): 3 neue Frontmatter-Felder (`state`, `state_changed`, `due_date`) + 4 Meta Bind Buttons mit atomaren `updateMetadata` actions
4. **Dataview-Dashboard** erstellt (`20_Dokumente/Dashboard.md`): 5 Sektionen (Offene, Eingang, In-Bearbeitung, Warte, Kürzlich erledigt, Fällige Fristen)
5. **3 Betreuungs-Dokumente** als End-to-End-Beweis in `20_Dokumente/13_Betreuung/`:
   - Vorsorgevollmacht-Waldemar (state: Eingang, due_date: 2026-04-30)
   - Pflegegrad-Antrag-Nina (state: Warte-auf-Rueckmeldung)
   - Schwerbehindertenausweis-Waldemar (state: Erledigt)
6. **Migration-Script** `bin/tom-state migrate-dokumente`: 15 Kategorie-Index-Dateien migriert, idempotent, `--dry-run`, Symlink `~/bin/tom-state`
7. **Doku-Updates**: CLAUDE.md Lifecycle-Sektion, REQUIREMENTS.md LCY-01..06 done, ROADMAP.md + STATE.md, Vault Phase-Note + Journal + Entscheidungen + log.md + index.md

## Key Decisions

- **Meta Bind Buttons statt inlineSelect**: `inlineSelect` kann nur 1 Feld updaten — `state_changed` würde nie aktualisiert. Buttons setzen via `actions`-Array beide Felder atomar.
- **Meta Bind statt obsidian-note-status**: 325k vs 3k Downloads, flexibler, kein starres Schema.
- **Obsidian Bases verworfen**: Nur Catalyst Early Access (v1.9.0+).
- **Kanban-Integration deferred**: Maxim-Entscheidung, erst Basis-Schema.
- **LCY-03 re-scoped**: Templater-Transition-Snippet → Meta Bind Buttons.

## Files Changed

- `$TOM_VAULT/.obsidian/plugins/obsidian-meta-bind-plugin/` (new)
- `$TOM_VAULT/.obsidian/community-plugins.json` (edited)
- `$TOM_VAULT/99_Vorlagen/state-schema.md` (new)
- `$TOM_VAULT/99_Vorlagen/Dokument.md` (edited)
- `$TOM_VAULT/20_Dokumente/Dashboard.md` (new)
- `$TOM_VAULT/20_Dokumente/13_Betreuung/Vorsorgevollmacht-Waldemar.md` (new)
- `$TOM_VAULT/20_Dokumente/13_Betreuung/Pflegegrad-Antrag-Nina.md` (new)
- `$TOM_VAULT/20_Dokumente/13_Betreuung/Schwerbehindertenausweis-Waldemar.md` (new)
- `$TOM_VAULT/20_Dokumente/13_Betreuung.md` (edited)
- `$TOM_VAULT/20_Dokumente/01..15_*.md` (15 files migrated)
- `bin/tom-state` (new)
- `CLAUDE.md` (edited)
- `.planning/REQUIREMENTS.md` (edited)
- `.planning/ROADMAP.md` (edited)
- `.planning/STATE.md` (edited)
- `$TOM_VAULT/index.md` (edited)
- `$TOM_VAULT/log.md` (edited)
- `$TOM_VAULT/30_Projekte/Tom/Journal/2026-04-12.md` (edited)
- `$TOM_VAULT/30_Projekte/Tom/Entscheidungen.md` (edited)
- `$TOM_VAULT/30_Projekte/Tom/Phasen/Phase-40-v15-Lifecycle-Dokumente.md` (new)
