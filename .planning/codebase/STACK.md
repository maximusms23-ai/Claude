# Technology Stack

**Analysis Date:** 2026-04-12

## Languages

**Primary:**
- Python 3.13 - RAG pipeline, wiki indexing, query processing (`/Users/maxim/Claude/Gemma/rag/`)
- Markdown - Wiki content and documentation throughout vault

**Secondary:**
- YAML - MkDocs configuration, Ollama modelfiles, frontmatter parsing
- Bash - Deployment scripts and CLI operations

## Runtime

**Environment:**
- Python 3.13 (inferred from `.venv` in `/Users/maxim/Claude/Gemma/rag/`)
- Ollama 0.x - Local LLM inference runtime for model execution

**Package Manager:**
- pip - Python dependency management
- Lockfile: Not detected (uses `requirements.txt` only)

## Frameworks

**Core:**
- MkDocs 1.x - Static site generator for wiki (`/Users/maxim/Claude/Obsidian/mkdocs.yml`)
  - Material theme - Modern responsive documentation theme
  - roamlinks plugin - Obsidian-style wikilink support for cross-references
- Ollama - Local LLM runtime and inference engine
  - Runs `qwen2.5:3b` as the active local chat/research model
- LangChain - Orchestration layer for local chat and embeddings
- sentence-transformers - Local embedding runtime for semantic search
- Open WebUI - Local UI and web-search/RAG surface over Ollama

**Testing:**
- Not detected

**Build/Dev:**
- GitHub Actions - CI/CD for wiki deployment (`/Users/maxim/Claude/Obsidian/.github/workflows/deploy.yml`)

## Key Dependencies

**Critical:**
- chromadb - Vector database for RAG semantic search and retrieval (`/Users/maxim/Claude/Gemma/rag/`)
  - Persistent storage in `/Users/maxim/Claude/Gemma/rag/chroma_db/`
- langchain-ollama - LangChain adapter for Ollama chat/inference
- langchain-huggingface - LangChain adapter for Hugging Face embeddings
- sentence-transformers - Local embeddings via `BAAI/bge-small-en-v1.5`
- pyyaml - YAML parsing for frontmatter extraction in wiki indexing
- mkdocs-material - Material Design theme for MkDocs
- mkdocs-roamlinks-plugin - Wikilink plugin for Obsidian-style cross-references

**Infrastructure:**
- GitHub Pages - Hosting for static wiki site (configured in deploy workflow)
- Obsidian - Local knowledge management application (vault in `/Users/maxim/Claude/Obsidian/`)

## Configuration

**Environment:**
- `TOM_LOCAL_MODEL=qwen2.5:3b`
- `TOM_RAG_EMBED_MODEL=BAAI/bge-small-en-v1.5`
- `OLLAMA_BASE_URL=http://127.0.0.1:11434`
- Open WebUI uses env-based configuration in `openwebui/.env.example`

**Build:**
- MkDocs config: `/Users/maxim/Claude/Obsidian/mkdocs.yml`
  - Site name: "WIKI-Maximsu_OS"
  - Docs directory: `wiki/`
  - Theme: Material with dark/light mode toggle
  - Plugins: search, roamlinks
- Ollama modelfile: `/Users/maxim/Claude/Gemma/modelfile/Modelfile`
  - Base model: `qwen2.5:3b`
  - Context window: 16384 tokens
  - Temperature: 0.2
- GitHub Actions workflow: `/Users/maxim/Claude/Obsidian/.github/workflows/deploy.yml`
  - Python 3.12
  - Auto-deploys to GitHub Pages on main branch push

## Platform Requirements

**Development:**
- macOS (confirmed: Darwin 25.4.0 via env info)
- Mac Mini M4 with 16 GB unified memory (per `/Users/maxim/Claude/Gemma/README.md`)
- Ollama installed and running locally
- Python 3.13+ with pip
- Apple Silicon friendly local model/runtime path (`qwen2.5:3b`, Ollama, optional MLX follow-up)

**Production:**
- GitHub Pages (static hosting for wiki)
- Python 3.12+ environment for RAG pipeline (if deployed remotely)
- Ollama installation with `qwen2.5:3b`
- Local embedding assets for `BAAI/bge-small-en-v1.5`

---

*Stack analysis: 2026-04-12*
