---
title: "Phase 38 Verification — Local Tool-Use Modell-Upgrade"
created: 2026-04-12
type: verification
---

# Phase 38: Verification Report

## Test-Matrix

| Test | Modell | Methode | Ergebnis | Details |
|------|--------|---------|----------|---------|
| Ollama-native Tool-Call | `qwen2.5-coder` | `/api/chat` + `tools` | **FAIL** | Tool-Call als Text-String im `content`, kein `tool_calls[]`-Array |
| Ollama-native Tool-Call | `qwen2.5:3b` | `/api/chat` + `tools` | **PASS** | `message.tool_calls[0].function.name == "list_files"`, leerer `content` |
| Multi-Tool-Selection | `qwen2.5:3b` | `/api/chat` + 2 Tools | **PASS** | Korrekt `get_weather` gewählt statt `list_files` |
| CCR-Proxy Anthropic-Format | `qwen2.5:3b` via CCR | `/v1/messages` + Anthropic tools | **PASS** | `content[0].type == "tool_use"`, `stop_reason: tool_use` |
| Real-Use: Read-Tool | `qwen2.5:3b` via CCR | 3-Tool-Set (Read/Shell/Write) | **PASS** | Korrekt `Read` mit Pfad selektiert |
| Real-Use: Shell-Tool | `qwen2.5:3b` via CCR | 3-Tool-Set (Read/Shell/Write) | **PASS** | Korrekt `Shell` mit `git status` selektiert |
| tom-compile --local | `qwen2.5:3b` | `--file daily --dry-run` | **PASS** | 12s, 1 Artikel generiert, Parse OK |

## Schlüssel-Erkenntnis

`qwen2.5:3b` (1.9 GB) liefert native Tool-Calls korrekt — sowohl direkt über Ollama als auch über den CCR-Proxy im Anthropic-Format. `qwen2.5-coder` (4.7 GB) hingegen verpackt Tool-Calls immer noch als Text-String, exakt wie in Phase 36 dokumentiert.

Die Ursache liegt wahrscheinlich im Finetuning: `qwen2.5-coder` wurde primär auf Code-Completion optimiert und hat ein anderes Tool-Call-Handling als das Basis-Modell `qwen2.5:3b`.

## OpenClaw-Fix

Live-Config `~/.openclaw/openclaw.json` von `gemma4:latest` auf `qwen2.5:3b` umgestellt. Betrifft:
- `agents.defaults.model.primary`: `ollama/gemma4:latest` → `ollama/qwen2.5:3b`
- `models.providers.ollama.models[0].id/name`: `gemma4:latest` → `qwen2.5:3b`
- `reasoning`: `true` → `false`

## CCR-Config-Fix

Von defunktem `omniroute:20128`-Provider zurück auf direktes Ollama:
- Provider: `ollama` → `http://localhost:11434/v1/chat/completions`
- Router: `default` + `background` → `ollama,qwen2.5:3b`
- Reference-Copy: `ccr-config.reference.json` in diesem Verzeichnis

## Regressions-Check

`tom-compile --local` mit daily-log `2026-04-11.md`:
- Parse: OK
- Duration: 12.19s
- Articles created: 1 (`concepts/ocr-pipeline.md`)
- Keine Regression gegenüber Phase 31 Baseline
