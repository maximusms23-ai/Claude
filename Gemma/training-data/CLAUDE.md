# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A git repo containing an Obsidian vault (`Obsidian/`) that serves as an LLM-maintained knowledge base. The LLM actively writes, links, and maintains wiki content. The human rarely edits wiki files directly. See `AGENTS.md` for detailed working instructions and `Obsidian/CLAUDE.md` for vault-specific rules.

## Key Constraints

- **Language**: German for content, English for code/technical identifiers
- **Never modify**: `Obsidian/raw/` and `Obsidian/Clippings/` (source material)
- **Write area**: `Obsidian/wiki/` is where content goes. Entry point: `Obsidian/wiki/index.md`
- **Outputs**: Generated artifacts (slides, plots, reports, canvas) go to `Obsidian/output/`
- **Personal tracking**: `Obsidian/TODOS.md` and `Obsidian/PROJEKTE.md` — not in git, not on website

## Commands

```bash
# Serve wiki locally via MkDocs
cd Obsidian && mkdocs serve

# Build static site
cd Obsidian && mkdocs build
```

## Architecture

```
Claude/
├── AGENTS.md          # Codex working instructions (German)
├── Obsidian/          # The vault
│   ├── CLAUDE.md      # Vault-specific Claude instructions
│   ├── wiki/          # Main knowledge base (write here)
│   ├── raw/           # Source material (read-only)
│   ├── Clippings/     # Web clipper articles (read-only)
│   ├── output/        # Generated deliverables
│   ├── TODOS.md       # Task tracking (gitignored)
│   ├── PROJEKTE.md    # Project tracking (gitignored)
│   └── mkdocs.yml     # MkDocs config
└── .obsidian/         # Obsidian app config
```

## Mandatory After Every Content Change

1. Update relevant index files (`Themen-Index.md`, `Konzepte-Index.md`, `Personen-Index.md`, `Projekte-Index.md`, `Quellen-Index.md`)
2. Update `wiki/index.md` — "Letzte Aktualisierungen" table and statistics
3. Every `.md` page needs YAML frontmatter: `title`, `created` (YYYY-MM-DD), `type`, optional `tags`
4. Use `[[Wikilinks]]` for internal cross-references
