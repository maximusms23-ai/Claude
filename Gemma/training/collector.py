"""Q&A-Paare aus Wiki-Inhalten via Self-Instruct generieren."""

import argparse
import hashlib
import json
import sys
from datetime import date
from pathlib import Path

import ollama
import yaml

sys.path.insert(0, str(Path(__file__).parent / "../rag"))
from config import WIKI_PATH, MODEL, TRAINING_DATA_PATH


GENERATE_PROMPT = """Du bekommst einen Wiki-Artikel. Generiere daraus {n} verschiedene Frage-Antwort-Paare auf Deutsch.
Die Fragen sollen natuerlich klingen, als wuerde ein Nutzer sie stellen.
Die Antworten sollen praezise und nur auf dem Artikelinhalt basieren.

Gib die Paare als JSON-Array zurueck, z.B.:
[{{"q": "Was ist X?", "a": "X ist ..."}}, ...]

Nur das JSON-Array, kein anderer Text.

---
Artikel:
{text}"""


def load_existing_hashes(output_path: Path) -> set[str]:
    """Bereits generierte Instructions laden (Deduplizierung)."""
    hashes = set()
    if output_path.exists():
        for line in output_path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                entry = json.loads(line)
                hashes.add(hashlib.sha256(entry["instruction"].encode()).hexdigest())
    return hashes


def generate_pairs(text: str, n: int = 3) -> list[dict]:
    """Via lokalem Qwen-Stack Q&A-Paare generieren."""
    prompt = GENERATE_PROMPT.format(n=n, text=text[:2000])
    response = ollama.chat(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
    )
    content = response["message"]["content"].strip()
    # JSON aus Antwort extrahieren
    start = content.find("[")
    end = content.rfind("]") + 1
    if start == -1 or end == 0:
        return []
    try:
        pairs = json.loads(content[start:end])
        return [p for p in pairs if "q" in p and "a" in p]
    except json.JSONDecodeError:
        return []


def collect(limit: int | None = None, pairs_per_page: int = 3):
    """Wiki-Seiten durchgehen und Q&A-Paare generieren."""
    wiki_path = WIKI_PATH.resolve()
    if not wiki_path.exists():
        print(f"Wiki-Pfad nicht gefunden: {wiki_path}")
        sys.exit(1)

    output_path = TRAINING_DATA_PATH / "qa_pairs.jsonl"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    existing = load_existing_hashes(output_path)

    md_files = sorted(wiki_path.rglob("*.md"))
    if limit:
        md_files = md_files[:limit]

    print(f"Verarbeite {len(md_files)} Dateien...")
    new_count = 0

    with open(output_path, "a", encoding="utf-8") as f:
        for filepath in md_files:
            rel_path = str(filepath.relative_to(wiki_path))
            text = filepath.read_text(encoding="utf-8")

            # Frontmatter entfernen
            if text.startswith("---"):
                parts = text.split("---", 2)
                if len(parts) >= 3:
                    text = parts[2].strip()

            if len(text) < 100:
                continue

            print(f"  {rel_path}...", end=" ", flush=True)
            pairs = generate_pairs(text, n=pairs_per_page)

            added = 0
            for pair in pairs:
                h = hashlib.sha256(pair["q"].encode()).hexdigest()
                if h in existing:
                    continue
                existing.add(h)
                entry = {
                    "instruction": pair["q"],
                    "input": "",
                    "output": pair["a"],
                    "source": f"wiki/{rel_path}",
                    "created": str(date.today()),
                }
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")
                added += 1
                new_count += 1

            print(f"{added} Paare")

    print(f"\nFertig: {new_count} neue Paare in {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Q&A-Paare aus Wiki generieren")
    parser.add_argument("--limit", type=int, default=None, help="Max. Anzahl Dateien")
    parser.add_argument("--pairs", type=int, default=3, help="Paare pro Seite")
    args = parser.parse_args()
    collect(limit=args.limit, pairs_per_page=args.pairs)
