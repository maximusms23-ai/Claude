"""Tom MCP Server — Read-only Bridge zu Toms CLI-Tools.

Exponiert tom-doc (inkl. multi-search), tom-wiki und tom-ask als MCP-Tools via stdio-Transport.
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
        "tom_doc_multi_search: RAG-Anything/LightRAG, konfigurierbar (Opt-in-Manifest). "
        "tom_wiki_query / tom_ask: Standard ist Anthropic (ANTHROPIC_API_KEY), "
        "Embeddings+Chroma lokal; optionales Ollama nur bei Legacy-Env."
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
async def tom_doc_multi_search(
    query: str, mode: str = "mix"
) -> str:
    """Multimodale Dokumenten-Abfrage via RAG-Anything (LightRAG, konfigurierbarer LLM-Endpoint).

    Laeuft nur wenn rag-anything-env und Opt-in-Manifest unter
    archivum/rag-anything/rag_index_manifest.json gesetzt sind (siehe Phase-48-Doku).
    LLM-Endpoint in Konfiguration — historisch oft Ollama-11434; kein fester Default im Tool.
    Read-only — keine Index-Aenderung.

    Args:
        query: Frage auf Deutsch oder Englisch.
        mode: LightRAG-Modus: local, global, hybrid, naive, mix (default), bypass.
    """
    tool = _resolve_tool("tom-doc")
    cmd = [tool, "multi-search", query, "--mode", mode]
    return await _run_tool(cmd, timeout=180)


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

    Synthese-Default: Anthropic (ANTHROPIC_API_KEY, siehe TOM_ANTHROPIC_MODEL).
    Optional: Ollama nur mit Legacy-Env. Praezise fuer bekannte Themen.
    Lokal: indexierter Content; fuer Ausfuehrung API-Key bzw. Legacy-Ollama.

    Args:
        question: Die Wissensfrage auf Deutsch oder Englisch.
    """
    tool = _resolve_tool("tom-wiki")
    return await _run_tool([tool, question], timeout=120)


@mcp.tool
async def tom_ask(question: str) -> str:
    """RAG-Query ueber Wiki, Clippings und Brain via ChromaDB.

    Retrieval: Chroma (wiki, clippings, gehirn) — Embeddings lokal.
    Synthese-Default: Anthropic (ANTHROPIC_API_KEY). Optional: Ollama-Backend
    (TOM_RAG_GENERATION_BACKEND=ollama). Fuzzy-Fallback in der Toolchain.
    Voraussetzung: indexierte ChromaDB; fuer Anthropic-Default zusaetzlich API-Key.

    Args:
        question: Die Frage auf Deutsch oder Englisch.
    """
    tool = _resolve_tool("tom-ask")
    return await _run_tool([tool, question], timeout=120)


_VAULT_WRITE_ROOTS = (
    "30_Projekte",
    "40_Aufgaben",
    "90_Wiki",
    "95_Gehirn",
    "00_Inbox",
)
_VAULT_WRITE_FILES = ("log.md", "index.md")

# Wenn TOM_MCP_VAULT_FULL_ACCESS=1, wird die Whitelist deaktiviert und der Server
# erlaubt Read/Write/List unter jedem Vault-Pfad (raw/, Clippings/, Archiv/,
# 99_Vorlagen/, 10_Personen/, 20_Dokumente/, 50_Gesundheit/, 60_Finanzen/,
# 70_Hardware/, 80_Social_Media/ inklusive). Path-Traversal-Schutz bleibt aktiv.
_VAULT_FULL_ACCESS = os.environ.get("TOM_MCP_VAULT_FULL_ACCESS", "0") == "1"


def _resolve_vault_path(relpath: str) -> str:
    """Resolve relpath under TOM_VAULT, reject traversal.

    Returns absolute path. Raises ValueError if path escapes vault. Wenn
    TOM_MCP_VAULT_FULL_ACCESS=1 ist die Whitelist aufgehoben (alle Vault-Roots
    erlaubt). Sonst beschraenkt auf _VAULT_WRITE_ROOTS + _VAULT_WRITE_FILES.
    """
    if not relpath or relpath.startswith("/") or ".." in relpath.split("/"):
        raise ValueError(f"Pfad ungueltig (absolut oder traversal): {relpath}")
    vault = os.path.realpath(TOM_VAULT)
    target = os.path.realpath(os.path.join(vault, relpath))
    if not (target == vault or target.startswith(vault + os.sep)):
        raise ValueError(f"Pfad ausserhalb Vault: {relpath}")
    if _VAULT_FULL_ACCESS:
        return target
    rel_resolved = os.path.relpath(target, vault)
    first = rel_resolved.split(os.sep, 1)[0]
    if first in _VAULT_WRITE_ROOTS:
        return target
    if rel_resolved in _VAULT_WRITE_FILES:
        return target
    raise ValueError(
        f"Schreiben nicht erlaubt unter '{first}'. "
        f"Erlaubt: {_VAULT_WRITE_ROOTS} + {_VAULT_WRITE_FILES} "
        f"(setze TOM_MCP_VAULT_FULL_ACCESS=1 um Whitelist aufzuheben)"
    )


@mcp.tool
async def tom_vault_write_note(relpath: str, content: str, overwrite: bool = False) -> str:
    """Schreibt eine neue Markdown-Note in den Vault.

    Erlaubte Zielordner: 30_Projekte, 40_Aufgaben, 90_Wiki, 95_Gehirn, 00_Inbox.
    Verboten: raw/, Clippings/, Archiv/, 99_Vorlagen/, 10_Personen/, 20_Dokumente/,
    50_Gesundheit/, 60_Finanzen/, 70_Hardware/, 80_Social_Media/.

    Path-Traversal wird verworfen. Standard: ueberschreibt nicht (overwrite=False).

    Args:
        relpath: Relativer Pfad ab Vault-Root, z.B. "90_Wiki/themen/neues-thema.md".
        content: Markdown-Inhalt inkl. Frontmatter (title, created, type).
        overwrite: Wenn True, ueberschreibt existierende Datei.
    """
    try:
        target = _resolve_vault_path(relpath)
    except ValueError as e:
        return f"FEHLER: {e}"
    if os.path.exists(target) and not overwrite:
        return f"FEHLER: Datei existiert bereits: {relpath} (overwrite=False)"
    os.makedirs(os.path.dirname(target), exist_ok=True)
    try:
        with open(target, "w", encoding="utf-8") as f:
            f.write(content)
    except OSError as e:
        return f"FEHLER beim Schreiben: {e}"
    return f"OK: geschrieben {relpath} ({len(content)} bytes)"


@mcp.tool
async def tom_vault_append(relpath: str, content: str) -> str:
    """Haengt Text an eine existierende Datei im Vault an (idempotent durch Aufrufer).

    Erlaubte Ziele: 30_Projekte, 40_Aufgaben, 90_Wiki, 95_Gehirn, 00_Inbox,
    plus log.md und index.md im Vault-Root.

    Args:
        relpath: Relativer Pfad, z.B. "log.md" oder "30_Projekte/Tom.md".
        content: Text der angehaengt wird (kein impliziter Newline-Prefix).
    """
    try:
        target = _resolve_vault_path(relpath)
    except ValueError as e:
        return f"FEHLER: {e}"
    if not os.path.exists(target):
        return f"FEHLER: Datei existiert nicht: {relpath}"
    try:
        with open(target, "a", encoding="utf-8") as f:
            f.write(content)
    except OSError as e:
        return f"FEHLER beim Anhaengen: {e}"
    return f"OK: angehaengt an {relpath} ({len(content)} bytes)"


@mcp.tool
async def tom_vault_read(relpath: str, max_bytes: int = 65536) -> str:
    """Liest eine Datei aus dem Vault (read-only Komplement zu write/append).

    Akzeptiert dieselbe Whitelist wie Schreiben PLUS index.md/log.md im Root.
    raw/, Clippings/, Archiv/ bleiben verboten (Privacy).

    Args:
        relpath: Relativer Pfad ab Vault-Root.
        max_bytes: Maximalgroesse fuer Rueckgabe (default 64 KB).
    """
    try:
        target = _resolve_vault_path(relpath)
    except ValueError as e:
        return f"FEHLER: {e}"
    if not os.path.exists(target):
        return f"FEHLER: Datei existiert nicht: {relpath}"
    try:
        with open(target, "rb") as f:
            data = f.read(max_bytes + 1)
    except OSError as e:
        return f"FEHLER beim Lesen: {e}"
    truncated = len(data) > max_bytes
    text = data[:max_bytes].decode("utf-8", errors="replace")
    if truncated:
        text += f"\n\n[... abgeschnitten bei {max_bytes} bytes ...]"
    return text


@mcp.tool
async def tom_vault_list(relpath: str = "") -> str:
    """Listet Dateien/Ordner im Vault (max. 200 Eintraege, 1 Ebene).

    Args:
        relpath: Relativer Ordner-Pfad, leer = Vault-Root.
    """
    vault = os.path.realpath(TOM_VAULT)
    if relpath:
        if relpath.startswith("/") or ".." in relpath.split("/"):
            return f"FEHLER: Pfad ungueltig: {relpath}"
        target = os.path.realpath(os.path.join(vault, relpath))
        if not (target == vault or target.startswith(vault + os.sep)):
            return f"FEHLER: Pfad ausserhalb Vault: {relpath}"
    else:
        target = vault
    if not os.path.isdir(target):
        return f"FEHLER: kein Verzeichnis: {relpath or '<root>'}"
    try:
        entries = sorted(os.listdir(target))[:200]
    except OSError as e:
        return f"FEHLER: {e}"
    out = []
    for name in entries:
        full = os.path.join(target, name)
        kind = "d" if os.path.isdir(full) else "f"
        out.append(f"{kind} {name}")
    return "\n".join(out) if out else "(leer)"


if __name__ == "__main__":
    mcp.run()
