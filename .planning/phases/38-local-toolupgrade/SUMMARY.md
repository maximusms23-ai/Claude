---
title: "Phase 38 Summary — Local Tool-Use Modell-Upgrade"
created: 2026-04-12
type: summary
status: done
---

# Phase 38: Local Tool-Use Modell-Upgrade

## Ziel

Tool-Use-Fähigkeit im lokalen Ollama-Modus herstellen — Phase 36 hatte gezeigt, dass `qwen2.5-coder` Tool-Calls nur als Text-String statt als strukturierte `tool_use`-Blöcke liefert.

## Ergebnis

**PASS** — `qwen2.5:3b` (1.9 GB, das bereits installierte Chat-Modell) kann nativ Tool-Calls. Kein neues Modell nötig.

## Was wurde gemacht

1. **OpenClaw-Config gefixt**: Live-Config von `gemma4:latest` auf `qwen2.5:3b` umgestellt (`.openclaw/openclaw.json` + `.tmp-openclaw/openclaw.json`)
2. **Ollama-native Tests**: `qwen2.5:3b` PASS, `qwen2.5-coder` FAIL (Text-String statt `tool_calls[]`)
3. **CCR-Config repariert**: Von defunktem `omniroute:20128` zurück auf direktes Ollama (`localhost:11434`) mit `qwen2.5:3b`
4. **CCR-Proxy Tool-Use PASS**: Anthropic-Format `/v1/messages` liefert korrekte `tool_use`-Blöcke mit `stop_reason: tool_use`
5. **Real-Use-Tests**: Read-Tool und Shell-Tool korrekt aus 3-Tool-Set selektiert
6. **Regressions-Check**: `tom-compile --local` weiterhin funktional (12s, 1 Artikel)
7. **`glm-4.7-flash` entfernt**: 19 GB freigegeben
8. **Doku aktualisiert**: CLAUDE.md Limitations FAIL→PASS, Use-Cases erweitert, REQUIREMENTS.md LOCAL-06 komplett

## Architektur-Entscheidung

`qwen2.5:3b` bleibt das **einzige** lokale Modell für Chat UND Tool-Use. `qwen2.5-coder` wird nicht mehr für Tool-Use eingesetzt — sein Finetuning auf Code-Completion verhindert strukturierte Tool-Calls. Für reine Code-Fragen kann es weiterhin per `ollama run qwen2.5-coder` direkt genutzt werden.

## Shipped

- `~/.claude-code-router/config.json` → `qwen2.5:3b`
- `~/.openclaw/openclaw.json` → `qwen2.5:3b`
- CLAUDE.md: Tool-Use PASS dokumentiert + Use-Cases erweitert
- REQUIREMENTS.md: LOCAL-06-01..06 alle `[x]`
- `glm-4.7-flash` entfernt (19 GB frei)

## Requirements-Coverage

| REQ | Status |
|-----|--------|
| LOCAL-06-01 | ✓ qwen2.5:3b nativ Tool-Calls |
| LOCAL-06-02 | ✓ CCR-Config auf qwen2.5:3b |
| LOCAL-06-03 | ✓ Tool-Use-Gate PASS |
| LOCAL-06-04 | ✓ Real-Use-Test PASS |
| LOCAL-06-05 | ✓ CLAUDE.md aktualisiert |
| LOCAL-06-06 | ✓ tom-compile Regression PASS |
