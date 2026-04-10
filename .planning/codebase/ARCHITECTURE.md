# Architecture

**Analysis Date:** 2026-04-08

## Pattern Overview

**Overall:** LLM-Maintained Knowledge Management System with Dual Layers (Human-Readable Wiki + Distributed Processing)

**Key Characteristics:**
- Git-backed Obsidian vault as primary knowledge repository
- LLM-active content generation and maintenance (not read-only)
- Structured semantic organization (topics, concepts, sources, people, projects)
- RAG (Retrieval-Augmented Generation) pipeline for knowledge querying
- MkDocs publishing layer for static site generation
- Agent platform integration for autonomous knowledge operations

## Layers

**Presentation Layer:**
- Purpose: Public-facing knowledge access via static website
- Location: `Obsidian/output/` (generated artifacts) and MkDocs publishing from `Obsidian/wiki/`
- Contains: Markdown files compiled to HTML, slides (Marp), plots (matplotlib), reports, JSON Canvas visualizations
- Depends on: Wiki content from `Obsidian/wiki/`
- Used by: External users via mkdocs serve or deployed website

**Content Layer (Wiki):**
- Purpose: Authoritative, human-curated semantic knowledge base
- Location: `Obsidian/wiki/`
- Contains: Markdown pages organized in five semantic categories (themen, konzepte, personen, projekte, quellen)
- Depends on: Raw source material in `Obsidian/raw/` and `Obsidian/Clippings/`
- Used by: RAG pipeline, export operations, index aggregation

**Ingestion Layer:**
- Purpose: Collect and prepare source material for knowledge extraction
- Location: `Obsidian/raw/` (artikel, paper, repos, datasets, images) and `Obsidian/Clippings/` (web clipper artifacts)
- Contains: Unprocessed source material (read-only)
- Depends on: External sources, web clipper, file uploads
- Used by: Content creation workflow (human curates these into wiki)

**Processing Layer (RAG):**
- Purpose: Index and query wiki content using embeddings
- Location: `Gemma/rag/`
- Contains: Python modules for indexing (`index.py`), querying (`query.py`), configuration (`config.py`)
- Depends on: ChromaDB for vector storage, Ollama for embeddings and LLM inference, wiki content
- Used by: Knowledge-based applications, query answering, semantic search

**Agent Platform:**
- Purpose: Autonomous knowledge operations (research, curation, validation)
- Location: External service (PaperclipAI at `127.0.0.1:3100`)
- Contains: Specialized agents (Wiki-Kurator, Archivarius, Tom, CEO, CTO, etc.)
- Depends on: Obsidian wiki as knowledge source, Ollama for LLM inference
- Used by: Automated wiki maintenance, research tasks, issue tracking

**Configuration Layer:**
- Purpose: Application settings and environment configuration
- Location: `Obsidian/mkdocs.yml` (site config), `.obsidian/` (Obsidian app config), `.planning/` (GSD workflow)
- Contains: Build settings, theme configuration, plugin settings, workflow metadata
- Depends on: MkDocs, Material theme, Obsidian plugins
- Used by: Build pipeline, app initialization, LLM agent instructions

## Data Flow

**Source Ingestion Flow:**

1. External sources arrive via web (Obsidian Web Clipper) or download (PDFs, datasets)
2. Material placed in `Obsidian/raw/` or auto-captured to `Obsidian/Clippings/`
3. Human reads/scans raw material
4. Concepts extracted → new pages created in `Obsidian/wiki/konzepte/`
5. Thematic articles created/extended in `Obsidian/wiki/themen/`
6. Cross-references added: people → `Obsidian/wiki/personen/`, projects → `Obsidian/wiki/projekte/`
7. Source entry created in `Obsidian/wiki/quellen/` linking back to raw material
8. Index files updated (`*-Index.md`), main index updated (`Obsidian/wiki/index.md`)

**Knowledge Querying Flow:**

1. Query enters RAG system (`Gemma/rag/query.py`)
2. Query embedded using `nomic-embed-text` via Ollama
3. Similarity search against ChromaDB vector index (`Gemma/rag/chroma_db/`)
4. Top 5 chunks retrieved with metadata (source, title, tags)
5. Context synthesized from retrieved chunks
6. System prompt + context + question sent to Gemma model via Ollama
7. Response generated with source citations
8. Sources traced back to wiki pages

**Publishing Flow:**

1. Content edited/created in `Obsidian/wiki/` directory
2. MkDocs reads from `docs_dir: wiki` in `Obsidian/mkdocs.yml`
3. Markdown processed with roamlinks plugin (converts `[[Page]]` to web links)
4. Static HTML generated in `Obsidian/site/`
5. Published via GitHub Pages or served locally via `mkdocs serve`

**Artifact Generation Flow:**

1. LLM processes queries or tasks
2. Generated outputs written to `Obsidian/output/` with appropriate subdirectory
   - Presentations → `output/slides/` (Marp format with `marp: true` frontmatter)
   - Plots → `output/plots/` (matplotlib PNG/SVG)
   - Reports → `output/reports/` (Markdown)
   - Visualizations → `output/canvas/` (JSON Canvas `.canvas` files)
3. Optionally "filed" back into wiki for integration with knowledge base
4. Tracked in index updates

**State Management:**

- **Authoritative state**: Git repository at `/Users/maxim/Claude/` (committed content in wiki/)
- **Temporary state**: Obsidian app config in `.obsidian/`, RAG index in `Gemma/rag/chroma_db/`, agent state in PaperclipAI
- **Personal state**: Task tracking (`Obsidian/TODOS.md`) and project tracking (`Obsidian/PROJEKTE.md`) — gitignored, local-only
- **Cache invalidation**: RAG index must be regenerated after wiki changes via `python3 Gemma/rag/index.py`

## Key Abstractions

**Page Types:**

- Purpose: Semantic categorization of wiki content
- Examples: `Obsidian/wiki/themen/Gemma-4-Modelle.md` (topic), `Obsidian/wiki/konzepte/ollama.md` (concept), `Obsidian/wiki/projekte/paperclipai.md` (project)
- Pattern: YAML frontmatter declares `type` (thema, konzept, person, projekt, quelle, index); content follows markdown with Obsidian wikilinks

**Frontmatter Schema:**

- Purpose: Machine-readable metadata for content organization and indexing
- Examples: `title`, `created` (YYYY-MM-DD), `type`, optional `tags` list
- Pattern: All `.md` files start with YAML delimited by `---`, parsed by RAG indexer and MkDocs pipeline

**Wikilinks Convention:**

- Purpose: Internal cross-referencing across semantic boundaries
- Examples: `[[Gemma-4-Modelle]]`, `[[Ollama]]`, `[[PaperclipAI]]`
- Pattern: Double-bracket syntax; converted to HTML links by roamlinks plugin; enable semantic relationships without file path coupling

**Index Files:**

- Purpose: Discoverable entry points for each semantic category
- Examples: `Obsidian/wiki/themen/Themen-Index.md`, `Obsidian/wiki/konzepte/Konzepte-Index.md`
- Pattern: Maintains curated list with wikilinks grouped by subcategory; auto-updated when pages added/removed

## Entry Points

**Web Browser (Published Site):**
- Location: Generated `Obsidian/site/` or live at `http://localhost:8000` during `mkdocs serve`
- Triggers: User navigates to published site
- Responsibilities: Serve HTML with full-text search, navigation through semantic index, wikilink traversal

**Local Obsidian App:**
- Location: `Obsidian/` directory, opened in Obsidian.app with config in `.obsidian/`
- Triggers: User opens Obsidian
- Responsibilities: Edit/create content, preview wikilinks, manage vault (search, graph, plugins)

**RAG Query Interface:**
- Location: `Gemma/rag/query.py`
- Triggers: `python3 Gemma/rag/query.py "Your question"`
- Responsibilities: Accept natural language question, retrieve contextual chunks, generate answer with citations

**RAG Indexing:**
- Location: `Gemma/rag/index.py`
- Triggers: `python3 Gemma/rag/index.py` (manual or after wiki updates)
- Responsibilities: Scan wiki directory, parse frontmatter, chunk content, generate embeddings, populate ChromaDB

**Agent Platform CLI:**
- Location: PaperclipAI accessible via `paperclipai` commands
- Triggers: User runs `paperclipai run`, `paperclipai agent list`, etc.
- Responsibilities: Launch agent orchestration server, manage agents, execute autonomous tasks, track issues

**GSD Workflow Integration:**
- Location: `.planning/codebase/` for documentation, `/gsd:*` commands
- Triggers: User invokes `/gsd:map-codebase`, `/gsd:plan-phase`, `/gsd:execute-phase`
- Responsibilities: Analyze codebase, generate implementation plans, execute guided development

## Error Handling

**Strategy:** Graceful degradation with explicit error reporting

**Patterns:**

- **RAG Pipeline Failures**: If embeddings unavailable, fallback to keyword search; if Ollama offline, suggest local model restart
- **Wiki Parsing**: YAML parse errors caught, content still indexed with empty metadata; missing pages reported as broken links
- **Missing Indices**: RAG queries check ChromaDB existence, refuse to run if index stale (requires `index.py` re-run)
- **Source Material**: Gracefully handle missing `raw/` or `Clippings/` directories; content layer independent of sources
- **Agent Operations**: PaperclipAI failures logged with diagnostic commands (`paperclipai doctor`); agents transition to `idle` state on error

## Cross-Cutting Concerns

**Logging:** RAG pipeline logs indexing progress to stdout; Obsidian app logs to `Obsidian/.obsidian/` internal logs; PaperclipAI logs to `~/.paperclip/instances/default/logs`

**Validation:**

- Frontmatter validated against schema (required: title, created, type)
- Wikilinks checked against index files (broken links identifiable via graph view in Obsidian)
- Page deduplication enforced (prefer extend existing over create new)
- Tag consistency maintained through controlled vocabulary in index definitions

**Authentication:**

- Obsidian vault access: Local filesystem permissions only
- PaperclipAI: Loopback-only (127.0.0.1:3100), no external access
- Ollama: Local TCP (default 11434), loopback access sufficient
- Git: Local repo, no credential management needed for this closed system

**Documentation:**

- Operational guidance in `CLAUDE.md` (project-level) and `Obsidian/CLAUDE.md` (vault-specific)
- Working instructions in `AGENTS.md` (German language for LLM agents)
- Configuration files self-documented through comments and examples
