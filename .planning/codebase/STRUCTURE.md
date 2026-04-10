# Codebase Structure

**Analysis Date:** 2026-04-08

## Directory Layout

```
/Users/maxim/Claude/
├── AGENTS.md              # Operational instructions for LLM agents (German)
├── CLAUDE.md              # Project-level Claude Code guidance
├── .gitignore             # Git exclusions (TODOS.md, PROJEKTE.md, personal state)
├── .obsidian/             # Obsidian app configuration
│   ├── app.json           # App preferences
│   ├── appearance.json    # Theme settings
│   ├── core-plugins.json  # Built-in plugin configuration
│   ├── community-plugins.json  # Third-party plugin list
│   ├── workspace.json     # Window layout and editor state
│   ├── graph.json         # Knowledge graph visualization config
│   └── ...                # Other Obsidian internal files
├── .planning/             # GSD (goal-solution-details) workflow documentation
│   └── codebase/          # This folder: ARCHITECTURE.md, STRUCTURE.md, etc.
├── Obsidian/              # Main Obsidian vault (LLM-maintained knowledge base)
│   ├── CLAUDE.md          # Vault-specific Claude Code instructions
│   ├── mkdocs.yml         # MkDocs configuration (site_name, theme, plugins, docs_dir)
│   ├── TODOS.md           # Task tracking (gitignored, local-only)
│   ├── PROJEKTE.md        # Project status tracking (gitignored, local-only)
│   ├── wiki/              # Authoritative knowledge base (write here)
│   │   ├── index.md       # Main entry point with "Letzte Aktualisierungen" table
│   │   ├── themen/        # Topic articles (large-scale content)
│   │   │   ├── Themen-Index.md
│   │   │   ├── Gemma-4-Modelle.md      # Model overview, architecture, variants
│   │   │   ├── gemma4.md               # Detailed Gemma 4 feature set
│   │   │   └── Mannheim.md             # Example topical article
│   │   ├── konzepte/      # Concept/term definitions (vocabulary building)
│   │   │   ├── Konzepte-Index.md
│   │   │   ├── ollama.md          # Ollama usage patterns
│   │   │   ├── gguf-quantisierung.md    # Model quantization techniques
│   │   │   └── turboquant.md            # TurboQuant optimization
│   │   ├── personen/      # People and author registry
│   │   │   └── Personen-Index.md
│   │   ├── projekte/      # Project descriptions and tracking
│   │   │   ├── Projekte-Index.md
│   │   │   ├── paperclipai.md    # Agent platform setup and agent roster
│   │   │   ├── gemme-training.md # Fine-tuning pipeline
│   │   │   └── ollama.md         # Ollama deployment
│   │   ├── quellen/       # Source registry linking back to raw/
│   │   │   ├── Quellen-Index.md
│   │   │   ├── Gemma-4-Google-AI-Docs.md
│   │   │   └── Mannheim-Wikipedia.md
│   │   └── Werkzeuge.md   # Tools/utilities overview
│   ├── raw/               # Unprocessed source material (read-only)
│   │   ├── artikel/       # Downloaded articles
│   │   ├── paper/         # Academic papers
│   │   ├── repos/         # Repository clones or references
│   │   ├── datasets/      # Data files for analysis
│   │   └── images/        # Asset images
│   ├── Clippings/         # Web Clipper artifacts (read-only, treat like raw/)
│   ├── output/            # Generated deliverables (created by LLM)
│   │   ├── slides/        # Marp presentations
│   │   ├── plots/         # matplotlib charts and visualizations
│   │   ├── reports/       # Markdown reports and analyses
│   │   └── canvas/        # JSON Canvas files for visual knowledge mapping
│   ├── Projekte/          # Legacy project directory (not in use)
│   ├── Ideen/             # Ideas/brainstorming directory
│   ├── .github/           # GitHub Actions for deployment
│   │   └── workflows/
│   │       └── deploy.yml # Static site deployment workflow
│   └── .gitignore         # Excludes personal tracking (TODOS.md, PROJEKTE.md)
├── Gemma/                 # Gemma model integration and RAG pipeline
│   ├── README.md          # Gemma project overview
│   ├── training-data/     # Training data preparation
│   │   ├── AGENTS.md      # Training-specific instructions
│   │   ├── CLAUDE.md      # Training pipeline guidance
│   │   └── wiki/          # Extracted wiki for model fine-tuning
│   ├── rag/               # RAG (Retrieval-Augmented Generation) pipeline
│   │   ├── config.py      # Central configuration (paths, models, chunking params)
│   │   ├── index.py       # Wiki indexing script (frontmatter parsing, chunking, ChromaDB)
│   │   ├── query.py       # Query interface (embedding, retrieval, LLM generation)
│   │   ├── requirements.txt  # Python dependencies (chromadb, ollama, pyyaml)
│   │   ├── chroma_db/     # Persistent ChromaDB vector store (gitignored)
│   │   └── __pycache__/   # Python compilation cache (gitignored)
│   ├── eval/              # Evaluation directory (empty)
│   ├── modelfile/         # Ollama Modelfile definitions
│   └── .venv/             # Python virtual environment (gitignored)
└── .git/                  # Git repository metadata
```

## Directory Purposes

**AGENTS.md:**
- Purpose: Operational codex for LLM agents working in this repository
- Contains: Working instructions in German (language for content), workflow procedures
- Who maintains: The human writes initial guidance; LLM reads before major content changes

**CLAUDE.md:**
- Purpose: Project-level guidance for Claude Code (claude.ai/code)
- Contains: Constraints, architecture diagram, commands, content rules
- Who maintains: Human (defines boundaries), LLM (follows them)

**.gitignore:**
- Purpose: Exclude personal/local state from version control
- Contains: `TODOS.md`, `PROJEKTE.md`, `.venv/`, `__pycache__/`, virtual environment
- Rationale: Task/project tracking is ephemeral; environment is local-specific

**.obsidian/:**
- Purpose: Obsidian app configuration (window layout, plugins, themes, workspace)
- Contains: JSON configuration files for Obsidian.app
- Who maintains: Obsidian app writes dynamically, human customizes via settings

**.planning/codebase/:**
- Purpose: GSD workflow documentation (goal-solution-details methodology)
- Contains: Analysis documents created by Claude Code (`ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `TESTING.md`, `CONCERNS.md`, `STACK.md`, `INTEGRATIONS.md`)
- Who maintains: Orchestrator spawns mapping agents; developers consume for context

**Obsidian/CLAUDE.md:**
- Purpose: Vault-specific Claude Code instructions
- Contains: Content rules (YAML frontmatter schema), workflow procedures (ingesting sources, answering questions), file organization rules
- Who maintains: Human (initial structure), LLM (enforces when editing)

**Obsidian/mkdocs.yml:**
- Purpose: MkDocs build configuration for static site generation
- Contains: Site name (`site_name: WIKI-Maximus_OS`), theme settings (Material with indigo primary), plugins (search, roamlinks), docs directory
- Dependencies: MkDocs installed, Material theme available

**Obsidian/TODOS.md:**
- Purpose: Task tracking with timestamps (gitignored, local-only)
- Contains: Checkbox items with dates, LLM reads/writes on `/loop` or user query
- Scope: Not published to website, ephemeral

**Obsidian/PROJEKTE.md:**
- Purpose: Project status tracking with logs (gitignored, local-only)
- Contains: Project name, status, last update, progress log
- Scope: Not published, used for context on `/loop` or status queries

**Obsidian/wiki/ (Main Knowledge Base):**

Sub-directories and their purposes:

| Directory | Purpose | Content Type | Naming | Frontmatter `type` |
|-----------|---------|--------------|--------|-------------------|
| `themen/` | Major topic articles (city, AI models, fields) | Long-form content | adjective-noun or name | `thema` |
| `konzepte/` | Vocabulary and concept definitions | Medium explanations | lowercase-with-hyphens | `konzept` |
| `personen/` | People and author registry | Short bio/reference | Firstname-Lastname | `person` |
| `projekte/` | Project descriptions and tracking | Medium-long content | lowercase-project-name | `projekt` |
| `quellen/` | Source registry linking back to `raw/` | Citation + summary | Source-Title format | `quelle` |

**Obsidian/raw/ (Source Material — Read-Only):**
- Purpose: Original, unprocessed sources (never hand-edit)
- Structure:
  - `artikel/` — Downloaded web articles
  - `paper/` — Academic PDFs
  - `repos/` — Repository clones or documentation downloads
  - `datasets/` — Data files (.csv, .json, .xlsx)
  - `images/` — Asset images

**Obsidian/Clippings/ (Web Clipper Output — Read-Only):**
- Purpose: Automatically captured web articles via Obsidian Web Clipper
- Treat as: Source material (do not edit); inject findings into wiki

**Obsidian/output/ (Generated Artifacts):**

Sub-directories:

| Directory | Contains | Format | Tool | Owner |
|-----------|----------|--------|------|-------|
| `slides/` | Presentations | Marp (YAML + Markdown) | Marp CLI | LLM |
| `plots/` | Charts/visualizations | PNG, SVG | matplotlib | LLM |
| `reports/` | Analysis documents | Markdown | LLM writer | LLM |
| `canvas/` | Knowledge maps | JSON Canvas (`.canvas`) | Obsidian plugin | LLM |

**Gemma/ (Model Integration):**
- Purpose: Gemma language model support and RAG pipeline
- Scope: Fine-tuning, evaluation, knowledge retrieval

**Gemma/rag/ (RAG Pipeline — Core Processing):**

| File | Lines | Purpose |
|------|-------|---------|
| `config.py` | ~20 | Centralized configuration (paths, models, chunking) |
| `index.py` | ~109 | Wiki indexer (frontmatter parser, chunker, ChromaDB writer) |
| `query.py` | ~74 | Query interface (question embedder, retriever, LLM responder) |
| `requirements.txt` | ~3 | Dependencies (chromadb, ollama, pyyaml) |
| `chroma_db/` | — | Persistent vector store (gitignored) |

**Gemma/training-data/ (Training Set Preparation):**
- Purpose: Extract and prepare wiki for model fine-tuning
- Contains: Copy of AGENTS.md, CLAUDE.md, and `wiki/` subset
- Owner: LLM maintains, human curates what gets included

## Key File Locations

**Entry Points:**

| Entry Point | File Path | Purpose |
|-------------|-----------|---------|
| Main wiki | `Obsidian/wiki/index.md` | Front page with update table and navigation |
| Thematic index | `Obsidian/wiki/themen/Themen-Index.md` | Curated topic list |
| Concepts index | `Obsidian/wiki/konzepte/Konzepte-Index.md` | Vocabulary gateway |
| Projects index | `Obsidian/wiki/projekte/Projekte-Index.md` | Active project tracker |
| Sources index | `Obsidian/wiki/quellen/Quellen-Index.md` | Source material registry |
| Query CLI | `Gemma/rag/query.py` | Ask questions to RAG system |

**Configuration:**

| Setting | File Path | Scope |
|---------|-----------|-------|
| Site build | `Obsidian/mkdocs.yml` | MkDocs (site name, theme, plugins) |
| App layout | `Obsidian/.obsidian/workspace.json` | Obsidian.app window state |
| Theme | `Obsidian/.obsidian/appearance.json` | Obsidian color scheme |
| Plugins | `Obsidian/.obsidian/community-plugins.json` | Third-party plugin list |
| RAG config | `Gemma/rag/config.py` | Embedding model, chunking, retrieval size |
| LLM Guidance | `Obsidian/CLAUDE.md` | Content rules and workflows |

**Core Logic:**

| Component | File Path | Responsibility |
|-----------|-----------|-----------------|
| Frontmatter parser | `Gemma/rag/index.py:parse_frontmatter()` | Extract YAML metadata |
| Text chunker | `Gemma/rag/index.py:chunk_text()` | Split content for embedding |
| Indexer | `Gemma/rag/index.py:index_wiki()` | Scan wiki, embed, store in ChromaDB |
| Query handler | `Gemma/rag/query.py:query()` | Embed Q, retrieve context, generate answer |
| Source sync | `Gemma/training-data/wiki/` | Copy of wiki for training |

**Testing:**
- Not detected: No test files in codebase (RAG scripts are single-purpose, Obsidian config is GUI-driven)

## Naming Conventions

**Files:**

- `.md` files in wiki: `lowercase-hyphenated.md` (e.g., `gguf-quantisierung.md`, `gemme-training.md`) or `TitleCased.md` for index pages (e.g., `Themen-Index.md`)
- `.py` files: `lowercase_underscore.py` (e.g., `config.py`, `index.py`, `query.py`)
- Config files: `*.yml` (MkDocs) or `.json` (Obsidian, Ollama)

**Directories:**

- German content directories: lowercase plural with hyphens (`themen/`, `konzepte/`, `personen/`, `projekte/`, `quellen/`)
- Python packages: lowercase (`rag/`, `eval/`)
- Output types: lowercase plural (`slides/`, `plots/`, `reports/`, `canvas/`)

**Frontmatter Fields:**

- `title`: Free text, shown as page heading
- `created`: ISO 8601 date (YYYY-MM-DD)
- `type`: Enum (thema, konzept, person, projekt, quelle, index)
- `tags`: Array of lowercase strings with hyphens (e.g., `llm`, `open-weights`, `multimodal`)

**Wikilinks:**

- Format: `[[Page Name]]` (exact match to page title)
- Style: Sentence case or proper nouns (e.g., `[[Gemma 4]]`, `[[Ollama]]`, `[[PaperclipAI]]`)
- Scope: Any page, any type (thema, konzept, etc.)

## Where to Add New Code

**New Wiki Page (Primary Path):**
1. Create `.md` file in appropriate directory:
   - Topic: `Obsidian/wiki/themen/{topic-name}.md`
   - Concept: `Obsidian/wiki/konzepte/{concept-name}.md`
   - Person: `Obsidian/wiki/personen/{Firstname-Lastname}.md`
   - Project: `Obsidian/wiki/projekte/{project-name}.md`
   - Source: `Obsidian/wiki/quellen/{Source-Title}.md`
2. Add YAML frontmatter:
   ```yaml
   ---
   title: "Your Title"
   created: YYYY-MM-DD
   type: [thema|konzept|person|projekt|quelle]
   tags:
     - tag1
     - tag2
   ---
   ```
3. Write content with `[[Wikilinks]]` for internal cross-references
4. Update relevant index file (`Themen-Index.md`, `Konzepte-Index.md`, etc.)
5. Update `Obsidian/wiki/index.md` → add row to "Letzte Aktualisierungen" table, update statistics
6. Commit to git

**New RAG Feature (Rare):**
- Add Python functions to `Gemma/rag/query.py` or `index.py`
- Update `Gemma/rag/config.py` if adding new parameters
- Update `Gemma/rag/requirements.txt` if adding dependencies
- Test via `python3 Gemma/rag/index.py` then `python3 Gemma/rag/query.py "test query"`

**New Artifact Type:**
- Create `.md` file in `Obsidian/output/{type}/` (slides, plots, reports, canvas)
- For Marp slides: Include `marp: true` in YAML frontmatter
- For plots: Generate PNG/SVG via Python script and save to `output/plots/`
- For canvas: Generate `.canvas` JSON file via Python or Obsidian Canvas export

**New Output Destination:**
- Create subdirectory in `Obsidian/output/{new-type}/`
- Document in `CLAUDE.md` under "Output Generation" section
- No code change needed (convention-based)

## Special Directories

**Obsidian/.obsidian/:**
- Purpose: Obsidian.app internal configuration
- Generated: Partially (workspace state auto-written, config partially manual)
- Committed: Yes, so team config syncs
- Modify via: Obsidian settings GUI (not by hand-editing JSON)

**Gemma/rag/chroma_db/:**
- Purpose: Persistent ChromaDB vector database
- Generated: Yes (`python3 Gemma/rag/index.py` creates/populates)
- Committed: No (gitignored, regenerated on demand)
- Invalidation: After any wiki change, regenerate via `python3 Gemma/rag/index.py`

**Obsidian/raw/ and Obsidian/Clippings/:**
- Purpose: Unprocessed source material
- Generated: No (manually placed or auto-captured)
- Committed: Optionally (typically gitignored if large; kept if small and important)
- Modify: Never by hand (treat as read-only sources)

**Obsidian/TODOS.md and Obsidian/PROJEKTE.md:**
- Purpose: Personal task/project tracking
- Generated: Human creates, LLM updates
- Committed: No (gitignored)
- Scope: Local-only, not published

**Obsidian/output/:**
- Purpose: Generated deliverables
- Generated: Yes (LLM creates on demand)
- Committed: Selectively (keep important reports, gitignore large plot collections)
- Lifecycle: Can be recreated from source material in wiki

---

*Structure analysis: 2026-04-08*
