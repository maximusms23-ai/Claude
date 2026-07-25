---
phase: 23
plan: "01"
subsystem: tom-wiki
tags: [wiki-query, keyword-filter, quality-pass, ollama, gemme]
dependency_graph:
  requires: []
  provides: [wiki_query.keyword_filter, wiki_query.top_k, wiki_query.citation_prompt]
  affects: [tom-wiki CLI]
tech_stack:
  added: []
  patterns: [Keyword-Scoring, Top-K-Filter, Citation-Enforcement]
key_files:
  created: []
  modified:
    - claude-memory-compiler/tom_tools/wiki_query.py
    - claude-memory-compiler/TOM-PATCHES.md
decisions:
  - "STOPWORDS manuell erweitert (gibt hinzugefuegt) damit extract_keywords('Welche Gemma 4 Groessen gibt es?') 'gibt' herausfiltert"
  - "Smoke-Test Fallback nicht noetig: konzepte/turboquant.md existiert im Vault"
  - "Maximus_OS-Issue FAM-129 an cto abgesetzt mit Before/After-Auszug"
metrics:
  duration: "~15 min"
  completed: "2026-04-10"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
requirements_closed: [QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06]
---

# Phase 23 Plan 01: tom-wiki Quality-Pass Summary

**One-liner:** Keyword-Filter + Top-K=5 Artikel-Auswahl + Zitations-Pflicht-Prompt für tom-wiki (wiki_query.py), verifiziert via Live-Smoke-Test gegen echten Vault.

## Was wurde gemacht

### Task 1 — wiki_query.py: Keyword-Filter + Top-K + verschaerfter System-Prompt

Drei Erweiterungen an `claude-memory-compiler/tom_tools/wiki_query.py`:

**Neue Konstanten:**
- `TOP_K = 5` — max. Artikel zusaetzlich zum Index
- `MIN_KEYWORD_LEN = 3` — kurze Tokens ignorieren
- `STOPWORDS` — deutsche + englische Basisliste (ca. 45 Eintraege)

**Neue Funktionen:**
- `extract_keywords(question)` — Tokenisierung, Stopword-Filter, Lowercase
- `score_article(content, keywords)` — Scoring: Titel (+5), Header (+3), erster Absatz (+2), Body (min count, capped 5)

**Erweiterte Funktion:**
- `collect_wiki_content(root, question)` — Signature um `question` erweitert; laedt jetzt Index + Top-K statt alle Artikel

**Neuer System-Prompt:**
- Verlangt explizit Quelldatei-Zitation (Dateiname oder `[[wikilink]]`)
- Verbietet generische Floskeln
- Ehrlicher Hinweis + `tom-ask`-Fallback wenn Wiki nichts enthaelt
- Format: 3-8 Saetze plus Quellenzeile

**CLI-Surface unveraendert** (`bin/tom-wiki`, argparse in `main()`).

Commit: `d47e2a9`

### Task 2 — Smoke-Test + TOM-PATCHES.md + Maximus_OS-Issue

**Smoke-Test (Live gegen Vault):**

Query: `tom-wiki "Was ist TurboQuant?"`

Ergebnis (NACHHER):
```
TurboQuant ist ein von Google Research entwickelter KV-Cache-Quantisierungsalgorithmus,
der den Key-Value-Cache während der Inferenz auf bis zu 3 Bit komprimiert. Im Gegensatz
zur Quantisierung der Modellgewichte (wie GGUF) optimiert TurboQuant den Laufzeit-
Speicherbedarf des Kontext-Verständnisses. [...]
Die niedrigste Stufe, `turbo3`, erreicht eine Kompression von 4.9x des KV-Cache-Speichers.

Quelle: konzepte/turboquant.md

Quellen-Scope (Index + Top-5 Keyword-Matches):
  - 90_Wiki/index.md
  - 90_Wiki/konzepte/turboquant.md
  - 90_Wiki/themen/gemma4.md
  - 90_Wiki/konzepte/gguf-quantisierung.md
  - 90_Wiki/konzepte/Konzepte-Index.md
  - 90_Wiki/konzepte/ollama.md
```

**TOM-PATCHES.md:** Patch 7 (v1.3 Quality-Pass) eingefuegt mit Before/After und Backwards-Compat-Hinweis.

**Maximus_OS-Issue:** FAM-129 an CTO-Agent abgesetzt mit Before/After-Beispiel.

Commit: `a9048ce`

## QUAL-Requirement-Status

| Req    | Beschreibung                        | Status |
|--------|-------------------------------------|--------|
| QUAL-01 | System-Prompt mit Zitations-Pflicht | DONE   |
| QUAL-02 | Keyword-Filter + Top-K Context      | DONE   |
| QUAL-03 | Quellen-Zitation im Output          | DONE   |
| QUAL-04 | Smoke-Test turboquant.md zitiert    | DONE   |
| QUAL-05 | TOM-PATCHES.md Abschnitt 7          | DONE   |
| QUAL-06 | Maximus_OS-Issue FAM-129 abgesetzt  | DONE   |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] STOPWORDS fehlte "gibt"**
- **Found during:** Task 1, Smoke-Test
- **Issue:** `extract_keywords('Welche Gemma 4 Groessen gibt es?')` lieferte `['gemma', 'groessen', 'gibt']` — "gibt" war nicht in STOPWORDS
- **Fix:** "gibt" zu STOPWORDS hinzugefuegt
- **Files modified:** `claude-memory-compiler/tom_tools/wiki_query.py`
- **Commit:** `d47e2a9`

## Self-Check: PASSED

- wiki_query.py: FOUND
- TOM-PATCHES.md: FOUND
- Commit d47e2a9: FOUND
- Commit a9048ce: FOUND
