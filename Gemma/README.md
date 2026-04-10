# Gemme — Lokales LLM + RAG für Tom

Lokale LLM-Inferenz + Retrieval-Augmented-Generation gegen Maxims iCloud-Vault. Liefert `tom-ask` — den Frontend-Wrapper, mit dem Tom (Claude Code) und Maxim Wiki-Fragen lokal stellen können, ohne Cloud-Call.

**Stand:** Tom v1.1 (2026-04-10)

## Architektur

```
Frage (tom-ask)
  → embed (nomic-embed-text)
  → ChromaDB query (wiki + clippings Collections)
  → Top-K Chunks als Kontext
  → gemme (custom model, basierend auf gemma4:e4b)
  → Antwort auf Deutsch + Quellen-Liste
```

## Hardware + Modelle

- **Host**: Mac Mini M4, 16 GB unified memory
- **Runtime**: Ollama v0.20.5+ (Homebrew-Install)
- **Modelle-Pfad**: `/Users/maxim/Ollama` (via `OLLAMA_MODELS` Env-Var)

| Modell | Größe | Zweck |
|---|---|---|
| `gemma4:e4b` (= `latest`) | 9.6 GB, 4.5B effektive Params, 128K Context | Base-Modell |
| `gemme` (custom) | Layer auf `gemma4:e4b` | System-Prompt Deutsch, temperature 0.7, num_ctx 8192 |
| `nomic-embed-text` | ~274 MB | Embedding-Modell für ChromaDB |

### Modell-Wahl

Gegen Mac M4 16 GB RAM geprüft: `gemma4:e4b` ist der Sweet Spot. `e2b` (7.2 GB) wäre sparsamer, `26b`/`31b` sprengen den RAM.

| Tag | Params | Disk | Passt auf 16 GB M4? |
|---|---|---|---|
| `gemma4:e2b` | 2.3B effektiv | 7.2 GB | Ja (viel Headroom) |
| **`gemma4:e4b`** (`latest`) | 4.5B effektiv | 9.6 GB | Ja (Sweet Spot) |
| `gemma4:26b` (MoE) | 25.2B total | 18 GB | Nein |
| `gemma4:31b` | 30.7B | 20 GB | Nein |

## Voraussetzungen (einmaliges Setup)

### 1. Env-Variablen in `~/.zshrc`

```bash
export OLLAMA_MODELS="/Users/maxim/Ollama"
export TOM_VAULT="/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw"
```

### 2. Ollama installieren + Modelle pullen

```bash
# Binary (falls nicht vorhanden)
brew install ollama

# Server starten (manuell)
OLLAMA_MODELS=/Users/maxim/Ollama ollama serve &

# Base + Embed
ollama pull gemma4:e4b
ollama pull nomic-embed-text

# Custom model bauen
ollama create gemme -f /Users/maxim/Claude/Gemma/modelfile/Modelfile
```

### 3. Python venv für RAG

```bash
cd /Users/maxim/Claude/Gemma/rag
python3 -m venv .venv
source .venv/bin/activate
pip install chromadb ollama pyyaml
```

### 4. Wiki indizieren

```bash
cd /Users/maxim/Claude/Gemma/rag
source .venv/bin/activate
python3 index.py
```

Indiziert `$TOM_VAULT/90_Wiki/` (Wiki-Collection) und `$TOM_VAULT/Clippings/` (Clippings-Collection) in ChromaDB (`rag/chroma_db/`, gitignored).

## Tägliche Nutzung

### Query via Wrapper

```bash
tom-ask "Was ist Turboquant?"
tom-ask "Welche Gemma 4 Groessen gibt es?"
```

Der Wrapper liegt in `/Users/maxim/Claude/bin/tom-ask` und ist via `~/bin/tom-ask` (Symlink) im PATH. Aktiviert automatisch das venv und setzt Env-Vars.

### Direkt ohne RAG

```bash
ollama run gemme "Frage"
```

### Reindex nach Wiki-Änderungen

```bash
cd /Users/maxim/Claude/Gemma/rag
source .venv/bin/activate
python3 index.py
```

## Trainingsdaten (Self-Instruct)

Self-Instruct: `gemme` generiert aus Wiki-Seiten selbst Q&A-Paare, die später für Fine-Tuning genutzt werden.

```bash
cd /Users/maxim/Claude/Gemma
source rag/.venv/bin/activate
python3 training/collector.py --limit 5   # 5 Wiki-Dateien
python3 training/collector.py              # alle
```

Output: `training/data/qa_pairs.jsonl` (JSONL, ein Pair pro Zeile, dedupliziert via SHA256).

Zusätzlich wird jede RAG-Query automatisch in `training/data/interactions.jsonl` geloggt (Frage + Antwort + Quellen).

## Eval-Framework

```bash
cd /Users/maxim/Claude/Gemma
source rag/.venv/bin/activate
python3 eval/run_eval.py
```

Liest `eval/questions.yaml` (Frage + erwartete Keywords), ruft jeweils den RAG auf, zählt Keyword-Matches. Score ≥ 50% = PASS.

**Baseline Tom v1.1 (2026-04-10):** 1/5 = 20%. Erwartung: wächst mit wachsendem Wiki und späterem Fine-Tuning.

## Fine-Tuning — Roadmap (ab v1.2)

Ollama kann **keine Gemma-FT direkt**. In v1.1 wird nur der Self-Instruct-Datensatz aufgebaut; echtes Gewichts-Update kommt in v1.2+ via externem Runner:

- **Option A**: [MLX-LM](https://github.com/ml-explore/mlx-lm) — Apple Silicon nativ, gute Gemma-Unterstützung
- **Option B**: [Unsloth](https://github.com/unslothai/unsloth) — QLoRA-Fine-Tuning, erfordert CUDA oder Apple Metal via Shim

Nach FT wird das resultierende Modell zurück zu GGUF konvertiert und mit einem neuen `Modelfile` als `gemme-ft` in Ollama geladen. A/B-Eval gegen Base-`gemme` via `run_eval.py`.

## Verzeichnisstruktur

```
Gemma/
├── README.md             # Diese Datei
├── modelfile/
│   └── Modelfile         # FROM gemma4:latest + System-Prompt + Params
├── rag/
│   ├── config.py         # TOM_VAULT / WIKI_PATH / CLIPPINGS_PATH / EMBED_MODEL
│   ├── index.py          # Wiki + Clippings → ChromaDB
│   ├── query.py          # Frage → Embedding → Top-K → gemme
│   ├── requirements.txt  # chromadb, ollama, pyyaml
│   ├── .venv/            # Python venv (gitignored)
│   └── chroma_db/        # Persistente Vektor-DB (gitignored)
├── training/
│   ├── collector.py              # Self-Instruct Q&A-Gen via gemme
│   ├── interaction_logger.py     # Query-Log-Helfer
│   ├── README.md                 # Datenformate
│   └── data/
│       ├── qa_pairs.jsonl        # Self-Instruct Q&A
│       └── interactions.jsonl    # RAG-Query-Log
└── eval/
    ├── questions.yaml   # Test-Fragen + Keywords
    └── run_eval.py      # Keyword-Match Eval
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `tom-ask` sagt "venv nicht gefunden" | `cd Gemma/rag && python3 -m venv .venv && source .venv/bin/activate && pip install chromadb ollama pyyaml` |
| "Kein Index gefunden" | `python3 Gemma/rag/index.py` |
| "could not connect to Ollama" | `OLLAMA_MODELS=/Users/maxim/Ollama ollama serve &` |
| Modell fehlt in `ollama list` | `echo $OLLAMA_MODELS` prüfen, muss `/Users/maxim/Ollama` sein |
| Eval-Score stürzt nach Modelfile-Änderung ab | Baseline-Eval vor JEDER Änderung notieren, A/B vergleichen |
| Wiki-Query findet nichts | Reindex nach Wiki-Updates: `python3 index.py` |

## Siehe auch

- `/Users/maxim/Claude/bin/tom-ask` — Wrapper-Skript
- `/Users/maxim/Claude/bin/tom-issue` — Maximus_OS Audit-Channel
- `$TOM_VAULT/70_Hardware/ollama-setup.md` — Hardware-Seite im Vault
- `$TOM_VAULT/90_Wiki/projekte/paperclipai.md` — Maximus_OS Integration-Layer
