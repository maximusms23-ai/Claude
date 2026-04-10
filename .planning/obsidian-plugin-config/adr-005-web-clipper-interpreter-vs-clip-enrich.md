---
title: "ADR-005: Web-Clipper-Interpreter vs tom-clip-enrich — Rollen-Teilung"
created: 2026-04-10
type: adr
status: accepted
milestone: v1.4.1
phase: 35-hotfix
tags: [adr, web-clipper, ollama, gemme, interpreter, privacy]
---

# ADR-005 — Web-Clipper-Interpreter vs `tom-clip-enrich`: Rollen-Teilung

**Status:** Accepted — 2026-04-10
**Milestone:** v1.4.1 (Phase 35-Hotfix)
**Context-Ref:** Phase 35 lieferte 7 typ-spezifische Clipper-Templates ohne Nutzung des nativen Interpreter-Features. Phase 35-Hotfix korrigiert das.

## Context

Der Obsidian Web Clipper hat ein natives **Interpreter**-Feature: Template-Autoren können `{{"prompt text"}}`-Blöcke in Frontmatter oder Body einbauen. Beim Clip ruft die Extension einen konfigurierten LLM-Provider (OpenAI-kompatibel, Ollama, Anthropic) mit dem Prompt + Page-Content auf und ersetzt den Block durch die LLM-Antwort.

Phase 35 hat das übersehen und stattdessen den Post-hoc-Weg über `tom-clip-enrich "<file>"` gebaut — einen manuellen Shell-Call nach dem Clip, der `gemme` mit `format="json"` aufruft und `summary`, `tags`, `concepts`, `wiki_category` ins Frontmatter schreibt + Konzepte in `90_Wiki/konzepte-vorschlaege.md` anhängt.

Nach Phase-35-Abschluss hat Maxim festgestellt, dass die Interpreter-Variante fehlt. Damit überlappen zwei Enrichment-Pfade funktional: beide produzieren Summary + Tags + Konzept-Extraktion via `gemme`.

## Decision

**Der Web-Clipper-Interpreter ist ab sofort Primary für Clip-Zeit-Enrichment** (`summary`, `tags`, `konzepte_vorschlaege`, `enriched: clip-time`, `enriched_by: gemme-interpreter`).

**`tom-clip-enrich` bleibt erhalten in zwei klar abgegrenzten Rollen:**

1. **Fallback-Enrichment** (`tom-clip-enrich <file> --force`) — wenn der Interpreter nicht gelaufen ist (Ollama offline, CORS falsch, Extension-Toggle aus). Überschreibt Roh-Prompts mit gemme-generierten Werten und setzt `enriched_by: tom-clip-enrich`.
2. **Konzept-Queue-Writer** (`tom-clip-enrich <file> --queue-only`) — liest `konzepte_vorschlaege` aus dem Frontmatter (egal ob vom Interpreter oder vom eigenen Fallback befüllt) und hängt pro Konzept eine Zeile in `90_Wiki/konzepte-vorschlaege.md`. `summary`, `tags`, `enriched_by` werden **nicht** angefasst.

### Warum nicht voll-deprecaten?

1. **Interpreter kann nicht in externe Dateien schreiben** — die `90_Wiki/konzepte-vorschlaege.md`-Review-Queue aus Phase 30 ist ein zentrales Wiki-Tom-Feature und bleibt Python-only.
2. **Idempotenter Retry** (`--force`) mit JSON-Output-Validation (`format="json"`) ist robuster als 3 separate Free-Text-Prompts des Interpreters. Bei Ollama-Ausfall während des Clippens ist ein sauberer Wiederherstellungs-Pfad wichtig.
3. **Zero-Lock-in auf Extension-Feature**: Wenn der Obsidian Web Clipper das Interpreter-Feature ändert oder Maxim auf einen anderen Clipper wechselt, bleibt die Enrichment-Logik in Python erhalten.

## Consequences

### Frontmatter-Feld-Erweiterung

Neues Feld `enriched_by` unterscheidet die Herkunft:

| Wert | Bedeutung |
|---|---|
| `gemme-interpreter` | Clip-Zeit via Browser-Extension-Interpreter |
| `tom-clip-enrich` | Post-hoc via Shell-Wrapper (Fallback oder Phase-30-Legacy) |
| *(leer/fehlt)* | Noch nicht enriched, oder Legacy-Clip vor Phase 35-Hotfix |

Das bestehende Feld `enriched` akzeptiert jetzt drei Werte statt nur `true`:

| Wert | Bedeutung |
|---|---|
| `clip-time` | Interpreter hat zur Clip-Zeit geschrieben |
| `true` | `tom-clip-enrich` hat post-hoc geschrieben (Legacy + Fallback-Pfad) |
| `false` | Noch nicht enriched |

### `clip_enrich.py`-Patch

Minimaler Patch (~40 Zeilen) in `claude-memory-compiler/tom_tools/clip_enrich.py`:

- Neuer CLI-Flag `--queue-only` → neuer Code-Pfad der nur `append_concept_suggestions()` ruft
- Skip-Gate erweitert: `enriched in ("true", "yes", "1", "clip-time", "tom-clip-enrich")` wird ohne `--force` übersprungen
- Standard-Pfad schreibt jetzt zusätzlich `enriched_by: tom-clip-enrich` ins Frontmatter
- Rückwärts-kompatibel: alte Clippings mit `enriched: true` bleiben skip-fähig, alte API ohne `queue_only`-Argument funktioniert weiter

### Templates

Alle 7 Clipper-Templates in `$TOM_VAULT/99_Vorlagen/web-clipper/*.md` nutzen ab sofort 3 Interpreter-Prompts pro Template (`summary`, `tags`-Ergänzung, `konzepte_vorschlaege`). Jeder Prompt enthält eine String-Hinweis "Betrachte nur die ersten X Zeichen" als Context-Budget-Schutz gegen gemme's 8K-Fenster.

### Performance-Trade-off

3 sequentielle gemme-Calls pro Clip, je ~5–15 s → Gesamt-Clip-Zeit **15–45 s** statt **<1 s** beim reinen Preset-Clip. Das ist der bewusste Kompromiss gegen die UX-Regression, weil das Clip-Ergebnis direkt anreichert-fertig im Vault liegt ohne manuellen Shell-Call.

Mitigation: Ollama `keep_alive=5m` (Default) hält `gemme` nach erstem Call im RAM, Folge-Clips sind schneller.

### Privacy

- `OLLAMA_ORIGINS` wird persistent via `launchctl setenv` gesetzt auf `chrome-extension://*,moz-extension://*` — **nur** Browser-Extensions, nicht beliebige Web-Origins
- Alle Interpreter-Calls bleiben 100 % lokal (Ollama läuft auf Maxim's Maschine, `gemme` ist Custom-Modell auf `gemma4:e4b`)
- Beim Clip schickt die Extension den `{{content}}`-Body an Ollama — lokal, aber Maxim entscheidet pro Clip, ob er auf privaten Seiten clippt

## Alternatives Considered

### A) Voll-Deprecation von `tom-clip-enrich`

**Verworfen**, weil:

- Die `konzepte-vorschlaege.md`-Queue bräuchte einen anderen Writer (Obsidian-Plugin? Separater Watcher-Daemon?) → deutlich mehr Code
- Kein Fallback-Pfad mehr wenn Ollama während des Clippens ausfällt
- `format="json"`-Garantie von Python/ollama-Lib ist robuster als Free-Text-Prompts

### B) Nur `tom-clip-enrich` behalten, kein Interpreter

**Verworfen**, weil:

- Widerspricht dem v1.4-Architektur-Prinzip "lokale gemme-Integration **direkt im Editor/Tool**", das Phase 29 mit Smart Connections schon etabliert hat
- Maxim muss sonst nach jedem Clip manuell einen Shell-Call machen → UX-Regression

### C) Single-Prompt-JSON via Interpreter

Ein einziger Interpreter-Prompt, der JSON zurückliefert (`{"summary": …, "tags": […], "concepts": […]}`), statt 3 separate Prompts.

**Verworfen für v1.4.1**, weil:

- Community-Recherche zeigt nicht eindeutig, ob der Web Clipper Interpreter `format="json"` unterstützt
- Die 3-Prompt-Variante ist robust, auch wenn ein Prompt scheitert bekommt man trotzdem 2/3 der Felder
- Kann in v1.5+ konsolidiert werden, wenn Extension-Feature klar ist

## Verification

- [x] Templates enthalten je ≥3 `{{"…"}}`-Blöcke (`grep -c '{{"' <template>` ≥ 3)
- [x] `clip_enrich.py --queue-only` schreibt nur in Queue, ändert Clip-File nicht (Unit-Dry-Run)
- [x] `enriched: clip-time` wird von `enrich_file()` als skip-Grund erkannt (Unit-Dry-Run)
- [x] `launchctl getenv OLLAMA_ORIGINS` zeigt die Extension-Origins
- [ ] Maxim-Handoff: 1 echter Clip über Interpreter produziert gefülltes Frontmatter (CLIP141-13)
- [ ] Maxim-Handoff: Fallback-Pfad (Ollama offline + `tom-clip-enrich --force`) produziert Fallback-Frontmatter
- [ ] Maxim-Handoff: `--queue-only` Konzept-Übernahme ins `konzepte-vorschlaege.md`

## References

- Phase 35 Plan / SUMMARY: `.planning/phases/35-web-clipper-templates/`
- Phase 35-Hotfix Plan: *(dieser Commit)*
- `clip_enrich.py`: `claude-memory-compiler/tom_tools/clip_enrich.py`
- Templates: `$TOM_VAULT/99_Vorlagen/web-clipper/*.md`
- Related ADRs: ADR-001 (Smart Connections Privacy), ADR-003 (obsidian-ocr Koexistenz)
- Obsidian Web Clipper: https://github.com/obsidianmd/obsidian-clipper
