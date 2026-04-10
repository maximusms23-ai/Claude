# External Integrations

**Analysis Date:** 2026-04-08

## APIs & External Services

**Local LLM Runtime:**
- Ollama - Local LLM inference engine
  - SDK/Client: `ollama` Python package
  - Purpose: Model execution (Gemma 4 8B), embeddings generation (nomic-embed-text)
  - Communication: Local HTTP API (default port 11434)
  - Used in: `index.py` for embeddings, `query.py` for inference

**Web Content Integration:**
- Obsidian Web Clipper - Browser extension for capturing web articles
  - Purpose: Save external articles to `/Users/maxim/Claude/Obsidian/Clippings/`
  - No authentication required (local browser extension)

## Data Storage

**Databases:**
- ChromaDB (Vector Database)
  - Type: In-process vector database with persistent disk storage
  - Connection: Local filesystem at `/Users/maxim/Claude/Gemma/rag/chroma_db/`
  - Client: chromadb Python package (PersistentClient)
  - Purpose: Store and retrieve embeddings for RAG semantic search
  - Collection: "wiki" - Contains indexed markdown chunks with metadata

**File Storage:**
- Local filesystem only
  - Wiki files: `/Users/maxim/Claude/Obsidian/wiki/`
  - Raw sources: `/Users/maxim/Claude/Obsidian/raw/`
  - Web clippings: `/Users/maxim/Claude/Obsidian/Clippings/`
  - Vector DB: `/Users/maxim/Claude/Gemma/rag/chroma_db/`
  - Training data: `/Users/maxim/Claude/Gemma/training-data/`

**Caching:**
- ChromaDB embeddings cache - Persistent vector embeddings in chroma_db directory

## Authentication & Identity

**Auth Provider:**
- None - This is a local-only system with no remote authentication
- Obsidian: Local application, no cloud auth
- Ollama: Local runtime, no authentication
- GitHub Pages deployment: Uses GitHub Actions with standard `contents: write` permissions

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- Console-based logging via Python print() statements
  - Ollama embedding generation progress in `index.py`
  - RAG query execution in `query.py`
  - No log files configured

## CI/CD & Deployment

**Hosting:**
- GitHub Pages - Static wiki deployment
  - Repository: This repository (GitHub)
  - Deployment trigger: Push to main branch
  - Built artifact: MkDocs static site

**CI Pipeline:**
- GitHub Actions workflow: `/Users/maxim/Claude/Obsidian/.github/workflows/deploy.yml`
  - Trigger: Push to main branch
  - Environment: Ubuntu latest
  - Steps:
    1. Checkout code (actions/checkout@v4)
    2. Setup Python 3.12 (actions/setup-python@v5)
    3. Install mkdocs, mkdocs-material, mkdocs-roamlinks-plugin
    4. Build and deploy via `mkdocs gh-deploy --force`
  - Permissions: `contents: write` for pushing to gh-pages branch

## Environment Configuration

**Required env vars:**
- None detected - All configuration is file-based

**Secrets location:**
- No secret management detected
- No .env files in use
- GitHub Actions uses default GITHUB_TOKEN for gh-pages deployment

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- GitHub Pages deployment hook - Auto-triggered on push to main

## Local Development Integrations

**Obsidian Vault:**
- Local knowledge management application
- Syncs with wiki directory at `/Users/maxim/Claude/Obsidian/wiki/`
- Supports: Markdown editing, wikilinks, frontmatter, tags, search

**RAG Pipeline Workflow:**
- Manual trigger via CLI commands:
  - `python3 Gemma/rag/index.py` - Index wiki into ChromaDB
  - `python3 Gemma/rag/query.py "question"` - Query via RAG

---

*Integration audit: 2026-04-08*
