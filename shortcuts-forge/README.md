# shortcuts-forge — AI → Apple Shortcuts Pipeline

**Milestone:** v1.6 · **Phase:** 61 · **Requirements:** SCF16-01..06

## Zweck

Maxim gibt eine natürlichsprachige Beschreibung → am Ende steht ein fertiger, **signierter `.shortcut`** in der Ablage `~/Documents/Tom-Shortcuts/`, bereit zum Import in die Kurzbefehle-App. Dazu eine Helper-Bibliothek (**Python, AppleScript, Swift**), die generierte Kurzbefehle über einen festen Vertrag aufrufen können.

Die eigentliche Generierung macht das [shortcuts-playground Plugin](https://github.com/viticci/shortcuts-playground-plugin) (v1.2.1, Federico Viticci/MacStories): Brief → XML-Plist-Entwurf → Craig-Loop-Validierung (`validate_shortcut.py`) → `shortcuts sign --mode anyone`. shortcuts-forge liefert die **Ablage, Mac-Integration und Helper** drumherum.

**Plugin-Update:** `claude plugin update shortcuts-playground@shortcuts-playground` (Marketplace-Cache) + `git -C ~/.claude/plugins/shortcuts-playground-plugin pull` (manueller Clone). Seit 1.2.x bevorzugt das Plugin `SHORTCUTS_PLAYGROUND_OUTPUT_DIR` vor `CLAUDE_PLUGIN_OPTION_OUTPUT_DIR` — `tom-shortcut setup` setzt beide.

## Ordnerbaum

```
/Users/maxim/Claude/shortcuts-forge/            # Repo = Quelle (git, NICHT iCloud)
├── README.md                                    # diese Datei
├── reference/script-actions.md                  # Ground-Truth: runshellscript/runapplescript XML
├── ui/                                          # Forge-UI: server.py (stdlib) + index.html
└── helpers/
    ├── python/text_tools.py                     # stdin→Transform (upper|slug|stats|lines)
    ├── applescript/safari_current_page.applescript  # URL<TAB>Titel des Safari-Tabs
    └── swift/battery_info.swift                 # IOKit → JSON {percent,charging,source}
        └── build/                               # swiftc-Output (gitignored)

~/Documents/Tom-Shortcuts/                       # Ablage = Artefakte (iCloud-synced)
├── drafts/                                      # XML-Entwürfe (Plugin schreibt direkt hierhin)
├── signed/                                      # finale .shortcut (via tom-shortcut tidy)
├── archive/                                     # Datums-Archive der Roh-XML (via tidy)
└── helpers -> /Users/maxim/Claude/shortcuts-forge/helpers   # SYMLINK
```

**Warum Symlink statt Kopie?** `~/Documents` ist iCloud-synced. iCloud „Speicher optimieren" kann Dateikopien zu dataless files evakuieren — ein Kurzbefehl, der offline einen evakuierten Helper aufruft, scheitert. Der Symlink (22 B) wird nie evakuiert; das Ziel liegt in `/Users/maxim/Claude` außerhalb iCloud. Caveat: auf iPhone/iPad (Files.app) erscheint der Symlink defekt — irrelevant, die Helper laufen Mac-only. Fallback bei Sync-Problemen: `tom-shortcut helpers deploy --copy` (rsync-Kopie).

## Nutzung — vier Wege

| Weg | Wann | Befehl |
|---|---|---|
| **Forge-UI (Browser)** | Komfortabel mit Formular, Live-Log, Remix, Import/Run-Buttons | `tom-shortcut ui` → http://127.0.0.1:7461 |
| **Claude/Cursor-Session** | Beim Arbeiten in einer Session | `/shortcuts-playground:build <Beschreibung>` — danach ggf. `tom-shortcut tidy` |
| **Terminal (headless)** | Schnell aus dem Terminal | `tom-shortcut build "Beschreibung" [--name N] [--open]` |
| **Stream Deck** | Ein Knopfdruck | Button auf `bin/streamdeck/tom-shortcut-build.command` → Eingabe-Dialog |

### Forge-UI

`tom-shortcut ui` startet einen lokalen Server (`shortcuts-forge/ui/server.py`, Python stdlib, **nur 127.0.0.1**) und öffnet die Oberfläche:

- **Bauen**: Anforderung + optionaler Name → Build läuft mit Live-Log
- **Ändern (Remix)**: Draft aus `drafts/` wählen + Änderungswunsch → neuer Kurzbefehl unter neuem Namen (Original bleibt)
- **Liste**: fertige `.shortcut` mit Status (installiert / nur Ablage) + Import-/Ausführen-Buttons
- Ein Job zur Zeit; der Build-Subprozess läuft ohne `CLAUDECODE`-Env (UI ist eigener Kontext, bewusster Guard-Bypass)
- Jobs leben mit dem Server: Server beenden bricht einen laufenden Build ab
- **Modell-Auswahl** (Dropdown, gilt für Bauen + Remix): Sonnet 5 (Standard, Token-sparend) · Haiku 4.5 (maximal sparsam) · CLI-Default (bestes Modell, teuer)

### Token sparen: Build-Modell

Headless-Builds laufen standardmäßig mit **Sonnet 5** (`claude-sonnet-5`) statt dem großen CLI-Default — der Craig-Loop-Validator fängt Modellschwächen ab. Steuerung:

```bash
tom-shortcut build "…"                          # Sonnet 5 (Default)
tom-shortcut build "…" --model claude-opus-4-8  # komplexe Aufgaben: stark, weniger Fehlversuche
tom-shortcut build "…" --model claude-haiku-4-5-20251001   # noch sparsamer (simple Briefs)
tom-shortcut build "…" --model ""               # CLI-Default (teuerste Option)
TOM_SHORTCUT_MODEL="" tom-shortcut build "…"    # dito per Env (persistent setzbar)
```

**Modell-Heuristik:** Sonnet 5 für alles Normale. **Opus 4.8** wählen bei komplexen Ketten (Video→Build, große Menü-Shortcuts, viele Bedingungen) — pro Token teurer, aber durch weniger Craig-Loop-Iterationen und Fehlversuche oft *insgesamt* günstiger und schneller. Haiku nur für Trivialfälle. Session-Weg `/shortcuts-playground:build` nutzt immer das Modell der laufenden Session.

CLI-Pendant für Änderungen: `tom-shortcut remix <name|drafts-xml> "Änderungswunsch" [--name N]` (nutzt `/shortcuts-playground:remix`; Quelle muss unsignierte XML aus `drafts/` sein — signierte `.shortcut` sind verschlüsselt).

**Wichtig:** `tom-shortcut build` startet einen eigenen `claude`-Prozess — **nie aus einer laufenden Claude-Session aufrufen** (Rekursion). In Sessions immer `/shortcuts-playground:build` nutzen.

### Starter-App: Mac, iPad, iPhone (seit 2026-07-25)

Zwei per Pipeline gebaute Kurzbefehle (iCloud synct sie automatisch auf alle Geräte):

| Kurzbefehl | Gerät | Macht |
|---|---|---|
| **„Forge starten"** | Mac (auch Dock: Rechtsklick in Kurzbefehle-App → „Zum Dock hinzufügen") | Startet den Server falls nötig (**LAN-Modus**) und öffnet die Seite — via Helper `helpers/zsh/forge_starter` |
| **„Forge öffnen"** | iPhone/iPad/Mac | Öffnet `http://Mac-mini-von-Maxim.local:7461` (Bonjour-Name, stabil trotz IP-Wechsel) |

**Ablauf mobil:** Auf dem Mac einmal „Forge starten" (oder Server läuft eh) → auf iPhone/iPad „Forge öffnen" → volle Forge-UI im Safari (Builds laufen weiterhin auf dem Mac).

⚠️ **LAN-Modus-Sicherheit:** `tom-shortcut ui --lan` bindet an alle Interfaces **ohne Authentifizierung** — nur im vertrauten Heimnetz nutzen, nie in fremden WLANs. Ohne `--lan` bleibt alles wie bisher auf 127.0.0.1.

### Erstes Setup

```bash
tom-shortcut setup          # Ablage anlegen, Helpers verlinken, Env-Vars persistieren, Doctor
bin/build-shortcut-helpers  # Swift-Helper kompilieren + Smoke-Tests
```

**Manuelle Schritte (einmalig):**
1. Kurzbefehle-App → Einstellungen → Erweitert → **„Ausführen von Skripten erlauben"** aktivieren (sonst scheitern alle Run-Shell-Script-Shortcuts still).
2. Optional: In Claude Code `/plugin` → shortcuts-playground → userConfig `output_dir` = `~/Documents/Tom-Shortcuts` (das Setup setzt bereits die Env-Var `CLAUDE_PLUGIN_OPTION_OUTPUT_DIR`, die dasselbe bewirkt).

### Subcommands `tom-shortcut`

| Subcommand | Verhalten |
|---|---|
| `setup` | Ablage + Symlink + Env-Vars (`CLAUDE_PLUGIN_OPTION_OUTPUT_DIR`, `SHORTCUTS_PLAYGROUND_PYTHON`) in `~/.claude/settings.json` + Doctor. Idempotent. |
| `build "Angabe"` | Headless-Build via `claude --print`; Flags: `--name N`, `--open` (Finder-Reveal), `--fallback-prompt` |
| `tidy` | Wurzel-`*.shortcut` → `signed/`, Datums-Ordner → `archive/` |
| `list` | Installierte Shortcuts (`shortcuts list`) + Ablage-Inhalt |
| `run <name>` | `shortcuts run` |
| `import <name\|datei>` | `open -a Shortcuts` (Import-Dialog) |
| `helpers deploy [--copy]` | Symlink neu setzen (Default) oder rsync-Kopie |

## Helper-Vertrag

Generierte Kurzbefehle rufen Helper **immer** über den stabilen Ablage-Pfad auf — nie Repo-Pfade einbetten:

```
$HOME/Documents/Tom-Shortcuts/helpers/<sprache>/<name>
```

**I/O-Vertrag:**
- Parameter via `argv`, Payload via `stdin` (Run Shell Script: „Eingabe übergeben: an stdin")
- Ergebnis UTF-8 auf `stdout`; strukturiert = einzeiliges JSON bei `--json`
- Fehler auf `stderr` + Exit ≠ 0; **keine interaktiven Prompts**
- Shortcuts-Shell ist zsh non-login mit Minimal-PATH → Shebang `#!/usr/bin/env python3` bzw. `#!/bin/zsh`, **keine Homebrew-Abhängigkeiten** (stdlib-only)

**Beispiel-Zeilen für „Run Shell Script"-Actions:**

```bash
# Python: Text transformieren (Eingabe an stdin)
"$HOME/Documents/Tom-Shortcuts/helpers/python/text_tools.py" --mode upper

# AppleScript: Safari-Tab lesen
osascript "$HOME/Documents/Tom-Shortcuts/helpers/applescript/safari_current_page.applescript"

# Swift: Batterie-Status als JSON
"$HOME/Documents/Tom-Shortcuts/helpers/swift/build/battery_info"
```

Neue Helper: Quelldatei unter `shortcuts-forge/helpers/<sprache>/` anlegen (deutscher Header: Zweck/Usage/Output), Vertrag einhalten, bei Swift `bin/build-shortcut-helpers` laufen lassen.

## Quick-Templates: 0 Token, Sekunden statt Minuten

Für Standard-Muster braucht es **kein LLM** — der Cherri-Compiler baut deterministisch (verifizierte Templates):

```bash
tom-shortcut quick notify "Titel" "Text"                    # Benachrichtigung
tom-shortcut quick shell 'echo hi | $HOME/…/text_tools.py --mode upper'   # Shell/Helper-Aufruf (+ Fertig-Meldung; --no-notify)
tom-shortcut quick url "https://…"                          # Link öffnen
```

Jeder Quick-Build erzeugt signierte Datei **und** XML-Draft (→ später per Remix erweiterbar). Bekannter Cherri-Bug: Action-Nesting verursacht Compiler-Panic — Templates sind deshalb sequentiell aufgebaut.

## Analyse zuerst: anpassen statt neu entwickeln

```bash
tom-shortcut advise "Rechnung fotografieren und Betrag in Übersicht eintragen"
tom-shortcut advise "" --youtube "https://www.youtube.com/watch?v=…"   # Video als Quelle
```

Die Experten-Analyse (Sonnet 5 + WebSearch, ~1–2 Min, Plan: [`61-03-ADVISE-REUSE-PLAN.md`](../.planning/phases/61-shortcuts-forge/61-03-ADVISE-REUSE-PLAN.md)) liefert **vor** dem Bauen:

1. **Empfohlenes Werkzeug** — Kurzbefehl · Python-Helper · AppleScript · Pages · Numbers · Kombination (mit Begründung)
2. **Ähnliche existierende Projekte** — RoutineHub/GitHub/r/shortcuts/MacStories mit Links (übernehmen statt neu bauen)
3. **Lokale Wiederverwendung** — welcher deiner installierten Kurzbefehle/Drafts als Basis taugt (→ `fix`)
4. **Optimierter Bau-/Änderungs-Brief** — fertig für `build`/`fix`/`remix` (UI-Button „→ Übernehmen" routet in die richtige Karte)
5. **Einschätzung** — Erfolgswahrscheinlichkeit, Aufwand, Risiken
6. **APIs & Programme** — konkrete externe APIs (Zweck, Doku-Link, Auth, Kosten) und Apps mit Kurzbefehl-Actions/App Intents — **bevorzugt aus Maxims installierten Apps** (Baukasten-Katalog, s. u.); Neu-Installationen nur wenn nötig und als solche gekennzeichnet

### App-Baukasten-Katalog

`tom-shortcut apps [--refresh]` scannt `/Applications` + `/System/Applications` nach Apps mit Kurzbefehl-Actions (Erkennung: `Metadata.appintents` = moderne App Intents, `PlugIns/*.appex` = Legacy) → `~/Documents/Tom-Shortcuts/reference/apps-baukasten.md` (aktuell 49 Apps, u. a. Hazel, Goodnotes, Telegram, WhatsApp, Keynote/Numbers/Pages). Die Analyse hält den Katalog automatisch aktuell (7-Tage-Cache) und liest ihn bei jeder Beratung ein — Vorschläge bauen auf dem, was wirklich da ist.

**Kontext-Analyse** (seit 2026-07-20): `advise --shortcut "<Name>"` bzw. `--draft x.xml` analysiert einen **bestehenden** Kurzbefehl (echte Action-Struktur fließt ins Prompt) — in der UI als „🎓 Erst analysieren" in den Karten „Bestehende bearbeiten" und „Draft ändern", plus **„🎓 Optimierungsvorschläge zum Ergebnis"** nach jedem erfolgreichen Build (dein Testfall-Feedback-Loop).

Ergebnisse liegen in `~/Documents/Tom-Shortcuts/advice/*.md`. In der Forge-UI: Karte **„🎓 Analyse zuerst"** (mit YouTube-Feld). Hinweis: 100-%-Garantien gibt es nicht — die Analyse maximiert die Trefferquote, der Craig-Loop-Validator fängt den Rest.

## Installierte Kurzbefehle korrigieren

```bash
tom-shortcut export "Mein Kurzbefehl"                 # App → drafts/*.xml (via eivs-shortcut-template-export)
tom-shortcut fix "Mein Kurzbefehl" "Vorgabe…" --name "Mein Kurzbefehl v2"   # Export + Remix in einem
```

Dazu zwei weitere Modi auf derselben Kette (Export → Remix):

```bash
tom-shortcut optimize "Mein Kurzbefehl" ["Hinweis"]      # aufräumen & robuster — Funktion bleibt identisch
tom-shortcut extend "Mein Kurzbefehl" "neue Funktion…"   # erweitern — Bestehendes bleibt vollständig erhalten
```

In der Forge-UI: Karte **„Bestehende Kurzbefehle bearbeiten"** — Kurzbefehl wählen, Modus wählen (🩹 Korrigieren · ⚡ Optimieren · ➕ Erweitern), Text eintippen (bei Optimieren optional), fertig. Das Original in der App bleibt immer unberührt; das Ergebnis kommt als neue signierte Datei.

## Multi-Engine: Claude · ChatGPT/Codex · Open Source

Umsetzungsplan + Recherche: [`.planning/phases/61-shortcuts-forge/61-02-MULTI-ENGINE-PLAN.md`](../.planning/phases/61-shortcuts-forge/61-02-MULTI-ENGINE-PLAN.md)

| Engine | Aufruf | Voraussetzung | Status |
|---|---|---|---|
| **claude** (Default) | `--engine claude` + `--model` | claude CLI (da) | ✅ produktiv |
| **codex** (ChatGPT-Cloud) | `--engine codex` | `codex` CLI (installiert, `~/.local/bin`) + **einmalig `codex login`** | ⏳ Login ausstehend |
| **codex-oss** (lokal, gpt-oss:20b) | `--engine codex-oss` | zusätzlich Ollama + `ollama pull gpt-oss:20b` (~13 GB) | 💤 Stufe 2, Opt-in — 16-GB-RAM-Warnung: nicht parallel zu Cursor/Obsidian |
| Apple Intelligence | — | „Modell verwenden"-Action **im Brief anfordern** (On-Device/Private Cloud/ChatGPT); native NL-Erstellung erst macOS 27 | Action heute nutzbar |

Alle Engines: gleicher Prompt, gleiche Ablage, gleiche Artefakt-Verifikation. Codex-Skill liegt als Symlink in `~/.codex/skills/` (Setup pflegt ihn). Env-Default: `TOM_SHORTCUT_ENGINE`.

## Engine-Wahl: Playground vs. Cherri

| | shortcuts-playground (Default) | Cherri |
|---|---|---|
| Ansatz | Brief → XML-Plist → Craig Loop → sign | `.cherri`-Quellcode → Compiler → signierter `.shortcut` |
| Stärke | Beste Action-Abdeckung (1.794-ID-Allowlist, HealthKit, App Intents), Validierung, ein Satz genügt | Komplexe Kontrolllogik/Loops, Shortcut **als Code pflegen**, diffbar |
| Wann | Standard für alles | Wenn der Kurzbefehl langlebig ist und iterativ weiterentwickelt wird |

Cherri ist installiert: CLI `~/go/bin/cherri` + `/Applications/Cherri.app`.

```bash
cherri mein-shortcut.cherri -s anyone -o out.shortcut   # kompilieren + signieren
cherri --import <datei|icloud-link>                     # bestehenden Shortcut → Cherri-Quelle
```

Siehe auch `bin/cherri-sign-import-all.sh`. Ein `tom-shortcut build --engine cherri` ist bewusst **nicht** implementiert (Deferred, siehe `61-01-PLAN.md`).

## Limit-Resilienz (seit 2026-07-20)

Wenn das Claude-Nutzungslimit **mitten im Build** zuschlägt, gilt automatisch:

1. **Kein Doppel-Verbrauch:** Der Fallback-Zweitversuch wird bei erkanntem Limit übersprungen
2. **Draft-Rettung (0 Token):** Liegt schon ein valider XML-Entwurf vor, wird er direkt signiert — Build gerettet
3. **Klare Meldung** statt kryptischem Fehler: Reset-Zeit + Optionen (warten / `--engine codex` / `salvage`)

```bash
tom-shortcut salvage          # neuesten validen Draft ohne LLM signieren
tom-shortcut resume [draft]   # unfertigen Draft nach Limit-Reset fertigstellen lassen
```

**Restart in der Forge-UI (seit 2026-07-20):** Jeder Job wird mit Parametern in `.last-job.json` persistiert — das überlebt auch Server-Neustarts und Abstürze. Bricht ein Job ab (Limit, ✕ Abbrechen, Absturz), zeigt die Status-Zeile:

- **▶ Fortsetzen** — wenn seit Job-Start ein Draft entstand: die Kompilierung macht genau dort weiter (Draft wird fertiggestellt)
- **↻ Neu starten** — gleicher Auftrag mit denselben Parametern nochmal von vorn

Nach einem Server-Neustart erscheint der unterbrochene Job automatisch wieder mit beiden Optionen.

Hinweis: `salvage` validiert vor dem Signieren — halbfertige (invalide) Drafts werden nicht blind signiert, sondern auf `resume` verwiesen. Exportierte App-Kurzbefehle fallen durch die strenge Validator-Prüfung (ungenutzte Input-Klassen) — die gehen über `fix`, nicht über `salvage`.

## Troubleshooting

| Problem | Lösung |
|---|---|
| Build bricht mit „hit your session limit" ab | Passiert automatisch: Rettung + klare Meldung (s. o.). Danach: warten bis Reset oder `--engine codex` |
| Run-Shell-Script-Shortcut tut nichts | Kurzbefehle → Einstellungen → Erweitert → „Ausführen von Skripten erlauben" |
| AppleScript-Helper: Fehler -1743 | macOS-Automation-Consent bestätigen (Systemeinstellungen → Datenschutz → Automation) |
| `build` findet keinen signierten Output | `--fallback-prompt` probieren; `drafts/` prüfen (XML da, aber Sign gescheitert?); `tom-shortcut setup` (Doctor) |
| Builder-Agent „fragt" statt zu bauen | Headless-Prompts enthalten bereits Autonomie-Anweisung + Verweis auf `reference/script-actions.md` — bei neuen Action-Lücken dort weitere Ground-Truth-Snippets ergänzen (Cherri: `cherri x.cherri --skip-sign` → `plutil -convert xml1`) |
| Session-Build landet in `~/Documents/Shortcuts Playground/` | `tom-shortcut setup` erneut (Env-Var), Claude neu starten, oder `/plugin`-userConfig setzen |
| Helper unter iCloud „defekt" | `tom-shortcut helpers deploy` (Symlink neu) oder `--copy` |
| Signierte Datei liegt in Ablage-Wurzel | `tom-shortcut tidy` |

## Privacy

- Alles läuft **lokal**: XML-Generierung, Validierung, Signierung (`shortcuts sign --mode anyone`), Helper.
- Einzige externe Verbindung: der **Claude-API-Call** des Builds (die Beschreibung + Plugin-Wissensbasis gehen an Anthropic — keine Vault-Inhalte, sofern die Beschreibung keine enthält).
- Helper lesen nur lokale Daten (Safari-Tab, Batterie); nichts wird gesendet.
- **Keine Vault-Daten in Shortcut-Beschreibungen** einbetten, die über Dateinamen/Pfade hinausgehen.

## Referenzen

- Plugin: [viticci/shortcuts-playground-plugin](https://github.com/viticci/shortcuts-playground-plugin) · [MacStories-Ankündigung](https://www.macstories.net/stories/introducing-shortcuts-playground/)
- Cherri: [cherrilang.org](https://cherrilang.org) · [LLM-Guide](https://gist.github.com/charignon/6be70dfac22cb3a68bce8676f68f0560)
- Referenz-Skill: [drewocarr/generate-shortcuts-skill](https://github.com/drewocarr/generate-shortcuts-skill) (`~/.claude/skills/shortcuts-generator/`)
- Ausführungs-Bridge (Deferred): [recursechat/mcp-server-apple-shortcuts](https://github.com/recursechat/mcp-server-apple-shortcuts)
- Repo-intern: `bin/eivs-build-tags-shortcut`, `bin/eivs-shortcut-template-export|apply` (Plist-Handarbeit + Sign-Konvention)
- GSD: `.planning/phases/61-shortcuts-forge/61-01-PLAN.md`
