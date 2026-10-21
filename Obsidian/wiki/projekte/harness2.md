---
title: "Projekt: Harness² (Google Research)"
created: 2026-10-21
type: projekt
tags:
  - llm
  - agenten
  - harness
  - bewertung
aliases:
  - Harness²
  - Harness2
---

# Harness² (Google Research)

Open-Source-Framework für „recursive agent harnessing“, Repository: [google-research/harness2](https://github.com/google-research/harness2). Lizenz: Apache 2.0. Google bezeichnet es ausdrücklich als nicht offiziell unterstütztes Produkt.

## Was es tut

Harness² verbessert die **Umgebung um ein Sprachmodell**, also den Harness. Die **Modellgewichte bleiben fest**. Optimiert werden acht Bausteine: System-Prompt, Guardrails, Memory, Tool-Guidance, Subagents, Skills, Scripts und Plugins.

- **Task-Ebene (Propose–Probe–Compose):** Ein Editor schlägt Harness-Varianten vor. Die Varianten laufen auf derselben Aufgabe, und ein Composer verbindet die besten Verhaltensunterschiede. Die Budgets steuern `--k` und `--mode parallel|sequential`.
- **Harnessing-Ebene:** Ein „Experience Reflector“ sammelt bewährte Harnesses und belegte Lektionen für spätere Aufgaben.
- **Bewertung:** `harness2-judge` bewertet anhand von Rubriken, `harness2-report` erstellt den Bericht.

## Voraussetzungen

- Linux, Python 3.12 (uv), Node.js 20+, Google Cloud CLI
- Docker (für WorkBuddy-Bench), Pandoc und Poppler (für LAB)
- Modelle: standardmäßig Vertex AI (Gemini/Claude). Andere Modelle lassen sich nur über den Codex-Executor an einem Responses-API-Endpoint anbinden, zum Beispiel über LiteLLM. Ollama, vLLM und llama.cpp sind nicht dokumentiert.
- Codex läuft ohne Sandbox, und das Netzwerk des Executors ist unbeschränkt.
- Mitgeliefert werden nur die Benchmarks LAB, JobBench und WorkBuddy-Bench. Eine Schnittstelle für eigene Benchmarks ist nicht dokumentiert.

## Eignungsprüfung für Agent OS (2026-10-21)

**Ergebnis: für die Ausbildung nicht geeignet, daher nicht integriert.**

| Kriterium | Ausbildung im Agent OS | Harness² | Passt? |
|---|---|---|---|
| Was verbessert wird | LoRA-Adapter pro Rolle (Kopfdaten, Dokumenttyp, Frist/Aktion, Zusammenfassung) | nur Prompts, Skills und Tools; kein Training | nein |
| Bewertung | eigene Prüfsätze pro Rolle, Lehrer-Konsens (Claude + Codex), JEV/LAYA | Rubrik-Judge auf eigenen Benchmarks; keine Schnittstelle für eigene Benchmarks | nein |
| Modelle | lokal (4B über GPU-Broker, Ollama) | Vertex AI; lokal nur über Umweg (LiteLLM, Responses API) | eingeschränkt |
| Ressourcen RTX | RAM und Swap knapp (Swap-Schutz bricht Training ab) | Docker-Rollouts, K parallele Kandidaten | nein |
| Sicherheit | nur Loopback-Ports, abgeschottete Dienste | Codex ohne Sandbox, Executor-Netz offen | nein |
| Kosten | lokal | API-Kosten pro Kandidat und Judge | nein |

**Möglicher späterer Nutzen (Nutzungsvorhaben):** Die *Idee* passt auf das Agent OS im Betrieb, also Prompts und Skills der Agenten anhand ihrer Läufe verbessern, ohne neu zu trainieren. Ein Versuch lohnt sich erst, wenn alle drei Bedingungen erfüllt sind:
1. Es gibt einen eigenen Benchmark mit Aufgaben im Format `task.json` oder `task.toml`, dazu Rubriken.
2. Das lokale 4B ist über einen LiteLLM-Responses-Endpoint angebunden.
3. Der Lauf ist auf einem Rechner abgeschottet, der nicht trainiert, zum Beispiel ohne Netz für den Executor.

Bis dahin ist der eigene Lehrer-Loop für die Ausbildung das passendere Werkzeug.

## Verwandt

- [[Gemme Training]] — lokales Fine-Tuning (Gewichte statt Harness)
- [[PaperclipAI]] — Agenten-Orchestrierung
- [[Ollama Projekt|Ollama]]
