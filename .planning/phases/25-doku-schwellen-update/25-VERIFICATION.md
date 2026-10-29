---
phase: 25
phase_name: doku-schwellen-update
status: passed
verified: 2026-04-10
---

# Verification: Phase 25 — Doku + Schwellen-Update

## Phase Goal

Die Karpathy-Schwelle bleibt bei **500** und der Umstiegspfad auf RAG-Primary ist in `CLAUDE.md` (Repo) und `$TOM_VAULT/CLAUDE.md` (Vault) klar dokumentiert.

**Status:** ✓ Passed (4/4 requirements verified)

## Verification Results

### DOC13-01: Wissens-Kaskade bestätigt Schwelle 500

```bash
$ grep -n "500 Artikel" /Users/maxim/Claude/CLAUDE.md
143:   - Präzise bei bekannten Themen (bis **500 Artikel** — siehe Skalierungs-Stufen unten)
```

**Verified:** ✓ Schwelle ist weiterhin 500, nicht 1500.

### DOC13-02: Vault-CLAUDE.md konsistent

```bash
$ grep -n "500\|1500\|Karpathy\|Schwelle" "$TOM_VAULT/CLAUDE.md"
(no matches)
```

**Verified:** ✓ Vault-CLAUDE.md erwähnt die Schwelle nicht → keine Inkonsistenz möglich → auto-erfüllt.

### DOC13-03: Skalierungs-Stufen-Sektion

```bash
$ grep -n "Skalierungs-Stufen\|Index-first\|Hybrid\|RAG-Primary" /Users/maxim/Claude/CLAUDE.md
153:### Skalierungs-Stufen (v1.3-Entscheidung: Schwelle bleibt 500)
159:| **Index-first** | **<500 Artikel** | `tom-wiki` (Karpathy Index + Top-K) | `tom-ask` | **aktuell aktiv** |
160:| **Hybrid** | 500–2000 | `tom-wiki` mit engerem Keyword-Filter, `tom-ask` für fuzzy | — | geplant bei Überschreitung |
161:| **RAG-Primary** | >2000 | `tom-ask` (Cosine + LLM-Synthese) | `tom-wiki` nur für bekannte Topics | ferne Zukunft |
```

**Verified:** ✓ Neue Sektion mit vollständiger Skalierungs-Tabelle und 4-Schritte-Umstiegspfad vorhanden.

### DOC13-04: Maximus_OS-Issue an wiki-kurator

**FAM-135** abgesetzt via `bin/tom-issue --agent wiki-kurator`.

**Verified:** ✓ Issue dokumentiert Doku-Update mit Commit-Hash 3cf02cb.

## Commits Verified

```bash
$ git log --oneline 7a77699 842e0d0 3cf02cb
3cf02cb docs(phase-25): Karpathy-Schwelle bleibt 500 + Skalierungs-Stufen-Sektion
842e0d0 docs(state): Karpathy-Schwelle bleibt 500
7a77699 docs(phase-25): Schwellenwert bleibt 500 (User-Entscheidung)
```

## Deviation From Original Plan

**Original Plan:** Schwelle von 500 auf 1500 anheben (v1.2 → v1.3 Upgrade).

**User Decision (2026-04-10):** Schwelle bleibt 500. Grund: v1.3 Eval-Baseline bestätigt, dass die aktuelle Methode funktioniert. Umstieg soll durch **Präzisionsverlust** getriggert werden, nicht durch arbiträre Artikel-Zahl.

**Konsequenz:** REQUIREMENTS.md + ROADMAP.md + STATE.md wurden vor der Implementierung korrigiert (Commits 7a77699, 842e0d0). Die Phase wurde dann mit der korrigierten Zielsetzung ausgeführt.

## Phase Goal Achievement

✓ **Passed** — Die Karpathy-Schwelle ist in allen Planning-Artefakten und in `CLAUDE.md` konsistent auf 500 dokumentiert. Der Umstiegspfad auf RAG-Primary ist als explizite, messbare Skalierungs-Tabelle hinterlegt. Der Vault-CLAUDE.md benötigt keine Änderung (erwähnt die Schwelle nicht). Maximus_OS Audit-Trail via FAM-135 komplett.
