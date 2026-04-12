---
title: "Gemma 4"
created: 2026-04-08
type: thema
tags:
  - llm
  - google
  - open-weights
  - multimodal
---

# Gemma 4

> **Tom-Stack (Phase 38+):** OpenClaw/CCR nutzen **`qwen2.5:3b`**. Diese Seite beschreibt **Gemma 4**; für Toms Standard siehe Projekt-`CLAUDE.md` und `openclaw/README.md` im Repo **Claude**.

Gemma 4 ist Googles neueste Generation offener Sprachmodelle (2026), entwickelt fuer Frontier-Level-Performance in verschiedenen Groessen.

## Faehigkeiten

- **Reasoning** — fortgeschrittenes logisches Denken
- **Agentic Workflows** — Einsatz in autonomen Agenten-Pipelines
- **Coding** — Codegenerierung und -verstaendnis
- **Multimodal** — Vision, Audio, Thinking
- **Tool Use** — native Werkzeugnutzung

## Architektur und Groessen

| Variante | Effektive Params | Total Params | Layers | Architektur | Kontext |
|----------|-----------------|--------------|--------|-------------|---------|
| E2B | 2.3B | 5.1B (mit Embeddings) | 35 | Dense | 128K |
| E4B | 4.5B | 8B (mit Embeddings) | 42 | Dense | 128K |
| 26B | 3.8B aktiv | 25.2B total | 30 | **MoE** | 256K |
| 31B | 30.7B | 30.7B | 60 | Dense | 256K |

## Ollama-Varianten und Quantisierung

Alle Gemma-4-Modelle auf [[Ollama]] nutzen [[GGUF-Quantisierung]]:

| Tag | Groesse | Quant | Input |
|-----|---------|-------|-------|
| `gemma4:latest` (= e4b) | 9.6 GB | q4_K_M | Text, Bild |
| `gemma4:e2b` | 7.2 GB | q4_K_M | Text, Bild |
| `gemma4:e4b` | 9.6 GB | q4_K_M | Text, Bild |
| `gemma4:26b` | 18 GB | q4_K_M | Text, Bild |
| `gemma4:31b` | 20 GB | q4_K_M | Text, Bild |
| `gemma4:e2b-it-q8_0` | 8.1 GB | q8_0 | Text, Bild |
| `gemma4:e2b-it-bf16` | 10 GB | bf16 | Text, Bild |
| `gemma4:e4b-it-q8_0` | 12 GB | q8_0 | Text, Bild |
| `gemma4:e4b-it-bf16` | 16 GB | bf16 | Text, Bild |
| `gemma4:31b-it-q8_0` | 34 GB | q8_0 | Text, Bild |
| `gemma4:31b-it-bf16` | 63 GB | bf16 | Text, Bild |

**Empfehlung**: E4B (q4_K_M) fuer die meisten Laptops, 26B braucht 16GB+ VRAM, 31B braucht 20GB+.

## TurboQuant-Potenzial

[[TurboQuant]] wurde u.a. auf Gemma-Modellen getestet. Eine native Integration in [[Ollama]] ist noch offen (siehe [[TurboQuant#Integration mit Ollama]]). Mit TurboQuant turbo3 koennten die Kontextfenster bei gleichem VRAM ca. 5x vergroessert werden.

## Nutzung via Ollama

```bash
ollama run gemma4
```

## Integration mit Entwicklertools

Gemma 4 laesst sich ueber [[Ollama]] in verschiedene Coding-Assistenten einbinden:

- **Claude Code**: `ollama launch claude --model gemma4`
- **Codex**: `ollama launch codex --model gemma4`
- **OpenCode**: `ollama launch opencode --model gemma4`
- **OpenClaw (offiziell, Gemma)**: `ollama launch openclaw --model gemma4` — **Tom:** Live oft `qwen2.5:3b` in `~/.openclaw/openclaw.json`

## Quellen

- [[Quelle: Gemma 4 (Ollama)|Ollama Library]]
- [Google Blog: Gemma 4](https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/)
- [Google AI: Gemma + Ollama](https://ai.google.dev/gemma/docs/integrations/ollama)
