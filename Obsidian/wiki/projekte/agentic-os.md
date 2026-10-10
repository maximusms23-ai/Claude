---
title: Agentic OS
created: 2026-10-10
type: projekt
tags:
  - agenten
  - infrastruktur
  - automatisierung
  - claude-code
---

# Agentic OS

Agenten-Ebene dieses Repos: spezialisierte Claude-Code-Subagenten fuer die Pflege der Wissensbasis, plus ein versioniertes Projektgedaechtnis. Ziel ist, dass jede neue Session den Stand kennt, ohne ihn neu herauszufinden.

## Aufbau

```
Claude/
├── .claude/
│   ├── agents/                     # fuenf Agenten-Definitionen
│   ├── commands/                   # sieben Slash-Commands
│   ├── hooks/
│   │   ├── session-start-memory.sh # laedt das Gedaechtnis in den Kontext
│   │   ├── guard-readonly.py       # blockt Schreibzugriffe auf raw/ + Clippings/
│   │   └── stop-wiki-gate.py       # erzwingt die Pflicht-Updates am Sessionende
│   └── settings.json               # registriert Hooks und Permissions
├── scripts/
│   ├── wiki_check.py               # prueft die Wissensbasis maschinell
│   └── agentic-os-bootstrap.sh     # lokaler Arbeitsplatz auf dem Rechner
├── .github/workflows/
│   └── wiki-check.yml              # dieselbe Pruefung in CI
└── Obsidian/Agentic OS/
    ├── AI Memory Protocol.md       # Regelwerk fuer das Gedaechtnis
    └── MEMORY.md                   # das Gedaechtnis selbst
```

## Agenten

| Agent | Zweck |
|-------|-------|
| `wiki-ingest` | Quelle aus `raw/`/`Clippings/` vollstaendig einarbeiten, inkl. Index-Pflege |
| `wiki-health` | Tote Wikilinks, Duplikate, Orphans, Frontmatter, Index-Drift |
| `wiki-index` | Indexseiten und Statistiken mit dem Dateibestand abgleichen |
| `output-builder` | Marp-Slides, matplotlib-Plots, Reports, JSON-Canvas nach `output/` |
| `memory-keeper` | Projektgedaechtnis nach dem AI Memory Protocol pflegen |

Die Zuschnitte folgen den Workflows aus `CLAUDE.md` und `AGENTS.md` — sie ersetzen diese Regeln nicht, sondern fuehren sie aus.

## Slash-Commands

| Command | Wirkung |
|---------|---------|
| `/ingest <quelle>` | Quelle einarbeiten (`wiki-ingest`); ohne Argument: nicht erfasste Quellen auflisten |
| `/health` | Pruefskript plus `wiki-health` fuer das, was ein Skript nicht sieht |
| `/sync` | Indizes und Statistiken abgleichen (`wiki-index`) |
| `/output <art> <thema>` | Deliverable bauen (`output-builder`) |
| `/memory` | Gedaechtnis pflegen (`memory-keeper`) |
| `/check` | nur `scripts/wiki_check.py`, schnell, ohne Agent |
| `/anstehend` | `TODOS.md` und `PROJEKTE.md` lesen |

## Erzwungene Regeln

Drei Regeln des Repos sind nicht mehr nur dokumentiert, sondern werden von Hooks durchgesetzt:

1. **Quellmaterial ist read-only.** `guard-readonly.py` blockt als PreToolUse-Hook jeden Schreibzugriff auf `Obsidian/raw/` und `Obsidian/Clippings/` — `Write`, `Edit`, `NotebookEdit` und mutierende Bash-Kommandos (`rm`, `mv`, `sed -i`, Umleitungen). Lesen bleibt frei.
2. **Pflicht-Updates sind Pflicht.** `stop-wiki-gate.py` laesst eine Session nicht beenden, solange eine Inhaltsaenderung nicht in `wiki/index.md` steht — und, wenn eine Seite angelegt, umbenannt oder entfernt wurde, auch nicht im zugehoerigen `*-Index.md`. Eine bloss im Text geaenderte Seite braucht keinen neuen Index-Eintrag, nur die Zeile im Aenderungsprotokoll. Zusaetzlich blockt der Hook, wenn `wiki_check.py` einen Fehler meldet. Ein Loopschutz (`stop_hook_active`) verhindert, dass er sich selbst einsperrt.
3. **Gedaechtnis wird gelesen.** `session-start-memory.sh` laedt `MEMORY.md` beim Sessionstart in den Kontext.

Alle drei fallen im Fehlerfall offen aus — ein defekter Hook blockiert die Arbeit nicht.

## Pruefskript

`scripts/wiki_check.py` rechnet die Regeln nach, ohne externe Abhaengigkeiten (kein PyYAML):

```bash
python3 scripts/wiki_check.py                 # Bericht, Exit 1 bei Fehlern
python3 scripts/wiki_check.py --warnings-ok   # Exit 0 solange nur Warnungen
```

- **Fehler** (brechen): fehlendes oder kaputtes Frontmatter bei nicht-leeren Seiten
- **Warnungen**: offene Wikilinks, Index-Drift, falsche Statistik, leere Seiten

Offene `[[Links]]` sind bewusst keine Fehler: in Obsidian markieren sie Seiten, die es noch nicht gibt, und sind damit Themenvorschlaege. `wiki/themen/Mannheim.md` haelt allein 36 davon.

`.github/workflows/wiki-check.yml` fuehrt dieselbe Pruefung in CI aus, plus einen probeweisen MkDocs-Build, damit der Pages-Deploy nicht erst auf `main` scheitert.

## Gedaechtnis

Das Gedaechtnis liegt als Markdown-Datei **in git**, nicht als Zustand auf einer Maschine. Grund: Cloud-Sessions laufen in Wegwerf-Containern, die beim Start frisch klonen und nach Inaktivitaet eingezogen werden — nur was committet ist, ueberlebt den Session-Wechsel.

Regeln (Aufnahmekriterien, Groessengrenzen, Verbote) stehen im AI Memory Protocol unter `Obsidian/Agentic OS/`. Der Ordner liegt bewusst ausserhalb von `wiki/`, weil MkDocs mit `docs_dir: wiki` baut — das Gedaechtnis erscheint damit nicht auf der oeffentlichen Website.

## Lokaler Arbeitsplatz

```bash
./scripts/agentic-os-bootstrap.sh            # Projekt "claude-default"
./scripts/agentic-os-bootstrap.sh mein-name  # eigener Projektname
```

Legt `~/.agentic-os/claude-projects/<projekt>/` an und verlinkt Repo, Vault und `MEMORY.md` dorthin. Erzeugt nur Symlinks, keine Kopien — damit es keine zweite Wahrheit gibt. Mehrfaches Ausfuehren ist unschaedlich.

## Verhaeltnis zu Agent OS (Maximus_OS)

Nicht zu verwechseln: **Agent OS** ist ein fertiges Desktop-Produkt des Users unter `/Users/maxim/Projects/Maximus_OS` mit einem Dashboard auf `http://localhost:3737`. Es bringt einen eigenen Obsidian-Connector mit (`install/11-MEMORY-OBSIDIAN.md`, „Memory Galaxy") und legt seine Laufzeitdaten in `~/.agentic-os/` ab.

Die hier beschriebene Ebene ist **nicht** der Anschluss daran. Sie regelt, wie Claude Code in diesem Repo arbeitet, und erscheint in jenem Dashboard nicht — sie besteht aus Konfigurationsdateien, die beim Sessionstart gelesen werden, und registriert sich nirgends. Soll der Vault im Leitstand auftauchen, laeuft das ueber Agent OS' eigenen Connector.

`scripts/agentic-os-bootstrap.sh` verlangt deshalb `--confirm`: sein Verzeichnis-Layout unter `~/.agentic-os/claude-projects/<projekt>/` ist geraten und nicht gegen Agent OS verifiziert.

## Abgrenzung zu PaperclipAI

[[PaperclipAI]] ist eine externe Orchestrierungsplattform mit eigenem Server und eigener Agenten-Hierarchie. Agentic OS ist repo-intern und braucht keinen laufenden Dienst: es sind Dateien unter `.claude/`, die Claude Code beim Start einliest. Beide koennen ins selbe Wiki schreiben.

## Siehe auch

- [[PaperclipAI]] — externe Agenten-Orchestrierung
- [[index|Wiki-Index]] — Einstieg in die Wissensbasis
