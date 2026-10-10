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
- Agent-OS-Ebene liegt in `.claude/` (Agenten, Hook, Settings) und `Obsidian/Agentic OS/` (Protokoll, Gedaechtnis).

## Aktueller Stand

Agent-OS-Integration ist repo-seitig vollstaendig und in Cloud-Sessions **nachweislich aktiv**: beim Resume dieser Session hat der SessionStart-Hook gefeuert und `MEMORY.md` in den Kontext geladen, die fuenf Agenten aus `.claude/agents/` stehen als Agent-Typen bereit. Branch `claude/agent-os-integration-context-gobmre`, Commit 52940ea.

Nicht erledigt: das lokale Setup unter `~/.agentic-os/claude-projects/` auf dem Mac des Users. Dafuer liegt `scripts/agentic-os-bootstrap.sh` bereit, das der User selbst ausfuehren muss — aus einem Cloud-Container ist dieser Pfad nicht erreichbar.

## Entscheidungen

- 2026-10-10 — Gedaechtnis als versionierte Datei im Repo (`Obsidian/Agentic OS/MEMORY.md`) statt als lokaler Zustand — Cloud-Container sind ephemer, nur git ueberlebt den Session-Wechsel.
- 2026-10-10 — `Agentic OS/` liegt ausserhalb von `wiki/`, damit `mkdocs build` das Gedaechtnis nicht auf die oeffentliche Website stellt.
- 2026-10-10 — Agenten-Zuschnitt entlang der bestehenden Workflows aus `CLAUDE.md`/`AGENTS.md` (Ingest, Health, Index, Output) plus `memory-keeper`, statt generischer Rollen.
- 2026-10-10 — Der SessionStart-Hook laedt Kontext und bricht nie ab (`exit 0` in jedem Fall), damit ein Fehler im Hook keine Session blockiert.

## Offene Punkte

- Lokales Bootstrap auf dem Mac des Users ist offen. Aus einer Cloud-Session nicht machbar: keine Computer-Use-/Remote-Device-Tools vorhanden, keine Remote-Control-Verbindung, keine Peer-Session auf seiner Maschine. Erfordert eine Session, die auf seinem Rechner laeuft (Claude Desktop oder `claude remote-control`).
- `Obsidian/raw/` existiert laut Dokumentation, ist im Repo aber nicht vorhanden — nur `Clippings/`, `Ideen/`, `Projekte/`. Ob `raw/` lokal existiert und nur nicht committet ist, ist ungeklaert.
- Slash-Commands unter `.claude/commands/` sind nicht angelegt; die Agenten werden bis dahin per Name aufgerufen.
- `Obsidian/wiki/Unbenannt.base` und `Obsidian/Unbenannt.canvas` sind unbenannte Platzhalter ohne Inhalt — Zweck unklar.

## Gelernte Konventionen

- Der User fragt auf Deutsch und erwartet Antworten auf Deutsch.
- Vor Aussagen ueber Vorhandensein oder Fehlen von Dateien tatsaechlich im Repo nachsehen. In einer frueheren Session wurde ein fehlender Vault-Pfad als Rechteproblem gedeutet, obwohl die Datei einfach nicht existierte.
- Cloud-Session laeuft in einem Linux-Container, nicht auf dem Mac des Users: `/Users/maxim/...` ist dort grundsaetzlich nicht erreichbar. Das explizit sagen statt es als Zugriffsfehler zu melden.
- Index-Pflege nach jeder Inhaltsaenderung ist Pflicht, nicht Kuer (`*-Index.md` plus `wiki/index.md`).

## Session-Log

- 2026-10-10 — Geprueft, ob Agent OS integriert war: war es nicht (leerer Branch, keine Agenten, kein Protokoll). Anschliessend die repo-seitige Integration gebaut und committet.
- 2026-10-10 — Integration im Cloud-Resume verifiziert: Hook feuert, Agenten laden. Zugriff auf den Mac geprueft und ausgeschlossen (siehe "Offene Punkte").
