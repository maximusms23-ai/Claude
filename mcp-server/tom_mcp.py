"""Tom MCP Server — Read-only Bridge zu Toms CLI-Tools.

Exponiert tom-doc, tom-wiki und tom-ask als MCP-Tools via stdio-Transport.
Alle Tools sind Read-only. Kein Write-Zugriff ueber MCP.

Architektur: FastMCP v3 standalone + async subprocess (AWS-MCP-Pattern).
Referenz: ADR-006 in .planning/obsidian-plugin-config/adr-006-mcp-architecture.md
"""

from __future__ import annotations

import asyncio
import os
import shutil

from fastmcp import FastMCP

TOM_VAULT = os.environ.get(
    "TOM_VAULT",
    "/Users/maxim/Library/Mobile Documents/"
    "com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw",
)

mcp = FastMCP(
    "Tom Tools",
    instructions=(
        "Read-only Zugriff auf Toms Wissens- und Dokumenten-Tools. "
        "tom_doc_* durchsucht persoenliche Dokumente (Archiv). "
        "tom_wiki_query beantwortet Fragen aus dem oeffentlichen Wiki. "
        "tom_ask beantwortet Fragen via RAG ueber Wiki, Clippings und Brain."
    ),
)


def _resolve_tool(name: str) -> str:
    """Resolve tool path — ~/bin/ symlinks or absolute path in bin/."""
    home_bin = os.path.expanduser(f"~/bin/{name}")
    if os.path.isfile(home_bin) and os.access(home_bin, os.X_OK):
        return home_bin
    repo_bin = os.path.join(os.path.dirname(__file__), "..", "bin", name)
    if os.path.isfile(repo_bin) and os.access(repo_bin, os.X_OK):
        return os.path.abspath(repo_bin)
    found = shutil.which(name)
    if found:
        return found
    return name


async def _run_tool(cmd: list[str], timeout: int = 60) -> str:
    """Async subprocess mit Timeout und Cleanup (AWS-MCP-Pattern)."""
    env = {
        **os.environ,
        "TOM_VAULT": TOM_VAULT,
        "OLLAMA_MODELS": os.environ.get("OLLAMA_MODELS", "/Users/maxim/Ollama"),
    }

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env=env,
    )
    try:
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout)
    except asyncio.TimeoutError:
        proc.kill()
        await proc.wait()
        return f"FEHLER: Timeout nach {timeout}s bei Kommando: {' '.join(cmd)}"

    if proc.returncode != 0:
        err = stderr.decode(errors="replace").strip()
        return f"FEHLER (exit {proc.returncode}): {err}"

    return stdout.decode(errors="replace").strip()


@mcp.tool
async def tom_doc_search(query: str, limit: int = 10) -> str:
    """Volltextsuche ueber persoenliche Dokumente im Archiv.

    Durchsucht OCR-indexierte PDFs aus ~/Downloads/Archiv/ und $TOM_VAULT/raw/
    via SQLite FTS5. Gibt Treffer mit Kategorie, Dateiname und Text-Snippet zurueck.

    Args:
        query: Suchbegriff(e) fuer die FTS5-Volltextsuche.
        limit: Maximale Anzahl Treffer (default 10).
    """
    tool = _resolve_tool("tom-doc")
    return await _run_tool([tool, "search", query, "--limit", str(limit)])


@mcp.tool
async def tom_doc_list(kategorie: str = "") -> str:
    """Liste indexierter Dokumente im Archiv.

    Zeigt alle indizierten Dokumente, optional gefiltert nach Archiv-Kategorie
    (z.B. '07 Vertraege', '13 Betreuung').

    Args:
        kategorie: Optional — Archiv-Kategorie zum Filtern.
    """
    tool = _resolve_tool("tom-doc")
    cmd = [tool, "list"]
    if kategorie:
        cmd.append(kategorie)
    return await _run_tool(cmd)


@mcp.tool
async def tom_doc_show(identifier: str) -> str:
    """Einzeldokument anzeigen — Metadaten und Text-Auszug.

    Zeigt Details zu einem spezifischen Dokument: Kategorie, Dateipfad,
    Seitenanzahl und einen Textauszug.

    Args:
        identifier: Dokument-ID (Zahl), Dateipfad oder Dateiname.
    """
    tool = _resolve_tool("tom-doc")
    return await _run_tool([tool, "show", identifier])


@mcp.tool
async def tom_wiki_query(question: str) -> str:
    """Karpathy-Index-first Query gegen das oeffentliche Wiki (90_Wiki/).

    Beantwortet Wissensfragen durch LLM-Reasoning ueber den Wiki-Index
    via qwen2.5:3b (lokal). Praeziser als RAG fuer bekannte Themen.
    Braucht laufendes Ollama.

    Args:
        question: Die Wissensfrage auf Deutsch oder Englisch.
    """
    tool = _resolve_tool("tom-wiki")
    return await _run_tool([tool, question], timeout=120)


@mcp.tool
async def tom_ask(question: str) -> str:
    """RAG-Query ueber Wiki, Clippings und Brain via ChromaDB.

    Beantwortet Fragen durch Cosine-Similarity-Suche ueber drei Collections
    (wiki, clippings, gehirn) mit qwen2.5:3b Synthese. Fuzzy-Fallback wenn
    tom_wiki_query nichts findet. Braucht Ollama + indexierte ChromaDB.

    Args:
        question: Die Frage auf Deutsch oder Englisch.
    """
    tool = _resolve_tool("tom-ask")
    return await _run_tool([tool, question], timeout=120)


if __name__ == "__main__":
    mcp.run()
