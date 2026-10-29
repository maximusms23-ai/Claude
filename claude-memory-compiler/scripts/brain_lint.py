"""
Brain lint with selectable semantic backend.

Structural checks stay local and deterministic.
Semantic contradiction checks can run via Claude, Codex, Ollama, or Apple
Foundation Models.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from config import KNOWLEDGE_DIR, REPORTS_DIR, now_iso, today_iso
from lint import (
    check_broken_links,
    check_missing_backlinks,
    check_orphan_pages,
    check_orphan_sources,
    check_sparse_articles,
    check_stale_articles,
)
from utils import list_wiki_articles, load_state, save_state

ROOT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_BACKEND = os.environ.get("TOM_BRAIN_LINT_BACKEND", "ollama")
CLAUDE_MODEL = os.environ.get("TOM_BRAIN_LINT_CLAUDE_MODEL", "sonnet")
CODEX_MODEL = os.environ.get("TOM_BRAIN_LINT_CODEX_MODEL", "gpt-5.4-mini")
OLLAMA_MODEL = os.environ.get("TOM_BRAIN_LINT_OLLAMA_MODEL", "qwen2.5:3b")
OLLAMA_CHAT_URL = os.environ.get("TOM_BRAIN_LINT_OLLAMA_URL", "http://127.0.0.1:11434/api/chat")
OLLAMA_NUM_CTX = int(os.environ.get("TOM_BRAIN_LINT_OLLAMA_NUM_CTX", "32768"))
OLLAMA_TIMEOUT = int(os.environ.get("TOM_BRAIN_LINT_OLLAMA_TIMEOUT", "900"))
SEMANTIC_ARTICLE_CHARS = int(os.environ.get("TOM_BRAIN_LINT_ARTICLE_CHARS", "2500"))
SEMANTIC_TOTAL_CHARS = int(os.environ.get("TOM_BRAIN_LINT_TOTAL_CHARS", "70000"))
APPLE_TOOL_APP = Path(
    os.environ.get(
        "TOM_APPLE_TEXT_TOOL_APP",
        "/Users/maxim/Claude/apple-intelligence/build/TomAppleTextTool.app",
    )
)
APPLE_TOOL_BUILDER = Path(
    os.environ.get(
        "TOM_APPLE_TEXT_TOOL_BUILDER",
        "/Users/maxim/Claude/bin/build-apple-text-tool",
    )
)
EMPTY_KNOWLEDGE_CONTEXT = "## knowledge\n\nKeine Brain-Artikel gefunden."


def strip_frontmatter(content: str) -> str:
    if not content.startswith("---"):
        return content
    end = content.find("\n---", 3)
    if end == -1:
        return content
    return content[end + 4 :].strip()


def trim_text(text: str, limit: int) -> str:
    if limit <= 0 or len(text) <= limit:
        return text
    return text[:limit].rstrip() + "\n\n[gekürzt]"


def build_semantic_context() -> str:
    sections: list[str] = []
    total_chars = 0

    for article in list_wiki_articles():
        content = strip_frontmatter(article.read_text(encoding="utf-8"))
        excerpt = trim_text(content, SEMANTIC_ARTICLE_CHARS)
        rel = article.relative_to(KNOWLEDGE_DIR)
        block = f"## {rel}\n\n{excerpt}"
        if SEMANTIC_TOTAL_CHARS > 0 and total_chars + len(block) > SEMANTIC_TOTAL_CHARS:
            remaining = SEMANTIC_TOTAL_CHARS - total_chars
            if remaining > 120:
                sections.append(trim_text(block, remaining))
            break
        sections.append(block)
        total_chars += len(block)

    if not sections:
        return EMPTY_KNOWLEDGE_CONTEXT
    return "\n\n---\n\n".join(sections)


def build_prompt(context: str) -> str:
    return f"""Pruefe dieses private Brain auf Widersprueche, Inkonsistenzen oder veraltete Aussagen.

## Brain-Auszug

{context}

## Regeln

Suche nach:
- direkten Widerspruechen
- inkonsistenten Empfehlungen
- veralteten Aussagen, die neueren Eintraegen widersprechen

Ausgabeformat:
- Fuer jeden Fund genau eine Zeile
- Erlaubte Praefixe:
  CONTRADICTION: [file1] vs [file2] - Beschreibung
  INCONSISTENCY: [file] - Beschreibung
- Wenn keine Wissensartikel im Auszug enthalten sind: genau NO_ISSUES
- Wenn nichts gefunden wird: genau NO_ISSUES
- Keine Einleitung, keine Markdown-Liste, kein Zusatztext
"""


def build_apple_prompt(context: str) -> str:
    return f"""Review this private brain extract for contradictions, inconsistencies, or outdated claims.

## Brain Extract

{context}

## Output Rules

- One issue per line
- Allowed prefixes only:
  CONTRADICTION: [file1] vs [file2] - conflict description
  INCONSISTENCY: [file] - inconsistency description
- If the extract clearly contains no knowledge articles, output exactly NO_ISSUES
- If there are no issues, output exactly NO_ISSUES
- No bullets, no intro, no extra text
"""


def parse_semantic_output(output: str, backend: str) -> list[dict]:
    issues: list[dict] = []
    for raw_line in output.splitlines():
        line = raw_line.strip().lstrip("-").strip()
        if line.startswith("CONTRADICTION:") or line.startswith("INCONSISTENCY:"):
            issues.append(
                {
                    "severity": "warning",
                    "check": f"semantic_{backend}",
                    "file": "(cross-article)",
                    "detail": line,
                }
            )

    if issues or "NO_ISSUES" in output:
        return issues

    cleaned = " ".join(output.split())
    snippet = cleaned[:240] if cleaned else "leere Antwort"
    return [
        {
            "severity": "error",
            "check": f"semantic_{backend}",
            "file": "(system)",
            "detail": f"Unparseable {backend} response: {snippet}",
        }
    ]


def run_process(cmd: list[str], env: dict | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
        env=env,
    )


def summarize_failure(result: subprocess.CompletedProcess[str], fallback: str) -> str:
    combined = "\n".join(
        part.strip() for part in [result.stderr, result.stdout] if part and part.strip()
    ).strip()
    if not combined:
        return fallback

    usage_lines = [
        line.strip()
        for line in combined.splitlines()
        if "hit your limit" in line.lower() or "usage limit" in line.lower()
    ]
    if usage_lines:
        return " / ".join(dict.fromkeys(usage_lines))

    short_lines = [line.strip() for line in combined.splitlines() if line.strip()][:8]
    return " | ".join(short_lines)


def run_claude_cli(prompt: str) -> str:
    if not shutil.which("claude"):
        raise RuntimeError("Claude CLI wurde nicht gefunden")
    result = run_process(
        [
            "claude",
            "-p",
            "--model",
            CLAUDE_MODEL,
            "--output-format",
            "text",
            "--no-session-persistence",
            prompt,
        ]
    )
    if result.returncode != 0:
        raise RuntimeError(summarize_failure(result, "Claude CLI fehlgeschlagen"))
    return result.stdout.strip()


def run_codex_cli(prompt: str) -> str:
    if not shutil.which("codex"):
        raise RuntimeError("Codex CLI wurde nicht gefunden")
    with tempfile.TemporaryDirectory(prefix="brain-lint-codex-") as tmpdir:
        output_file = Path(tmpdir) / "codex-last.txt"
        result = run_process(
            [
                "codex",
                "exec",
                "--ephemeral",
                "--skip-git-repo-check",
                "-C",
                str(ROOT_DIR),
                "--sandbox",
                "read-only",
                "--model",
                CODEX_MODEL,
                "--output-last-message",
                str(output_file),
                prompt,
            ]
        )
        if result.returncode != 0:
            raise RuntimeError(summarize_failure(result, "Codex CLI fehlgeschlagen"))
        if output_file.exists():
            return output_file.read_text(encoding="utf-8").strip()
        return result.stdout.strip()


def post_json(url: str, payload: dict, max_time: int) -> dict:
    cmd = ["curl", "-s"]
    if max_time > 0:
        cmd.extend(["--max-time", str(max_time)])
    cmd.extend(
        [
            url,
            "-H",
            "Content-Type: application/json",
            "-d",
            json.dumps(payload),
        ]
    )
    result = run_process(cmd)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "curl fehlgeschlagen")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"ungueltige JSON-Antwort: {exc}") from exc


def run_ollama(prompt: str) -> str:
    if not shutil.which("ollama"):
        raise RuntimeError("Ollama wurde nicht gefunden")
    payload = {
        "model": OLLAMA_MODEL,
        "messages": [
            {
                "role": "system",
                "content": (
                    "Du bist ein praeziser Wissens-Linter. "
                    "Halte dich strikt an das geforderte Zeilenformat."
                ),
            },
            {"role": "user", "content": prompt},
        ],
        "stream": False,
        "options": {"num_ctx": OLLAMA_NUM_CTX, "temperature": 0},
    }
    data = post_json(OLLAMA_CHAT_URL, payload, max_time=OLLAMA_TIMEOUT)
    return data["message"]["content"].strip()


def ensure_apple_tool() -> Path:
    if APPLE_TOOL_APP.exists():
        return APPLE_TOOL_APP
    if not APPLE_TOOL_BUILDER.exists():
        raise RuntimeError("Apple Text Tool Builder fehlt")
    result = run_process(["/bin/bash", str(APPLE_TOOL_BUILDER)])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "Apple Text Tool Build fehlgeschlagen")
    if not APPLE_TOOL_APP.exists():
        raise RuntimeError("Apple Text Tool wurde nicht gebaut")
    return APPLE_TOOL_APP


def run_apple(prompt: str) -> str:
    app = ensure_apple_tool()
    with tempfile.TemporaryDirectory(prefix="brain-lint-apple-") as tmpdir:
        prompt_file = Path(tmpdir) / "prompt.txt"
        instructions_file = Path(tmpdir) / "instructions.txt"
        output_file = Path(tmpdir) / "output.txt"

        prompt_file.write_text(prompt, encoding="utf-8")
        instructions_file.write_text(
            "Pruefe Wissensauszuege streng nach Widerspruechen und antworte nur im geforderten Zeilenformat.",
            encoding="utf-8",
        )

        result = run_process(
            [
                "/usr/bin/open",
                "-W",
                str(app),
                "--args",
                "--instructions-file",
                str(instructions_file),
                "--prompt-file",
                str(prompt_file),
                "--output-file",
                str(output_file),
            ]
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "Apple Text Tool fehlgeschlagen")
        if not output_file.exists():
            raise RuntimeError("Apple Text Tool hat keine Ausgabedatei geschrieben")
        text = output_file.read_text(encoding="utf-8").strip()
        if text.startswith("ERROR:"):
            raise RuntimeError(text.removeprefix("ERROR:").strip())
        return text


def run_semantic_backend(backend: str, prompt: str) -> str:
    if backend == "claude":
        return run_claude_cli(prompt)
    if backend == "codex":
        return run_codex_cli(prompt)
    if backend == "ollama":
        return run_ollama(prompt)
    if backend == "apple":
        return run_apple(prompt)
    raise RuntimeError(f"Unbekanntes Backend: {backend}")


def generate_report(backend: str, all_issues: list[dict], context: str) -> str:
    errors = [i for i in all_issues if i["severity"] == "error"]
    warnings = [i for i in all_issues if i["severity"] == "warning"]
    suggestions = [i for i in all_issues if i["severity"] == "suggestion"]

    lines = [
        f"# Brain Lint Report - {today_iso()}",
        "",
        f"- Backend: `{backend}`",
        f"- Scope chars: `{len(context)}`",
        f"- Generated: `{now_iso()}`",
        "",
        f"**Total issues:** {len(all_issues)}",
        f"- Errors: {len(errors)}",
        f"- Warnings: {len(warnings)}",
        f"- Suggestions: {len(suggestions)}",
        "",
    ]

    for heading, items, marker in [
        ("Errors", errors, "x"),
        ("Warnings", warnings, "!"),
        ("Suggestions", suggestions, "?"),
    ]:
        if not items:
            continue
        lines.append(f"## {heading}")
        lines.append("")
        for issue in items:
            fixable = " (auto-fixable)" if issue.get("auto_fixable") else ""
            lines.append(f"- **[{marker}]** `{issue['file']}` - {issue['detail']}{fixable}")
        lines.append("")

    if not all_issues:
        lines.append("All checks passed. Brain is healthy.")
        lines.append("")

    return "\n".join(lines)


def save_report(backend: str, report: str) -> Path:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    stamp = now_iso().replace(":", "").replace("+", "-")
    report_path = REPORTS_DIR / f"brain-lint-{backend}-{stamp}.md"
    report_path.write_text(report, encoding="utf-8")
    latest_backend = REPORTS_DIR / f"brain-lint-latest-{backend}.md"
    latest_backend.write_text(report, encoding="utf-8")
    latest_global = REPORTS_DIR / "brain-lint-latest.md"
    latest_global.write_text(report, encoding="utf-8")
    return report_path


def structural_checks() -> list[tuple[str, callable]]:
    return [
        ("Broken links", check_broken_links),
        ("Orphan pages", check_orphan_pages),
        ("Orphan sources", check_orphan_sources),
        ("Stale articles", check_stale_articles),
        ("Missing backlinks", check_missing_backlinks),
        ("Sparse articles", check_sparse_articles),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Brain lint with selectable semantic backend")
    parser.add_argument(
        "--backend",
        choices=["claude", "codex", "ollama", "apple"],
        default=DEFAULT_BACKEND,
        help="Semantic backend for contradiction checks",
    )
    parser.add_argument(
        "--structural-only",
        action="store_true",
        help="Nur strukturelle Checks, ohne semantischen Modell-Check",
    )
    args = parser.parse_args()

    print("Running Brain lint...")
    all_issues: list[dict] = []

    for name, check_fn in structural_checks():
        print(f"  Checking: {name}...")
        issues = check_fn()
        all_issues.extend(issues)
        print(f"    Found {len(issues)} issue(s)")

    context = build_semantic_context()
    if not args.structural_only:
        if context == EMPTY_KNOWLEDGE_CONTEXT:
            print("  Skipping: Contradictions (no knowledge articles)")
        else:
            print(f"  Checking: Contradictions ({args.backend})...")
            prompt = build_apple_prompt(context) if args.backend == "apple" else build_prompt(context)
            try:
                semantic_output = run_semantic_backend(args.backend, prompt)
                issues = parse_semantic_output(semantic_output, args.backend)
            except Exception as exc:
                issues = [
                    {
                        "severity": "error",
                        "check": f"semantic_{args.backend}",
                        "file": "(system)",
                        "detail": f"{args.backend} semantic check failed: {exc}",
                    }
                ]
            all_issues.extend(issues)
            print(f"    Found {len(issues)} issue(s)")
    else:
        print("  Skipping: Contradictions (--structural-only)")

    report = generate_report(args.backend, all_issues, context)
    report_path = save_report(args.backend, report)
    print(f"\nReport saved to: {report_path}")

    state = load_state()
    state["last_lint"] = now_iso()
    state["last_brain_lint_backend"] = args.backend
    save_state(state)

    errors = sum(1 for i in all_issues if i["severity"] == "error")
    warnings = sum(1 for i in all_issues if i["severity"] == "warning")
    suggestions = sum(1 for i in all_issues if i["severity"] == "suggestion")
    print(f"\nResults: {errors} errors, {warnings} warnings, {suggestions} suggestions")

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
