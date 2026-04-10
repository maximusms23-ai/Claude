---
phase: 22
plan: 02
subsystem: compile-automation
tags: [launchd, plist, automation, logging, macos]
dependency_graph:
  requires: [bin/tom-compile-safe (22-01)]
  provides: [com.maxim.tom-compile launchd job, CLAUDE.md automation docs]
  affects: [tom-compile daily execution, 95_Gehirn/knowledge articles]
tech_stack:
  added: []
  patterns: [launchd-user-agent, StartCalendarInterval, preflight-wrapper]
key_files:
  created:
    - ~/Library/LaunchAgents/com.maxim.tom-compile.plist
  modified:
    - CLAUDE.md
decisions:
  - "18:00 Europe/Berlin als Trigger-Zeit (statt 03:00) weil Laptop zu dieser Zeit typischerweise aktiv ist; Änderung auf 03:00 via Plist-Edit + re-bootstrap dokumentiert"
  - "RunAtLoad=false damit kein sofortiger Lauf bei launchd-Bootstrap (expliziter Trigger via kickstart bevorzugt)"
metrics:
  duration: "~15 min (inkl. User-Bootstrap Checkpoint)"
  completed_date: "2026-04-10"
  tasks_completed: 4
  files_changed: 2
---

# Phase 22 Plan 02: launchd-Plist + Registrierung + Trigger Summary

**One-liner:** launchd-Job com.maxim.tom-compile registriert und via kickstart verifiziert — täglich 18:00 ruft bin/tom-compile-safe, erster echter Compile-Lauf (OK | EXIT=0 | 17s) bestätigt Dauerbetrieb.

## What Was Built

`~/Library/LaunchAgents/com.maxim.tom-compile.plist` — launchd User-Agent der `bin/tom-compile-safe` täglich um 18:00 Europe/Berlin aufruft. Registriert unter Label `com.maxim.tom-compile`. Erster manueller Trigger via `launchctl kickstart` hat `2026-04-10.md` erfolgreich kompiliert.

## Tasks

### Task 1: launchd-Plist schreiben (Commit: a3ff033)

Plist erstellt mit:
- `StartCalendarInterval` Hour=18, Minute=0 (18:00 lokale Zeit = Europe/Berlin)
- `RunAtLoad` = false
- `EnvironmentVariables`: PATH, TOM_VAULT, HOME
- `WorkingDirectory`: /Users/maxim/Claude
- `StandardOutPath` + `StandardErrorPath` → `tom-compile-launchd.log`
- `plutil -lint`: OK

### Task 2: User-Bootstrap (Checkpoint human-action)

Maxim führte manuell aus:
```
launchctl bootout gui/$(id -u)/com.maxim.tom-compile 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.maxim.tom-compile.plist
launchctl list | grep tom-compile
```
Ergebnis: `-    0    com.maxim.tom-compile` — Job registriert, exit 0, kein Fehler.

### Task 3: Manueller Trigger + Log-Verifikation (kein git-Commit — Plist außerhalb Repo)

```bash
launchctl kickstart -p gui/$(id -u)/com.maxim.tom-compile
# Returned PID: 34243
```

Log nach 15s sleep:
```
2026-04-10 14:25:35 +0200 | START | EXIT=- | DURATION=0s | running tom-compile
2026-04-10 14:25:52 +0200 | OK | EXIT=0 | DURATION=17s | tom-compile finished successfully
```

tom-compile-launchd.log:
```
Files to compile (1):
  - 2026-04-10.md
[1/1] Compiling 2026-04-10.md...
  Cost: $0.2239
  Done.
Compilation complete. Total cost: $0.22
Knowledge base: 0 articles
```

CRON-04 und CRON-05: verifiziert.

### Task 4: CLAUDE.md Doku-Notiz (Commit: fe9ef20)

Neue Sektion `## tom-compile Automation (seit v1.3 Phase 22)` nach "Claude-Code Hooks"-Sektion eingefügt. Enthält Plist-Pfad, Wrapper, Schedule, Log-Locations, Verifikations-Commands, Anleitung zum Trigger-Zeit-Ändern.

### Task 5: Maximus_OS-Issue an CTO

Issue **FAM-128** erstellt. Enthält alle Artefakt-Pfade, Verifikations-Ergebnisse, Requirements CRON-01..06, Commit-Hash fe9ef20.

## Trigger-Zeit-Entscheidung

**18:00 Europe/Berlin** gewählt (statt 03:00) weil:
- Laptop ist abends aktiv — launchd führt den Job aus ohne Aufwach-Mechanismus zu benötigen
- Bei verpassten Runs (Laptop off) holt launchd nach sobald Laptop läuft
- Änderung auf 03:00 ist möglich durch Plist-Edit (`<integer>18</integer>` → `<integer>3</integer>`) + re-bootstrap (dokumentiert in CLAUDE.md)

## launchctl-Output (Bestätigung)

```
-    0    com.maxim.tom-compile
```

## Letzte 5 Zeilen tom-compile.log (nach erstem Trigger)

```
2026-04-10 14:21:32 +0200 | SKIP | EXIT=0 | DURATION=0s | TOM_VAULT not reachable: /nonexistent/path/xyz
2026-04-10 14:21:32 +0200 | SKIP | EXIT=0 | DURATION=0s | ollama binary not found in PATH
2026-04-10 14:21:36 +0200 | SKIP | EXIT=0 | DURATION=0s | TOM_VAULT not reachable: /nonexistent/xyz
2026-04-10 14:25:35 +0200 | START | EXIT=- | DURATION=0s | running tom-compile
2026-04-10 14:25:52 +0200 | OK | EXIT=0 | DURATION=17s | tom-compile finished successfully
```

## Deviations from Plan

None — plan executed exactly as written. Task 3 hat keinen separaten git-Commit da die Plist außerhalb des git-Repos liegt (~/Library/LaunchAgents/) und die Log-Dateien ebenfalls außerhalb. Der Trigger-Beweis ist in dieser SUMMARY dokumentiert.

## Requirements Fulfilled

- **CRON-01:** Plist existiert, triggert `tom-compile-safe` täglich 18:00 Europe/Berlin
- **CRON-04:** `launchctl list | grep tom-compile` zeigt aktiven Job-Eintrag
- **CRON-05:** Manueller kickstart hat Log-Eintrag (OK | EXIT=0 | DURATION=17s) produziert
- **CRON-06:** Maximus_OS-Issue FAM-128 an CTO gepostet mit allen Artefakt-Pfaden

## Self-Check: PASSED

- CLAUDE.md contains `tom-compile Automation (seit v1.3 Phase 22)`: CONFIRMED
- Commit fe9ef20 (CLAUDE.md update): CONFIRMED
- Commit a3ff033 (plist): CONFIRMED
- FAM-128 issue: CONFIRMED
- ~/Library/Logs/tom-compile.log populated with OK entry: CONFIRMED
