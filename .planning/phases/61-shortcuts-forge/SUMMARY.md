# Phase 61 — shortcuts-forge: SUMMARY

**Milestone:** v1.6 · **Requirements:** SCF16-01..06 · **Zeitraum:** 2026-07-19

## Was geliefert wurde

**Ziel erreicht:** Maxim gibt eine Beschreibung → signierter `.shortcut` in `~/Documents/Tom-Shortcuts/`. Headless in ~2 Min inkl. Validierung + Signierung.

### Neue Dateien

| Datei | Zweck |
|---|---|
| `shortcuts-forge/README.md` | Projekt-Doku: Nutzung (3 Wege), Helper-Vertrag, Cherri, Troubleshooting, Privacy |
| `shortcuts-forge/reference/script-actions.md` | Ground-Truth-XML für `runshellscript`/`runapplescript` (via Cherri-Compiler extrahiert) |
| `shortcuts-forge/helpers/python/text_tools.py` | Text-Helper (upper/slug/stats/lines, `--json`) — Referenz des Helper-Vertrags |
| `shortcuts-forge/helpers/applescript/safari_current_page.applescript` | Safari-Tab: URL+Titel |
| `shortcuts-forge/helpers/swift/battery_info.swift` | IOKit-Batterie-Status als JSON |
| `bin/tom-shortcut` | CLI: setup/build/tidy/list/run/import/helpers deploy |
| `bin/build-shortcut-helpers` | swiftc + ad-hoc codesign + Smoke-Tests |
| `bin/streamdeck/tom-shortcut-build.command` | Stream-Deck-Button (prompt_text → build → pause) |

### Geänderte Dateien

- `CLAUDE.md` — neue Sektion „Kurzbefehl-Pipeline — tom-shortcut / shortcuts-forge"
- `.gitignore` — `shortcuts-forge/helpers/swift/build/`
- `~/.claude/settings.json` — env: `CLAUDE_PLUGIN_OPTION_OUTPUT_DIR`, `SHORTCUTS_PLAYGROUND_PYTHON` (via `tom-shortcut setup`, mit Backup)
- `.planning/`: REQUIREMENTS (SCF16), ROADMAP (Phase 61 + Coverage 41), STATE

### Ablage angelegt (außerhalb Repo)

`~/Documents/Tom-Shortcuts/` mit `drafts/`, `signed/`, `archive/`, `helpers` (Symlink → Repo).

## Key Decisions

1. **Symlink statt Deploy-Copy** für Helpers — iCloud evakuiert Kopien, nie den Symlink; Ziel außerhalb iCloud; `--copy` als Fallback.
2. **Env-Var statt Plugin-userConfig-Write** — userConfig-Persistenzformat opak/leer; `CLAUDE_PLUGIN_OPTION_OUTPUT_DIR` doppelt (settings.json + CLI-Export).
3. **`tidy` statt Plugin-Patch** — Plugin legt Signed + XML-Archiv in die Ablage-Wurzel; idempotente Nachsortierung hält Plugin update-fähig.
4. **Ground-Truth-Referenz für Skript-Actions** — Plugin-KB kennt kein Parameterschema für `runshellscript`/`runapplescript`; der Builder-Agent stoppte im Headless-Mode mit Rückfrage. Fix: Cherri-Compiler als Schema-Orakel (`cherri x.cherri --skip-sign` → `plutil -convert xml1`), Snippets in `reference/script-actions.md`, Headless-Prompts verweisen darauf + Autonomie-Anweisung („keine Rückfragen").
5. **Referenz als Markdown, nicht XML** — der PostToolUse-Validator des Plugins lehnt Shortcut-artige XML-Dateien ohne Comments/Icon/InputClasses ab.
6. **Cherri documented-only** — `--engine cherri` deferred.
7. **Python-Kandidaten erweitert** — `/opt/homebrew/Cellar/python@3.14` gehört uid 502 (nicht Maxim) → `~/.local/bin/python3.13` (3.13.12) als funktionierender Validator-Python.

## Verifiziert (E2E)

- `setup` 2× idempotent, Doctor komplett grün
- Helper über Symlink-Pfad: `text_tools.py` ✓, `battery_info` ✓ (JSON), AppleScript kompiliert ✓
- Headless-Build „Hallo Tom": Slash-Command im Print-Mode → signiert (24K), Import + `shortcuts run` ✓ (Benachrichtigung)
- Headless-Build „Helper-Test" (Run Shell Script → `text_tools.py`): signiert ✓, Draft-XML korrekt (`/bin/zsh`, korrekter Script-String)
- `--fallback-prompt`-Pfad: „Uhrzeit-Test" signiert ✓
- `tidy`: Wurzel sauber, Datums-Archive nach `archive/` ✓

**Nachprüfung (2026-07-19/20):** Plugin auf **1.2.1** aktualisiert (Cache + Clone); `tom-shortcut` setzt jetzt beide Output-Dir-Env-Vars (`SHORTCUTS_PLAYGROUND_OUTPUT_DIR` neu in 1.2.x) und spiegelt die Skript-Action-Referenz in die Ablage (build.md-Sandbox). Regressionstest „Batterie-Status" (Swift-Helper) first-pass ✓; „Uhrzeit-Test" importiert + Run ✓.

**Offen (manuell, Maxim):** Helper-Test-Import-Klick + Run (Skript-Erlaubnis in Kurzbefehle-Einstellungen), Stream-Deck-Doppelklick-Test + Elgato-Registrierung, Session-Pfad-Probe (`/shortcuts-playground:build`). Details: `VERIFICATION.md`.

## Deferred

- `tom-shortcut build --engine cherri`
- Weitere Helper (tom-status-Bridge, Kalender-Swift)
- mcp-server-apple-shortcuts als Agent-Ausführungs-Bridge
