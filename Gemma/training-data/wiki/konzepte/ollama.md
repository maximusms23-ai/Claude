---
title: "Ollama"
created: 2026-04-08
type: konzept
tags:
  - tooling
  - llm
  - local-inference
  - llama-cpp
---

# Ollama

Ollama ist ein Open-Source-Framework zum lokalen Ausfuehren von LLMs, aufgebaut auf [[llama.cpp]]. Es bietet CLI, REST API (localhost:11434, OpenAI-kompatibel) und Modellverwaltung.

## Kernfeatures

- Lokale Modelausfuehrung ohne Cloud
- REST API mit Streaming (OpenAI-kompatibel)
- Modelfile-Format fuer Custom-Konfigurationen
- Import von Safetensors und GGUF
- Quantisierung beim Import via `--quantize`

## Modellformat

Ollama nutzt **ausschliesslich [[GGUF-Quantisierung|GGUF]]** — kein GPTQ, AWQ oder EXL2.

## Plattformen

macOS, Windows, Linux, Docker. SDKs: Python, JavaScript (offiziell), plus Community-SDKs fuer Rust, Go, .NET, Java, Ruby, Swift u.a.

## Relevante Modelle

- [[Gemma 4]]

## Offene Entwicklungen

- [[TurboQuant]]-Integration: [Issue #15051](https://github.com/ollama/ollama/issues/15051) — stark nachgefragt, noch nicht umgesetzt

## Links

- https://ollama.com
- https://github.com/ollama/ollama
- https://docs.ollama.com

## Siehe auch

- [[GGUF-Quantisierung]]
- [[TurboQuant]]
