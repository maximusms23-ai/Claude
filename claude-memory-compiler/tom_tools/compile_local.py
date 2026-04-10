"""Tom Compile — Lokale Gemma-basierte Variante (ohne Claude Agent SDK).

Alternative zum `scripts/compile.py` mit claude_agent_sdk. Ruft lokales
`gemme` via Ollama an, lässt es strukturiertes JSON mit Artikel-Inhalten
zurückgeben, und schreibt die Files selbst (statt dem LLM Tool-Zugriff zu
geben wie der claude-sdk-Modus).

Trade-offs:
- Pro: Kein Subscription-Verbrauch, läuft komplett lokal, deterministisch-reproduzierbar
- Con: Kein Tool-Access → gemme kann existierende Artikel nicht lazy laden,
       muss den ganzen Kontext im Prompt bekommen (8192 num_ctx Budget)
- Con: JSON-Output-Parsing ist fragiler als Agent-mit-Tools
- Con: Keine multi-turn Exploration des Brains

Usage:
    python -m tom_tools.compile_local --file daily/2026-04-10.md
    python -m tom_tools.compile_local --file path.md --output-dir /tmp/sandbox
    python -m tom_tools.compile_local --file path.md --dry-run

Teil von Tom v1.4 — Phase 31 (LOCAL-01).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import ollama

# Reuse config paths
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from config import (  # noqa: E402
    AGENTS_FILE,
    CONCEPTS_DIR,
    CONNECTIONS_DIR,
    KNOWLEDGE_DIR,
    DAILY_DIR,
    now_iso,
)

MODEL = os.environ.get("TOM_COMPILE_MODEL", "gemme")
NUM_CTX = int(os.environ.get("TOM_COMPILE_NUM_CTX", "8192"))
TEMPERATURE = float(os.environ.get("TOM_COMPILE_TEMP", "0.3"))


@dataclass
class CompileResult:
    log_name: str
    duration_s: float
    articles_created: list[str]
    articles_updated: list[str]
    raw_response: str
    parse_ok: bool
    error: str | None = None

    def summary(self) -> dict:
        return {
            "log": self.log_name,
            "duration_s": round(self.duration_s, 2),
            "created": self.articles_created,
            "updated": self.articles_updated,
            "parse_ok": self.parse_ok,
            "error": self.error,
        }


# ── Prompt Construction ────────────────────────────────────────────────────


SYSTEM_PROMPT = """Du bist ein Wissens-Compiler. Deine Aufgabe: Lies einen täglichen
Konversations-Log und extrahiere die zentralen wiederverwendbaren Konzepte als
strukturierte Daten (NICHT als fertiges Markdown).

Antworte AUSSCHLIESSLICH mit validem JSON in EXAKT diesem Schema:

{
  "articles": [
    {
      "slug": "ocr-pipeline",
      "title": "OCR-Pipeline Architektur",
      "kernpunkte": [
        "Kurzer Satz 1",
        "Kurzer Satz 2",
        "Kurzer Satz 3"
      ],
      "details": "Ein bis drei Absätze Prosa mit Fakten aus dem Log.",
      "related": ["tom-doc-cli", "sqlite-fts5"]
    }
  ]
}

WICHTIGE REGELN:
1. Nur einfache JSON-Strings — KEINE eingebetteten Backslash-n, KEINE Markdown-Blöcke, KEINE Newlines in Strings
2. "details" ist ein einzelner String (ohne Zeilenumbrüche, Satzende mit Punkt)
3. "kernpunkte" ist ein Array von 3-5 kurzen deutschen Sätzen
4. "slug" ist kebab-case (z.B. "ocr-pipeline-architektur")
5. "related" enthält 2-4 slugs anderer Artikel (verwandte Konzepte)
6. 0-5 articles gesamt, je nach Substanz im Log
7. Wenn das Log nur triviale Einträge enthält (z.B. nur "FLUSH_OK"-Nachrichten): leeres articles-Array
8. Sprache: Deutsch
9. Keine Halluzinationen — nur Fakten aus dem Log"""


def build_user_prompt(log_path: Path, log_content: str, existing_articles: dict[str, str]) -> str:
    today = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d")
    existing_section = ""
    if existing_articles:
        listing = "\n".join(f"- {p}" for p in sorted(existing_articles.keys())[:30])
        existing_section = f"\n## Bereits existierende Artikel\n{listing}\n\nNeue Artikel sollen diese NICHT duplizieren.\n"
    else:
        existing_section = "\n(Keine existierenden Artikel bisher)\n"

    return f"""Datum: {today}
Log-Datei: {log_path.name}

{existing_section}

## Daily Log

{log_content}

---

Extrahiere jetzt die Konzepte als JSON wie spezifiziert."""


# ── gemme Call ─────────────────────────────────────────────────────────────


def call_gemme(system: str, user: str) -> tuple[str, float]:
    t0 = time.monotonic()
    response = ollama.chat(
        model=MODEL,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        format="json",
        options={"temperature": TEMPERATURE, "num_ctx": NUM_CTX},
    )
    dt = time.monotonic() - t0
    return response["message"]["content"], dt


# ── Compile Logic ──────────────────────────────────────────────────────────


def compile_local(
    log_path: Path,
    *,
    output_dir: Path | None = None,
    dry_run: bool = False,
) -> CompileResult:
    """Compile a daily log using local gemme. Returns CompileResult with metrics."""
    out_root = output_dir or KNOWLEDGE_DIR
    out_concepts = out_root / "concepts"
    out_connections = out_root / "connections"
    out_index = out_root / "index.md"
    out_log = out_root / "log.md"

    log_content = log_path.read_text(encoding="utf-8")

    existing: dict[str, str] = {}
    if out_root.exists():
        for p in out_root.rglob("*.md"):
            try:
                rel = p.relative_to(out_root)
                existing[str(rel)] = p.read_text(encoding="utf-8")
            except ValueError:
                continue

    user_prompt = build_user_prompt(log_path, log_content, existing)

    try:
        raw, duration = call_gemme(SYSTEM_PROMPT, user_prompt)
    except Exception as e:
        return CompileResult(
            log_name=log_path.name,
            duration_s=0.0,
            articles_created=[],
            articles_updated=[],
            raw_response="",
            parse_ok=False,
            error=f"ollama error: {e}",
        )

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        return CompileResult(
            log_name=log_path.name,
            duration_s=duration,
            articles_created=[],
            articles_updated=[],
            raw_response=raw,
            parse_ok=False,
            error=f"json parse: {e}",
        )

    articles = data.get("articles", []) or []

    created: list[str] = []
    updated: list[str] = []

    if not dry_run and articles:
        out_concepts.mkdir(parents=True, exist_ok=True)
        out_connections.mkdir(parents=True, exist_ok=True)

    today = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d")

    for art in articles:
        slug = str(art.get("slug", "")).strip()
        title = str(art.get("title", "")).strip()
        kernpunkte = art.get("kernpunkte") or []
        details = str(art.get("details", "")).strip()
        related = art.get("related") or []
        if not slug or not title:
            continue
        slug = re.sub(r"[^a-z0-9\-]", "", slug.lower().replace(" ", "-"))
        if not slug:
            continue

        rel_path = f"concepts/{slug}.md"
        target = out_root / rel_path

        # Build markdown from structured data (Python, not LLM)
        lines = [
            "---",
            f"title: {title}",
            "type: concept",
            f"created: {today}",
            f"sources: [daily/{log_path.name}]",
            "---",
            "",
            f"# {title}",
            "",
            "## Kernpunkte",
        ]
        for kp in kernpunkte:
            kp_str = str(kp).strip()
            if kp_str:
                lines.append(f"- {kp_str}")
        lines.append("")
        lines.append("## Details")
        lines.append("")
        lines.append(details if details else "(Details ausstehend)")
        lines.append("")
        lines.append("## Verwandte Konzepte")
        for rel in related:
            rel_str = str(rel).strip().lower().replace(" ", "-")
            rel_str = re.sub(r"[^a-z0-9\-]", "", rel_str)
            if rel_str:
                lines.append(f"- [[concepts/{rel_str}]]")
        content = "\n".join(lines) + "\n"

        existed_before = target.exists()
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        if existed_before:
            updated.append(rel_path)
        else:
            created.append(rel_path)

    # Append log entry
    if articles and not dry_run:
        timestamp = now_iso()
        entry_lines = [
            f"\n## [{timestamp}] compile-local | {log_path.name}",
            f"- Source: daily/{log_path.name}",
        ]
        if created:
            entry_lines.append(f"- Articles created: {', '.join(f'[[concepts/{Path(p).stem}]]' for p in created)}")
        if updated:
            entry_lines.append(f"- Articles updated: {', '.join(f'[[concepts/{Path(p).stem}]]' for p in updated)}")
        with out_log.open("a", encoding="utf-8") as f:
            f.write("\n".join(entry_lines) + "\n")

    return CompileResult(
        log_name=log_path.name,
        duration_s=duration,
        articles_created=created,
        articles_updated=updated,
        raw_response=raw,
        parse_ok=True,
        error=None,
    )


# ── CLI ────────────────────────────────────────────────────────────────────


def main() -> int:
    p = argparse.ArgumentParser(description="Tom Compile (local gemme variant)")
    p.add_argument("--file", type=Path, required=True, help="Daily log path")
    p.add_argument("--output-dir", type=Path, default=None, help="Override knowledge/ output root")
    p.add_argument("--dry-run", action="store_true", help="Don't write files")
    p.add_argument("--json", action="store_true", help="Print result as JSON")
    args = p.parse_args()

    log = args.file
    if not log.is_absolute():
        if (DAILY_DIR / log.name).exists():
            log = DAILY_DIR / log.name

    if not log.exists():
        print(f"error: log not found: {log}", file=sys.stderr)
        return 1

    result = compile_local(log, output_dir=args.output_dir, dry_run=args.dry_run)

    if args.json:
        print(json.dumps(result.summary(), indent=2))
    else:
        print(f"Log: {result.log_name}")
        print(f"Duration: {result.duration_s:.2f}s")
        print(f"Parse OK: {result.parse_ok}")
        if result.error:
            print(f"Error: {result.error}")
            print(f"Raw: {result.raw_response[:500]}")
            return 1
        print(f"Articles created: {len(result.articles_created)}")
        for a in result.articles_created:
            print(f"  + {a}")
        print(f"Articles updated: {len(result.articles_updated)}")
        for a in result.articles_updated:
            print(f"  ~ {a}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
