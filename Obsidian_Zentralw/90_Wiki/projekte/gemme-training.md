---
title: "Projekt: Gemme Training"
created: 2026-04-08
type: projekt
tags:
  - llm
  - training
  - local-ai
aliases:
  - Gemme Training
---

# Gemme Training

Projekt zur Erstellung von Trainingsdaten fuer ein eigenes LLM namens "Gemme", basierend auf den Inhalten dieser Wissensbasis.

## Ziel

Ein lokal lauffaehiges Sprachmodell trainieren, das die Struktur und das Wissen dieses Wikis verinnerlicht hat. Gemme soll als spezialisierter Assistent fuer die hier dokumentierten Themengebiete dienen.

## Trainingsdaten

Die Trainingsdaten werden aus folgenden Quellen zusammengestellt:

- **Wiki-Seiten** — Alle Artikel aus `wiki/` mit ihren Verlinkungen und Strukturen
- **Arbeitsanweisungen** — `CLAUDE.md` und `AGENTS.md` als Beispiel fuer gewuenschtes Verhalten
- **Vault-Regeln** — `Obsidian/CLAUDE.md` fuer domainspezifische Konventionen

Die gesammelten Daten liegen unter `Gemma/training-data/` im Repository-Root.

## Modellwahl

**Basismodell**: `gemma4:latest` (Gemma 4 8B, Q4_K_M-Quantisierung, ~9.6 GB auf Disk)

Das 26B-MoE-Modell (Gemma 4 A4B) wurde verworfen — es benoetigt ~15.6 GB allein fuer Gewichte, mit KV-Cache sprengt es die 16 GB unified memory des Mac Mini M4. Das 8B-Modell laeuft mit ~5 GB komfortabel.

## Technischer Ansatz

Lokale Inferenz ueber [[Ollama]] mit Modellen der [[Gemma-4-Modelle|Gemma-4-Familie]] als Basis. Fine-Tuning auf die gesammelten Wiki-Inhalte im [[GGUF-Quantisierung|GGUF-Format]].

## RAG-Pipeline

Gemme hat Zugriff auf die Wiki-Inhalte ueber eine RAG-Pipeline (Retrieval Augmented Generation):

- **Vektordatenbank**: ChromaDB (persistent, lokal)
- **Embedding-Modell**: `nomic-embed-text` (~274MB, via Ollama)
- **Chunking**: 500 Zeichen, 50 Overlap
- **Retrieval**: Top-5 aehnlichste Chunks als Kontext

Architektur: `Frage → Embedding → ChromaDB-Suche → Top-K Chunks → Gemme → Antwort`

## Projektverzeichnis

Alle Projektdaten sind konsolidiert unter `Gemma/`:

- `training-data/` — Gesammelte Trainingsdaten
- `modelfile/` — Ollama Modelfile fuer Custom-Modell "gemme"
- `eval/` — Evaluierungsdaten (geplant)
- `rag/` — RAG-Pipeline (Wiki-Zugriff via Vektordatenbank)

## Status

- [x] Trainingsdaten gesammelt (2026-04-08)
- [x] Modellwahl getroffen: gemma4 8B Q4_K_M (2026-04-08)
- [x] Projektverzeichnis `Gemma/` eingerichtet (2026-04-08)
- [x] Custom-Modell "gemme" via Ollama Modelfile angelegt (2026-04-08)
- [x] RAG-Pipeline aufgesetzt (2026-04-08)
- [ ] Fine-Tuning-Pipeline aufsetzen
- [ ] Erste Evaluierung
