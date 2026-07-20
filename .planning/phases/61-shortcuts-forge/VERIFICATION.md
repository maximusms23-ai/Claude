# Phase 61 — shortcuts-forge: VERIFICATION

**Datum:** 2026-07-19 · **Protokoll:** 8 E2E-Schritte aus `61-01-PLAN.md`

## REQ-Coverage

| REQ | Status | Nachweis |
|---|---|---|
| SCF16-01 Ablage + Setup | ✅ | `setup` 2× ausgeführt → identisch; `readlink ~/Documents/Tom-Shortcuts/helpers` = `/Users/maxim/Claude/shortcuts-forge/helpers`; settings.json valide mit beiden Env-Vars (Backup `settings.json.bak-20260719-*`) |
| SCF16-02 Helper-Bibliothek | ✅ | `build-shortcut-helpers`: swiftc + codesign ok; Smoke: `text_tools.py --mode upper` → `HALLO TOM`, `battery_info` → `{"charging":false,"percent":-1,"source":"AC Power"}`, AppleScript kompiliert (osacompile) |
| SCF16-03 CLI | ✅ | build (2 Engines-Pfade), tidy, list, run („Hallo Tom" Exit 0), import (Dialog), helpers deploy — alle ausgeführt |
| SCF16-04 Stream Deck | ⚠️ Repo shipped | `.command` geschrieben, `bash -n` ok, chmod +x; **manuell offen:** Doppelklick-Test + Elgato-Registrierung |
| SCF16-05 Doku | ✅ | `shortcuts-forge/README.md` (inkl. reference/-Eintrag, Troubleshooting-Zeile Builder-Agent) + CLAUDE.md-Sektion |
| SCF16-06 E2E | ⚠️ Teilweise | Siehe Schritt-Tabelle — 3 manuelle Rest-Schritte bei Maxim |

## E2E-Schritte

| # | Schritt | Ergebnis |
|---|---|---|
| 1 | `setup` 2× (Idempotenz) | ✅ Doctor alle [ok]; zweiter Lauf „bereits aktuell" |
| 2 | Helper über Symlink-Pfad | ✅ alle drei (AppleScript: Compile-Check; Laufzeit braucht Safari + Consent — manuell) |
| 3 | Headless „Hallo Tom" | ✅ Exit 0, `signed/Hallo Tom.shortcut` 24K, `drafts/Hallo Tom.xml`, Wurzel sauber |
| 4 | Import + Run „Hallo Tom" | ✅ Import-Klick durch Maxim, `shortcuts list` zeigt Eintrag, `run` Exit 0 + Benachrichtigung |
| 5 | Helper-Shortcut „Helper-Test" | ✅ Build + Sign ✅; Import durch Maxim ✅; `run` Exit 0 → Kette Kurzbefehl→zsh→Symlink→`text_tools.py` funktioniert (2026-07-20). Skript-Erlaubnis damit nachweislich aktiv |
| 6 | Session-Pfad `/shortcuts-playground:build` | ⚠️ Offen — nach Claude/Cursor-Neustart testen (Env-Var aus settings.json greift erst in neuer Session) |
| 7 | Stream Deck | ⚠️ Offen — `.command` Doppelklick + Elgato-Registrierung (manuell) |
| 8 | `--fallback-prompt`-Probe | ✅ „Uhrzeit-Test" signiert (24K) über expliziten Fallback-Pfad |

## Incident-Log (während Verifikation gefunden + gefixt)

1. **Builder-Agent fragte statt zu bauen** (Schritt 5, erster Versuch): Kein `runshellscript`-Parameterschema in Plugin-KB → Headless-Build ohne Artefakt. **Fix:** Ground-Truth via Cherri extrahiert (`reference/script-actions.md`), Autonomie-Anweisung in beide Build-Prompts. Zweiter Versuch: ✅ First-Pass.
2. **PostToolUse-Validator blockte Referenz-XML**: Shortcut-artige `.xml` ohne Comments/Icon wird abgelehnt. **Fix:** Referenz als Markdown.
3. **`/opt/homebrew/bin/python3.14` permission denied**: Cellar gehört uid 502 (`drwx------`). **Fix:** Kandidatenliste um `~/.local/bin/python3*` erweitert → `python3.13` (3.13.12) gefunden.

## Nachprüfung gegen Upstream (2026-07-19/20, auf Maxim-Wunsch)

- **Plugin war veraltet:** lokal 1.0.1, Upstream **1.2.1** (AppIntent-Validation-Fixes, OS-27-Trigger, Signing-Robustheit: Temp-Dateinamen behalten den Shortcut-Stem). Update durchgeführt: `claude plugin update shortcuts-playground@shortcuts-playground` (Cache) + `git pull` (Clone) → beide auf 1.2.1.
- **Env-Var-Strategie gegen 1.2.1-Quelle verifiziert:** `sign-shortcut` liest jetzt `SHORTCUTS_PLAYGROUND_OUTPUT_DIR` mit Fallback `CLAUDE_PLUGIN_OPTION_OUTPUT_DIR` — `tom-shortcut` (setup + build) setzt seit diesem Fix **beide**.
- **build.md-Sandbox-Regel entdeckt:** Das Command erlaubt dem Agent nur Reads im Plugin-Dir + Output-Dir. Fix: `sync_reference()` spiegelt `reference/script-actions.md` vor jedem Build nach `$OUT/reference/`; Prompt verweist auf den Ablage-Pfad.
- **Regressionstest mit 1.2.1:** „Batterie-Status" (Run Shell Script → Swift-Helper `battery_info`) headless first-pass gebaut + signiert ✓.
- **„Uhrzeit-Test"** von Maxim importiert + `shortcuts run` ✓ (Fallback-Artefakt läuft E2E).

## Drift

- Keiner gegen den Plan; alle drei Incidents innerhalb der geplanten Risiko-Matrix (Fallback-Kette, Referenz-Strategie) gelöst.
- `run-shortcuts-playground.sh`-Hinweis auf python3.14 ist auf diesem System faktisch tot (Permissions) — `tom-shortcut setup` wählt jetzt selbst.

## Restpunkte für Phase-Close (Maxim)

1. ~~Helper-Test importieren + ausführen~~ ✅ 2026-07-20 (Run OK, Skript-Erlaubnis aktiv)
2. Session-Probe nach Neustart: `/shortcuts-playground:build …` → Artefakt in Tom-Shortcuts
3. Stream-Deck: Doppelklick-Test + Elgato-Button
4. Optional: „Batterie-Status"-Import bestätigen (Dialog offen)
