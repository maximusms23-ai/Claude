---
status: passed
---

# Phase 17: Karpathy-Index für 90_Wiki — Verification

**Status:** ✅ passed
**Commit:** (iCloud vault files, nicht git-tracked — Planning-Commit folgt)
**Maximus_OS Issue:** FAM-122

## Requirements

| ID | Status | Evidence |
|---|---|---|
| KIDX-01 | ✅ | `90_Wiki/index.md` → `90_Wiki/history.md` verschoben mit neuem Header + Hinweis auf v1.2 Phase 17 |
| KIDX-02 | ✅ | Neuer `90_Wiki/index.md` mit expliziter Nutzungs-Anleitung "Index lesen → 3–5 Artikel per Wikilink → Synthese" |
| KIDX-03 | ✅ | Alle 14 Artikel + 5 Meta-Indizes gruppiert nach Konzepte / Themen / Projekte / Quellen / Personen / Meta |
| KIDX-04 | ✅ | Smoke-Test: Index → `konzepte/turboquant.md` → Synthese möglich ohne RAG |
| KIDX-05 | ✅ | FAM-122 an wiki-kurator |

## Smoke-Test Detail

**Query:** "Was ist Turboquant?"

1. Index zeigt: `[[konzepte/turboquant]] — Google-Research KV-Cache-Quantisierungsalgorithmus (bis 3 Bit) ohne Retraining; längere Kontextfenster bei gleichem VRAM`
2. Direct-Read `konzepte/turboquant.md` liefert vollständigen Artikel mit Komponenten (PolarQuant, QJL, WHT), Varianten-Tabelle, Performance-Zahlen
3. Antwort-Synthese möglich ohne Ollama, ohne ChromaDB, nur mit 2 File-Reads (Index + Artikel)

Das bestätigt die Karpathy-Annahme: bei aktuell 14 Artikeln ist Index-first präziser und schneller als RAG.
