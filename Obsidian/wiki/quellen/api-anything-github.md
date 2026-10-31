---
title: API Anything – GitHub-Repository
created: 2026-10-31
type: quelle
tags:
  - quelle
  - repo
  - agenten
---

# API Anything – GitHub-Repository

| Feld | Wert |
|---|---|
| Typ | Repo |
| URL | <https://github.com/goodnight000/api-anything> |
| Autor | Tianjun Zheng (GitHub: goodnight000) |
| Lizenz | MIT |
| Stand | Commit `c58f5a6`, 2026-10-31; npm 0.3.1 |
| Gelesen | `README.md`, `INSTALL.md`, `skills/api-anything/SKILL.md`, `package.json` |

## Kernaussagen

- Agenten lernen fehlende Website-APIs aus den Requests des Frontends und teilen sie über einen gemeinsamen Katalog (Cloudflare Worker).
- Aufrufe laufen lokal (eigener Rechner, eigene Sessions); der Katalog speichert nur Specs und zählt Reports, er proxyt keine Requests.
- Zugriff per MCP-Server, CLI oder TypeScript-Bibliothek; zusätzlich ein Agent-Skill.
- 107 Lese-Operationen auf 55 Seiten mitgeliefert.
- Benchmark: Google-Flights-Aufgabe 1,5–2× schneller, ~halbe Tokens gegenüber Browser-Agent.

## Verarbeitet in

- [[api-anything|API Anything]] (Projekt)
- [[Website-als-API]] (Konzept)
