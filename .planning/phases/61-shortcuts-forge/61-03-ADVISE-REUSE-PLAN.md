# 61-03 — Advise-Stufe: Experten-Analyse vor dem Bauen (Umsetzungsplan)

**Datum:** 2026-07-20 · **Basis:** Phase 61 + 61-02 · **Maxim-Anforderung:** „Erst ähnliche Projekte auf Web/GitHub suchen und anpassen statt neu entwickeln; Experten-Schätzung, ob Kurzbefehl, Python, Pages, Excel … das richtige Werkzeug ist; YouTube-Videos als Anforderungsquelle; Export-Button für existierende (auch extern hinzugefügte) Kurzbefehle."

## Bausteine (alles auf Bestehendem)

| Anforderung | Umsetzung | Basis |
|---|---|---|
| **Vorab-Suche Web/GitHub + Anpassen statt Neubau** | Neues Subcommand `tom-shortcut advise "Angabe"`: headless `claude --print` (Sonnet 5) **mit WebSearch/WebFetch-Tools** — sucht RoutineHub/GitHub/r/shortcuts/MacStories nach ähnlichen Shortcuts/Projekten, schlägt Anpassung statt Neubau vor | vorhandene Headless-Harness (`run_claude_build`-Muster) |
| **Experten-Schätzung Werkzeugwahl** | advise-Prompt bewertet: Kurzbefehl vs. Python-Helper vs. AppleScript vs. Pages/Numbers/Excel vs. Kombination — mit Begründung + Erfolgswahrscheinlichkeit + optimiertem Bau-Brief zum Übernehmen | Helper-Vertrag (Python/AppleScript/Swift existieren schon als Bausteine) |
| **Lokale Wiederverwendung** | advise bekommt die Liste **aller installierten** (45, inkl. extern hinzugefügter — `shortcuts list` sieht alles) + Ablage-Drafts in den Prompt → „Nimm X als Basis, per fix ändern" | `installed_shortcuts()`, `list_dir()` |
| **YouTube als Quelle** | `--youtube URL`: Agent holt Titel/Beschreibung/Transkript-Infos per WebFetch/WebSearch (Best-Effort — YouTube rendert JS; Suche nach Titel+Transcript gleicht das meist aus) und extrahiert die Anforderung | WebFetch/WebSearch im Print-Mode |
| **Export-Button** | UI: Button „⬇ Als Draft exportieren" in der Korrektur-Karte → `/api/export` (synchron, <10 s) → `tom-shortcut export` | `cmd_export` (61-02) |
| **Ergebnis-Ablage** | Analyse landet als Markdown in `$OUT/advice/<zeit>-<slug>.md` + wird in der UI angezeigt; Button „→ In Bau-Formular übernehmen" | Ablage-Konvention |

## Ablauf für Maxim

1. Karte **„🎓 Analyse zuerst"**: Angabe (+ optional YouTube-Link) → „Analysieren" (~1–2 Min, Sonnet 5)
2. Ergebnis erscheint: Werkzeug-Empfehlung · ähnliche existierende Projekte (Links) · lokale Reuse-Kandidaten · optimierter Bau-Brief
3. Ein Klick übernimmt den optimierten Brief ins Bau-Formular → normaler Build/Fix

## Grenzen (ehrlich)

- „100 % Gewährleistung" gibt es bei generativen Systemen nicht — die Advise-Stufe **maximiert** die Trefferquote (richtiges Werkzeug, erprobte Vorlagen, Validator), Rest fängt der Craig Loop
- Fremde `.shortcut`-Downloads von Galerien sind signiert/verschlüsselt → nicht direkt remixbar; Reuse heißt: Struktur/Ideen übernehmen oder iCloud-Link in der Shortcuts-App hinzufügen und dann per `fix` ändern (Cherri `--import` für iCloud-Links = Deferred)
- YouTube ohne öffentliches Transkript → Agent fällt auf Titel/Beschreibung/Suchtreffer zurück

## Verifikation

1. `tom-shortcut advise "Morgens Wetter + erste 3 Termine als Benachrichtigung"` → Markdown mit allen 5 Sektionen, Datei in `advice/`
2. `/api/export` mit „Uhrzeit-Test" → Draft erscheint (synchron)
3. UI: Analyse-Karte startet Job, Ergebnis wird angezeigt, Übernehmen-Button füllt Bau-Formular
