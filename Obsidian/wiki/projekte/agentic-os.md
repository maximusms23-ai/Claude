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
│   ├── agents/                     # Agenten-Definitionen
│   ├── hooks/
│   │   └── session-start-memory.sh # laedt das Gedaechtnis in den Kontext
│   └── settings.json               # registriert den SessionStart-Hook
├── scripts/
│   └── agentic-os-bootstrap.sh     # lokaler Arbeitsplatz auf dem Rechner
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

## Gedaechtnis

Das Gedaechtnis liegt als Markdown-Datei **in git**, nicht als Zustand auf einer Maschine. Grund: Cloud-Sessions laufen in Wegwerf-Containern, die beim Start frisch klonen und nach Inaktivitaet eingezogen werden — nur was committet ist, ueberlebt den Session-Wechsel.

Regeln (Aufnahmekriterien, Groessengrenzen, Verbote) stehen im AI Memory Protocol unter `Obsidian/Agentic OS/`. Der Ordner liegt bewusst ausserhalb von `wiki/`, weil MkDocs mit `docs_dir: wiki` baut — das Gedaechtnis erscheint damit nicht auf der oeffentlichen Website.

## Lokaler Arbeitsplatz

```bash
./scripts/agentic-os-bootstrap.sh            # Projekt "claude-default"
./scripts/agentic-os-bootstrap.sh mein-name  # eigener Projektname
```

Legt `~/.agentic-os/claude-projects/<projekt>/` an und verlinkt Repo, Vault und `MEMORY.md` dorthin. Erzeugt nur Symlinks, keine Kopien — damit es keine zweite Wahrheit gibt. Mehrfaches Ausfuehren ist unschaedlich.

## Abgrenzung zu PaperclipAI

[[PaperclipAI]] ist eine externe Orchestrierungsplattform mit eigenem Server und eigener Agenten-Hierarchie. Agentic OS ist repo-intern und braucht keinen laufenden Dienst: es sind Dateien unter `.claude/`, die Claude Code beim Start einliest. Beide koennen ins selbe Wiki schreiben.

## Siehe auch

- [[PaperclipAI]] — externe Agenten-Orchestrierung
- [[index|Wiki-Index]] — Einstieg in die Wissensbasis
