"""Side-by-Side-Eval: tom-wiki vs tom-ask gegen identische Fragen.

Ruft beide CLI-Wrapper via subprocess auf, scort die Antworten gegen
erwartete Keywords und schreibt einen Markdown-Report.

Usage:
    python3 Gemma/eval/run_eval.py
    python3 Gemma/eval/run_eval.py --output results/custom.md

Voraussetzungen:
    - ollama serve laeuft
    - bin/tom-wiki und bin/tom-ask sind im PATH (oder Symlink in ~/bin/)
    - Gemma/rag ChromaDB ist indiziert (fuer tom-ask)
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
EVAL_DIR = Path(__file__).resolve().parent
DEFAULT_REPORT = EVAL_DIR / "results" / "v1.3-baseline.md"
TIMEOUT_SECS = 180


def load_questions() -> list[dict]:
    qfile = EVAL_DIR / "questions.yaml"
    with open(qfile, encoding="utf-8") as f:
        return yaml.safe_load(f)["questions"]


def resolve_tool(name: str) -> str:
    """Find a CLI tool in PATH or fall back to repo bin/ symlink target."""
    found = shutil.which(name)
    if found:
        return found
    fallback = REPO_ROOT / "bin" / name
    if fallback.exists():
        return str(fallback)
    raise FileNotFoundError(f"Cannot locate {name} in PATH or {fallback}")


def run_tool(tool_path: str, args: list[str]) -> tuple[str, str]:
    """Run a CLI tool, return (answer, status). status in {OK, TIMEOUT, ERROR}."""
    try:
        result = subprocess.run(
            [tool_path, *args],
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECS,
        )
        if result.returncode != 0:
            return (result.stderr or "", "ERROR")
        return (result.stdout or "", "OK")
    except subprocess.TimeoutExpired:
        return ("", "TIMEOUT")
    except Exception as exc:  # noqa: BLE001
        return (f"{type(exc).__name__}: {exc}", "ERROR")


def score_answer(answer: str, keywords: list[str]) -> tuple[float, list[str], list[str]]:
    if not keywords:
        return (0.0, [], [])
    lower = answer.lower()
    matched = [kw for kw in keywords if kw.lower() in lower]
    missing = [kw for kw in keywords if kw.lower() not in lower]
    return (len(matched) / len(keywords), matched, missing)


def winner(score_wiki: float, score_ask: float) -> str:
    if abs(score_wiki - score_ask) < 1e-9:
        return "tie"
    return "tom-wiki" if score_wiki > score_ask else "tom-ask"


def format_status(status: str, score: float) -> str:
    if status != "OK":
        return status
    return f"{score:.0%}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Side-by-side eval tom-wiki vs tom-ask")
    parser.add_argument("--output", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()

    tom_wiki = resolve_tool("tom-wiki")
    tom_ask = resolve_tool("tom-ask")

    questions = load_questions()
    rows: list[dict] = []

    print(f"Eval: {len(questions)} Fragen, je 2 Tool-Calls -> ~{len(questions)*2} Aufrufe")
    print(f"Tools: {tom_wiki} | {tom_ask}\n")

    for idx, q in enumerate(questions, 1):
        question = q["question"]
        keywords = q["keywords"]
        category = q.get("category", "wiki")

        print(f"[{idx}/{len(questions)}] ({category}) {question}")

        wiki_args = ["--brain", question] if category == "brain" else [question]
        ans_wiki, st_wiki = run_tool(tom_wiki, wiki_args)
        score_wiki, matched_wiki, _ = score_answer(ans_wiki, keywords)
        print(f"  tom-wiki: {st_wiki} score={score_wiki:.0%} matched={matched_wiki}")

        ans_ask, st_ask = run_tool(tom_ask, [question])
        score_ask, matched_ask, _ = score_answer(ans_ask, keywords)
        print(f"  tom-ask : {st_ask} score={score_ask:.0%} matched={matched_ask}")

        rows.append({
            "idx": idx,
            "category": category,
            "question": question,
            "score_wiki": score_wiki,
            "status_wiki": st_wiki,
            "score_ask": score_ask,
            "status_ask": st_ask,
            "winner": winner(score_wiki, score_ask),
            "answer_wiki": ans_wiki[:500],
            "answer_ask": ans_ask[:500],
        })
        print()

    write_report(args.output, rows)
    print(f"Report geschrieben: {args.output}")
    return 0


def write_report(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    n = len(rows)
    avg_wiki = sum(r["score_wiki"] for r in rows) / n if n else 0
    avg_ask = sum(r["score_ask"] for r in rows) / n if n else 0
    wins_wiki = sum(1 for r in rows if r["winner"] == "tom-wiki")
    wins_ask = sum(1 for r in rows if r["winner"] == "tom-ask")
    ties = sum(1 for r in rows if r["winner"] == "tie")

    lines: list[str] = []
    lines.append("---")
    lines.append("title: v1.3 Baseline-Eval — tom-wiki vs tom-ask")
    lines.append(f"created: {datetime.now().strftime('%Y-%m-%d')}")
    lines.append("type: eval-report")
    lines.append("phase: 24-eval-framework")
    lines.append("---")
    lines.append("")
    lines.append("# v1.3 Baseline-Eval — tom-wiki vs tom-ask")
    lines.append("")
    lines.append(f"**Datum:** {datetime.now().strftime('%Y-%m-%d %H:%M')}  ")
    lines.append(f"**Fragen:** {n}  ")
    lines.append(f"**Avg-Score tom-wiki:** {avg_wiki:.0%}  ")
    lines.append(f"**Avg-Score tom-ask:** {avg_ask:.0%}  ")
    lines.append(f"**Wins:** tom-wiki={wins_wiki}, tom-ask={wins_ask}, ties={ties}")
    lines.append("")
    lines.append("## Score-Vergleich")
    lines.append("")
    lines.append("| # | Category | Question | tom-wiki | tom-ask | Winner |")
    lines.append("|---|----------|----------|----------|---------|--------|")
    for r in rows:
        q = r["question"].replace("|", "\\|")
        lines.append(
            f"| {r['idx']} | {r['category']} | {q} | "
            f"{format_status(r['status_wiki'], r['score_wiki'])} | "
            f"{format_status(r['status_ask'], r['score_ask'])} | "
            f"{r['winner']} |"
        )
    lines.append("")
    lines.append("## Antwort-Auszuege (erste 500 Zeichen)")
    lines.append("")
    for r in rows:
        lines.append(f"### [{r['idx']}] {r['question']}")
        lines.append("")
        lines.append("**tom-wiki:**")
        lines.append("")
        lines.append("```")
        lines.append(r["answer_wiki"] or "(leer)")
        lines.append("```")
        lines.append("")
        lines.append("**tom-ask:**")
        lines.append("")
        lines.append("```")
        lines.append(r["answer_ask"] or "(leer)")
        lines.append("```")
        lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
