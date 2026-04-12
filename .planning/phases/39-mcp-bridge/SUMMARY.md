# Phase 39: MCP-Bridge für Tom-CLIs — Summary

**Milestone:** v1.5
**Status:** Done
**Date:** 2026-04-12

## Goal

Tom's Lese-CLI-Tools als MCP-Tools in Cursor verfügbar machen — ohne Kontextwechsel ins Terminal.

## Results

### Shipped

1. **`mcp-server/tom_mcp.py`** — FastMCP v3.2.3 Server mit 5 async Tools
   - `tom_doc_search(query, limit)` — FTS5-Volltextsuche über Archiv
   - `tom_doc_list(kategorie)` — Liste indexierter Dokumente
   - `tom_doc_show(identifier)` — Einzeldokument Metadaten + Auszug
   - `tom_wiki_query(question)` — Karpathy-Index-first Wiki-Query
   - `tom_ask(question)` — RAG über 3 Collections

2. **`.cursor/mcp.json`** — Cursor MCP-Client-Config mit `uv run` Spawn

3. **ADR-006** — Architektur-Entscheidung dokumentiert in `.planning/obsidian-plugin-config/adr-006-mcp-architecture.md`

4. **CLAUDE.md** — Neue Sektion "MCP-Bridge für Tom-CLIs" mit Tools, Privacy, Troubleshooting

### Key Decisions

- **FastMCP v3 standalone** statt SDK-bundled oder raw SDK
- **Async subprocess** (`asyncio.create_subprocess_exec`) statt blocking `subprocess.run` — AWS-MCP-Pattern
- **Cursor als Primär-Client** statt Obsidian `mcp-tools` Plugin (das kein generischer MCP-Client ist)
- **`tom-clip-enrich` nicht exponiert** — Write-Zugriff über MCP ist Privacy-Risiko
- **`uv run`** in Cursor-Config für automatische Dependency-Auflösung

### Re-scoped Requirements

- MCP-05: `tom-clip-enrich` bewusst excluded (Write-Risiko)
- MCP-07: Re-scoped von Obsidian `mcp-tools` auf Cursor `.cursor/mcp.json`
- MCP-08: Re-scoped von Obsidian MCP-Panel auf Cursor Tool-Call

## Kritische Recherche-Ergebnisse

1. `mcp-tools` v0.2.27 ist kein generischer MCP-Client — bündelt eigenen Server-Binary für Claude Desktop
2. FastMCP v3 standalone (`pip install fastmcp`) ist De-facto-Standard mit ~70% Marktanteil
3. `asyncio.create_subprocess_exec` + `asyncio.wait_for` ist das Best-Practice-Pattern (AWS-MCP-Server)
4. `obsidian-mcp-pro` als komplementärer Server für generische Vault-Ops (nicht in Phase 39)

## Files Changed

- `mcp-server/tom_mcp.py` (new)
- `mcp-server/pyproject.toml` (new)
- `.cursor/mcp.json` (new)
- `.planning/obsidian-plugin-config/adr-006-mcp-architecture.md` (new)
- `CLAUDE.md` (MCP-Bridge Sektion)
- `.planning/REQUIREMENTS.md` (MCP-01..09 markiert)
- `.planning/ROADMAP.md` (Phase 39 ✓)
- `.planning/STATE.md` (Phase 39 Done)
