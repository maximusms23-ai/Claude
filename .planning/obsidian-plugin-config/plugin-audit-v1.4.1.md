# Plugin-Audit v1.4.1 — 17 neue Community-Plugins

**Datum:** 2026-04-10
**Anlass:** Phase 34 (v1.4.1) — Zwischen v1.4-Close (Plugin-Landscape dort: 35) und v1.4.1-Start wurden **17 weitere Plugins** installiert. Gesamt jetzt: **52 Plugins**.
**Scope:** Nur Recherche + Klassifikation + Tom-relevante Setup-Empfehlung. Keine Aktivierungen ohne Maxim-Abnahme.

## Klassifikations-Legende

- **★ Tom-relevant** — direkter Bezug zu Tom-Workflows, Setup empfohlen
- **~ Orthogonal** — nützlich für Maxim, kein Tom-Touchpoint, nur inventarisieren
- **· Nicht relevant** — kein klarer Mehrwert, installed-but-unused
- **⚠ Potentiell störend** — konkurriert mit bestehenden Tom-Tools, braucht Entscheidung

## Die 17 neuen Plugins

| # | Plugin-ID | Name (manifest) | Version | Zweck | Klassifikation | Tom-Touchpoint / Empfehlung |
|---|---|---|---|---|---|---|
| 1 | `ai-latex-generator` | AI LaTeX Generator | 1.0.5 | Natural Language → LaTeX-Formeln via lokalem LLM | · | Kein Tom-Bezug. Maxim braucht aktuell keine LaTeX-Formeln im Vault. **Installed-but-unused.** |
| 2 | `apple-books-import-highlights` | Apple Books — Import Highlights | 1.7.1 | Apple-Books-Highlights + Notes → Vault | ~ | Für Maxim nützlich wenn er Apple Books nutzt. Inventarisieren, kein Tom-Setup. Könnte später an `90_Wiki/`-Ingest-Flow angeschlossen werden. |
| 3 | `cao` | CAO | 1.6.1 | Claude-AI-Chat in Notes | ⚠ | Überlappt mit Smart Connections + `tom-ask`/`tom-wiki`. CAO ist Remote-Claude, Tom nutzt lokal `gemme`. **Empfehlung: installed-but-unused**, keine API-Keys hinterlegen. Wenn Maxim remote-Claude direkt im Vault will, später separat konfigurieren. |
| 4 | `email-block-plugin` | Email code block | 1.1.1 | Rendert ```email```-Codeblöcke (Preview-Formatierung) | ~ | Passiver Renderer ohne externe Connectivity. Ungefährlich, kein Setup nötig. Könnte für Eltern-Betreuung-Korrespondenz-Quotes im Vault verwendet werden. |
| 5 | `eml-reader` | Email Reader | 1.1.2 | Preview für eingebettete `*.eml`-Dateien | ★ | **Direkt relevant für Eltern-Betreuung**: Ämterbriefe kommen oft als .eml (Outlook-Export) oder als Scan. Mit eml-reader kann Maxim die .eml-Originale in `20_Dokumente/13_Betreuung/` ablegen und direkt im Vault lesen. **Empfehlung: aktivieren, Config-Backup, Privacy-Check.** |
| 6 | `large-language-models` | Large Language Models | 0.23.0 | Access zu OpenAI/Claude/Gemini + lokale GPT4ALL | ⚠/· | LLM-Hub — redundant mit `gemme` + Smart Connections + zukünftigem mcp-tools. **Empfehlung: installed-but-unused**, keine API-Keys hinterlegen. Falls in v1.5 ein einziges LLM-Plugin als Standard gewählt wird, hier entscheiden. |
| 7 | `llm-summary` | LLM Summary | 0.1.9 | Zusammenfassung von PDFs + Notes via LLM | ⚠/· | Überlappt mit `tom-clip-enrich` (Summary-Feature) und `tom-doc show` (PDF-Excerpt). **Empfehlung: installed-but-unused.** Tom behält die Pipeline. |
| 8 | `llm-test-gen` | LLM Test Generator | 1.2.2 | Testfragen-Generator aus Notes | · | Kein Tom-Bezug. Use-Case wäre "Wissens-Abfrage-Training" — passt nicht zum Lebens-Vault. **Installed-but-unused.** |
| 9 | `marker-api` | OCR-AI (Marker) | 1.4.6 | PDF → Markdown via Marker API (self-hosted oder Mistral) | ⚠ | **Upgrade-Kandidat für `tom-doc` Backend** in v1.5+. Marker liefert deutlich bessere Layouts als `ocrmypdf+tesseract` für komplexe PDFs (Tabellen, Formeln). Für v1.4.1 nur dokumentieren via **ADR-005**. Setup nach Marker-Host-Entscheidung (self-hosted vs Mistral-API). |
| 10 | `mcp-tools` | MCP Tools | 0.2.27 | Model Context Protocol in Obsidian — Semantic Search + Templates + File Mgmt | ★ | **Hoch relevant**: MCP ist das potenzielle Gateway für Tom-CLI-Tools (tom-doc, tom-wiki, tom-ask) direkt im Obsidian-Editor. Für v1.4.1: **nur ADR-004**, keine Integration. Echte Integration braucht eigene Phase in v1.5 (Server-Schema prüfen, Config, Privacy-Check). |
| 11 | `messager` | Messager | 1.1.8 | Nachrichten-Import via WeChat / HTTP-API / Email in Vault | ★/⚠ | Direkt relevant für Eltern-Betreuung-Email-Korrespondenz (HTTP-API-Endpoint). **Privacy-kritisch**: Öffnet Vault für externen POST-Input. **Empfehlung: installed-but-unused** bis Maxim konkreten Use-Case definiert. Für v1.5 Email-Workflow-Evaluation zusammen mit `taskrobin`. |
| 12 | `obsidian-apple-reminders-plugin` | Apple Reminders | 2.0.0 | Sync Apple Reminders ↔ Vault | ★ | **Direkt relevant** für `40_Aufgaben/TODOS.md`. Wenn Maxim Apple Reminders nutzt, kann das die Brücke zwischen macOS-Reminders und TODOS.md werden. **Empfehlung: aktivieren wenn Maxim Reminders nutzt**, Config-Backup, Smoke-Test mit 1 Test-Reminder. Kollisionsprüfung mit `obsidian-tasks-plugin` (v1.5 Eval). |
| 13 | `obsidian-ocr` | Obsidian OCR | 2.0.1 | OCR für Bilder/PDFs in Obsidian | ⚠ | **Konkurriert mit `tom-doc` OCR-Pipeline.** Koexistenz möglich: obsidian-ocr als Ad-hoc-Tool für einzelne Seiten im Editor (z.B. schnelle Handschrift-Erkennung), `tom-doc` bleibt Primary für Batch + SQLite-FTS-Index. **ADR-003 dokumentiert Koexistenz-Regel**: obsidian-ocr darf NICHT `~/Downloads/Archiv/` oder `archivum/db/` beschreiben. |
| 14 | `open-in-terminal` | Open in Terminal | 0.9.1 | Vault-Ordner in Terminal öffnen, CLI-Tools starten | ~ | Developer-Convenience. Für Maxim nützlich wenn er aus Obsidian heraus schnell `tom-doc search` o.ä. starten will (bevor mcp-tools integriert ist). Aktivieren ist risikofrei, kein Tom-Setup nötig. |
| 15 | `shell-path-copy` | Shell Path Copy | 1.17.1 | Vault-Pfade als Shell-Pfad kopieren (für Claude Code / Gemini CLI) | ~ | Pure Convenience — wenn Maxim aus Obsidian heraus einen Pfad in Claude Code paste will. Kein Tom-Workflow-Impact. |
| 16 | `tars` | Tars | 3.5.2 | Text-Generation via DeepSeek/Claude/OpenAI/Gemini/Qwen | ⚠/· | Text-Generation-Plugin — überlappt mit Smart Connections LLM-Chat + gemme. **Empfehlung: installed-but-unused**, keine API-Keys. Wenn Maxim ein Obsidian-internes Chat-Plugin will, in v1.5 entscheiden ob Smart Connections reicht oder Tars/CAO parallel läuft. |
| 17 | `taskrobin` | Sync Emails | 1.2.0 | Email-Sync (inkl. Attachments) → Vault via TaskRobin-Service | ★/⚠ | Direkt relevant für Eltern-Betreuung (Amtsbriefe per Email). **Braucht TaskRobin-Account** (externer Service) — Privacy-Check vor Aktivierung. **Empfehlung: installed-but-unused** bis Maxim-Entscheidung ob TaskRobin OK ist, oder `eml-reader` + manueller Workflow reicht. |

## Summary nach Klassifikation

- **★ Tom-relevant (potentiell aktivieren):** 4 Plugins — `eml-reader`, `mcp-tools`, `obsidian-apple-reminders-plugin`, `taskrobin`
- **★/⚠ Relevant aber Privacy-kritisch:** 2 Plugins — `messager`, `taskrobin` (überlappt mit ★)
- **⚠ Konflikt / Koexistenz-Entscheidung:** 4 Plugins — `cao`, `marker-api`, `obsidian-ocr`, `tars` (+ `large-language-models`, `llm-summary` als Varianten)
- **~ Orthogonal (inventarisieren, kein Setup):** 4 Plugins — `apple-books-import-highlights`, `email-block-plugin`, `open-in-terminal`, `shell-path-copy`
- **· Nicht relevant (installed-but-unused):** 3 Plugins — `ai-latex-generator`, `llm-test-gen`, `large-language-models`/`llm-summary`/`tars` (redundante LLM-Plugins)

## Empfohlenes Setup (wartet auf Maxim-Abnahme)

**Setup-Kandidaten (4):**
1. **`eml-reader`** — Aktivieren, Smoke-Test mit 1 Dummy-`.eml`, Config-Backup
2. **`obsidian-apple-reminders-plugin`** — Aktivieren nur wenn Maxim Apple Reminders nutzt, Config-Backup, 1 Test-Reminder
3. **`mcp-tools`** — NICHT aktivieren, nur **ADR-004** anlegen als v1.5-Kandidat
4. **`marker-api`** — NICHT aktivieren, nur **ADR-005** anlegen als Upgrade-Kandidat für `tom-doc` Backend

**Explizit NICHT aktivieren (bleibt installed-but-unused):**
- `cao`, `tars`, `large-language-models`, `llm-summary`, `llm-test-gen`, `ai-latex-generator` — LLM-Plugin-Überlapp
- `messager`, `taskrobin` — Privacy-kritisch, braucht dedizierte Use-Case-Entscheidung

**Risikofrei nutzbar ohne Setup:**
- `apple-books-import-highlights`, `email-block-plugin`, `open-in-terminal`, `shell-path-copy` — keine Konfiguration, kein Privacy-Risiko

**Koexistenz-Entscheidung nötig:**
- `obsidian-ocr` — **ADR-003** mit Koexistenz-Regel (darf nicht `archivum/` anfassen)

## Offene Fragen an Maxim — BEANTWORTET (Phase 37, 2026-04-12)

**Status: answered**

1. **Apple Reminders** → **Ja, aktivieren.** Plugin `obsidian-apple-reminders-plugin` v2.0.0 wird konfiguriert und smoke-tested. Recherche (2026-04-12) zeigt: Plugin ist AppleScript-basiert, macOS-only, v2.0.0 stabil. Bidirektionaler Sync mit `obsidian-reminders-sync` (oleksiitymchenko) als Upgrade-Option falls nötig. Für Phase 43 (Lifecycle Dashboards) wird Apple-Reminders-Sync für `state == Doing`-Aufgaben gebraucht.
2. **`.eml`-Dateien in Betreuung** → **Ja, aktivieren.** `eml-reader` v1.1.2 ist reiner lokaler Preview-Renderer (kein Netzwerk, kein Privacy-Risiko). Maxim kann `.eml`-Exports aus Outlook/Mail in `20_Dokumente/13_Betreuung/` ablegen und direkt im Vault lesen.
3. **TaskRobin vs eml-reader** → **eml-reader-only für jetzt.** TaskRobin braucht externen Cloud-Account (Privacy-kritisch). `eml-reader` + manueller `.eml`-Export aus Mail.app reicht für den Betreuungs-Workflow. TaskRobin bleibt installed-but-unused bis ein konkreter Automatisierungs-Bedarf entsteht.
4. **LLM-Plugin-Konsolidierung** → **Nur Smart Connections bleibt aktiv.** Die 6 redundanten LLM-Plugins (`cao`, `tars`, `large-language-models`, `llm-summary`, `llm-test-gen`, `ai-latex-generator`) wurden in Phase 37 aus `community-plugins.json` entfernt. Smart Connections + lokaler `qwen2.5:3b`-Stack (tom-wiki/tom-ask) ist der einzige LLM-Pfad. MCP-Bridge (Phase 39) wird der nächste Integrationsschritt.
5. **marker-api Backend-Upgrade** → **Deferred nach v1.6+.** Aktuell ist `pdftotext` + `ocrmypdf`-Fallback ausreichend für den Archiv-Bestand. `marker-api` bleibt installed-but-unused. Wenn komplexe PDFs (Tabellen, Formeln) zum Problem werden, self-hosted Marker evaluieren (kein externer API-Key).

## Nicht-Ziele in Phase 34

- **Echte Integration von mcp-tools** → v1.5 Phase 39
- **Echte Integration von marker-api** → v1.6+
- **Echte Aktivierung von messager/taskrobin mit Accounts** → deferred bis konkreter Use-Case
- ~~Entscheidung ob `large-language-models` ggf. doch Primary wird~~ → **Erledigt: Nein, Smart Connections bleibt einziges LLM-Plugin (Phase 37)**
