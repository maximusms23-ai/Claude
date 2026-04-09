---
title: "TurboQuant"
created: 2026-04-08
type: konzept
tags:
  - quantisierung
  - kv-cache
  - google-research
  - inferenz-optimierung
---

# TurboQuant

TurboQuant ist ein **KV-Cache-Quantisierungsalgorithmus** von Google Research, der den Key-Value-Cache waehrend der Inferenz auf bis zu 3 Bit komprimiert — ohne Genauigkeitsverlust und ohne Training oder Finetuning.

## Kernidee

TurboQuant ist keine Gewichts-Quantisierung (wie [[GGUF-Quantisierung|GGUF Q4_K_M]]), sondern komprimiert den **KV-Cache zur Laufzeit**. Das ermoeglicht laengere Kontextfenster bei gleichem VRAM.

## Komponenten

### PolarQuant
Konvertiert Vektoren von kartesischen in Polarkoordinaten fuer gleichmaessige Informationsdichte vor der Kompression. Eliminiert teure Normalisierung.

### QJL (Quantized Johnson-Lindenstrauss)
1-Bit-Fehlerkorrektur ueber zufaellige Projektionen. Korrigiert Inner-Product-Bias nach der Quantisierung mit null Overhead.

### Kombiniert
Walsh-Hadamard-Transform (WHT) Rotation + Lloyd-Max skalare Quantisierung.

## Varianten

| Variante | Bits/Wert | Kompression |
|----------|-----------|-------------|
| turbo3 | 3.25 | 4.9x |
| turbo4 | 4.25 | 3.8x |

## Performance

- **6x Reduktion** des KV-Cache-Speichers
- **8x Speedup** auf H100 (4-bit vs 32-bit)
- Ein 70B-Modell mit 34GB freiem VRAM: ~536K Tokens (turbo3) vs ~109K (FP16)

## Autoren

- Amir Zandieh (Research Scientist, Google)
- Vahab Mirrokni (VP & Google Fellow)
- Praneeth Kacham, Majid Hadian, Insu Han, Majid Daliri, Lars Gottesburen, Rajesh Jayaram

## Paper

- **TurboQuant**: [arxiv.org/abs/2504.19874](https://arxiv.org/abs/2504.19874) (ICLR 2026)
- **QJL**: [arxiv.org/abs/2406.03482](https://arxiv.org/abs/2406.03482) (AAAI 2025)
- **PolarQuant**: [arxiv.org/abs/2502.02617](https://arxiv.org/abs/2502.02617) (AISTATS 2026)

## Integration mit Ollama

Stand April 2026: **Noch nicht nativ unterstuetzt.**

- **Ollama Issue [#15051](https://github.com/ollama/ollama/issues/15051)**: 180 Thumbs-Up, 29 Kommentare, offen, keine Maintainer-Antwort
- **llama.cpp Discussion [#20969](https://github.com/ggml-org/llama.cpp/discussions/20969)**: Sehr aktiv (189 Reaktionen, 306+ Antworten). Unabhaengige Implementierungen fuer Metal, CUDA, CPU, Vulkan/ROCm existieren bereits
- **llama.cpp Issue [#20977](https://github.com/ggml-org/llama.cpp/issues/20977)**: Feature Request

### Community-Implementierungen

- [Lucien2468/Ollama-TurboQuant-Integration](https://github.com/Lucien2468/Ollama-TurboQuant-Integration) — Custom 3-bit asymmetrisches Format, 25-28% bessere Kompression als Q4_0
- [0xSero/turboquant](https://github.com/0xSero/turboquant) — Triton Kernels + vLLM-Integration
- [TheTom/turboquant_plus](https://github.com/TheTom/turboquant_plus)

### Wichtige Community-Erkenntnis

Moderne LLMs haben dramatische K-vs-V-Magnitudenunterschiede (bis zu 182x bei Qwen2.5-1.5B), was asymmetrische Bit-Allokation bevorzugt. WHT-Rotation erreicht 59x bessere PPL als zufaellige Rotation bei 4-bit.

Google hat **keinen offiziellen Code** veroeffentlicht — alle Implementierungen basieren auf der Mathematik aus dem Paper.

## Siehe auch

- [[Ollama]]
- [[GGUF-Quantisierung]]
- [[Gemma 4]]
