---
title: PaperclipAI
created: 2026-04-08
type: projekt
tags:
  - automatisierung
  - agenten
  - infrastruktur
---

# PaperclipAI

Open-Source-Orchestrierungsplattform für autonome KI-Agenten. Positioniert sich als System für "zero-human companies" — eine virtuelle Firma mit spezialisierten Agenten in Rollen wie CEO, CTO, Designer, Engineer etc.

## Setup

- **Version**: 2026.403.0
- **Server**: `http://127.0.0.1:3100` (loopback only)
- **Datenbank**: Embedded PostgreSQL (Port 54329)
- **Config**: `~/.paperclip/instances/default/config.json`
- **Logs**: `~/.paperclip/instances/default/logs`
- **Backups**: alle 60 Min, 30 Tage Retention

## Company: Maximus_OS

ID: `2ff8e79a-c0f8-4966-aaba-13b9ea06cc03`

### Agenten

| Name | Rolle | Status | Berichtet an |
|------|-------|--------|-------------|
| CEO | ceo | running | — |
| CTO | cto | running | CEO |
| Wiki-Kurator | researcher | running | CEO |
| Tom | researcher | running | CEO |
| UXDesigner | designer | idle | CEO |
| Archivarius | researcher | idle | CEO |
| CMO | cmo | idle | CEO |
| Staff Engineer | engineer | idle | CTO |
| QA Engineer | qa | idle | CTO |
| Release Engineer | devops | idle | CTO |

### Hierarchie

```
CEO
├── CTO
│   ├── Staff Engineer
│   ├── QA Engineer
│   └── Release Engineer
├── Wiki-Kurator
├── Tom
├── Archivarius
├── UXDesigner
└── CMO
```

## CLI-Befehle

```bash
paperclipai run                    # Server starten
paperclipai doctor                 # Diagnose
paperclipai agent list -C <id>     # Agenten auflisten
paperclipai company list           # Companies auflisten
paperclipai plugin install <pkg>   # Plugin installieren
paperclipai plugin list            # Plugins auflisten
paperclipai issue list             # Issues auflisten
paperclipai configure              # Konfiguration ändern
```

## Integration mit Obsidian

Agenten wie **Wiki-Kurator** und **Archivarius** können Recherche-Ergebnisse ins [[index|Wiki]] einspeisen. PaperclipAI-Issues können als Aufgaben in [[TODOS]] gespiegelt werden.

## Siehe auch

- [[Ollama]] — Lokales LLM-Backend (potentiell als LLM-Provider nutzbar)
- [[Gemme Training]] — Fine-Tuning für spezialisierte Agenten
