# 61-02 — Multi-Engine + Kurzbefehl-Korrektur (Umsetzungsplan)

**Datum:** 2026-07-20 · **Basis:** Phase 61 shortcuts-forge · **Prinzip:** Bestehende Projekte nur kurz anpassen, nichts neu erfinden.

## Recherche-Ergebnis (GitHub/Web, geprüft 2026-07-20)

### Rechnerleistung (Grenze für lokale Modelle)

Apple **M4 Basis, 10 Kerne, 16 GB RAM**, 560 GB frei.

| Modell lokal | RAM | Machbar | Einschätzung |
|---|---|---|---|
| gpt-oss:20b (OpenAI open-weights, MoE 3,6B aktiv, 128K Kontext) | ~13 GB | ⚠️ knapp (nicht parallel zu Cursor+Obsidian) | bester lokaler Kandidat, offiziell für 16 GB |
| qwen3:8b/14b quantisiert | 5–9 GB | ✅ | schwach für komplexe Plists; Craig Loop fängt Fehler, mehr Iterationen |
| gpt-oss:120b, 30B+-Dense | 60–80 GB | ❌ | — |

Eval-Historie (v1.4, Cloud-First-Entscheidung): lokale Modelle deutlich schwächer bei Agent-Aufgaben → OSS-Engine ist **Opt-in**, nie Default.

### Engine-Landschaft

1. **ChatGPT/Codex** — [shortcuts-playground-plugin](https://github.com/viticci/shortcuts-playground-plugin) liefert eine **fertige Codex-Variante** (`codex/` mit identischer KB + Validator, liegt lokal in `~/.claude/plugins/shortcuts-playground-plugin/codex/`). Harness: `codex` CLI (`npm i -g @openai/codex`), headless via `codex exec`. Skills-Ort: `~/.codex/skills/` (gleiche Konvention wie Paperclip-Skills).
2. **Open Source lokal** — **derselbe Codex-CLI** hat `--oss`-Modus über Ollama, Default-Modell gpt-oss:20b ([Ollama-Blog](https://ollama.com/blog/codex), [Ollama-Doku](https://docs.ollama.com/integrations/codex)). Eine Harness für Cloud + lokal → minimale Integration.
3. **Apple Intelligence** — zwei Ebenen:
   - *Build-Engine:* erst ab **macOS 27** (native NL-Erstellung); On-Device-Modell zu schwach für Plist+Validator-Loop → **kein** Engine-Kandidat heute.
   - *Action im Kurzbefehl:* [„Modell verwenden"](https://support.apple.com/guide/mac-help/use-apple-intelligence-in-shortcuts-mchl91750563/mac) (seit macOS Tahoe, bei Maxim vorhanden) — On-Device / Private Cloud Compute / ChatGPT-Extension. **Heute nutzbar**, indem der Brief die Action anfordert.

## Umsetzung — nur kurze Anpassungen an Bestehendem

| Baustein | Bestehendes Projekt | Anpassung |
|---|---|---|
| **Engine-Umschaltung** | `bin/tom-shortcut` (`run_claude_build`) | `--engine claude\|codex\|codex-oss`; Codex-Zweig ruft `codex exec --full-auto` (bzw. `--oss`) mit gleichem Prompt + gleichen Env-Vars. Artefakt-Verifikation/`tidy` unverändert |
| **Codex-Skill** | Plugin `codex/skills/shortcuts-playground` | Symlink nach `~/.codex/skills/` (Konvention wie Paperclip) |
| **Codex-CLI** | — | `npm i -g @openai/codex`; Login (`codex login`, Browser) = **manueller Maxim-Schritt** |
| **Export installierter Kurzbefehle** | `bin/eivs-shortcut-template-export` (Methoden: `shortcuts share` → SQLite-Fallback) | Neues Subcommand `tom-shortcut export "<Name>"` = dünner Wrapper mit `--output $OUT/drafts/<Name>.xml` + `plutil -convert xml1` |
| **Korrektur nach Vorgabe** | export + `cmd_remix` (vorhanden) | Neues Subcommand `tom-shortcut fix "<Name>" "Vorgabe"` = export → remix in einer Kette |
| **Forge-UI** | `shortcuts-forge/ui/` | Engine-Dropdown (Verfügbarkeit via Doctor), neue Karte „Installierten korrigieren" (Dropdown `shortcuts list` + Vorgabe-Text → `/api/fix`) |
| **Doctor** | `cmd_setup` | Checks: codex vorhanden? ollama + gpt-oss vorhanden? (nur Hinweise, kein Zwang) |

### Stufen

- **Stufe 1 (jetzt):** Codex-CLI installieren, Skill verlinken, `--engine codex`, `export`/`fix`, UI. Login = Maxim (einmalig `codex login`).
- **Stufe 2 (Opt-in, später):** Ollama installieren + `ollama pull gpt-oss:20b` (~13 GB) → `--engine codex-oss` wird nutzbar. RAM-Warnung im Doctor.
- **Stufe 3 (dokumentiert):** Apple Intelligence — „Modell verwenden"-Action im Brief anfordern (heute); native NL-Erstellung nach macOS-27-Upgrade evaluieren.

## Verifikation

1. `tom-shortcut export "Hallo Tom"` → valide XML in `drafts/`
2. `tom-shortcut fix "Hallo Tom" "Der Benachrichtigungstext soll 'Hallo Maxim' lauten" --name "Hallo Maxim"` → neuer signierter Kurzbefehl (Engine claude/Sonnet 5) — testet zugleich den Remix-Pfad E2E
3. `--engine codex` nach `codex login`: gleicher Build-Smoke wie Sonnet-Test
4. UI: Korrektur-Karte baut denselben fix-Job; Engine-Dropdown zeigt nur verfügbare Engines
5. Doctor zeigt Codex/Ollama-Status korrekt

## Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| `codex exec` Sandbox blockt sign-Bash | `--full-auto`; falls nötig Codex-Profil mit workspace-write; Artefakt-Check bleibt harte Wahrheit |
| Export liefert Binär-Plist (SQLite-Weg) | Wrapper konvertiert immer `plutil -convert xml1` + Validator-Lauf |
| gpt-oss auf 16 GB verdrängt Apps | Doctor-Warnung; Engine nie Default; Doku „nichts Großes parallel" |
| Codex-KB driftet vom Claude-Stand | beide kommen aus demselben Plugin-Repo; `git pull` + `claude plugin update` aktualisiert beide |
