"""Tom Clipper Auto-Enrichment — Summary + Tags + Konzepte + Wiki-Kategorie via qwen2.5:3b.

Liest eine Clipping-Datei aus $TOM_VAULT/Clippings/, baut einen strukturierten
Prompt mit Body-Preview, ruft lokales Ollama (`qwen2.5:3b`) mit JSON-Output-Format,
und schreibt die angereicherte Version idempotent zurück. Konzept-Vorschläge
landen als Zeilen in 90_Wiki/konzepte-vorschlaege.md zur manuellen Review.

Usage:
    python -m tom_tools.clip_enrich <clipping-path>
    python -m tom_tools.clip_enrich <clipping-path> --dry-run
    python -m tom_tools.clip_enrich <clipping-path> --force       # ignore enriched flag
    python -m tom_tools.clip_enrich <clipping-path> --queue-only  # nur konzepte-vorschlaege.md,
                                                                  # Frontmatter NICHT überschreiben

Idempotent via Frontmatter-Flag `enriched` (true | clip-time | tom-clip-enrich).

Part of Tom v1.4 — Phase 30 (erweitert in v1.4.1 Phase 35-Hotfix um --queue-only für
Koexistenz mit Web-Clipper-Interpreter, siehe ADR-005).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

import ollama

# ── Config ──────────────────────────────────────────────────────────────────

MODEL = os.environ.get("TOM_CLIP_MODEL", "qwen2.5:3b")
MAX_BODY_CHARS = 6000
DEFAULT_VAULT = Path(os.environ.get(
    "TOM_VAULT",
    "/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw",
))

WIKI_CATEGORIES = ["themen", "konzepte", "personen", "projekte", "quellen"]

SYSTEM_PROMPT = """Du bist Tom, ein persönlicher Assistent, der Wissens-Clippings anreichert.

Deine Aufgabe: Lies den gegebenen Clipping-Text und extrahiere:
1. Eine präzise Zusammenfassung in 3-5 Sätzen auf Deutsch (keine Aufzählung, ganze Sätze)
2. 3-5 treffende Tags (kurze Stichworte ohne Leerzeichen, kleingeschrieben, alle auf Deutsch)
3. 2-4 Konzept-Begriffe, die als eigene Wiki-Artikel sinnvoll wären (Eigennamen, Fachbegriffe, Konzepte)
4. Eine Wiki-Kategorie aus dieser Liste: themen, konzepte, personen, projekte, quellen
   - themen: für allgemeine Themenartikel (z.B. "Mannheim", "Quantencomputer")
   - konzepte: für Fachbegriffe und Ideen (z.B. "Turboquant", "Karpathy-Methode")
   - personen: für fachliche/öffentliche Personen
   - projekte: für Software-Projekte, Tools, Frameworks
   - quellen: für Bücher, Papers, Websites als Quellenreferenz

Antworte AUSSCHLIESSLICH mit validem JSON im folgenden Format, nichts anderes:

{
  "summary": "...",
  "tags": ["tag1", "tag2", "tag3"],
  "concepts": ["Konzept A", "Konzept B"],
  "wiki_category": "themen"
}

Keine Erklärungen, keine Markdown-Codefences, nur das JSON-Objekt."""


# ── Frontmatter I/O ─────────────────────────────────────────────────────────

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def split_frontmatter(text: str) -> tuple[dict, str, str]:
    """Returns (fm_dict, raw_fm_block, body).

    fm_dict is a simple flat parse: strings and lists. Does NOT handle nested maps.
    raw_fm_block is the original YAML text (for preservation if we only append).
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, "", text
    raw_fm = m.group(1)
    body = text[m.end():]
    fm = parse_simple_yaml(raw_fm)
    return fm, raw_fm, body


def parse_simple_yaml(block: str) -> dict:
    """Minimal YAML parser for Obsidian frontmatter. Supports: strings, lists."""
    result: dict = {}
    current_key: str | None = None
    for line in block.splitlines():
        if not line.strip():
            continue
        # List item
        if line.lstrip().startswith("- ") and current_key is not None:
            value = line.lstrip()[2:].strip()
            value = _strip_quotes(value)
            if not isinstance(result.get(current_key), list):
                result[current_key] = []
            result[current_key].append(value)
            continue
        # key: value
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            if val == "":
                # Could be a list starting on next line
                result[key] = []
                current_key = key
            else:
                result[key] = _strip_quotes(val)
                current_key = key
    return result


def _strip_quotes(s: str) -> str:
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def format_frontmatter(fm: dict) -> str:
    """Render the dict back to YAML frontmatter. Preserves key order."""
    lines = []
    for key, val in fm.items():
        if isinstance(val, list):
            lines.append(f"{key}:")
            for item in val:
                lines.append(f'  - "{_yaml_escape(item)}"')
        elif isinstance(val, bool):
            lines.append(f"{key}: {'true' if val else 'false'}")
        elif val is None or val == "":
            lines.append(f"{key}:")
        else:
            s = str(val)
            if "\n" in s or '"' in s or ":" in s:
                lines.append(f'{key}: "{_yaml_escape(s)}"')
            else:
                lines.append(f"{key}: {s}")
    return "\n".join(lines)


def _yaml_escape(s: str) -> str:
    return str(s).replace("\\", "\\\\").replace('"', '\\"')


# ── Qwen Call ───────────────────────────────────────────────────────────────


def enrich_via_model(title: str, body_preview: str) -> dict:
    """Call qwen2.5:3b with JSON-format request. Returns parsed enrichment dict."""
    user_prompt = f"""Titel: {title}

Clipping-Text (gekürzt):
---
{body_preview}
---

Antworte im spezifizierten JSON-Format."""

    response = ollama.chat(
        model=MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        format="json",
        options={"temperature": 0.3, "num_ctx": 8192},
    )
    content = response["message"]["content"]
    try:
        data = json.loads(content)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"qwen returned non-JSON:\n{content[:500]}") from e

    # Validate + normalize
    summary = str(data.get("summary", "")).strip()
    tags = [str(t).strip().lower() for t in data.get("tags", []) if str(t).strip()]
    concepts = [str(c).strip() for c in data.get("concepts", []) if str(c).strip()]
    wiki_cat = str(data.get("wiki_category", "")).strip().lower()
    if wiki_cat not in WIKI_CATEGORIES:
        wiki_cat = "themen"  # safe default
    return {
        "summary": summary,
        "tags": tags[:5],
        "concepts": concepts[:4],
        "wiki_category": wiki_cat,
    }


# ── Body Extraction ─────────────────────────────────────────────────────────

MARKDOWN_LINK_RE = re.compile(r"\[([^\]]+)\]\([^)]+\)")
HTML_TAG_RE = re.compile(r"<[^>]+>")
WIKI_LINK_RE = re.compile(r"!\[\[[^\]]+\]\]|\[\[[^\]]+\]\]")
FOOTNOTE_RE = re.compile(r"\[\^[^\]]+\]")


def clean_body_preview(body: str, max_chars: int = MAX_BODY_CHARS) -> str:
    """Strip links/footnotes/images for cleaner LLM context."""
    text = WIKI_LINK_RE.sub("", body)
    text = MARKDOWN_LINK_RE.sub(r"\1", text)  # keep link text
    text = FOOTNOTE_RE.sub("", text)
    text = HTML_TAG_RE.sub("", text)
    text = re.sub(r"\n{3,}", "\n\n", text).strip()
    if len(text) > max_chars:
        text = text[:max_chars] + "…"
    return text


# ── Konzept-Vorschläge sink ─────────────────────────────────────────────────


def append_concept_suggestions(vault: Path, source_filename: str, concepts: list[str]) -> Path:
    if not concepts:
        return vault / "90_Wiki" / "konzepte-vorschlaege.md"
    target = vault / "90_Wiki" / "konzepte-vorschlaege.md"
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists():
        target.write_text(
            "---\n"
            "title: Konzept-Vorschläge\n"
            "type: review-queue\n"
            f"created: {datetime.now():%Y-%m-%d}\n"
            "---\n\n"
            "# Konzept-Vorschläge zur Wiki-Aufnahme\n\n"
            "Automatisch von `tom-clip-enrich` befüllt. Tom überprüft Vorschläge manuell, "
            "bevor sie als Stub-Seiten in `90_Wiki/konzepte/` landen.\n\n"
            "## Queue\n\n"
        )
    date = datetime.now().strftime("%Y-%m-%d")
    with target.open("a") as f:
        for concept in concepts:
            f.write(f"- [ ] **{concept}** — aus `[[Clippings/{source_filename}]]` ({date})\n")
    return target


# ── Main Apply ──────────────────────────────────────────────────────────────


def _parse_konzepte_field(value) -> list[str]:
    """Parse `konzepte_vorschlaege` frontmatter field (Komma-Liste oder YAML-Liste)."""
    if not value:
        return []
    if isinstance(value, list):
        return [str(c).strip() for c in value if str(c).strip()]
    # String: komma-separiert
    return [c.strip() for c in str(value).split(",") if c.strip()]


def enrich_file(
    path: Path,
    *,
    force: bool = False,
    dry_run: bool = False,
    vault: Path | None = None,
    queue_only: bool = False,
) -> dict:
    if not path.exists():
        raise FileNotFoundError(path)
    vault = vault or DEFAULT_VAULT
    text = path.read_text(errors="replace")
    fm, _raw_fm, body = split_frontmatter(text)

    # Idempotenz: akzeptiert "true", "clip-time", "tom-clip-enrich" als bereits-enriched.
    # ADR-005: Interpreter schreibt `enriched: clip-time` + `enriched_by: qwen-interpreter`,
    # tom-clip-enrich (legacy) schreibt `enriched: true` + `enriched_by: tom-clip-enrich`.
    enriched_val = str(fm.get("enriched", "")).lower().strip()
    already = enriched_val in ("true", "yes", "1", "clip-time", "tom-clip-enrich")

    # --- queue-only: Konzepte aus Frontmatter in Review-Queue übernehmen,
    #                  NICHTS am Clip-File selbst ändern ---
    if queue_only:
        konzepte = _parse_konzepte_field(fm.get("konzepte_vorschlaege") or fm.get("concepts"))
        if not konzepte:
            return {
                "status": "skip",
                "reason": "no konzepte_vorschlaege in frontmatter",
                "path": str(path),
            }
        result = {
            "status": "ok" if not dry_run else "dry-run",
            "mode": "queue-only",
            "path": str(path),
            "concepts": konzepte,
        }
        if not dry_run:
            concept_path = append_concept_suggestions(vault, path.name, konzepte)
            result["concepts_appended_to"] = str(concept_path)
        return result

    if already and not force:
        return {"status": "skip", "reason": f"already enriched ({enriched_val})", "path": str(path)}

    title = fm.get("title") or path.stem
    body_preview = clean_body_preview(body)
    if len(body_preview) < 200:
        return {"status": "skip", "reason": f"body too short ({len(body_preview)} chars)", "path": str(path)}

    enrichment = enrich_via_model(title, body_preview)

    # Merge tags (existing + new, dedup, preserve order)
    existing_tags = fm.get("tags") or []
    if not isinstance(existing_tags, list):
        existing_tags = [str(existing_tags)]
    merged_tags: list[str] = []
    seen = set()
    for t in list(existing_tags) + enrichment["tags"]:
        ts = str(t).strip()
        if ts and ts.lower() not in seen:
            merged_tags.append(ts)
            seen.add(ts.lower())

    # Update frontmatter (preserve existing keys, add new ones)
    new_fm = dict(fm)
    new_fm["summary"] = enrichment["summary"]
    new_fm["tags"] = merged_tags
    new_fm["suggested_wiki_category"] = enrichment["wiki_category"]
    new_fm["enriched"] = True
    new_fm["enriched_by"] = "tom-clip-enrich"
    new_fm["enriched_at"] = datetime.now().strftime("%Y-%m-%d")

    new_text = "---\n" + format_frontmatter(new_fm) + "\n---\n" + body

    result = {
        "status": "ok" if not dry_run else "dry-run",
        "path": str(path),
        "summary": enrichment["summary"],
        "tags_added": [t for t in enrichment["tags"] if t not in {x.lower() for x in existing_tags}],
        "concepts": enrichment["concepts"],
        "wiki_category": enrichment["wiki_category"],
    }

    if not dry_run:
        path.write_text(new_text)
        concept_path = append_concept_suggestions(vault, path.name, enrichment["concepts"])
        result["concepts_appended_to"] = str(concept_path)

    return result


# ── CLI ─────────────────────────────────────────────────────────────────────


def main() -> int:
    p = argparse.ArgumentParser(description="Tom Clipper Auto-Enrichment via qwen2.5:3b")
    p.add_argument("path", type=Path, help="Clipping file to enrich")
    p.add_argument("--dry-run", action="store_true", help="Don't write changes, just print result")
    p.add_argument("--force", action="store_true", help="Re-enrich even if already enriched")
    p.add_argument(
        "--queue-only",
        action="store_true",
        help="Nur konzepte_vorschlaege in 90_Wiki/konzepte-vorschlaege.md übernehmen, "
        "Frontmatter NICHT ändern. Für Koexistenz mit Web-Clipper-Interpreter (ADR-005).",
    )
    p.add_argument("--vault", type=Path, default=None, help="Vault root (default: $TOM_VAULT)")
    args = p.parse_args()

    try:
        result = enrich_file(
            args.path,
            force=args.force,
            dry_run=args.dry_run,
            vault=args.vault,
            queue_only=args.queue_only,
        )
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    status = result["status"]
    print(f"[{status}] {result['path']}")
    if status == "skip":
        print(f"  reason: {result['reason']}")
        return 0
    if result.get("mode") == "queue-only":
        print(f"  concepts: {result['concepts']}")
        if "concepts_appended_to" in result:
            print(f"  concepts → {result['concepts_appended_to']}")
        return 0
    print(f"  summary: {result['summary'][:120]}{'…' if len(result['summary']) > 120 else ''}")
    print(f"  tags added: {result['tags_added']}")
    print(f"  concepts: {result['concepts']}")
    print(f"  wiki category: {result['wiki_category']}")
    if "concepts_appended_to" in result:
        print(f"  concepts → {result['concepts_appended_to']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
