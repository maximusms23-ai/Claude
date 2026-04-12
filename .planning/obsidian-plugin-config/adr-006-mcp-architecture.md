---
title: "ADR-006: MCP-Bridge-Architektur für Tom-CLIs"
created: 2026-04-12
type: adr
status: accepted
tags: [adr, mcp, fastmcp, cursor, v1.5, phase-39]
---

# ADR-006: MCP-Bridge-Architektur für Tom-CLIs

**Status:** Accepted
**Date:** 2026-04-12
**Milestone:** v1.5 (Phase 39 — MCP-Bridge)
**Deciders:** Maxim, Tom

## Context

Tom hat 4 Lese-CLI-Tools (`tom-doc`, `tom-wiki`, `tom-ask`, `tom-clip-enrich`), die bisher nur vom Terminal aus nutzbar sind. Phase 39 soll diese Tools über das Model Context Protocol (MCP) aus der IDE heraus aufrufbar machen — idealerweise ohne Kontextwechsel in ein Terminal.

In ADR-004 (v1.4.1) wurde `mcp-tools` v0.2.27 als v1.5-Integrationskandidat identifiziert. Die nachfolgende Recherche zeigt, dass die ursprüngliche Annahme — `mcp-tools` als generischer MCP-Client für eigene Server — nicht zutrifft.

### Recherche-Ergebnisse (2026-04-12)

**Obsidian `mcp-tools` Plugin (v0.2.27, Jack Steam):**
- Bündelt einen eigenen Server-Binary und registriert sich in Claude Desktop.
- Bietet Vault-spezifische Tools (Semantic Search, File Management, Templates).
- Ist **kein generischer MCP-Client** — kann keine beliebigen MCP-Server einbinden.
- Für Tom's custom Backends (FTS5, ChromaDB, Karpathy-Index) nicht nutzbar.

**Existierende Obsidian-MCP-Server (GitHub-Recherche):**
- `obsidian-mcp-pro` (TypeScript, 23 generische Vault-Tools) — komplementär, nicht Tom-ersetzend
- `fast-obsidian-mcp` (Python, 1 generisches Tool via SKILL.md) — anderes Paradigma
- `obsidian-vault-mcp`, `lstpsche/obsidian-mcp` — generische Vault-Wrapper, kein Zugriff auf Tom-Backends

**FastMCP-Landschaft (April 2026):**
- **Standalone FastMCP v3.x** (`pip install fastmcp`): De-facto-Standard, Dekoratoren, CLI, OpenTelemetry
- **SDK-bundled** (`from mcp.server.fastmcp`): Legacy, wird in SDK v2 zu `MCPServer`
- **Raw MCP SDK** (`pip install mcp`): Zu viel Boilerplate für einfache Tool-Wrapper

**Subprocess-Pattern:**
- AWS-MCP-Server (`alexei-led/aws-mcp-server`) als Best-Practice-Referenz: `asyncio.create_subprocess_exec` + `asyncio.wait_for` für Timeouts + `proc.kill()` + `await proc.wait()` für Cleanup
- Blocking `subprocess.run` ist Anti-Pattern in MCP-Servern (blockiert Event-Loop)

## Decision

### 1. FastMCP v3 standalone als Server-Framework

`pip install fastmcp` (standalone, nicht SDK-bundled). Dekoratoren-basierte Tool-Definition, stdio-Transport.

### 2. Cursor als Primär-Client

Registrierung in `.cursor/mcp.json`. Cursor startet den Server automatisch beim Launch via stdio-Spawn.

### 3. Async subprocess mit Timeouts

Jedes Tool ruft das CLI per `asyncio.create_subprocess_exec` auf — non-blocking, mit `asyncio.wait_for(timeout)` und `proc.kill()` bei Überschreitung. Referenz-Pattern: AWS-MCP-Server.

### 4. Nur Read-only-Tools

5 Tools: `tom_doc_search`, `tom_doc_list`, `tom_doc_show`, `tom_wiki_query`, `tom_ask`.
Kein Write-Zugriff über MCP. `tom-clip-enrich` bewusst ausgeschlossen.

### 5. `tom-clip-enrich` nicht exponiert

`tom-clip-enrich` schreibt in Vault-Dateien. Write-Operationen über MCP sind ein Privacy-Risiko — ein fehlerhafter oder unbeabsichtigter Tool-Call könnte Clippings überschreiben. Die CLI bleibt als einziger Schreibpfad bestehen.

## Privacy-Boundaries

| Tool | Datenquelle | Zugriff | Persönliche Daten |
|------|------------|---------|-------------------|
| `tom_doc_search` | `~/Downloads/Archiv/` + `$TOM_VAULT/raw/` via SQLite FTS5 | Read-only | Ja (Verträge, Arztberichte) |
| `tom_doc_list` | Index-Metadaten | Read-only | Nur Dateinamen |
| `tom_doc_show` | Einzeldokument-Excerpt | Read-only | Ja (Volltext-Auszug) |
| `tom_wiki_query` | `$TOM_VAULT/90_Wiki/` via Karpathy Index | Read-only | Nein (öffentlich) |
| `tom_ask` | ChromaDB (wiki + clippings + gehirn) | Read-only | Teilweise (gehirn) |

**Kein Tool schreibt Dateien.** Alle Ergebnisse fließen nur als Text-Response zurück an den MCP-Client.

## Alternatives Considered

1. **Obsidian `mcp-tools` Plugin als Client**: Verworfen — ist kein generischer MCP-Client, nur eigener Server für Claude Desktop.
2. **Raw MCP SDK**: Verworfen — zu viel Boilerplate (Handler, Schema-Definitionen) für 5 einfache Tools.
3. **SDK-bundled FastMCP (`from mcp.server.fastmcp`)**: Verworfen — Legacy, wird in SDK v2 umbenannt.
4. **HTTP-Transport**: Verworfen — Overkill für lokalen Single-User-Einsatz, stdio reicht.
5. **1 generisches Tool mit SKILL.md (à la `fast-obsidian-mcp`)**: Verworfen — schlechte Discoverability, kein JSON-Schema pro Tool, LLM muss SKILL.md parsen.
6. **Blocking `subprocess.run`**: Verworfen — blockiert Event-Loop, Anti-Pattern in async MCP-Servern.
7. **`tom-clip-enrich` als `--dry-run` Tool**: Verworfen — `--dry-run` Output ist für MCP-Clients wenig nützlich, und der Kompromiss verschleiert die bewusste Read-only-Entscheidung.

## Complementary Recommendation (not Phase 39)

`obsidian-mcp-pro` (`npx -y obsidian-mcp-pro`) als zweiter MCP-Server für generische Vault-Operationen (Search, Read, Tags, Links). Unabhängig von Tom-MCP, kann in separater Phase evaluiert werden.

## Consequences

- `mcp-tools` bleibt installed-but-unused für seinen eigenen Zweck (Claude Desktop).
- Tom-MCP ist ein separater, unabhängiger Server in `mcp-server/`.
- Cursor wird zum Primär-Client für MCP-Tool-Aufrufe.
- ADR-004 bleibt gültig (mcp-tools als Kandidat für Claude Desktop), wird durch ADR-006 nicht invalidiert.
- Write-Zugriff (enrichment, inject) bleibt CLI-exklusiv.

## References

- [FastMCP v3 Docs](https://gofastmcp.com/)
- [Model Context Protocol Spec](https://modelcontextprotocol.io/)
- [AWS-MCP-Server (async subprocess pattern)](https://github.com/alexei-led/aws-mcp-server)
- ADR-004: `mcp-tools` als v1.5-Integrationskandidat
- CLAUDE.md Sektion "Obsidian Plugin Landscape"
