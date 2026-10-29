#!/usr/bin/env python3
"""
Copy candidate document files from a TSV (path per line) into Obsidian vault raw/,
deduplicated by SHA-256. Does not delete sources.

Default: skip rows with suspect=yes (software-doc heuristic), skip PDFs < 50 KiB,
skip paths under .vscode / .claude / .codex.

Resume: reads DEST/.raw_ingest_manifest.tsv (hash\\trelative_dest_path) to skip
already copied content. On first run, hashes existing files in DEST (non-hidden).
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import shutil
import sys
import time
from pathlib import Path


def sha256_file(path: Path, chunk: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def should_skip_path(p: str) -> bool:
    low = p.lower()
    for needle in ("/.vscode/", "/.claude/", "/.codex/", "/.git/"):
        if needle in low:
            return True
    return False


def safe_dest_name(name: str) -> str:
    name = name.replace("\x00", "").strip()
    for c in "/\\:":
        name = name.replace(c, "-")
    return name or "unnamed"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--tsv",
        default=str(Path.home() / "Desktop" / "candidates_review.tsv"),
        help="TSV with columns: path, size_bytes, mtime, ext, suspect",
    )
    ap.add_argument(
        "--dest",
        default="/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/"
        "Obsidian_Valuet/Obsidian_Zentralw/raw",
        help="Vault raw/ directory",
    )
    ap.add_argument("--skip-suspect", action="store_true", default=True)
    ap.add_argument("--no-skip-suspect", action="store_false", dest="skip_suspect")
    ap.add_argument("--min-pdf-bytes", type=int, default=51200)
    ap.add_argument("--progress-every", type=int, default=50)
    args = ap.parse_args()

    dest = Path(args.dest).expanduser().resolve()
    dest.mkdir(parents=True, exist_ok=True)
    manifest = dest / ".raw_ingest_manifest.tsv"
    log_path = Path.home() / "Desktop" / "raw_copy_progress.log"

    known: dict[str, str] = {}  # hash -> relative path under dest

    def log(msg: str) -> None:
        line = f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {msg}\n"
        # Single sink: progress file (nohup often redirects stderr to the same file)
        with log_path.open("a", encoding="utf-8") as lf:
            lf.write(line)

    if manifest.exists():
        with manifest.open(encoding="utf-8", newline="") as f:
            for row in f:
                parts = row.strip().split("\t", 1)
                if len(parts) == 2:
                    known[parts[0]] = parts[1]
        log(f"loaded manifest: {len(known)} hashes")
    else:
        # Bootstrap: hash existing files in raw/ once, create manifest
        with manifest.open("w", encoding="utf-8") as mf:
            for p in sorted(dest.iterdir()):
                if not p.is_file() or p.name.startswith("."):
                    continue
                try:
                    h = sha256_file(p)
                except OSError as e:
                    log(f"bootstrap skip (read error): {p.name} ({e})")
                    continue
                known[h] = p.name
                mf.write(f"{h}\t{p.name}\n")
        log(f"bootstrap manifest from dest: {len(known)} files")

    tsv_path = Path(args.tsv).expanduser()
    if not tsv_path.is_file():
        log(f"ERROR: TSV not found: {tsv_path}")
        return 1

    copied = skipped_dup = skipped_filter = errors = 0
    t0 = time.time()
    row_n = 0

    with tsv_path.open(encoding="utf-8", newline="") as tf:
        reader = csv.DictReader(tf, delimiter="\t")
        if reader.fieldnames is None or "path" not in reader.fieldnames:
            log("ERROR: TSV missing header with 'path' column")
            return 1
        for row in reader:
            row_n += 1
            src_s = (row.get("path") or "").strip()
            if not src_s:
                skipped_filter += 1
                continue
            src = Path(src_s)
            ext = (row.get("ext") or "").lower().strip()
            suspect = (row.get("suspect") or "").strip().lower()
            try:
                size_b = int(row.get("size_bytes") or 0)
            except ValueError:
                size_b = 0

            if args.skip_suspect and suspect in ("yes", "true", "1"):
                skipped_filter += 1
                continue
            if should_skip_path(src_s):
                skipped_filter += 1
                continue
            if ext == "pdf" and size_b < args.min_pdf_bytes:
                skipped_filter += 1
                continue
            if not src.is_file():
                skipped_filter += 1
                continue

            try:
                digest = sha256_file(src)
            except OSError as e:
                log(f"ERR hash {src}: {e}")
                errors += 1
                continue

            if digest in known:
                skipped_dup += 1
            else:
                base = safe_dest_name(src.name)
                out = dest / base
                if out.exists():
                    stem = out.stem
                    suf = out.suffix
                    out = dest / f"{stem}_{digest[:10]}{suf}"
                try:
                    shutil.copy2(src, out)
                except OSError as e:
                    log(f"ERR copy {src} -> {out}: {e}")
                    errors += 1
                    continue
                known[digest] = out.name
                with manifest.open("a", encoding="utf-8") as mf:
                    mf.write(f"{digest}\t{out.name}\n")
                copied += 1

            if row_n % args.progress_every == 0:
                elapsed = time.time() - t0
                log(
                    f"row={row_n} copied={copied} dup={skipped_dup} "
                    f"skip_filter={skipped_filter} err={errors} elapsed_s={elapsed:.0f}"
                )

    elapsed = time.time() - t0
    log(
        f"DONE row={row_n} copied={copied} dup={skipped_dup} "
        f"skip_filter={skipped_filter} err={errors} elapsed_s={elapsed:.0f}"
    )
    return 0 if errors == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
