# Phase 31 Summary

**Token-Spar-Lokalisierung** — v1.4 Phase 31

## What Shipped

- `tom_tools/compile_local.py` — alternative Compile-Implementierung via lokalem `gemme` (Ollama), ohne `claude_agent_sdk`
- `bin/tom-compile --local` dispatcht auf das neue Modul; Default bleibt `claude_agent_sdk`
- `Gemma/eval/results/v1.4-compile-local-vs-claude.md` — Vergleichs-Report mit Messungen auf real + synthetic log
- `CLAUDE.md` — dokumentiert `--local` Opt-in und `tom-lint --structural-only` als empfohlener launchd-Default (kein neues `--no-llm` Flag nötig — minimal-invasive Lösung)

## Requirements Complete

LOCAL-01..04 ✓ (4/4) — mit v1.5-Deferral für 3-Log-Vollvergleich (braucht mehr echte daily-logs)

## Key Decisions

- **Structured-data-first JSON**: Der LLM returnt flache Daten (slug/title/kernpunkte/details/related), Python baut das Markdown-Frontmatter und die Sections deterministisch. Eliminiert multi-line-string-Escaping-Probleme beim JSON-Parsing.
- **Default bleibt claude_agent_sdk**: Tool-Access + Multi-turn-Exploration + validierte Qualität schlagen Kosten-Ersparnis für Maxim's Nutzungsprofil.
- **`--local` als Safety-Net**: Offline-fähig, keine Subscription nötig, deterministisch. Für Experimente und Quota-Engpässe.
- **kein neues `--no-llm` Flag für tom-lint**: `--structural-only` existiert bereits seit v1.2 und ist funktional äquivalent. Dokumentation verstärkt statt Flag-Duplikat.

## Cost Snapshot

- Claude SDK auf Real-Log (FLUSH_OK-only): **$0.22 Subscription-Quota für 0 Artikel-Output**
- Local (gemme) auf Real-Log: **$0.00** für 0 Artikel-Output
- Local auf Synthetic-Log: **$0.00** für 2 Artikel (67.75s Laufzeit)

Ersparnis-Kontext: primär prinzipiell (Offline-Fähigkeit, Subscription-Entlastung), ökonomisch marginal (~$0.04-0.22 pro Tag).

## Next Up

**Phase 32: Milestone-Close v1.4** — Alle 6 Doku-Kanäle nach v1.3-Close-Checklist (MILESTONES/PROJECT/CEO-Briefing/log/Tom.md/Close-Issue).
