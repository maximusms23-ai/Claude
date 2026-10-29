# Qwen Sub-Projekt — Instructions fuer Claude Code

Dieses Unterverzeichnis `/Users/maxim/Claude/Gemma/` ist historisch der lokale LLM-Bereich. Der aktive Stack laeuft jetzt auf **Qwen 2.5 3B + bge-small-en-v1.5**, der Ordnername bleibt nur aus Kompatibilitaetsgruenden bestehen.

## Scope

- Hauptaufgaben: lokalen Qwen-Stack pflegen, RAG evaluieren, Training-Daten sammeln
- Nicht hier: Vault-Kuration, Eltern-/Familien-Orga, Maximus_OS-Steuerung

## Wissens-Kaskade

1. Projekt-Files direkt lesen (`rag/config.py`, `README.md`, `modelfile/Modelfile`)
2. `tom-wiki "Frage"` fuer bekannte Themen aus `90_Wiki/`
3. `tom-wiki --brain "Frage"` fuer privates Brain-Wissen
4. `tom-ask "Frage"` als RAG-Fallback ueber `wiki`, `clippings`, `gehirn`

## Wichtige Commands

```bash
cd /Users/maxim/Claude/Gemma

cd rag && python3 index.py
python3 eval/run_eval.py
python3 training/collector.py --limit 5
ollama create tom-qwen25 -f modelfile/Modelfile
```

## Aktive Modelle

- Chat: `qwen2.5:3b`
- Embeddings: `BAAI/bge-small-en-v1.5`
- Runtime: Ollama + LangChain (`langchain-ollama`, `langchain-huggingface`)

## Dateien

- `rag/config.py` — Pfade + Modell-Defaults
- `rag/langchain_stack.py` — LangChain-Wrapper
- `rag/index.py` — Chroma-Indexer
- `rag/query.py` — RAG-Abfrage
- `training/collector.py` — Self-Instruct-Daten
- `README.md` — Setup und Architektur
