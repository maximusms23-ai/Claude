---
title: Gemma 4-Modelle
created: 2026-04-08
type: thema
tags:
  - ki-modelle
  - llm
  - multimodal
  - open-weights
---

# Gemma 4-Modelle

**Gemma 4** ist eine offene Modellfamilie von Google fuer generative KI mit Fokus auf effiziente Bereitstellung, multimodale Eingaben und lange Kontextfenster.

## Ueberblick

- Offene Gewichte fuer Forschung und kommerzielle Nutzung
- Unterstuetzung fuer Text sowie je nach Modell auch Bild, Audio und Video
- Kontextfenster bis zu 256.000 Tokens
- Varianten fuer Edge-, Browser- und Server-Szenarien

## Modellvarianten

Die Familie wird in mehreren Groessen und Architekturen bereitgestellt:

- **E2B / E4B**: Effiziente kleinere Varianten fuer ressourcennahe Deployments
- **31B**: Dichtes groesseres Modell fuer hohe Qualitaet
- **26B A4B**: Mixture-of-Experts-Variante fuer hohen Durchsatz bei komplexen Aufgaben

## Technische Eckpunkte

| Modell | BF16 | 8 Bit | 4 Bit |
|---|---|---|---|
| Gemma 4 E2B | 9,6 GB | 4,6 GB | 3,2 GB |
| Gemma 4 E4B | 15 GB | 7,5 GB | 5 GB |
| Gemma 4 31B | 58,3 GB | 30,4 GB | 17,4 GB |
| Gemma 4 26B A4B | 48 GB | 25 GB | 15,6 GB |

> Die Werte beschreiben den ungefaehren Speicherbedarf fuer statische Modellgewichte; laufzeitabhaengige Kosten (z.B. KV-Cache) kommen zusaetzlich hinzu.

## Einsatzhinweise

- Modellwahl basiert auf Trade-off zwischen Qualitaet, Latenz, Kosten und verfuegbarer Hardware
- Quantisierung reduziert Speicherbedarf, kann aber Qualitaetseinbussen verursachen
- Fuer produktive Systeme ist eine gezielte Evaluation pro Use Case notwendig

## Quellen

- [[Gemma-4-Google-AI-Docs|Gemma 4-Modelle - Google AI Docs (Quellenregister)]]
