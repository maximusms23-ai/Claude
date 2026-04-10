"""Tom Wiki Query — Karpathy Index-first Retrieval über lokales Gemme.

Liest den Karpathy-Index-Gerüst einer Wiki-Quelle (default 90_Wiki/, optional
95_Gehirn/ via --brain), injiziert ihn + alle Artikel in den Prompt, und lässt
das lokale Ollama-Modell (`gemme`) synthetisieren. Kein RAG, keine Embeddings
— bei 20–500 Artikeln präziser als Cosine-Similarity.

Usage:
    python -m tom_tools.wiki_query "Was ist Turboquant?"
    python -m tom_tools.wiki_query --brain "Welches Pattern haben wir für X?"
    python -m tom_tools.wiki_query --root /path/to/wiki "Frage"
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

try:
    import ollama
except ImportError:
    print("Error: ollama Python-Package fehlt. Install: `uv pip install ollama`", file=sys.stderr)
    sys.exit(1)


MODEL = "gemme"
MAX_CONTEXT_CHARS = 100_000  # gemma4:e4b kann 128k, wir halten Puffer


def default_vault() -> Path:
    return Path(
        os.environ.get(
            "TOM_VAULT",
            "/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/"
            "Obsidian_Valuet/Obsidian_Zentralw",
        )
    )


def collect_wiki_content(root: Path) -> tuple[str, list[str]]:
    """Karpathy-Stil: Index zuerst, dann alle Artikel.

    Returns (prompt_text, list_of_source_paths).
    """
    if not root.exists():
        raise FileNotFoundError(f"Wiki-Root existiert nicht: {root}")

    index_file = root / "index.md"
    parts: list[str] = []
    sources: list[str] = []

    if index_file.exists():
        parts.append(f"## INDEX ({index_file.relative_to(root.parent)})\n\n{index_file.read_text(encoding='utf-8')}")
        sources.append(str(index_file.relative_to(root.parent)))

    for md in sorted(root.rglob("*.md")):
        if md.name in ("index.md", "history.md", "log.md", "CLAUDE.md"):
            continue
        rel = md.relative_to(root)
        content = md.read_text(encoding="utf-8")
        parts.append(f"## {rel}\n\n{content}")
        sources.append(f"{root.name}/{rel}")

    full = "\n\n---\n\n".join(parts)
    if len(full) > MAX_CONTEXT_CHARS:
        full = full[:MAX_CONTEXT_CHARS] + "\n\n...(truncated — wiki zu groß für Single-Prompt, Fallback auf tom-ask empfohlen)"
    return full, sources


def query(question: str, root: Path) -> str:
    content, sources = collect_wiki_content(root)
    system = (
        "Du bist Tom, ein deutschsprachiger Wissens-Assistent. Du bekommst einen "
        "Index und alle Artikel einer Wissensbasis. Lies zuerst den Index, wähle "
        "3–5 relevante Artikel, und synthesisiere eine klare Antwort auf Deutsch. "
        "Zitiere Quellen via [[wikilink]]. Wenn nichts passt, sag das ehrlich."
    )
    prompt = f"## Wissensbasis\n\n{content}\n\n---\n\n## Frage\n\n{question}"

    response = ollama.chat(
        model=MODEL,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": prompt},
        ],
    )
    answer = response["message"]["content"]

    src_list = "\n".join(f"  - {s}" for s in sources[:20])
    return f"{answer}\n\nQuellen-Scope (Index-first):\n{src_list}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Tom Wiki Query — Karpathy Index-first")
    parser.add_argument("question", nargs="+", help="Die Frage")
    parser.add_argument(
        "--brain",
        action="store_true",
        help="Gegen 95_Gehirn/ statt 90_Wiki/ abfragen (internal data)",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="Expliziter Wiki-Root-Pfad (überschreibt --brain / default)",
    )
    args = parser.parse_args()

    if args.root:
        root = args.root
    elif args.brain:
        root = default_vault() / "95_Gehirn"
    else:
        root = default_vault() / "90_Wiki"

    q = " ".join(args.question)
    try:
        print(query(q, root))
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except Exception as e:  # noqa: BLE001
        print(f"Error: {type(e).__name__}: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
