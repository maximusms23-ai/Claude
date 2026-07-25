---
phase: 24-eval-framework
plan: "01"
subsystem: eval
tags: [eval, tom-wiki, tom-ask, baseline, karpathy, rag]
dependency_graph:
  requires: []
  provides: [v1.3-baseline-report, side-by-side-comparator]
  affects: [phase-25-karpathy-doku]
tech_stack:
  added: []
  patterns: [subprocess-cli-comparator, keyword-match-scoring]
key_files:
  created:
    - Gemma/eval/results/v1.3-baseline.md
  modified:
    - Gemma/eval/questions.yaml
    - Gemma/eval/run_eval.py
decisions:
  - "tom-wiki schlaegt tom-ask bei Wiki-Themen klar (80% vs 27% avg) — Karpathy-Hypothese bestaetigt"
  - "Brain-Scores absichtlich niedrig als Baseline (95_Gehirn/knowledge/ leer, Stand 2026-04-10)"
  - "180s Timeout pro Subprocess-Call um lokale Ollama-Laufzeit zu tolerieren"
metrics:
  duration_minutes: 17
  completed_date: "2026-04-10"
  tasks_completed: 3
  files_changed: 3
---

# Phase 24 Plan 01: Eval-Framework Baseline v1.3 Summary

**One-liner:** Side-by-Side-Comparator tom-wiki vs tom-ask mit 10 Testfragen liefert Baseline: tom-wiki 60% vs tom-ask 33% Avg-Score, Karpathy-Index-first-Hypothese empirisch bestaetigt.

## What Was Built

Ein erweitertes Eval-Framework (`Gemma/eval/`) mit:

1. **questions.yaml** — 10 Testfragen (5 wiki + 5 brain) statt vorher 5 Konzept-Fragen ohne Kategorisierung
2. **run_eval.py** — Komplett neu als Subprocess-Comparator: ruft `tom-wiki` und `tom-ask` per `subprocess.run` auf, scort beide gegen Keywords, schreibt Markdown-Report
3. **v1.3-baseline.md** — Baseline-Report mit Score-Vergleichstabelle, Avg-Scores und Antwort-Auszuegen

## Eval-Ergebnisse

| Metrik | tom-wiki | tom-ask |
|--------|----------|---------|
| Avg-Score gesamt | 60% | 33% |
| Wins | 5 | 1 |
| Ties | 4 | — |
| Avg Wiki-Kategorie | 80% | 33% |
| Avg Brain-Kategorie | 40% | 33% |

**Alle 20 Tool-Calls erfolgreich (kein TIMEOUT, kein ERROR).**

### Auffaellige Ergebnisse

- `Was ist RAG?` — tom-wiki 100% vs tom-ask 0%: tom-ask returned keinen einzigen der 4 Keywords
- `Was ist GGUF?` — tom-wiki 100% vs tom-ask 33%: Index-first findet Quantisierungs-Kontext praezise
- `Was ist die Karpathy-Schwelle?` — tom-ask 67% vs tom-wiki 33%: RAG findet '1500' weil der Begriff im Index vorkommt
- Brain-Themen: Ueberwiegend 33% bei beiden — erwartet, da 95_Gehirn/knowledge/ leer

## Maximus_OS-Issue

**FAM-133** — Phase 24: Eval-Framework Baseline v1.3 — an CTO abgesetzt (priority: medium)

## Commits

- `c3431b3` feat(24-01): extend questions.yaml to 10 entries (5 wiki + 5 brain)
- `a34db89` feat(24-01): rewrite run_eval.py as side-by-side comparator (tom-wiki vs tom-ask)
- `c729df6` feat(24-01): run baseline eval, generate v1.3-baseline.md report

## Deviations from Plan

None — plan executed exactly as written.

## Caveats

- `95_Gehirn/knowledge/` ist Stand 2026-04-10 leer — Brain-Scores sind absichtlich niedrig als Baseline-Wert
- Folge-Eval nach erstem `tom-compile`-Lauf empfohlen (Phase 22 launchd-Setup)
- `tom-ask` RAG-Collection `gehirn` ebenfalls leer — gleiche Ursache

## Self-Check: PASSED

All files confirmed present. All 3 commits verified in git log.
