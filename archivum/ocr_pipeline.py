#!/usr/bin/env python3
"""
archivum/ocr_pipeline.py — OCR + FTS5 Index für Tom Dokumenten-Fundament

Phase 27 / v1.4. Requirements: DOC14-04, DOC14-05, DOC14-06

Usage:
    python3 ocr_pipeline.py --init                     # DB-Schema anlegen
    python3 ocr_pipeline.py --file /path/to/doc.pdf    # Single-file
    python3 ocr_pipeline.py --category "07 Verträge"   # Kategorie in Archiv/
    python3 ocr_pipeline.py --all                      # Alle Archiv-Kategorien
    python3 ocr_pipeline.py --search "query"           # Quick-Search (Phase 27 Smoke-Test)

Idempotent: Verarbeitet PDFs nur einmal (SHA256-Cache in ocr-cache/<hash>.txt).
"""

from __future__ import annotations

import argparse
import hashlib
import os
import sqlite3
import subprocess
import sys
import time
from pathlib import Path
from datetime import datetime

# ── Pfade (statisch, v1.4 Phase 27) ─────────────────────────────────────────
ARCHIVUM_ROOT = Path("/Users/maxim/Claude/archivum")
DB_PATH = ARCHIVUM_ROOT / "db" / "archivum.db"
OCR_CACHE = ARCHIVUM_ROOT / "ocr-cache"
LOGS = ARCHIVUM_ROOT / "logs"
LOG_FILE = LOGS / "ocr-pipeline.log"

ARCHIV_ROOT = Path("/Users/maxim/Downloads/Archiv")
TOM_VAULT = Path(os.environ.get(
    "TOM_VAULT",
    "/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw",
))

# ── Logging ─────────────────────────────────────────────────────────────────


def log(action: str, path: str, status: str, duration_s: float = 0.0, msg: str = "") -> None:
    LOGS.mkdir(parents=True, exist_ok=True)
    line = f"{datetime.now().isoformat(timespec='seconds')} | {action} | {path} | {status} | {duration_s:.2f}s | {msg}\n"
    with LOG_FILE.open("a") as f:
        f.write(line)
    # Stderr-Echo für interaktive Runs
    print(line.rstrip(), file=sys.stderr)


# ── DB ──────────────────────────────────────────────────────────────────────

SCHEMA = """
CREATE TABLE IF NOT EXISTS documents (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    sha256     TEXT NOT NULL UNIQUE,
    path       TEXT NOT NULL,
    category   TEXT,
    filename   TEXT NOT NULL,
    size_bytes INTEGER,
    pages      INTEGER,
    indexed_at TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
    filename,
    category,
    content,
    tokenize='unicode61 remove_diacritics 2'
);

CREATE INDEX IF NOT EXISTS idx_documents_sha256 ON documents(sha256);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
"""


def db_connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db() -> None:
    conn = db_connect()
    try:
        conn.executescript(SCHEMA)
        conn.commit()
        log("init", str(DB_PATH), "OK", msg="FTS5 schema created")
    finally:
        conn.close()


# ── OCR ─────────────────────────────────────────────────────────────────────


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def extract_text_to_cache(pdf: Path, sha: str) -> tuple[Path, int, str]:
    """Extract plain text to cache. Returns (text_file, page_count, method).

    Strategy:
    1. Try pdftotext first (fast, works for PDFs with existing text layer)
    2. If pdftotext yields <100 chars, fall back to ocrmypdf OCR (image-based PDFs)
    """
    OCR_CACHE.mkdir(parents=True, exist_ok=True)
    text_file = OCR_CACHE / f"{sha}.txt"
    pages = _count_pages(pdf)

    if text_file.exists() and text_file.stat().st_size > 0:
        return text_file, pages, "cached"

    # Strategy 1: pdftotext
    try:
        result = subprocess.run(
            ["pdftotext", "-layout", str(pdf), str(text_file)],
            check=True, capture_output=True, text=True, timeout=60,
        )
        if text_file.exists() and text_file.stat().st_size >= 100:
            return text_file, pages, "pdftotext"
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # Strategy 2: ocrmypdf (image-based PDF, needs OCR)
    with tempfile_pdf() as tmp_pdf:
        cmd = [
            "ocrmypdf",
            "--language", "deu",
            "--sidecar", str(text_file),
            "--force-ocr",        # Re-OCR even if text layer exists
            "--quiet",
            str(pdf),
            str(tmp_pdf),
        ]
        subprocess.run(cmd, check=True, capture_output=True, text=True, timeout=900)
    return text_file, pages, "ocrmypdf"


class tempfile_pdf:
    def __enter__(self) -> Path:
        import tempfile
        self._tmp = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False)
        self._tmp.close()
        return Path(self._tmp.name)

    def __exit__(self, *exc) -> None:
        try:
            Path(self._tmp.name).unlink(missing_ok=True)
        except Exception:
            pass


def _count_pages(pdf: Path) -> int:
    """Rough page count via pdfinfo if available, else 0."""
    try:
        out = subprocess.run(
            ["pdfinfo", str(pdf)],
            capture_output=True, text=True, timeout=10,
        )
        for line in out.stdout.splitlines():
            if line.startswith("Pages:"):
                return int(line.split(":", 1)[1].strip())
    except Exception:
        pass
    return 0


# ── Indexing ────────────────────────────────────────────────────────────────


def index_file(pdf: Path, category: str | None = None) -> dict:
    """OCR a PDF and insert/update it in the FTS5 index. Idempotent per SHA256."""
    start = time.monotonic()
    if not pdf.exists():
        log("index", str(pdf), "MISSING", msg="file not found")
        return {"status": "missing"}

    sha = sha256_file(pdf)
    conn = db_connect()
    try:
        row = conn.execute("SELECT id FROM documents WHERE sha256=?", (sha,)).fetchone()
        if row:
            log("index", str(pdf), "SKIP", time.monotonic() - start, f"already indexed id={row['id']}")
            return {"status": "skip", "id": row["id"], "sha": sha}

        text_file, pages, method = extract_text_to_cache(pdf, sha)
        content = text_file.read_text(errors="replace")

        cat = category or _derive_category(pdf)
        now = datetime.now().isoformat(timespec="seconds")
        cur = conn.execute(
            "INSERT INTO documents(sha256, path, category, filename, size_bytes, pages, indexed_at) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            (sha, str(pdf), cat, pdf.name, pdf.stat().st_size, pages, now),
        )
        doc_id = cur.lastrowid
        conn.execute(
            "INSERT INTO documents_fts(rowid, filename, category, content) VALUES (?, ?, ?, ?)",
            (doc_id, pdf.name, cat or "", content),
        )
        conn.commit()
        log(
            "index", str(pdf), "OK", time.monotonic() - start,
            f"id={doc_id} sha={sha[:12]} chars={len(content)} pages={pages} via={method}",
        )
        return {"status": "ok", "id": doc_id, "sha": sha, "chars": len(content), "method": method, "pages": pages}
    finally:
        conn.close()


def _derive_category(pdf: Path) -> str | None:
    """Derive category from parent dir name if inside ARCHIV_ROOT."""
    try:
        rel = pdf.resolve().relative_to(ARCHIV_ROOT.resolve())
        parts = rel.parts
        if parts:
            return parts[0]
    except ValueError:
        pass
    # Try TOM_VAULT/raw
    try:
        rel = pdf.resolve().relative_to(TOM_VAULT.resolve())
        return f"vault:{rel.parts[0]}"
    except ValueError:
        pass
    return None


def index_category(name: str) -> list[dict]:
    target = ARCHIV_ROOT / name
    if not target.exists():
        log("index-cat", name, "MISSING", msg=f"{target}")
        return []
    results = []
    for pdf in sorted(target.rglob("*.pdf")):
        results.append(index_file(pdf, category=name))
    return results


def index_all() -> list[dict]:
    results = []
    for sub in sorted(ARCHIV_ROOT.iterdir()):
        if sub.is_dir() and not sub.name.startswith("."):
            results.extend(index_category(sub.name))
    return results


# ── Search (Smoke-Test) ─────────────────────────────────────────────────────


def search(query: str, limit: int = 10) -> list[dict]:
    conn = db_connect()
    try:
        rows = conn.execute(
            """
            SELECT d.id, d.category, d.filename, d.path,
                   snippet(documents_fts, 2, '[', ']', '…', 12) AS snippet
            FROM documents_fts
            JOIN documents d ON d.id = documents_fts.rowid
            WHERE documents_fts MATCH ?
            ORDER BY rank
            LIMIT ?
            """,
            (query, limit),
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


# ── CLI ─────────────────────────────────────────────────────────────────────


def main() -> int:
    p = argparse.ArgumentParser(description="archivum OCR + FTS5 pipeline")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--init", action="store_true", help="Create/verify DB schema")
    g.add_argument("--file", type=Path, help="Index a single PDF file")
    g.add_argument("--category", type=str, help="Index all PDFs in an Archiv category")
    g.add_argument("--all", action="store_true", help="Index all Archiv categories")
    g.add_argument("--search", type=str, help="Search the FTS5 index")
    p.add_argument("--category-name", type=str, default=None, help="Override derived category for --file")
    args = p.parse_args()

    init_db()  # Always ensure schema exists

    if args.init:
        print(f"OK — schema at {DB_PATH}")
        return 0

    if args.file:
        res = index_file(args.file, category=args.category_name)
        print(res)
        return 0 if res.get("status") in ("ok", "skip") else 1

    if args.category:
        results = index_category(args.category)
        ok = sum(1 for r in results if r.get("status") == "ok")
        skip = sum(1 for r in results if r.get("status") == "skip")
        print(f"Category '{args.category}': {ok} new, {skip} already indexed, {len(results)} total")
        return 0

    if args.all:
        results = index_all()
        ok = sum(1 for r in results if r.get("status") == "ok")
        skip = sum(1 for r in results if r.get("status") == "skip")
        print(f"All categories: {ok} new, {skip} already indexed, {len(results)} total")
        return 0

    if args.search:
        hits = search(args.search)
        if not hits:
            print(f"No matches for: {args.search}")
            return 0
        for h in hits:
            print(f"[{h['category']}] {h['filename']}")
            print(f"  {h['snippet']}")
            print(f"  → {h['path']}")
            print()
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
