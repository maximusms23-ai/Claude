# Phase 28 Verification

**Phase:** 28 — tom-doc CLI
**Milestone:** v1.4
**Date:** 2026-04-10
**Status:** ✓ PASS

## Success Criteria

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| 1 | `tom-doc --help` zeigt alle 4 Subcommands | Output listet index/search/list/show | ✓ |
| 2 | `tom-doc search "Arbeitsvertrag"` liefert Treffer | Snippet: `"…Dieser [Arbeitsvertrag] ersetzt alle…"` | ✓ |
| 3 | `tom-doc list` zeigt indizierte Dokumente | `[  1] [vault:raw] 2204_Arbeitsvertrag_Schmidt.pdf (27p, 8894KB)` | ✓ |
| 4 | `tom-doc show 1` zeigt Metadaten + Auszug | 8 Metadaten-Felder + Excerpt-Block | ✓ |
| 5 | `tom-doc index --file <pdf>` idempotent | Zweiter Lauf: `status: skip, id=1` | ✓ |
| 6 | `~/bin/tom-doc` Symlink existiert | `-> /Users/maxim/Claude/bin/tom-doc` | ✓ |
| 7 | CLAUDE.md erwähnt tom-doc in Wissens-Kaskade | Punkt 4 (Answering) + Punkt 5 (Kaskade) | ✓ |

## Requirements

| Requirement | Status | Evidence |
|-------------|--------|----------|
| TDOC-01 | ✓ | `bin/tom-doc` mit index/search/list/show |
| TDOC-02 | ✓ | `tom-doc index <kat>` / `--all` / `--file` |
| TDOC-03 | ✓ | FTS5-Search mit Snippet-Ausgabe |
| TDOC-04 | ✓ | `show` akzeptiert id/pfad/filename/sha-prefix |
| TDOC-05 | ✓ | `list` optional nach Kategorie gefiltert |
| TDOC-06 | ✓ | `~/bin/tom-doc` symlinked |
| TDOC-07 | ✓ | CLAUDE.md Wissens-Kaskade erweitert |

## Smoke-Test Transcript

```
$ tom-doc search "Arbeitsvertrag" --limit 3
[vault:raw] 2204_Arbeitsvertrag_Schmidt.pdf
  …Schriftformklausel / Dieser [Arbeitsvertrag] ersetzt alle eventuellen vorherigen Vereinbarungen…
  → /Users/maxim/Library/Mobile Documents/.../raw/2204_Arbeitsvertrag_Schmidt.pdf

$ tom-doc list
Indexed documents (1)
---------------------
  [  1] [vault:raw] 2204_Arbeitsvertrag_Schmidt.pdf  (27p, 8894KB)

$ tom-doc show 1 --excerpt 300
ID:         1
Filename:   2204_Arbeitsvertrag_Schmidt.pdf
Category:   vault:raw
SHA256:     7dcfc40b6026b8ea83de01d05c0866978a12ffb0becc0b930d9c1e78998ff79b
Size:       9108264 bytes
Pages:      27
Total text: 89805 chars

── Excerpt ──
invenio Systems Engineering GmbH | Sossenheim
...

$ tom-doc index --file "<same-pdf>"
status: skip, id: 1 (idempotent)
```

## Files Changed

- `+ bin/tom-doc` (Bash-Wrapper, executable, symlinked to ~/bin/)
- `~ archivum/ocr_pipeline.py` (+ `list_documents`, `show_document`, `--list`, `--show`, `--limit`, `--excerpt`)
- `~ CLAUDE.md` (Wissens-Kaskade Punkt 4 + 5 erweitert)
- `~ .planning/REQUIREMENTS.md` (TDOC-01..07 → Complete)
- `+ .planning/phases/28-tom-doc-cli/{28-01-PLAN,VERIFICATION,SUMMARY}.md`

## Status: ✓ READY FOR PHASE 29 (Smart Connections) / PHASE 30 (Clipper Enrichment)
