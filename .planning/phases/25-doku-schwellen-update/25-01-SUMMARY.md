---
plan: 25-01
phase: 25
status: complete
completed: 2026-04-10
---

# SUMMARY: Phase 25 — Doku + Schwellen-Update

## Goal

Die Karpathy-Schwelle bleibt bei **500** und der Umstiegspfad auf RAG-Primary ist in `CLAUDE.md` (Repo) und `$TOM_VAULT/CLAUDE.md` (Vault) klar dokumentiert.

## Decision

**Schwelle bleibt 500** (User-Entscheidung, 2026-04-10). Keine Anhebung auf 1500 wie ursprünglich im Plan vorgesehen.

**Begründung:** Die v1.3-Eval-Baseline (Phase 24, `Gemma/eval/results/v1.3-baseline.md`) zeigt `tom-wiki` mit 80% auf Wiki-Queries vs `tom-ask` mit 33%. Die aktuelle Index-first-Methode funktioniert gut und soll erst umgestellt werden, wenn die Präzision spürbar fällt — nicht aufgrund einer arbiträren Artikel-Schwelle.

## Was geändert wurde

### CLAUDE.md (Repo)

- Wissens-Kaskade-Sektion: "~500 Artikel" → "**500 Artikel** — siehe Skalierungs-Stufen unten"
- Neue Sektion "### Skalierungs-Stufen (v1.3-Entscheidung: Schwelle bleibt 500)" mit:
  - Begründung der Entscheidung (Eval-Baseline)
  - Tabelle der drei Stufen: Index-first (<500, aktuell aktiv), Hybrid (500–2000, geplant), RAG-Primary (>2000, ferne Zukunft)
  - Konkreter 4-Schritte-Umstiegspfad bei Überschreitung

### $TOM_VAULT/CLAUDE.md

**Unverändert** — Konsistenz-Check `grep -n "500\|1500\|Karpathy\|Schwelle"` liefert 0 Matches. Der Vault-CLAUDE.md erwähnt die Schwelle nicht, also ist nichts zu synchronisieren. DOC13-02 ist damit auto-erfüllt.

## Requirements Coverage

| REQ | Status | Evidence |
|-----|--------|----------|
| DOC13-01 | ✓ | `CLAUDE.md` Zeile 143: "bis **500 Artikel** — siehe Skalierungs-Stufen unten" |
| DOC13-02 | ✓ | Vault-CLAUDE.md erwähnt die Schwelle nicht — auto-erfüllt |
| DOC13-03 | ✓ | `CLAUDE.md` neue Sektion "Skalierungs-Stufen" mit vollständiger Tabelle |
| DOC13-04 | ✓ | Maximus_OS Issue **FAM-135** an wiki-kurator (medium priority) |

## Commits

- `7a77699`: docs(phase-25): Schwellenwert bleibt 500 (REQUIREMENTS + ROADMAP korrigiert vor Implementierung)
- `842e0d0`: docs(state): Karpathy-Schwelle bleibt 500 (STATE.md Accumulated Context korrigiert)
- `3cf02cb`: docs(phase-25): Karpathy-Schwelle bleibt 500 + Skalierungs-Stufen-Sektion (CLAUDE.md Implementation)

## Maximus_OS Audit-Trail

**FAM-135** — wiki-kurator, medium priority, full context + commit-hash.

## Notes

Dies war eine reine Doku-Phase — kein Code geändert, keine Tests nötig. Phase lief inline statt via Planner/Executor-Agenten weil Umfang minimal war (3 kleine Edits + 1 Issue).
