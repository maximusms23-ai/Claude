#!/usr/bin/env python3
"""
text_tools.py — Text-Transformationen fuer Apple-Kurzbefehle (shortcuts-forge Helper)

Zweck:
    Deterministischer Text-Helper, den generierte Kurzbefehle per
    "Run Shell Script" aufrufen (Payload via stdin, Ergebnis auf stdout).
    Referenz-Implementierung des Helper-Vertrags (siehe shortcuts-forge/README.md).

Usage:
    echo "hallo tom" | text_tools.py --mode upper
    echo "Ein Titel: Ümläute & Co" | text_tools.py --mode slug
    cat datei.txt | text_tools.py --mode stats --json
    printf "b\na\nb\n" | text_tools.py --mode lines

Modi:
    upper   Text in Grossbuchstaben
    slug    URL-/Dateiname-tauglicher Slug (ascii, lowercase, '-')
    stats   Zeichen/Woerter/Zeilen zaehlen
    lines   Zeilen trimmen, deduplizieren, sortieren

Vertrag:
    - Parameter via argv, Payload via stdin (UTF-8)
    - Ergebnis auf stdout; --json liefert einzeiliges JSON
    - Fehler auf stderr + Exit != 0; keine interaktiven Prompts

Dependencies: Python 3 stdlib only (Shortcuts-Shell hat Minimal-PATH).
"""

import argparse
import json
import sys
import unicodedata


def mode_upper(text: str) -> str:
    return text.upper()


def mode_slug(text: str) -> str:
    text = text.strip().lower()
    # Umlaute & Akzente -> ASCII
    text = (
        text.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")
    )
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    out = []
    prev_dash = False
    for ch in text:
        if ch.isalnum():
            out.append(ch)
            prev_dash = False
        elif not prev_dash and out:
            out.append("-")
            prev_dash = True
    return "".join(out).rstrip("-")


def mode_stats(text: str) -> dict:
    lines = text.splitlines()
    return {
        "chars": len(text),
        "words": len(text.split()),
        "lines": len(lines),
        "nonempty_lines": sum(1 for l in lines if l.strip()),
    }


def mode_lines(text: str) -> str:
    seen = set()
    result = []
    for line in text.splitlines():
        line = line.strip()
        if line and line not in seen:
            seen.add(line)
            result.append(line)
    return "\n".join(sorted(result))


def main() -> int:
    parser = argparse.ArgumentParser(description="Text-Helper fuer Apple-Kurzbefehle")
    parser.add_argument(
        "--mode",
        required=True,
        choices=["upper", "slug", "stats", "lines"],
        help="Transformation",
    )
    parser.add_argument(
        "--json", action="store_true", help="Ergebnis als einzeiliges JSON"
    )
    args = parser.parse_args()

    text = sys.stdin.read()
    if not text.strip():
        print("text_tools: leere Eingabe auf stdin", file=sys.stderr)
        return 1

    if args.mode == "stats":
        result = mode_stats(text)
        if args.json:
            print(json.dumps(result, ensure_ascii=False))
        else:
            print("\n".join(f"{k}: {v}" for k, v in result.items()))
        return 0

    func = {"upper": mode_upper, "slug": mode_slug, "lines": mode_lines}[args.mode]
    output = func(text if args.mode != "upper" else text.rstrip("\n"))
    if args.json:
        print(json.dumps({"mode": args.mode, "result": output}, ensure_ascii=False))
    else:
        print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
