"""Tom Wiki Query — Karpathy Index-first Retrieval über lokales Gemme.

Liest den Karpathy-Index-Gerüst einer Wiki-Quelle (default 90_Wiki/, optional
95_Gehirn/ via --brain), injiziert Index + per Keyword gefilterte Top-K-Artikel
in den Prompt, und lässt das lokale Ollama-Modell (`gemme`) synthetisieren.
Kein RAG, keine Embeddings — bei 20–500 Artikeln präziser als Cosine-Similarity.

Usage:
    python -m tom_tools.wiki_query "Was ist Turboquant?"
    python -m tom_tools.wiki_query --brain "Welches Pattern haben wir für X?"
    python -m tom_tools.wiki_query --root /path/to/wiki "Frage"
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

try:
    import ollama
except ImportError:
    print("Error: ollama Python-Package fehlt. Install: `uv pip install ollama`", file=sys.stderr)
    sys.exit(1)


MODEL = "gemme"
MAX_CONTEXT_CHARS = 100_000  # gemma4:e4b kann 128k, wir halten Puffer

TOP_K = 5  # max. Anzahl Artikel zusaetzlich zum Index in den Prompt
MIN_KEYWORD_LEN = 3  # zu kurze Tokens (de, an, in) ignorieren

# Deutsche + englische Stopwords — bewusst klein gehalten
STOPWORDS = {
    "der", "die", "das", "den", "dem", "des", "ein", "eine", "einen", "einem", "einer",
    "und", "oder", "aber", "wenn", "dann", "weil", "dass", "ob", "als", "wie",
    "ist", "sind", "war", "waren", "wird", "werden", "hat", "haben", "hatte", "gibt",
    "was", "wer", "wo", "wann", "warum", "welche", "welcher", "welches",
    "ich", "du", "er", "sie", "es", "wir", "ihr", "mich", "dich", "uns",
    "in", "an", "auf", "fuer", "von", "mit", "bei", "zu", "zum", "zur",
    "the", "a", "an", "is", "are", "was", "were", "of", "to", "and", "or", "what",
    "how", "why", "when", "where", "which", "this", "that",
}


def default_vault() -> Path:
    return Path(
        os.environ.get(
            "TOM_VAULT",
            "/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/"
            "Obsidian_Valuet/Obsidian_Zentralw",
        )
    )


def extract_keywords(question: str) -> list[str]:
    """Simple Tokenisierung: lowercased, Stopwords gefiltert, min Laenge."""
    tokens = re.findall(r"[\w\u00c0-\u017f]+", question.lower())
    return [
        t for t in tokens
        if len(t) >= MIN_KEYWORD_LEN and t not in STOPWORDS
    ]


def score_article(content: str, keywords: list[str]) -> int:
    """Score = Treffer im Titel + ersten 500 Zeichen + Headern. Hoeher = relevanter."""
    if not keywords:
        return 0
    text = content.lower()
    head = text[:500]
    score = 0
    for kw in keywords:
        # Titel/Header bekommen 5x Gewicht (erste Zeile + alle # Headers)
        first_line = text.split("\n", 1)[0]
        if kw in first_line:
            score += 5
        # Header-Zeilen
        for line in text.split("\n"):
            if line.startswith("#") and kw in line:
                score += 3
        # Erster Absatz
        if kw in head:
            score += 2
        # Restlicher Text (einmal pro Vorkommen, capped)
        score += min(text.count(kw), 5)
    return score


def collect_wiki_content(root: Path, question: str) -> tuple[str, list[str]]:
    """Karpathy-Stil mit Keyword-Filter: Index immer, plus Top-K relevante Artikel.

    Returns (prompt_text, list_of_source_paths_actually_loaded).
    """
    if not root.exists():
        raise FileNotFoundError(f"Wiki-Root existiert nicht: {root}")

    keywords = extract_keywords(question)

    index_file = root / "index.md"
    parts: list[str] = []
    sources: list[str] = []

    if index_file.exists():
        parts.append(
            f"## INDEX ({index_file.relative_to(root.parent)})\n\n"
            f"{index_file.read_text(encoding='utf-8')}"
        )
        sources.append(str(index_file.relative_to(root.parent)))

    # Alle Artikel scoren
    candidates: list[tuple[int, Path, str]] = []
    for md in sorted(root.rglob("*.md")):
        if md.name in ("index.md", "history.md", "log.md", "CLAUDE.md"):
            continue
        try:
            content = md.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        s = score_article(content, keywords)
        if s > 0:
            candidates.append((s, md, content))

    # Top-K nach Score, deterministisch (Score desc, Pfad asc)
    candidates.sort(key=lambda c: (-c[0], str(c[1])))
    selected = candidates[:TOP_K]

    if not selected:
        parts.append(
            "## (keine Keyword-Matches — nur Index geladen, antworte auf Index-Basis)"
        )
    else:
        for score, md, content in selected:
            rel = md.relative_to(root)
            parts.append(
                f"## {rel}  (relevance={score})\n\n{content}"
            )
            sources.append(f"{root.name}/{rel}")

    full = "\n\n---\n\n".join(parts)
    if len(full) > MAX_CONTEXT_CHARS:
        full = full[:MAX_CONTEXT_CHARS] + (
            "\n\n...(truncated — Top-K bereits applied, fallback tom-ask empfohlen)"
        )
    return full, sources


def query(question: str, root: Path) -> str:
    content, sources = collect_wiki_content(root, question)

    system = (
        "Du bist Tom, ein praeziser deutschsprachiger Wissens-Assistent fuer Maxims persoenliches Wiki. "
        "Du bekommst einen INDEX und maximal 5 per Keyword vorgefilterte Artikel aus der Wissensbasis.\n\n"
        "REGELN (verbindlich):\n"
        "1. Antworte praezise und konkret auf die Frage. Keine generischen Floskeln, keine Wikipedia-Synthese.\n"
        "2. Du MUSST mindestens eine Quelldatei explizit zitieren — als Dateiname (z.B. `turboquant.md`) "
        "   oder als Wikilink (z.B. `[[turboquant]]`). Ohne Zitation ist die Antwort unbrauchbar.\n"
        "3. Wenn die Wissensbasis die Frage nicht beantwortet, sag das explizit: "
        "   'Dazu finde ich im Wiki nichts Konkretes. Naechster Schritt: tom-ask oder neuer Wiki-Artikel.'\n"
        "4. Spekuliere nicht. Wenn du unsicher bist, kennzeichne es als Vermutung.\n"
        "5. Halte die Antwort kurz: 3-8 Saetze, plus Quellenzeile am Ende.\n\n"
        "Format der Antwort:\n"
        "  <eigentliche Antwort in 3-8 Saetzen>\n"
        "  Quelle: <dateiname.md> oder [[wikilink]]\n"
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
    return f"{answer}\n\nQuellen-Scope (Index + Top-{TOP_K} Keyword-Matches):\n{src_list}"


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
