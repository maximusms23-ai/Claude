---
title: "Agenten-OS"
created: 2026-10-27
type: konzept
aliases:
  - Agent OS
  - Agentic OS
  - LLM OS
tags:
  - agenten
  - llm
  - architektur
  - orchestrierung
---

# Agenten-OS

Ein **Agenten-OS** (Agent Operating System) ist die Software-Schicht, die mehrere KI-Agenten so verwaltet, wie ein klassisches Betriebssystem Programme verwaltet: Es startet und weckt sie, teilt ihnen Arbeit, Gedächtnis, Werkzeuge und Budget zu, regelt was sie dürfen und lässt sie miteinander reden.

Ohne Agenten-OS ist jeder Agent ein einzelnes Chatfenster, das bei jedem Start bei null anfängt. Mit Agenten-OS werden daraus dauerhafte „Mitarbeiter“ mit Rolle, Gedächtnis und Zuständigkeit.

## Die Betriebssystem-Analogie

| Klassisches OS | Agenten-OS | Beispiel in [[PaperclipAI]] |
|---|---|---|
| CPU | LLM (das „Denken“) | Claude, GPT, lokal über [[Ollama]] |
| Prozess | Agent mit Rolle und Ziel | CEO, CTO, Wiki-Kurator |
| Scheduler | Wer arbeitet wann? (Heartbeats, Trigger, Warteschlangen) | Agenten-Status `running` / `idle` |
| Arbeitsspeicher (RAM) | Kontextfenster, aktueller Gesprächsstand | — |
| Festplatte | Langzeitgedächtnis (Dateien, Datenbank, Vektor-Suche) | Embedded PostgreSQL, dieses [[index|Wiki]] |
| Treiber / Peripherie | Werkzeuge (Tools, APIs, MCP-Server, Browser, Shell) | Plugins |
| Benutzerrechte | Berechtigungen, Freigaben, Sandbox | Freigabe durch den Menschen |
| Ressourcenlimits | Token- und Kosten-Budget pro Agent | Budget pro Agent |
| Interprozess-Kommunikation | Nachrichten, Tickets, Übergaben zwischen Agenten | Issues, Berichtslinien |
| Dateisystem-Hierarchie | Organigramm: wer berichtet an wen | CEO → CTO → Engineers |

Die Analogie geht auf Andrej Karpathys Idee des „LLM OS“ zurück (das LLM als Kern eines neuen Betriebssystems); Forschungsprojekte wie *AIOS* bauen sie wörtlich als Kernel für Agenten nach.

## Die fünf Aufgaben eines Agenten-OS

1. **Planen & Wecken (Scheduling)** — Agenten laufen nicht dauernd. Das OS weckt sie per Zeitplan, Ereignis oder Auftrag und legt sie danach wieder schlafen.
2. **Gedächtnis verwalten** — Ins Kontextfenster passt wenig. Das OS entscheidet, was ein Agent gerade sehen muss, und lagert den Rest ins Langzeitgedächtnis aus.
3. **Werkzeuge vermitteln** — Agenten bekommen Zugriff auf Tools (Dateien, Web, E-Mail, Code) über eine einheitliche Schnittstelle, z. B. MCP.
4. **Rechte & Budget durchsetzen** — Wer darf was? Wie viel darf ein Agent ausgeben? Wo muss ein Mensch freigeben?
5. **Zusammenarbeit organisieren** — Aufgaben werden als Tickets weitergereicht, Ergebnisse nach oben berichtet; Rollen verhindern, dass alle alles tun.

## Beispiel: Maximus_OS

Die Company **Maximus_OS** in [[PaperclipAI]] ist ein konkretes Agenten-OS: ein CEO-Agent verteilt Arbeit, der CTO führt Staff-, QA- und Release-Engineer, Rechercheure wie der Wiki-Kurator und Archivarius schreiben Ergebnisse in dieses Wiki. Issues sind die „Nachrichten“ zwischen den Prozessen, `running` / `idle` der Scheduler-Zustand.

## Typische Probleme

- **Kontext-Verlust** — Agent vergisst, was vorher passiert ist, wenn das Gedächtnis schlecht verwaltet wird.
- **Endlosschleifen & Kostenexplosion** — ohne Budget-Limits.
- **Zu viele Rechte** — ein Agent mit Shell- und Mail-Zugriff ohne Freigabe ist ein Sicherheitsrisiko.
- **Rollen-Chaos** — mehrere Agenten bearbeiten dieselbe Aufgabe oder schieben sie sich gegenseitig zu.

## Illustrationen

Shot-List und Bild-Prompts im Xiaohei-Stil: `output/illustrations/agenten-os/prompts.md` (erstellt mit dem Skill `/007`).

## Siehe auch

- [[PaperclipAI]] — Orchestrierungsplattform, auf der Maximus_OS läuft
- [[Ollama]] — lokales LLM als „CPU“ eines Agenten-OS
- [[Gemme Training]] — Fine-Tuning für spezialisierte Agenten
