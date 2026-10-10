# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A git repo containing an Obsidian vault (`Obsidian/`) that serves as an LLM-maintained knowledge base. The LLM actively writes, links, and maintains wiki content. The human rarely edits wiki files directly. See `AGENTS.md` for detailed working instructions and `Obsidian/CLAUDE.md` for vault-specific rules.

## Key Constraints

- **Language**: German for content, English for code/technical identifiers
- **Never modify**: `Obsidian/raw/` and `Obsidian/Clippings/` (source material)
- **Write area**: `Obsidian/wiki/` is where content goes. Entry point: `Obsidian/wiki/index.md`
- **Outputs**: Generated artifacts (slides, plots, reports, canvas) go to `Obsidian/output/`
- **Personal tracking**: `Obsidian/TODOS.md` and `Obsidian/PROJEKTE.md` — not in git, not on website. When user asks "was steht an?" or "woran arbeite ich?" → read these files
- **Output formats**: Marp (slides), matplotlib (plots), Markdown (reports), JSON Canvas (canvas)

## Commands

```bash
# Serve wiki locally via MkDocs (requires material theme + roamlinks plugin)
cd Obsidian && mkdocs serve

# Build static site
cd Obsidian && mkdocs build

# Install MkDocs dependencies
pip install mkdocs-material mkdocs-roamlinks-plugin
```

## Architecture

```
Claude/
├── AGENTS.md          # Codex working instructions (German)
├── Obsidian/          # The vault
│   ├── CLAUDE.md      # Vault-specific Claude instructions
│   ├── wiki/          # Main knowledge base (write here)
│   │   ├── themen/    # Topical articles
│   │   ├── konzepte/  # Term/concept definitions
│   │   ├── personen/  # People and authors
│   │   ├── projekte/  # Projects and repositories
│   │   └── quellen/   # Source registry linking back to raw/
│   ├── raw/           # Source material (read-only)
│   ├── Clippings/     # Web clipper articles (read-only)
│   ├── output/        # Generated deliverables
│   │   ├── slides/    # Marp presentations
│   │   ├── plots/     # matplotlib/Python charts
│   │   ├── reports/   # Markdown reports
│   │   └── canvas/    # JSON Canvas files
│   ├── TODOS.md       # Task tracking (gitignored)
│   ├── PROJEKTE.md    # Project tracking (gitignored)
│   └── mkdocs.yml     # MkDocs config
└── .obsidian/         # Obsidian app config
```

## Agentic OS (Agenten-Ebene)

- Subagenten: `.claude/agents/` — `wiki-ingest`, `wiki-health`, `wiki-index`, `output-builder`, `memory-keeper`
- Slash-Commands: `/ingest`, `/health`, `/sync`, `/output`, `/memory`, `/check`, `/anstehend`
- Projektgedaechtnis: `Obsidian/Agentic OS/MEMORY.md`, Regelwerk in `Obsidian/Agentic OS/AI Memory Protocol.md`
- **Zu Session-Beginn das Gedaechtnis lesen** (der SessionStart-Hook `.claude/hooks/session-start-memory.sh` laedt es automatisch; scheitert er, manuell lesen)
- Bei Widerspruch zwischen Gedaechtnis und Dateibestand gilt der Dateibestand
- Pruefung: `python3 scripts/wiki_check.py` (auch in CI via `.github/workflows/wiki-check.yml`)
- Lokaler Arbeitsplatz: `scripts/agentic-os-bootstrap.sh`
- Uebersicht: `Obsidian/wiki/projekte/agentic-os.md`

### Erzwungene Regeln (Hooks)

- `guard-readonly.py` blockt Schreibzugriffe auf `Obsidian/raw/` und `Obsidian/Clippings/`. Lesen bleibt frei. Soll dort wirklich geschrieben werden, braucht es eine ausdrueckliche Freigabe des Users.
- `stop-wiki-gate.py` laesst eine Session nicht beenden, solange eine Inhaltsaenderung nicht in `wiki/index.md` steht (und bei neuen, umbenannten oder entfernten Seiten nicht im zugehoerigen `*-Index.md`), oder solange `wiki_check.py` einen Fehler meldet. Das macht die Pflicht-Updates unten verbindlich.

## Mandatory After Every Content Change

1. Update relevant index files (`Themen-Index.md`, `Konzepte-Index.md`, `Personen-Index.md`, `Projekte-Index.md`, `Quellen-Index.md`)
2. Update `wiki/index.md` — "Letzte Aktualisierungen" table and statistics
3. Every `.md` page needs YAML frontmatter: `title`, `created` (YYYY-MM-DD), `type`, optional `tags`
4. Use `[[Wikilinks]]` for internal cross-references

## Answering User Questions

1. Search `wiki/` first, then `raw/`, then `Clippings/`
2. Synthesize answer from found material
3. Write findings back into wiki as new or updated pages

## Ingesting New Sources

Sources come from `raw/` files or `Clippings/` articles (Web Clipper).

1. Create/update source entry in `wiki/quellen/`
2. Extract concepts → `wiki/konzepte/`
3. Create/extend topical articles in `wiki/themen/`
4. Link people → `wiki/personen/`, projects → `wiki/projekte/`
5. Save referenced images locally and fix paths
6. Update all relevant index files
