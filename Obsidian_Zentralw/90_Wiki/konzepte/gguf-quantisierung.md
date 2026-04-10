---
title: "GGUF-Quantisierung"
created: 2026-04-08
type: konzept
tags:
  - quantisierung
  - llama-cpp
  - gguf
---

# GGUF-Quantisierung

GGUF ist das **exklusive Modellformat** von [[Ollama]] und [[llama.cpp]]. Im Gegensatz zu [[TurboQuant]] (KV-Cache) komprimiert GGUF die **Modellgewichte** selbst.

## Unterstuetzte Quantisierungstypen

| Typ | Bits | Anmerkungen |
|-----|------|-------------|
| Q2_K | 2 | Extreme Kompression, sehr geringe Qualitaet |
| Q3_K_S/M/L | 3 | Aggressiv, drei Varianten (Small/Medium/Large) |
| Q4_K_S | 4 | Kleinere Variante |
| **Q4_K_M** | **4** | **Standard fuer die meisten Ollama-Modelle** |
| Q5_K_S | 5 | Kleinere Variante |
| Q5_K_M | 5 | "Sweet Spot" — nahe an unkomprimierter Qualitaet |
| Q6_K | 6 | Sehr geringer Verlust vs FP16 |
| Q8_0 | 8 | Nahe FP16-Genauigkeit, groesste quantisierte Groesse |

Alle verwenden K-Means-Quantisierung aus llama.cpp. Die "K"-Varianten wenden unterschiedliche Quantisierungsstufen auf verschiedene Tensor-Typen an.

## Abgrenzung zu anderen Formaten

| Format | Engine | GPU-fokussiert |
|--------|--------|----------------|
| **GGUF** | Ollama, llama.cpp | Nein (CPU+GPU) |
| GPTQ | vLLM, text-gen-webui | Ja |
| AWQ | vLLM | Ja |
| EXL2 | ExLlamaV2 | Ja |

Ollama unterstuetzt **ausschliesslich GGUF** — kein GPTQ, AWQ oder EXL2.

## Nutzung in Ollama

```bash
ollama create mymodel --quantize q4_K_M -f Modelfile
```

## Siehe auch

- [[Ollama]]
- [[TurboQuant]]
- [[Gemma 4]]
