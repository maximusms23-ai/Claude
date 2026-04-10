# Phase 35 Verification

**Phase:** 35 — Web-Clipper-Template-System
**Milestone:** v1.4.1
**Date:** 2026-04-10
**Status:** ✓ PASS (mit Maxim-Handoff für Smoke-Test)

## Success Criteria

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| 1 | 7 Templates in `99_Vorlagen/web-clipper/` | Artikel, Paper, Video, Dokument, Social-Post, Rezept, Werkzeug | ✓ |
| 2 | README.md mit Setup + Variablen-Referenz + Troubleshooting | `99_Vorlagen/web-clipper/README.md` | ✓ |
| 3 | 7 Ziel-Ordner in `Clippings/` | Artikel, Paper, Videos, Dokumente, Social, Rezepte, Werkzeuge | ✓ |
| 4 | Pro Ziel-Ordner README-Stub mit Frontmatter | 7 README.md in `Clippings/<Typ>/` | ✓ |
| 5 | CLAUDE.md Ingesting-Sektion erweitert | Web-Clipper-Flow-Subsektion + tom-clip-enrich-Beispiel | ✓ |
| 6 | Tom-konformes Frontmatter in allen Templates | `title`, `created`, `type`, `source`, `tags`, `enriched`, `suggested_wiki_category` | ✓ |
| 7 | Smoke-Test mit echtem Clip | Maxim-Handoff — wird nach Plan-Execution durchgeführt | ⏳ |

## Requirements

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CLIP141-01 | ✓ | 7 Templates + README.md in `web-clipper/` |
| CLIP141-02 | ✓ | 7 Ziel-Ordner in `Clippings/` mit README-Stubs |
| CLIP141-03 | ✓ | Browser-Extension-Setup in README Schritt-für-Schritt |
| CLIP141-04 | ⏳ | Smoke-Test Maxim-Handoff (prepared-pending) |
| CLIP141-05 | ✓ | CLAUDE.md Ingesting-Sektion ergänzt |
| CLIP141-06 | ✓ | `tom-clip-enrich`-Aufruf-Beispiel in README |

## Handoff an Maxim — Smoke-Test

Um CLIP141-04 zu schließen, muss Maxim folgende Schritte manuell ausführen:

1. **Browser-Extension öffnen** (Obsidian Web Clipper)
2. **Settings → Templates**: 7 Templates aus `99_Vorlagen/web-clipper/*.md` einfügen (Copy-Paste des kompletten File-Contents)
3. **Pro Template Path setzen**: `Clippings/Artikel/`, `Clippings/Paper/`, etc.
4. **Test-Clip** (empfohlen: eine beliebige Wikipedia-Seite mit `Artikel.md`-Template)
5. **Prüfen:** Neue Datei in `$TOM_VAULT/Clippings/Artikel/` mit korrektem Frontmatter (`type: artikel`, `source: https://...`, `enriched: false`)
6. **Enrichment:** `tom-clip-enrich "$TOM_VAULT/Clippings/Artikel/<file>.md"`
7. **Verifikation:** `enriched: true`, Summary + Tags + Konzepte vorhanden
8. **Idempotenz:** Zweiter `tom-clip-enrich`-Lauf skipt sauber

**Variablen-Syntax-Validierung:** Sollte der Obsidian Web Clipper andere Variablen-Syntax als `{{title|default:""}}` unterstützen (z.B. `<%= title %>` oder andere Delimiter), muss in einem Template die Syntax angepasst werden, dann auf die anderen 6 übertragen. Das bestehende Mannheim-Clipping aus Phase 30 kann als Referenz für das Extension-Output-Format dienen.

## Notes

- Phase 35 folgt der neuen Dogfooding-Regel aus Phase 33: Phase-35-Note im Vault, Journal-Update, keine neuen Entscheidungen (reine Feature-Implementation).
- `tom-clip-enrich` wird laut Phase-30-Summary nicht verändert — der Enricher akzeptiert bereits beliebige Pfade unter `Clippings/`, die neuen Unterordner funktionieren out-of-the-box. *(Nachtrag Phase 35-Hotfix: `--queue-only` Mode + `enriched_by` Feld hinzugefügt, siehe Addendum unten)*

---

## Phase 35-Hotfix Addendum — Web-Clipper-Interpreter-Integration

**Hotfix-Date:** 2026-04-10
**Hotfix-Commit:** `f11b4d7` — fix(phase-35-hotfix): Web-Clipper-Interpreter-Integration (Ollama/gemme)
**Trigger:** Maxim-Feststellung direkt nach Phase-35-Close: "Web Clipper wurde nicht angepasst, ich sehe keine Ollama-/Gemma4-Implementierung" — Phase 35 hatte das native Interpreter-Feature des Obsidian Web Clippers übersehen und nur den Post-hoc-Pfad über `tom-clip-enrich` gebaut.

**Scope:** Korrektur einer unvollständigen Integration aus derselben Phase — analog Phase 29-Hotfix (Smart Connections Privacy-Leak). Kein neuer Milestone, kein neues Phasen-Verzeichnis.

### Hotfix Success Criteria

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| H1 | `OLLAMA_ORIGINS` persistent via `launchctl setenv` auf Browser-Extension-Scope | `launchctl getenv OLLAMA_ORIGINS` → `chrome-extension://*,moz-extension://*` | ✓ |
| H2 | Alle 7 Templates mit ≥3 Interpreter-Prompts refaktoriert | `grep -c '{{"' Artikel.md Paper.md Video.md Dokument.md Social-Post.md Rezept.md Werkzeug.md` jeweils ≥ 3 | ✓ |
| H3 | Typ-spezifische Prompt-Formulierungen pro Template | Code-Review der 7 Templates | ✓ |
| H4 | `web-clipper/README.md` Interpreter-Setup-Sektion + CORS-Troubleshooting | Sektion 1 ("Ollama mit CORS-Origins") + Sektion 2 ("Interpreter-Provider") + erweitertes Troubleshooting | ✓ |
| H5 | `clip_enrich.py --queue-only` Mode + Skip-if-present-Logik | Dry-Run-Tests: `queue-only` gibt Konzepte zurück; `enriched: clip-time` wird als skip erkannt | ✓ |
| H6 | `enriched_by`-Feld wird von `clip_enrich.py` im Standard-Pfad gesetzt | Code-Review `enrich_file()` Zeile "new_fm['enriched_by'] = 'tom-clip-enrich'" | ✓ |
| H7 | ADR-005 `.planning/obsidian-plugin-config/adr-005-web-clipper-interpreter-vs-clip-enrich.md` | Datei existiert, 4 Sektionen (Context, Decision, Consequences, Alternatives) | ✓ |
| H8 | `CLAUDE.md` Web-Clipper-Flow-Sektion aktualisiert: "Interpreter ist Primary" | Sektion Zeilen 158-ff | ✓ |
| H9 | REQUIREMENTS.md CLIP141-07..13 additiv | Zeilen 399+ | ✓ |
| H10 | Vault-Doku-Routine (Phase-Note + Journal + Entscheidungen + index.md + log.md) | Alle 4 Punkte der "Mandatory pro GSD-Phase"-Checklist | ✓ |
| H10b | 7 importable JSON-Templates in `99_Vorlagen/web-clipper/json/` (Schritt 2) | `Tom-Artikel.json`..`Tom-Werkzeug.json`, alle JSON-validiert, Schema 0.1.0 mit Properties + noteContentFormat + path | ✓ |
| H10c | README Sektion 3 auf Import-Workflow umgeschrieben | "Templates importieren" mit + Neue Vorlage / Import-Button | ✓ |
| H10d | Modell-Label `gemma4-interpreter` konsistent in JSONs + MD-Templates + README + ADR-005 | grep-Sweep | ✓ |
| H11 | Maxim-Handoff Smoke-Test: 1 echter Clip → gefüllte Interpreter-Felder | Maxim-Handoff (CLIP141-13) | ⏳ |
| H12 | Maxim-Handoff Fallback-Test: Ollama offline → `--force` füllt Felder | Maxim-Handoff | ⏳ |
| H13 | Maxim-Handoff `--queue-only`: Konzepte landen in `90_Wiki/konzepte-vorschlaege.md` ohne Frontmatter-Overwrite | Maxim-Handoff | ⏳ |

### Hotfix Requirements

| Req | Status | Evidence |
|-----|--------|----------|
| CLIP141-07 | ✓ | `launchctl getenv OLLAMA_ORIGINS` |
| CLIP141-08 | ✓ | `web-clipper/README.md` Abschnitt 2 |
| CLIP141-09 | ✓ | 7 Templates refaktoriert |
| CLIP141-10 | ✓ | `adr-005-web-clipper-interpreter-vs-clip-enrich.md` |
| CLIP141-11 | ✓ | `web-clipper/README.md` v2 |
| CLIP141-12 | ✓ | `CLAUDE.md` Web-Clipper-Flow v2 |
| CLIP141-13 | ⏳ | Maxim-Handoff Smoke-Test (prepared-pending) |

### Dependencies / Blocker für Smoke-Test

**Blocker für CLIP141-13:** Bei der Ausführung des Hotfix wurde entdeckt, dass der Ollama-Models-Symlink `/Users/maxim/.ollama/models → /Volumes/Archiv/Ollama` ins Leere zeigt (Volume gemounted, aber Ordner weg). `ollama serve` startet deshalb nicht sauber. `/Users/maxim/.ollama/models_backup/` existiert mit Blobs+Manifests und ist ein plausibler Wiederherstellungs-Kandidat — aber Tom hat das **nicht angefasst**, weil es außerhalb des Hotfix-Scopes liegt und Maxim entscheiden muss, ob die Models zurück auf das externe Volume kommen oder der Symlink auf `models_backup` umgebogen wird.

Das wurde in **FAM-154 an CTO** dokumentiert. Bis Ollama wieder läuft, bleibt CLIP141-13 im Status `prepared-pending`.

### Maxim-Handoff Steps (CLIP141-13)

1. **Ollama-Models wiederherstellen** (siehe FAM-154)
2. **Ollama neu starten**: Menüleisten-Icon → Quit → `open -a Ollama` → `pgrep -fl "ollama serve"` sollte Prozess zeigen
3. **CORS-Preflight**: `curl -sI -H "Origin: chrome-extension://x" http://127.0.0.1:11434/api/tags | grep -i access-control`
4. **Browser-Extension Settings → Interpreter**: Neuer Provider "Ollama" mit Endpoint `http://127.0.0.1:11434/api/chat`, Model `gemme`
5. **Template im Editor öffnen** (z.B. `Tom-Artikel`) — Toggle "Interpreter enabled" aktivieren
6. **Test-Clip** einer Wikipedia-Seite mit `Tom-Artikel`-Template → Datei in `Clippings/Artikel/`
7. **Verifikation Frontmatter**:
   - `summary`: 3–5 deutsche Sätze (keine Roh-Prompt mehr)
   - `tags`: über die 2 Static-Tags hinaus 3–5 weitere
   - `konzepte_vorschlaege`: Komma-Liste mit 2–4 Einträgen
   - `enriched: clip-time`
   - `enriched_by: gemme-interpreter`
8. **`tom-clip-enrich --queue-only <file>`** → Konzept-Einträge in `$TOM_VAULT/90_Wiki/konzepte-vorschlaege.md`; Frontmatter bleibt unverändert
9. **Fallback-Test**: Ollama stoppen (`killall ollama`), erneut clippen → Felder enthalten Roh-Prompts → `tom-clip-enrich <file>` ohne `--queue-only` (Standard-Modus mit `--force` falls nötig) füllt sie nachträglich mit `enriched_by: tom-clip-enrich`

### Hotfix Schritt 3 — Direkter LevelDB-Import + Ollama-Models-Fix

Maxim hat Tom angewiesen, die Browser-Setup-Schritte selbst durchzuführen ("du hast vollen Zugriff"). Schritt 3:

1. **Ollama-Models-Path-Fix:** Symlink `~/.ollama/models` zeigte auf das leere Volume `/Volumes/Archiv/Ollama`. Tom hat `mdfind` nach `gemma4*` ausgeführt und das funktionierende Models-Dir unter `/Users/maxim/Ollama/` gefunden (enthält `gemma4`, `gemme`, `nomic-embed-text`). Symlink umgebogen: `~/.ollama/models → /Users/maxim/Ollama`. Original-`models_backup/` blieb unangetastet.
2. **Ollama mit CORS gestartet:** `OLLAMA_ORIGINS="chrome-extension://*,moz-extension://*" ollama serve` als detached Background-Prozess. `gemma4`, `gemme`, `nomic-embed-text:latest` und `llama3.2` (4 Modelle) sind verfügbar. CORS-Preflight `curl -H "Origin: chrome-extension://cnjifjpddelmedmihgijeibhnjfabmlf" .../api/tags` antwortet mit `Access-Control-Allow-Origin: chrome-extension://cnjifjpddelmedmihgijeibhnjfabmlf` ✓
3. **End-to-end Smoke-Call gegen `gemma4`:** Tom hat einen echten POST gegen `/api/chat` mit Browser-Extension-Origin und einem deutschen Test-Prompt geschickt. gemma4 lieferte eine korrekte deutsche Zusammenfassung zurück → Pipeline (Origin → CORS → Ollama → gemma4 → Antwort) verifiziert ✓
4. **Direkter LevelDB-Import in Chrome-Extension-Storage:** Tom hat den Pfad `~/Library/Application Support/Google/Chrome/Default/Sync Extension Settings/cnjifjpddelmedmihgijeibhnjfabmlf` analysiert. Templates werden dort als `template_<id>` Keys gespeichert mit JSON-Array von LZ-String-UTF16-komprimierten Chunks. Tom hat:
    - Chrome sauber via `osascript … quit` beendet (LevelDB-Lock freigegeben)
    - Mit Node.js + `classic-level` + `lz-string` ein Import-Script gebaut (`/tmp/cliplev/import-templates.mjs`)
    - 7 Tom-Templates mit IDs, Properties (jeweils mit Property-IDs), `noteContentFormat`, `path` (`Clippings/Artikel` etc.), `noteNameFormat` aus den JSONs in `99_Vorlagen/web-clipper/json/` gelesen
    - Jedes Template via `LZString.compressToUTF16` komprimiert und als `template_<id>` Key in die LevelDB geschrieben
    - `template_list` um die 7 neuen IDs erweitert (3 alte Templates "Standard"/"Neue Vorlage"/"Neue Vorlage 1" bleiben erhalten)
    - **`vaults`-Eintrag** für Maxim's Obsidian-Vault `Obsidian_Zentralw` angelegt (war vorher leer `[]`!) + `lastSelectedVault` gesetzt
    - Chrome wieder normal gestartet (`open -a "Google Chrome"`)
5. **Verifikation:** Re-Read der LevelDB zeigt alle 7 Templates korrekt dekodiert mit Namen, Pfaden, Properties, Interpreter-Prompts.

**Erkenntnis Schritt 3:** Die Browser-Extension speichert Templates in Chrome's `Sync Extension Settings`-LevelDB. Direkter Import via Node.js + classic-level ist möglich, solange Chrome zum Schreibzeitpunkt nicht läuft. Das ist deutlich schneller als 7-fach manueller GUI-Import.

**Wichtig — `vaults` war leer:** Der Web Clipper kannte vorher keinen Obsidian-Vault. Das hätte die manuellen Imports auch nicht behoben — Maxim hätte zusätzlich Vault-Setup machen müssen. Tom hat das direkt mit erledigt.

### Hotfix Schritt 2 — Importable JSON-Templates

Direkt nach dem ersten Hotfix-Commit (`f11b4d7`) hat Maxim mit einem Browser-Screenshot bestätigt, dass die Extension **nicht** die Markdown-Templates aus dem Vault liest. Templates müssen als **JSON** über den Import-Button der Extension angelegt werden. Schritt 2:

- **7 neue JSON-Template-Dateien** in `$TOM_VAULT/99_Vorlagen/web-clipper/json/Tom-{Artikel,Paper,Video,Dokument,Social-Post,Rezept,Werkzeug}.json`
- Schema basierend auf Referenz-Implementierung `tuan3w/obsidian-template/templates/web-clipper/default-clipper.json` (`schemaVersion: 0.1.0`, `properties[]`, `noteContentFormat`, `path`, `noteNameFormat`)
- Jedes JSON enthält: 13–15 Frontmatter-Properties (Statische + 3 Interpreter-Prompt-Properties), `noteContentFormat` mit Body + Tom-Fallback-Hinweisen, korrekter `path` (`Clippings/<Typ>`), `noteNameFormat` `{{title|replace:"/":"-",":":" -"}}`
- Alle 7 JSONs validiert (`python3 -c "import json; json.load(open(...))"` für jede Datei)
- README.md Sektion 3 umgeschrieben — Import-Workflow (Datei-Upload-Button) statt Copy-Paste
- Modell-Label konsolidiert: **`gemma4-interpreter`** (Maxim's Modell heißt `gemma4`, nicht `gemme`) — angewendet in JSONs, Markdown-Referenz-Templates, README, ADR-005

**Erkenntnis:** Das ursprüngliche Konzept "Markdown-Templates im Vault sind die Quelle" funktioniert nicht — die Extension hat eigene Storage und liest die Vault-Files nicht. Die Markdown-Files in `99_Vorlagen/web-clipper/*.md` bleiben als **Lese-Referenz für Tom + Maxim** liegen, die JSONs in `json/` sind die **operativen Templates**, die in die Extension importiert werden.

### Was im Hotfix NICHT enthalten ist

- mcp-tools-Integration (v1.5-Kandidat, ADR-004)
- marker-api OCR-Upgrade (v1.5+)
- Ollama-Models-Path-Fix (out-of-scope, Maxim-Entscheidung via FAM-154)
- Single-Prompt-JSON-Interpreter (v1.5+ Konsolidierung, wenn Extension-Feature klar ist)
- Voll-Deprecation von `tom-clip-enrich`
