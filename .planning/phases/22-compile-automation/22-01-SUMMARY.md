---
phase: 22
plan: 01
subsystem: compile-automation
tags: [wrapper, bash, logging, preflight, launchd]
dependency_graph:
  requires: []
  provides: [bin/tom-compile-safe]
  affects: [bin/tom-compile, launchd-job-22-02]
tech_stack:
  added: []
  patterns: [preflight-check, structured-logging]
key_files:
  created:
    - bin/tom-compile-safe
  modified: []
decisions:
  - "set -uo pipefail statt set -euo pipefail damit Exit-Code nach tom-compile-Lauf captured werden kann"
  - "SKIP statt FAIL bei fehlenden Voraussetzungen (ollama weg, iCloud nicht gemountet) damit launchd kein Error-Reporting bekommt"
  - "Preflight 4 (tom-compile executable) als FAIL+exit 1 weil das ein Setup-Fehler ist, nicht ein transientes Problem"
metrics:
  duration: "~3 min"
  completed_date: "2026-04-10"
  tasks_completed: 2
  files_changed: 1
---

# Phase 22 Plan 01: tom-compile-safe Preflight Wrapper Summary

**One-liner:** Fehlertoleranter Bash-Wrapper mit 4 Preflight-Checks (ollama binary, ollama server, TOM_VAULT exists/readable, tom-compile executable) und strukturiertem Logging nach ~/Library/Logs/tom-compile.log.

## What Was Built

`bin/tom-compile-safe` — ein Bash-Wrapper der vor jedem `tom-compile`-Aufruf prüft ob die Voraussetzungen erfüllt sind und jeden Lauf (auch Abbrüche) mit Timestamp, Status, Exit-Code und Duration loggt.

## Tasks

### Task 1: bin/tom-compile-safe Wrapper

Datei erstellt mit:
- `set -uo pipefail` (nicht `-e`, damit `$RC` nach `"$TOM_COMPILE" "$@"` korrekt gesetzt wird)
- 4 Preflight-Checks in Reihenfolge
- `log_line()` Funktion mit Format `YYYY-MM-DD HH:MM:SS tz | STATUS | EXIT=N | DURATION=Ns | MSG`
- START-Log vor Aufruf, OK/FAIL-Log danach

**Commit:** 330cc7a

### Task 2: Smoke-Test

Zwei SKIP-Pfade getestet:

- `TOM_VAULT=/nonexistent/path/xyz` → Exit 0, Log: `SKIP | EXIT=0 | DURATION=0s | TOM_VAULT not reachable: /nonexistent/path/xyz`
- `PATH=/usr/bin:/bin` → Exit 0, Log: `SKIP | EXIT=0 | DURATION=0s | ollama binary not found in PATH`

Log-Datei nach Test:
```
2026-04-10 14:21:32 +0200 | SKIP | EXIT=0 | DURATION=0s | TOM_VAULT not reachable: /nonexistent/path/xyz
2026-04-10 14:21:32 +0200 | SKIP | EXIT=0 | DURATION=0s | ollama binary not found in PATH
```

## Deviations from Plan

None — plan executed exactly as written.

## Requirements Fulfilled

- **CRON-02:** Wrapper prüft ollama + $TOM_VAULT vor Ausführung, exitet sauber mit Log-Eintrag bei fehlenden Voraussetzungen.
- **CRON-03:** Jeder Lauf (auch SKIP) erzeugt eine Log-Zeile in `~/Library/Logs/tom-compile.log` mit Timestamp, Exit-Code und Duration.

## Self-Check: PASSED

- `bin/tom-compile-safe` exists: FOUND
- Commit 330cc7a: FOUND
- `~/Library/Logs/tom-compile.log` populated: CONFIRMED
