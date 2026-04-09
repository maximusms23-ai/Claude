---
title: "Gemma 4-Modelle – Übersicht"
source: "https://ai.google.dev/gemma/docs/core?hl=de"
author:
published:
created: 2026-04-08
description:
tags:
  - "clippings"
---
**Gemma 4** wurde veröffentlicht und unterstützt Text-, Audio- und Bildeingaben sowie ein langes Kontextfenster mit bis zu 256.000 Tokens. [**Weitere Informationen**](https://ai.google.dev/gemma/docs/core?hl=de)

![](https://www.youtube.com/watch?v=jZVBoFOJK-Q)

Gemma ist eine Familie generativer Modelle für künstliche Intelligenz, die für eine Vielzahl von Generierungsaufgaben verwendet werden können, darunter Fragenbeantwortung, Zusammenfassung und Schlussfolgern. Gemma-Modelle werden mit offenen Gewichten bereitgestellt und ermöglichen eine verantwortungsvolle [kommerzielle Nutzung](https://ai.google.dev/gemma/terms?hl=de), so dass Sie sie in Ihren eigenen Projekten und Anwendungen abstimmen und bereitstellen können.

Die Gemma 4-Modellfamilie umfasst drei verschiedene Architekturen, die auf bestimmte Hardwareanforderungen zugeschnitten sind:

- **Kleine Größen**:2B- und 4B-Modelle mit effektiven Parametern, die für die Bereitstellung auf mobilen Geräten, am Edge und im Browser entwickelt wurden (z.B. Pixel, Chrome).
- **Dicht**:Ein leistungsstarkes dichtes Modell mit 31 Milliarden Parametern, das die Lücke zwischen Serverleistung und lokaler Ausführung schließt.
- **Mixture-of-Experts:**:Ein hocheffizientes MoE-Modell mit 26 Milliarden Parametern, das für hohen Durchsatz und komplexes Schlussfolgern entwickelt wurde.

Sie können Gemma 4-Modelle von [Kaggle](https://www.kaggle.com/models?query=gemma-4&publisher=google) und [Hugging Face](https://huggingface.co/collections/google/gemma-4) herunterladen. Weitere technische Details zu Gemma 4 finden Sie auf der [Modellkarte](https://ai.google.dev/gemma/docs/core/model_card_4?hl=de). Ältere Versionen der Gemma-Kernmodelle sind ebenfalls zum Download verfügbar. Weitere Informationen finden Sie unter [Frühere Gemma-Modelle](#previous-models).

[Auf Kaggle herunterladen](https://www.kaggle.com/models?query=gemma-4&publisher=google) [Auf Hugging Face herunterladen](https://huggingface.co/collections/google/gemma-4)

## Leistungsspektrum

- **Schlussfolgern:** Alle Modelle der Familie sind als hochleistungsfähige Schlussfolgerer mit konfigurierbaren [Denk modi](https://ai.google.dev/gemma/docs/capabilities/thinking?hl=de).
- **Erweiterte Multimodalität:** Verarbeitet Text, [Bilder](https://ai.google.dev/gemma/docs/capabilities/vision/image?hl=de) mit variabler Seitenverhältnis- und Auflösungsunterstützung (alle Modelle), [Videos](https://ai.google.dev/gemma/docs/capabilities/vision/video?hl=de) und [Audio](https://ai.google.dev/gemma/docs/capabilities/audio?hl=de) (nativ in den Modellen E2B und E4B enthalten).
- **Größeres Kontextfenster**:Kleine Modelle haben ein Kontextfenster mit 128.000 Tokens, während die mittleren Modelle 256.000 Tokens unterstützen.
- **Verbesserte Codierungs- und Agentenfunktionen:** Erreicht deutliche Verbesserungen bei Codierungs-Benchmarks und bietet integrierte [Unterstützung für Funktionsaufrufe](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4?hl=de), wodurch hochleistungsfähige autonome Agenten möglich werden.
- **Native Unterstützung für System-Prompts**:Gemma 4 bietet integrierte Unterstützung für die Systemrolle, wodurch strukturiertere und besser kontrollierbare Unterhaltungen möglich werden.

## Parametergrößen und Quantisierung

Gemma 4-Modelle sind in vier Parametergrößen verfügbar: E2B, E4B, 31B und 26B A4B. Die Modelle können mit ihrer Standardgenauigkeit (16 Bit) oder mit einer geringeren Genauigkeit mithilfe der Quantisierung verwendet werden. Die verschiedenen Größen und Genauigkeiten stellen eine Reihe von Kompromissen für Ihre KI-Anwendung dar. Modelle mit mehr Parametern und Bits (höhere Genauigkeit) sind in der Regel leistungsfähiger, aber teurer in Bezug auf Verarbeitungszyklen, Speicherkosten und Stromverbrauch. Modelle mit weniger Parametern und Bits (geringere Genauigkeit) haben weniger Funktionen, sind aber möglicherweise für Ihre KI-Aufgabe ausreichend.

### Speicheranforderungen für die Inferenz mit Gemma 4

In der folgenden Tabelle sind die ungefähren GPU- oder TPU-Speicheranforderungen für die Ausführung der Inferenz mit den verschiedenen Größen der Gemma 4-Modellversionen aufgeführt.

| Parameter | BF16 (16 Bit) | SFP8 (8 Bit) | Q4\_0 (4 Bit) |
| --- | --- | --- | --- |
| Gemma 4 E2B | 9,6 GB | 4,6 GB | 3,2 GB |
| Gemma 4 E4B | 15 GB | 7,5 GB | 5 GB |
| Gemma 4 31B | 58,3 GB | 30,4 GB | 17,4 GB |
| Gemma 4 26B A4B | 48 GB | 25 GB | 15,6 GB |

**Tabelle 1.** Ungefährer GPU- oder TPU-Speicher, der zum Laden von Gemma 4-Modellen erforderlich ist, basierend auf der Anzahl der Parameter und der Quantisierungsstufe.

### Wichtige Überlegungen für die Speicherplanung

- **Effiziente Architektur (E2B und E4B)**: Das „E“ steht für „effektive“ Parameter. Die kleineren Modelle enthalten Einbettungen pro Ebene (Per-Layer Embeddings, PLE), um die Parametereffizienz bei der Bereitstellung auf Geräten zu maximieren. Anstatt dem Modell weitere Ebenen hinzuzufügen, bietet PLE jeder Decoderebene eine eigene kleine Einbettung für jedes Token. Diese Einbettungstabellen sind groß, werden aber nur für schnelle Suchvorgänge verwendet. Daher ist der für das Laden statischer Gewichte erforderliche Gesamtspeicher höher als die effektive Anzahl der Parameter.
- **MoE-Architektur (26B A4B)**: Das 26B-Modell ist ein Mixture of Experts-Modell. Obwohl während der Generierung nur 4 Milliarden Parameter pro Token aktiviert werden, müssen **alle 26 Milliarden Parameter** in den Speicher geladen werden, um schnelle Routing- und Inferenzgeschwindigkeiten zu gewährleisten. Daher liegt der Speicherbedarf im Basismodus viel näher an dem eines dichten 26B-Modells als an dem eines 4B-Modells.
- **Nur Basisgewichte**:Die Schätzungen in der vorherigen Tabelle berücksichtigen *nur* den Speicher, der zum Laden der statischen Modellgewichte erforderlich ist. Der zusätzliche VRAM, der für unterstützende Software oder das Kontextfenster benötigt wird, ist nicht enthalten.
- **Kontextfenster (KV-Cache)**: Der Speicherverbrauch steigt dynamisch in Abhängigkeit von der Gesamtzahl der Tokens in Ihrem Prompt und der generierten Antwort. Größere Kontextfenster erfordern zusätzlich zu den Basismodellgewichten deutlich mehr VRAM.
- **Overhead für die Feinabstimmung**:Die Speicheranforderungen für die *Feinabstimmung* von Gemma-Modellen sind deutlich höher als für die Standardinferenz. Der genaue Speicherbedarf hängt stark vom Entwicklungsframework, der Batchgröße und davon ab, ob Sie eine Feinabstimmung mit voller Genauigkeit oder eine Methode für die parameter-effiziente Feinabstimmung (Parameter-Efficient Fine-Tuning, PEFT) wie Low-Rank Adaptation (LoRA) verwenden.

## Frühere Gemma-Modelle

Sie können auch mit früheren Generationen von Gemma-Modellen arbeiten, die ebenfalls auf [Kaggle](https://www.kaggle.com/models?query=gemma) und [Hugging Face](https://huggingface.co/google/collections) verfügbar sind. Weitere technische Details zu früheren Gemma-Modellen finden Sie auf den folgenden Modellkartenseiten:

- Gemma 3 [Modellkarte](https://ai.google.dev/gemma/docs/core/model_card_3?hl=de)
- Gemma 2 [Modellkarte](https://ai.google.dev/gemma/docs/core/model_card_2?hl=de)
- Gemma 1 [Modellkarte](https://ai.google.dev/gemma/docs/core/model_card?hl=de)

Sind Sie bereit? [Erste Schritte](https://ai.google.dev/gemma/docs/get_started?hl=de) mit Gemma-Modellen