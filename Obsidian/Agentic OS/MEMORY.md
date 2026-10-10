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
- **„Agent OS" des Users ist ein fertiges Produkt**, nicht dieses Repo: ein Desktop-Paket unter `/Users/maxim/Projects/Maximus_OS`, Version 2026-10-10, bezogen aus dem „AI Profit Boardroom". Dashboard („Leitstand") auf `http://localhost:3737`, Start via `Start Agent OS.command` bzw. `start-maximus-os.sh`. Struktur: `install/` (nummerierte Anleitungen), `source/`, `runtime/`, `config.example.json`, `SETUP-WITH-AI.md`.
- **Agent OS hat einen eigenen Obsidian-Connector**: `install/11-MEMORY-OBSIDIAN.md` („Memory Galaxy", „Jarvis's memory"). Vorgesehener Weg laut dessen README: Terminal-Agenten IN jenem Ordner starten und sagen „connect my Obsidian vault to the Agent OS". Der User soll dabei keine Dateien selbst editieren.
- **Obsidian-Vault-ID des Arbeits-Vaults: `53213b4610731fc1`** (vom User genannt). Pfad aufloesbar ueber `~/Library/Application Support/obsidian/obsidian.json` (macOS). Damit ist geklaert, welcher Vault gemeint ist — auf `/Volumes/Daten_Bank/Obsidian/` liegen mehrere Vaults und Backups, die NICHT der Arbeits-Vault sind.
- Laufzeitdaten von Agent OS liegen in `~/.agentic-os/` — eigenes Verzeichnis pro Modul (`project-memory/`, `todos/`, `bots/`, `radar/`, `app-lab/`, `ultracode-runs/` u. a.). `~/.agentic-os/claude-projects/` enthaelt `claude-default/`, `ultracode-plan/`, `verbindungstest/` — alle drei leer.
- Offene `[[Wikilinks]]` sind in diesem Vault **keine Fehler**, sondern Themenvorschlaege fuer noch nicht existierende Seiten. `wiki/themen/Mannheim.md` haelt allein 36 davon.

## Aktueller Stand

Agent-OS-Ebene ist repo-seitig vollstaendig ausgebaut und in Cloud-Sessions nachweislich aktiv: SessionStart-Hook feuert, die fuenf Agenten laden. Dazu sieben Slash-Commands, drei Hooks (Gedaechtnis laden, Quellmaterial schuetzen, Pflicht-Updates erzwingen), `scripts/wiki_check.py` und dieselbe Pruefung in CI (`.github/workflows/wiki-check.yml`). Branch `claude/agent-os-integration-context-gobmre`.

Aktueller Pruefstand der Wissensbasis: 0 Fehler, 6 Warnungen, 40 offene Links (Stand 2026-10-10).

Im Leitstand von Agent OS ist diese Ebene **nicht sichtbar, und kann es auch nicht sein**: sie besteht aus Konfigurationsdateien, die Claude Code beim Start selbst liest. Nichts davon registriert sich bei Agent OS, meldet einen Heartbeat oder spricht dessen API. Konnektivitaet im Dashboard entsteht ueber Agent OS' eigenen Connector (`install/11-MEMORY-OBSIDIAN.md`), nicht hierueber.

Offen: diesen Connector laufen lassen. Erfordert einen Terminal-Agenten in `/Users/maxim/Projects/Maximus_OS` — aus einer Cloud-Session nicht erreichbar (`/Users/...` existiert dort nicht, `127.0.0.1:3737` ist die Loopback-Adresse des Containers).

## Entscheidungen

- 2026-10-10 — `scripts/agentic-os-bootstrap.sh` laeuft nur noch mit `--confirm` und verweist zuerst auf Agent OS' eigenen Connector. Sein Verzeichnis-Layout war geraten; unbesehen ausgefuehrt haette es Verzeichnisse angelegt, die Agent OS so vielleicht nicht erwartet.
- 2026-10-10 — Die hier gebaute Ebene bleibt bestehen, aber sie ist **nicht** der Anschluss an Agent OS. Sie regelt, wie Claude Code in diesem Repo arbeitet. Was Agent OS schon selbst macht (Memory Galaxy, Obsidian-Connector), soll nicht doppelt gefuehrt werden — vor dem Anschluss ist zu pruefen, welche Teile dann entfallen.
- 2026-10-10 — Gedaechtnis als versionierte Datei im Repo (`Obsidian/Agentic OS/MEMORY.md`) statt als lokaler Zustand — Cloud-Container sind ephemer, nur git ueberlebt den Session-Wechsel.
- 2026-10-10 — `Agentic OS/` liegt ausserhalb von `wiki/`, damit `mkdocs build` das Gedaechtnis nicht auf die oeffentliche Website stellt.
- 2026-10-10 — Agenten-Zuschnitt entlang der bestehenden Workflows aus `CLAUDE.md`/`AGENTS.md` (Ingest, Health, Index, Output) plus `memory-keeper`, statt generischer Rollen.
- 2026-10-10 — Der SessionStart-Hook laedt Kontext und bricht nie ab (`exit 0` in jedem Fall), damit ein Fehler im Hook keine Session blockiert. Dasselbe Prinzip gilt fuer alle drei Hooks: im Fehlerfall fallen sie offen aus.
- 2026-10-10 — Offene Wikilinks gelten als Warnung, nicht als Fehler. Ein erster Entwurf von `wiki_check.py` meldete 42 "tote Links" und haette CI dauerhaft rot gehalten, obwohl 40 davon normale Obsidian-Stubs sind.
- 2026-10-10 — Die Index-Pflicht im Stop-Hook greift nur bei strukturellen Aenderungen (anlegen, umbenennen, entfernen), nicht bei reinen Textaenderungen — so steht es in CLAUDE.md ("when adding/removing pages"). Der erste Entwurf war strenger als die Regel und hat sich selbst blockiert.

## Offene Punkte

- Lokales Bootstrap auf dem Mac des Users ist offen. Aus einer Cloud-Session nicht machbar: keine Computer-Use-/Remote-Device-Tools vorhanden, keine Remote-Control-Verbindung, keine Peer-Session auf seiner Maschine. Erfordert eine Session, die auf seinem Rechner laeuft (Claude Desktop oder `claude remote-control`).
- `Obsidian/raw/` existiert laut Dokumentation, ist im Repo aber nicht vorhanden — nur `Clippings/`, `Ideen/`, `Projekte/`. Ob `raw/` lokal existiert und nur nicht committet ist, ist ungeklaert.
- Ungeklaert, welche Teile der hier gebauten Ebene nach dem Anschluss ueberfluessig werden: Agent OS fuehrt mit `project-memory/` und der „Memory Galaxy" ein eigenes Gedaechtnis. Doppelte Quellen der Wahrheit sind zu vermeiden.
- `install/11-MEMORY-OBSIDIAN.md` aus Agent OS ist ungelesen — der Inhalt entscheidet, wie der Anschluss konkret aussieht.
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
- 2026-10-10 — Vault-ID `53213b4610731fc1` vom User erhalten; die Frage "welcher Vault" ist damit beantwortet.
- 2026-10-10 — Agent OS erstmals eingesehen (Verzeichnislisting und README vom User eingefuegt). Befund: eigenes Produkt mit eigenem Obsidian-Connector; die hier gebaute Ebene ist nicht der gesuchte Anschluss. Bootstrap daraufhin hinter `--confirm` gelegt.
- 2026-10-10 — Ebene voll ausgebaut: Commands, Guard-Hook, Stop-Gate, Pruefskript, Hook-Tests, CI. Drei eigene Entwurfsfehler dabei gefunden und behoben — zwei davon, weil die Hooks diese Session selbst blockiert haben (siehe "Entscheidungen").
