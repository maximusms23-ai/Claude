# Qwen 2.5 3B Stack fuer Tom

Legacy-Hinweis: Der Ordner heisst historisch weiter `Gemma/`, der aktive lokale Stack ist aber jetzt auf **`qwen2.5:3b`** umgestellt.

## Zielbild

```text
Frage (tom-ask)
  -> LangChain HuggingFaceEmbeddings
  -> BAAI/bge-small-en-v1.5
  -> ChromaDB query (wiki + clippings + gehirn)
  -> LangChain ChatOllama
  -> qwen2.5:3b
  -> Antwort auf Deutsch + Quellen
```

Warum so:

- `qwen2.5:3b` ist klein genug fuer den M4-Workflow und offiziell in Ollama verfuegbar.
- `BAAI/bge-small-en-v1.5` ist der empfohlene Nachfolger von `bge-small-en`.
- LangChain kapselt Chat + Embeddings sauber und haelt den Stack austauschbar.
- Open WebUI kann denselben Ollama-Chatpfad nutzen, waehrend Embeddings stabil lokal ueber SentenceTransformers laufen.

## Aktive Defaults

| Teil | Default |
|---|---|
| Chat-Modell | `qwen2.5:3b` |
| Embeddings | `BAAI/bge-small-en-v1.5` |
| Ollama URL | `http://127.0.0.1:11434` |
| Chat-Kontext | `16384` |

## Setup

### 1. Env-Variablen

```bash
export OLLAMA_MODELS="/Users/maxim/Ollama"
export TOM_VAULT="/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw"
export TOM_LOCAL_MODEL="qwen2.5:3b"
export TOM_RAG_EMBED_MODEL="BAAI/bge-small-en-v1.5"
```

### 2. Ollama

```bash
brew install ollama
OLLAMA_MODELS=/Users/maxim/Ollama ollama serve &
ollama pull qwen2.5:3b
```

Optional fuer einen eigenen Alias:

```bash
ollama create tom-qwen25 -f /Users/maxim/Claude/Gemma/modelfile/Modelfile
```

### 3. Python-Umgebung fuer RAG

```bash
cd /Users/maxim/Claude/Gemma/rag
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 4. Index bauen

```bash
cd /Users/maxim/Claude/Gemma/rag
source .venv/bin/activate
python3 index.py
```

## Nutzung

```bash
tom-ask "Was ist Turboquant?"
tom-wiki "Welches Pattern haben wir fuer Hooks?"
cd /Users/maxim/Claude/Gemma && python3 training/collector.py --limit 5
```

## Open WebUI / Apple-Notiz

- Open WebUI sollte fuer diesen Stack **Ollama fuer Chat** und **SentenceTransformers fuer Embeddings** nutzen.
- Offizielle Open-WebUI-Doku empfiehlt fuer lokale Embeddings standardmaessig `RAG_EMBEDDING_ENGINE=""` plus `RAG_EMBEDDING_MODEL=<sentence-transformer>`.
- Qwen dokumentiert neben Ollama auch **MLX LM** als lokalen Apple-Silicon-Pfad. Damit bleibt ein spaeterer nativer Apple-Fallback offen, falls Ollama fuer bestimmte Workloads nicht reicht.

## Dateien

- `rag/config.py` — Modell-, Embedding- und Pfad-Defaults
- `rag/langchain_stack.py` — LangChain-Wrapper fuer ChatOllama + HuggingFaceEmbeddings
- `rag/index.py` — Chroma-Indexierung
- `rag/query.py` — RAG-Abfrage
- `modelfile/Modelfile` — optionaler Qwen-Ollama-Alias
