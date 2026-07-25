# Training Data Pipeline

Sammelt strukturierte Trainingsdaten fuer spaeteres Fine-Tuning (Unsloth/QLoRA).

## Datenformate

### qa_pairs.jsonl (Self-Instruct)

Generiert via `collector.py` aus Wiki-Inhalten:

```json
{"instruction": "Was ist GGUF?", "input": "", "output": "GGUF ist ein Format fuer...", "source": "wiki/konzepte/gguf.md", "created": "2026-04-09"}
```

Kompatibel mit Alpaca/ShareGPT-Format fuer Unsloth.

### interactions.jsonl (RAG-Logs)

Automatisch geloggte RAG-Interaktionen:

```json
{"query": "...", "response": "...", "sources": [...], "timestamp": "...", "rating": null}
```

Das `rating`-Feld kann spaeter manuell befuellt werden (1-5) um hochwertige Paare zu selektieren.

## Nutzung

```bash
# Q&A-Paare generieren (3 Dateien als Test)
python3 collector.py --limit 3

# Alle Wiki-Seiten verarbeiten
python3 collector.py

# Interactions werden automatisch bei RAG-Queries geloggt
```

## Phase 2 (geplant, 3-6 Monate)

- Unsloth + QLoRA Fine-Tuning mit gesammelten Daten
- Datenqualitaet-Filter basierend auf Ratings
- DPO-Training mit positiven/negativen Beispielen
