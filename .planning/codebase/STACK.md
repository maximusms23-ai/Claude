# Technology Stack

**Analysis Date:** 2026-04-08

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
  - Runs Gemma 4 8B (Q4_K_M quantization) as base model
  - nomic-embed-text - Embedding model for RAG semantic search

**Testing:**
- Not detected

**Build/Dev:**
- GitHub Actions - CI/CD for wiki deployment (`/Users/maxim/Claude/Obsidian/.github/workflows/deploy.yml`)

## Key Dependencies

**Critical:**
- chromadb - Vector database for RAG semantic search and retrieval (`/Users/maxim/Claude/Gemma/rag/`)
  - Persistent storage in `/Users/maxim/Claude/Gemma/rag/chroma_db/`
- ollama - Python SDK for local LLM inference and embeddings
- pyyaml - YAML parsing for frontmatter extraction in wiki indexing
- mkdocs-material - Material Design theme for MkDocs
- mkdocs-roamlinks-plugin - Wikilink plugin for Obsidian-style cross-references

**Infrastructure:**
- GitHub Pages - Hosting for static wiki site (configured in deploy workflow)
- Obsidian - Local knowledge management application (vault in `/Users/maxim/Claude/Obsidian/`)

## Configuration

**Environment:**
- No detected environment variables in use
- All paths configured relative to repo structure in `config.py`

**Build:**
- MkDocs config: `/Users/maxim/Claude/Obsidian/mkdocs.yml`
  - Site name: "WIKI-Maximsu_OS"
  - Docs directory: `wiki/`
  - Theme: Material with dark/light mode toggle
  - Plugins: search, roamlinks
- Ollama modelfile: `/Users/maxim/Claude/Gemma/modelfile/Modelfile`
  - Base model: gemma4:latest (Gemma 4 8B)
  - Context window: 8192 tokens
  - Temperature: 0.7
- GitHub Actions workflow: `/Users/maxim/Claude/Obsidian/.github/workflows/deploy.yml`
  - Python 3.12
  - Auto-deploys to GitHub Pages on main branch push

## Platform Requirements

**Development:**
- macOS (confirmed: Darwin 25.4.0 via env info)
- Mac Mini M4 with 16 GB unified memory (per `/Users/maxim/Claude/Gemma/README.md`)
- Ollama installed and running locally
- Python 3.13+ with pip

**Production:**
- GitHub Pages (static hosting for wiki)
- Python 3.12+ environment for RAG pipeline (if deployed remotely)
- Ollama installation with gemma4:latest and nomic-embed-text models

---

*Stack analysis: 2026-04-08*
