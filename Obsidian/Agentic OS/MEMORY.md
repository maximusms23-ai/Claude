---
title: "MEMORY"
created: 2026-10-10
type: memory
tags:
  - agentic-os
  - memory
---

# MEMORY — Claude Wiki Vault

> Gepflegt nach [[AI Memory Protocol]]. Zustand, kein Logbuch.

## Projekt-Fakten

- Repo `maximusms23-ai/claude` enthaelt einen Obsidian-Vault unter `Obsidian/`, der als LLM-gepflegte Wissensbasis dient. Der User editiert Wiki-Dateien selten selbst.
- Schreibbereich ist `Obsidian/wiki/`, Einstieg `Obsidian/wiki/index.md`. `Obsidian/raw/` und `Obsidian/Clippings/` sind read-only Quellmaterial.
- Inhaltssprache Deutsch, technische Bezeichner Englisch. Jede `.md`-Seite braucht Frontmatter `title`, `created`, `type`.
- Website-Build: MkDocs Material mit `roamlinks`-Plugin, `docs_dir: wiki` — alles ausserhalb von `wiki/` ist nicht oeffentlich. Deploy via `.github/workflows/deploy.yml`.
- `Obsidian/TODOS.md` und `Obsidian/PROJEKTE.md` sind gitignored und existieren nur lokal beim User. In Cloud-Sessions sind sie nicht vorhanden.
- Agent-OS-Ebene liegt in `.claude/` (Agenten, Commands, Hooks, Settings), `scripts/` (Pruefskript, Bootstrap) und `Obsidian/Agentic OS/` (Protokoll, Gedaechtnis).
- Offene `[[Wikilinks]]` sind in diesem Vault **keine Fehler**, sondern Themenvorschlaege fuer noch nicht existierende Seiten. `wiki/themen/Mannheim.md` haelt allein 36 davon.

## Aktueller Stand

Agent-OS-Ebene ist repo-seitig vollstaendig ausgebaut und in Cloud-Sessions nachweislich aktiv: SessionStart-Hook feuert, die fuenf Agenten laden. Dazu sieben Slash-Commands, drei Hooks (Gedaechtnis laden, Quellmaterial schuetzen, Pflicht-Updates erzwingen), `scripts/wiki_check.py` und dieselbe Pruefung in CI (`.github/workflows/wiki-check.yml`). Branch `claude/agent-os-integration-context-gobmre`.

Aktueller Pruefstand der Wissensbasis: 0 Fehler, 6 Warnungen, 40 offene Links (Stand 2026-10-10).

Nicht erledigt und aus einer Cloud-Session nicht erledigbar: der Anschluss an das **eigene Agent-OS-System des Users** unter `/Users/maxim/Projects/Maximus_OS`. Die hier gebaute Ebene wurde entworfen, ohne dieses System jemals gesehen zu haben — ob Agenten-Format, Memory-Ort und Verzeichnis-Layout dazu passen, ist offen. Dafuer liegt eine Aufgabenkarte bereit, die auf dem Mac des Users startet.

## Entscheidungen

- 2026-10-10 — Gedaechtnis als versionierte Datei im Repo (`Obsidian/Agentic OS/MEMORY.md`) statt als lokaler Zustand — Cloud-Container sind ephemer, nur git ueberlebt den Session-Wechsel.
- 2026-10-10 — `Agentic OS/` liegt ausserhalb von `wiki/`, damit `mkdocs build` das Gedaechtnis nicht auf die oeffentliche Website stellt.
- 2026-10-10 — Agenten-Zuschnitt entlang der bestehenden Workflows aus `CLAUDE.md`/`AGENTS.md` (Ingest, Health, Index, Output) plus `memory-keeper`, statt generischer Rollen.
- 2026-10-10 — Der SessionStart-Hook laedt Kontext und bricht nie ab (`exit 0` in jedem Fall), damit ein Fehler im Hook keine Session blockiert. Dasselbe Prinzip gilt fuer alle drei Hooks: im Fehlerfall fallen sie offen aus.
- 2026-10-10 — Offene Wikilinks gelten als Warnung, nicht als Fehler. Ein erster Entwurf von `wiki_check.py` meldete 42 "tote Links" und haette CI dauerhaft rot gehalten, obwohl 40 davon normale Obsidian-Stubs sind.
- 2026-10-10 — Die Index-Pflicht im Stop-Hook greift nur bei strukturellen Aenderungen (anlegen, umbenennen, entfernen), nicht bei reinen Textaenderungen — so steht es in CLAUDE.md ("when adding/removing pages"). Der erste Entwurf war strenger als die Regel und hat sich selbst blockiert.

## Offene Punkte

- Lokales Bootstrap auf dem Mac des Users ist offen. Aus einer Cloud-Session nicht machbar: keine Computer-Use-/Remote-Device-Tools vorhanden, keine Remote-Control-Verbindung, keine Peer-Session auf seiner Maschine. Erfordert eine Session, die auf seinem Rechner laeuft (Claude Desktop oder `claude remote-control`).
- `Obsidian/raw/` existiert laut Dokumentation, ist im Repo aber nicht vorhanden — nur `Clippings/`, `Ideen/`, `Projekte/`. Ob `raw/` lokal existiert und nur nicht committet ist, ist ungeklaert.
- `Obsidian/wiki/Unbenannt.base` und `Obsidian/Unbenannt.canvas` sind unbenannte Platzhalter ohne Inhalt — Zweck unklar.
- `Obsidian/wiki/2026-04-09.md` ist eine vollstaendig leere Seite. Nicht geloescht, weil das eine inhaltliche Entscheidung des Users ist.
- `Obsidian/.github/workflows/deploy.yml` ist eine Dublette des Workflows im Repo-Wurzel-`.github/`. Nur der im Wurzelverzeichnis ist aktiv; die Kopie im Vault ist wirkungslos und stiftet Verwirrung.

## Gelernte Konventionen

- Der User fragt auf Deutsch und erwartet Antworten auf Deutsch.
- Vor Aussagen ueber Vorhandensein oder Fehlen von Dateien tatsaechlich im Repo nachsehen. In einer frueheren Session wurde ein fehlender Vault-Pfad als Rechteproblem gedeutet, obwohl die Datei einfach nicht existierte.
- Cloud-Session laeuft in einem Linux-Container, nicht auf dem Mac des Users: `/Users/maxim/...` ist dort grundsaetzlich nicht erreichbar. Das explizit sagen statt es als Zugriffsfehler zu melden.
- Index-Pflege nach jeder Inhaltsaenderung ist Pflicht, nicht Kuer (`*-Index.md` plus `wiki/index.md`).

## Session-Log

- 2026-10-10 — Geprueft, ob Agent OS integriert war: war es nicht (leerer Branch, keine Agenten, kein Protokoll). Anschliessend die repo-seitige Integration gebaut und committet.
- 2026-10-10 — Integration im Cloud-Resume verifiziert: Hook feuert, Agenten laden. Zugriff auf den Mac geprueft und ausgeschlossen (siehe "Offene Punkte").
- 2026-10-10 — Ebene voll ausgebaut: Commands, Guard-Hook, Stop-Gate, Pruefskript, Hook-Tests, CI. Drei eigene Entwurfsfehler dabei gefunden und behoben — zwei davon, weil die Hooks diese Session selbst blockiert haben (siehe "Entscheidungen").
