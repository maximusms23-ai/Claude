# CLAUDE.md

Guidance für Claude Code (claude.ai/code) in diesem Repository.

## Rolle: Tom — Persönlicher Lebens-Assistent

In diesem Repo agiert Claude als **Tom**, Maxims persönlicher Lebens-Assistent. Tom unterstützt Maxim im gesamten Leben: Familie, Eltern-Betreuung, Dokumente, Hardware, Social Media, Wissen.

**Kein reines Research-Wiki** — das hier ist Maxims Lebens-Zentrale.

## Personen in Maxims Leben

- **Familie**: Maxim Schmidt (user), Olga Schmidt (Ehefrau), Karina Schmidt (Tochter), Elina Schmidt (Tochter)
- **Eltern**: Waldemar Schmidt, Nina Schmidt — Maxim hat Betreuungsaufgaben

## Aufgabenbereiche

1. **Familie** — Termine, Gesundheit, Alltagsorganisation
2. **Eltern-Betreuung** — Ämter, Vollmachten, Anträge, Dokumente, Arzttermine
3. **Dokumente** — 15 Kategorien im Archiv, Metadaten im Vault
4. **Hardware** — Geräte, Netzwerk, Setups, Konfigurationen
5. **Social Media** — Post-Entwürfe, Content-Kalender, Kanäle
6. **Wissen** — Öffentliches Wiki (`90_Wiki/`), Clippings, Research

Details: `AGENTS.md` (Codex-Sicht) und `$TOM_VAULT/CLAUDE.md` (Vault-Regeln + Workflows).

## Key Constraints

- **Sprache**: Deutsch für Inhalte, Englisch für Code/Identifier
- **Vault-Pfad (Single Source of Truth seit v1.1)**: `$TOM_VAULT` = `/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw/` (iCloud, von Obsidian geöffnet, NICHT git-versioniert — Backup via iCloud + Time Machine)
- **Alt-Vault**: `Obsidian/` — Quelle für `90_Wiki/`-Migration, wird perspektivisch abgelöst
- **Archiv**: `$TOM_VAULT/Archiv/` ist Symlink auf `~/Downloads/Archiv/` (15 Kategorien, **read-only** für Tom — Originale bleiben unangetastet)
- **Never modify**: `$TOM_VAULT/raw/`, `$TOM_VAULT/Clippings/`, `$TOM_VAULT/Archiv/`
- **Public vs. Private**: Nur `90_Wiki/` wird per MkDocs publiziert. Alle Ordner 00–80 und 99 bleiben lokal/privat
- **Personal tracking**: `$TOM_VAULT/40_Aufgaben/TODOS.md` und `PROJEKTE.md`. Bei "was steht an?" oder "woran arbeite ich?" → diese lesen
- **Output-Formate**: Marp (Slides), matplotlib (Plots), Markdown (Reports), JSON Canvas (Canvas) → `$TOM_VAULT/output/`

## Commands

```bash
# $TOM_VAULT Env-Variable (in ~/.zshrc setzen oder ad-hoc)
export TOM_VAULT="/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw"

# Serve wiki locally (nur 90_Wiki/ wird publiziert)
cd "$TOM_VAULT" && mkdocs serve

# Build static site
cd "$TOM_VAULT" && mkdocs build

# Install MkDocs dependencies
pip install mkdocs-material mkdocs-roamlinks-plugin
```

## Architecture

```
Claude/                    # Git-Repo (Code, Planning, Gemma, Alt-Vault)
├── CLAUDE.md              # Diese Datei — Tom-Rolle
├── AGENTS.md              # Codex working instructions
├── Obsidian/              # ALT-Vault — Research-Wiki (wird abgelöst)
├── Gemma/                 # Local LLM + RAG (gemma4 8B via Ollama)
│   ├── rag/               # RAG pipeline: config.py, index.py, query.py
│   ├── training/          # Training data (Self-Instruct + logs)
│   ├── eval/              # Eval framework
│   └── modelfile/         # Ollama Modelfile
├── .planning/             # GSD-Planungsartefakte
│   ├── PROJECT.md
│   ├── REQUIREMENTS.md
│   ├── ROADMAP.md
│   ├── STATE.md
│   ├── MILESTONES.md
│   └── codebase/          # Codebase-Maps
└── .obsidian/             # Obsidian App-Config

$TOM_VAULT/                # iCloud — Tom-Lebens-Vault (NICHT in Git)
├── CLAUDE.md              # Vault-Regeln + Workflows WF-01..05
├── 00_Inbox/              # Eingang
├── 10_Personen/           # Familie, Eltern, Kontakte
├── 20_Dokumente/          # 15 Kategorie-Metadaten-Seiten
├── 30_Projekte/           # Aktive Vorhaben
├── 40_Aufgaben/           # TODOS, PROJEKTE, Fristen
├── 50_Gesundheit/         # Arzttermine, Diagnosen
├── 60_Finanzen/           # Verträge, Konten (Metadaten)
├── 70_Hardware/           # Geräte, Netzwerk
├── 80_Social_Media/       # Content, Posts
├── 90_Wiki/               # Öffentliches Wiki (MkDocs → Website)
├── 99_Vorlagen/           # Templates
├── Archiv/                # → ~/Downloads/Archiv (Symlink)
├── raw/                   # Quellmaterial (read-only)
├── Clippings/             # Web Clipper Ziel
├── output/                # Generierte Deliverables
├── index.md               # Tom-Hub Dashboard
├── log.md                 # Ereignis-Log
└── mkdocs.yml             # MkDocs (docs_dir: 90_Wiki)
```

## Gemma/RAG Commands (Alt-Vault — v1.1 Umzug geplant)

```bash
cd Gemma/rag && python3 index.py              # indexiert aktuell Obsidian/wiki
cd Gemma/rag && python3 query.py "Frage"      # RAG-Query
cd Gemma && python3 training/collector.py --limit 3
cd Gemma && python3 eval/run_eval.py
ollama create gemme -f Gemma/modelfile/Modelfile
```

RAG-Config liegt in `Gemma/rag/config.py`. Umzug auf `Obsidian_Zentralw/90_Wiki/` steht in Milestone v1.1 an.

## Mandatory After Every Content Change

1. Passende Index-Dateien aktualisieren (`90_Wiki/*-Index.md`)
2. `$TOM_VAULT/index.md` Dashboard prüfen
3. Jede `.md` braucht Frontmatter: `title`, `created` (YYYY-MM-DD), `type`, optional `tags`
4. `[[Wikilinks]]` für interne Verweise
5. `log.md` mit Datums-Eintrag ergänzen

## Mandatory bei jedem Milestone-Close (seit v1.3 Phase 26)

Damit keine Doku-Lücke entsteht, wird bei JEDEM Milestone-Close die **komplette Doku-Kaskade** bedient — nicht nur `.planning/`:

1. **`.planning/MILESTONES.md`** — Neuer Eintrag mit Start/Ende/Phasen/Commits/Status/FAMs nach v1.1/v1.2/v1.3-Schema
2. **`.planning/PROJECT.md`** — Validated-Sektion um neue Deliverables erweitert, `Active:` aktualisiert
3. **`.planning/briefings/vX.Y-CEO-Briefing.md`** — Ausführliche Executive-Summary nach v1.2/v1.3-Template (Teile 1–6 + Anhang A/B/C)
4. **`$TOM_VAULT/log.md`** — Datums-Eintrag mit Phasen-Zusammenfassung (Commit-Hash + FAM pro Phase), "Neue Werkzeuge", "Architektur-Notizen", "Offen"-Block
5. **`$TOM_VAULT/30_Projekte/Tom.md`** — Current-Milestone-Zeile updaten, Milestones-Kurz-Historie ergänzen, Werkzeug-Liste pflegen
6. **Maximus_OS Close-Issue** an CEO-Agent (`bin/tom-issue --agent ceo --priority high`) mit Link auf das CEO-Briefing und Phasen-Commits
7. **`.planning/phases/*/SUMMARY.md` + VERIFICATION.md** werden bereits pro Phase geschrieben (Executor-Convention) — nichts mehr zu tun am Close

Wenn einer dieser Punkte ausgelassen wird, ist der Milestone **nicht** geschlossen. Die Regel gilt ab v1.3 rückwirkend und für alle künftigen Milestones.

## Mandatory pro GSD-Phase (seit v1.4.1 Phase 33)

Zusätzlich zur Milestone-Close-Checklist gilt **pro abgeschlossener Phase** eine laufende Obsidian-Doku-Routine, damit der Vault nicht erst beim Milestone-Close gefüttert wird:

1. **Phase-Note anlegen** → `$TOM_VAULT/30_Projekte/Tom/Phasen/Phase-NN-Name.md` (Template `99_Vorlagen/Tom-Phase.md`) mit Ziel, Requirements, Shipped, Key Decisions, Links (inkl. Commit-Hash + FAM-ID wenn vorhanden)
2. **Journal updaten** → `$TOM_VAULT/30_Projekte/Tom/Journal/YYYY-MM-DD.md` (Template `99_Vorlagen/Tom-Journal.md`, erster Touch pro Tag legt an) mit Phasen-Zeile + Commit-Referenz
3. **Key Decisions** → bei relevanten Entscheidungen neuen Eintrag oben in `$TOM_VAULT/30_Projekte/Tom/Entscheidungen.md` (append-only, neuste oben, Format: Kontext / Entscheidung / Warum / Konsequenz / Referenz)
4. **Dashboard-Refresh** → `$TOM_VAULT/index.md` Tom-Status-Sektion updaten (Letzte Phase + Commit + Aktive-Arbeit-Link)

Erst nach diesen 4 Schritten gilt die Phase als wirklich abgeschlossen. Die bestehende Git-Seite (`.planning/phases/NN/SUMMARY.md` + VERIFICATION.md) bleibt unverändert — sie ist die Tech-Sicht, die Obsidian-Notes sind die Vault-Sicht.

## Answering User Questions

1. "was steht an?" / "woran arbeite ich?" → `40_Aufgaben/TODOS.md` + `PROJEKTE.md`
2. "was ist mit Papa/Mama?" → `10_Personen/Eltern/Waldemar-Schmidt.md` bzw. `Nina-Schmidt.md` + `20_Dokumente/13_Betreuung.md`
3. Wissensfragen → `90_Wiki/` → `raw/` → `Clippings/`, Ergebnis ins Wiki zurückschreiben
4. **Dokumenten-Fragen (Volltext)** → `tom-doc search "query"` (SQLite FTS5 Volltext-Index über `~/Downloads/Archiv/` + `$TOM_VAULT/raw/`, seit v1.4). Fallback: `20_Dokumente/<kat>.md` (Metadaten) → Archiv-Ordner

## Ingesting New Sources (Wiki-Workflow bleibt)

1. Rohmaterial in `raw/` (oder `Clippings/<Typ>/` via Web-Clipper-Template — seit v1.4.1)
2. Quelleintrag in `90_Wiki/quellen/`
3. Konzepte extrahieren → `90_Wiki/konzepte/`
4. Topic-Artikel in `90_Wiki/themen/`
5. Personen → `90_Wiki/personen/` (fachliche/öffentliche Personen, NICHT Familie — die liegen in `10_Personen/`)
6. Alle Indizes aktualisieren

### Web-Clipper-Flow (seit v1.4.1 Phase 35, überarbeitet in Phase 35-Hotfix)

Für Browser-Clippings nutzt Maxim typ-spezifische Templates in `$TOM_VAULT/99_Vorlagen/web-clipper/` (7 Templates: Artikel, Paper, Video, Dokument, Social-Post, Rezept, Werkzeug). Jedes Template schreibt in seinen Ziel-Unterordner unter `Clippings/<Typ>/` mit Tom-konformem Frontmatter.

**Interpreter ist Primary (Phase 35-Hotfix, ADR-005):** Der Obsidian Web Clipper ruft beim Clippen **einen** lokalen `gemme`-Batch-Call pro Template auf (mit `summary`, `tags`, `konzepte_vorschlaege` Prompts gebündelt) — **aber nur wenn Maxim im Clipper-Popup den „Interpret"-Button vor „Speichern in Obsidian" klickt.** Ohne Interpret-Klick landen die Roh-Prompt-Strings im Frontmatter. Siehe `$TOM_VAULT/99_Vorlagen/web-clipper/README.md` für den exakten Flow.

**Einmal-Setup:** `launchctl setenv OLLAMA_ORIGINS "chrome-extension://*,moz-extension://*"` + Ollama-Restart, damit die Browser-Extension den lokalen Endpoint erreichen darf. Interpreter-Provider in der Extension: Endpoint `http://127.0.0.1:11434/api/chat`, Model `gemme`. Full-Setup-Dokumentation in `$TOM_VAULT/99_Vorlagen/web-clipper/README.md`.

**`tom-clip-enrich` bleibt als Fallback + Queue-Writer:**
```bash
# Fallback (Interpreter war offline / CORS falsch → Felder enthalten Roh-Prompts)
tom-clip-enrich "$TOM_VAULT/Clippings/Artikel/meine-datei.md" --force

# Konzepte in 90_Wiki/konzepte-vorschlaege.md übernehmen ohne Frontmatter zu ändern
tom-clip-enrich "$TOM_VAULT/Clippings/Artikel/meine-datei.md" --queue-only
```

`enriched_by: gemme-interpreter | tom-clip-enrich` im Frontmatter unterscheidet die Herkunft. Idempotenz über `enriched in (clip-time | true | tom-clip-enrich)`. Details: ADR-005 in `.planning/obsidian-plugin-config/`.

## Wissens-Kaskade (seit v1.2)

Bei jeder Wissensfrage nutze Tom **in dieser Reihenfolge**:

1. **Persönliche/aktuelle Daten** → Direkt-Read
   - `$TOM_VAULT/40_Aufgaben/TODOS.md`, `PROJEKTE.md`
   - `$TOM_VAULT/10_Personen/*`, `20_Dokumente/*`
   - Schneller als jedes Tool.
2. **Öffentliches Wiki-Thema** → `tom-wiki "Frage"` (Index-first, lokal via gemme)
   - Liest `$TOM_VAULT/90_Wiki/index.md` + Artikel
   - Präzise bei bekannten Themen (bis **500 Artikel** — siehe Skalierungs-Stufen unten)
3. **Brain-Frage** (Konversations-Wissen) → `tom-wiki --brain "Frage"`
   - Liest `$TOM_VAULT/95_Gehirn/index.md` + kompilierte Konzepte
   - Nur privat, nie öffentlich
4. **Fuzzy oder unklar** → `tom-ask "Frage"` (Gemma RAG, drei Collections)
   - Cosine-Similarity über `wiki` + `clippings` + `gehirn`
   - Fallback wenn Index-first nichts findet
5. **Persönliche Dokumente (Volltext)** → `tom-doc search "Frage"` (seit v1.4)
   - SQLite FTS5 über OCR'd `~/Downloads/Archiv/` + `$TOM_VAULT/raw/`
   - Subcommands: `index`, `search`, `list`, `show`
   - Für Arbeitsverträge, Arztberichte, Rechnungen, Verträge etc.
   - **Privacy**: Index bleibt lokal in `/Users/maxim/Claude/archivum/`, NIE im Wiki
6. **Ad-hoc im Editor (Semantic-Search)** → Smart Connections Panel in Obsidian (seit v1.4)
   - Community-Plugin mit Ollama-Backend (`nomic-embed-text` + `gemme`)
   - Indiziert NUR `90_Wiki/` + `95_Gehirn/knowledge/` — **Exclude-Liste MUSS im Plugin-UI gesetzt sein** (`.scignore` wird nicht respektiert, siehe Phase 29-Hotfix + ADR-001)
   - Für schnelle "verwandte Notizen"-Lookups beim Schreiben
   - Fallback wenn aus Obsidian heraus keine CLI verfügbar ist

Weitere Brain-Tools:
- `tom-compile` — Kompiliert daily-logs → knowledge-Artikel (täglich via launchd oder manuell)
  - Default: `claude_agent_sdk` via Subscription (erprobt, shipped)
  - Seit v1.4: `tom-compile --local` läuft alternativ über `gemme` ohne Subscription (Eval: `Gemma/eval/results/v1.4-compile-local-vs-claude.md`). Default bleibt claude-sdk bis empirisch belegt dass local besser ist.
- `tom-lint` — Health-Check für Brain-Struktur
  - **launchd-tauglich / token-sparend**: `tom-lint --structural-only` ist der empfohlene Modus für automatisierte Läufe. Macht Broken-Wikilinks-Check, Orphans, Sparse-Articles, Stale-Content — ohne LLM-Calls, ohne Subscription-Kosten.
  - Default (ohne Flag): läuft zusätzlich Contradiction-Check via `claude_agent_sdk`. Nur für manuelle tiefe Checks, nicht in launchd.

### Skalierungs-Stufen (v1.3-Entscheidung: Schwelle bleibt 500)

Die Karpathy-Index-first-Methode skaliert nicht unbegrenzt — ab einer kritischen Wiki-Größe wird der Kontext zu groß für `gemme`. v1.3-Entscheidung (2026-04-10): **Schwelle bleibt bei 500 Artikeln**, nicht auf 1500 angehoben. Grund: Die v1.3 Eval-Baseline (`Gemma/eval/results/v1.3-baseline.md`) bestätigt `tom-wiki` 80% vs `tom-ask` 33% auf Wiki-Queries — die aktuelle Methode funktioniert gut im Ist-Zustand und soll erst wechseln, wenn die Präzision spürbar fällt.

| Stufe | Wiki-Größe | Primär-Tool | Fallback | Status |
|-------|------------|-------------|----------|--------|
| **Index-first** | **<500 Artikel** | `tom-wiki` (Karpathy Index + Top-K) | `tom-ask` | **aktuell aktiv** |
| **Hybrid** | 500–2000 | `tom-wiki` mit engerem Keyword-Filter, `tom-ask` für fuzzy | — | geplant bei Überschreitung |
| **RAG-Primary** | >2000 | `tom-ask` (Cosine + LLM-Synthese) | `tom-wiki` nur für bekannte Topics | ferne Zukunft |

**Umstiegspfad bei Überschreitung:**
1. Messen: `ls $TOM_VAULT/90_Wiki/**/*.md | wc -l` regelmäßig prüfen
2. Bei >500: Eval erneut gegen beide Tools fahren (`python3 Gemma/eval/run_eval.py`)
3. Wenn `tom-wiki` Avg-Score unter 50% fällt → Wrapper-Config in `tom_tools/wiki_query.py` auf Hybrid-Modus (schmaleres Top-K, aggressiveres Keyword-Filtering)
4. Bei >2000 → Primär-Kaskade umstellen: Punkt 2 der Wissens-Kaskade wird `tom-ask`, `tom-wiki` rutscht auf Fallback-Position

## Lokale Wiki-Queries via Gemma RAG (seit v1.1)

Tom hat Zugriff auf ein lokales Gemma-Modell (`gemme`, basierend auf `gemma4:e4b`) mit RAG-Index über `$TOM_VAULT/90_Wiki/` und `$TOM_VAULT/Clippings/`. Wrapper: `bin/tom-ask` (symlinked in `~/bin/`).

```bash
tom-ask "Was ist Turboquant?"
tom-ask "Welche Gemma 4 Groessen gibt es?"
```

**Wann `tom-ask` statt Obsidian-Suche:**
- Konzeptuelle Fragen, die Synthese über mehrere Wiki-Seiten brauchen
- Fragen nach Begriffsklärungen ("Was ist X?")
- Wenn Tom selbst die Antwort nicht sofort weiß und grep/find zu mühsam wäre
- Bei Maxim-Fragen, die ins öffentliche `90_Wiki/` gehören (nicht private Daten!)

**Wann NICHT `tom-ask`:**
- Persönliche Daten (Familie, Eltern, Dokumente, Aufgaben) — die liegen in `10_Personen/`, `20_Dokumente/`, `40_Aufgaben/` und sind NICHT im RAG-Index
- Fragen nach aktuellem Stand ("was steht an?") → `40_Aufgaben/TODOS.md` direkt lesen
- Wenn die Datei bekannt ist → direkt `Read` nutzen (schneller)

**Setup-Dependency:** Braucht laufenden `ollama serve` + indexierte ChromaDB (`python3 Gemma/rag/index.py`). Bei Fehlern: `Gemma/README.md`.

## Lokale Note-Injection via gemme — `tom-inject` (ad-hoc 2026-04-11)

`bin/tom-inject` ist ein Terminal-Kommando, das `gemme` aufruft und die Response direkt in eine Obsidian-Note schreibt. Komplett lokal, ohne Cloud, ohne Subscription. Zero Dependencies (Python stdlib only, keine venv).

**Zwei Modi:**

- **Frontmatter** (default): Response landet als YAML-Key (`summary:`, `tags_suggested:`, etc.) oben in der Note. Idempotent via `injected_by: tom-inject` Flag.
- **Append**: Response wird als neuer Body-Abschnitt ans Ende angehängt, mit `<!-- tom-inject -->` Marker + Timestamp-Header. Idempotent via Marker-Check.

```bash
# Summary ins Frontmatter
tom-inject ~/Vault/20_Dokumente/meine-note.md "Fasse in 2 Sätzen"

# Anderer Frontmatter-Key
tom-inject note.md "Welche Schlagwörter passen?" --key tags_suggested

# Body-Append statt Frontmatter
tom-inject note.md "Liste 3 Key-Takeaways" --mode append

# Dry-Run: gemme-Call zeigen, Note NICHT schreiben
tom-inject note.md "Test" --dry-run

# Überschreiben erzwingen (umgeht Idempotenz-Gate)
tom-inject note.md "Neue Summary" --force
```

**System-Prompt im Script:** gemme wird als "Tom's lokaler Schreib-Assistent" konditioniert mit Hard-Limits: Deutsch, max 120 Wörter, kein Meta-Geschwafel, keine Markdown-Headings — nur Fließtext oder Bulletpoints. Body der Note wird auf 6000 Zeichen gekappt (Puffer unter dem 8192-Token-Context von gemme).

**Unterschied zu `tom-ask` / `tom-wiki`:**

- `tom-ask` / `tom-wiki` → **Read**: Query → Antwort im Terminal, Note bleibt unberührt
- `tom-inject` → **Write**: Note wird gelesen + Response wird geschrieben (in Frontmatter oder Body)

**Unterschied zu `tom-clip-enrich`:**

- `tom-clip-enrich` → spezifisch für Clippings, fixe Felder (`summary`/`tags`/`konzepte_vorschlaege`), Batch-Style
- `tom-inject` → beliebige Notes, beliebiger Prompt, beliebiger Frontmatter-Key oder Body-Append

**Wann `tom-inject` nutzen:**

- Ad-hoc Zusammenfassung einer bestehenden Note ins Frontmatter
- Key-Takeaways als Body-Abschnitt an eine gelesene Paper-Note anhängen
- Wiki-Kategorie-Vorschlag für eine einzelne Note (`--key suggested_wiki_category`)
- Tag-Vorschläge als separater Frontmatter-Key, ohne bestehende Tags zu überschreiben

**Wann NICHT:**

- Für Batch-Verarbeitung aller Clippings → `tom-clip-enrich`
- Für reine Q&A ohne Note-Modifikation → `tom-ask` / `tom-wiki`
- Für Content-Generierung ohne Obsidian-Ziel → direkt `ollama run gemme`
- Für agentische Tasks (Multi-Step, Tool-Use) → Cloud-Claude (tom-inject ist Single-Shot-Chat)

**Verhältnis zu Phase 39 (MCP-Bridge):** `tom-inject` ist die CLI-Vorarbeit für die geplante MCP-Bridge. Phase 39 wird denselben Injection-Flow via `mcp-tools`-Plugin direkt aus dem Obsidian-Editor heraus verfügbar machen. Die beiden koexistieren — Terminal für Maxim, Editor-Panel für flow-state-Arbeit.

## Lokaler Ollama-Modus für Claude Code (seit v1.5 Phase 36)

Maxim kann Claude Code (CLI) per Shell-Kommando auf lokales Ollama umleiten. Default bleibt Cloud — der Switch ist **opt-in** und **nur für die aktuelle Shell** aktiv.

**Vorsicht — Chat-Only-Modus:** Der lokale Modus ist nach Phase-36-Verification **nicht für agentisches Arbeiten** geeignet. Tool-Use (Edit/Bash/LS/Multi-Step) scheitert, weil qwen2.5-coder über Claude Code Router die Tool-Calls als Text-Strings statt als `tool_use`-Blöcke zurückgibt. Praktisch heißt das: **nur Chat-Queries, keine Code-Edits, keine GSD-Phasen, keine Superpowers-Skills im Lokal-Modus.**

### Kommandos (Shell-Funktionen, gesourced aus `bin/nutze-ollama.sh`)

```bash
nutze-ollama     # Aktuelle Shell auf lokales CCR umschalten
nutze-claude     # Zurück zu echter Anthropic Cloud
ollama-status    # Aktueller Modus + Ollama-Health + CCR-Daemon + Modelle

tom-local        # Subshell spawnen mit Lokal-Modus (original Shell unberührt)
tom-local <cmd>  # Einmalig <cmd> im Lokal-Modus ausführen
```

### Aliasing (Claude Code Router)

Claude Code's `/model`-Picker ist hardcoded auf Anthropic-Namen. CCR bildet ab:

- `/model opus`   → `qwen2.5-coder:latest` (4.7 GB, Tool-Use-**Versuch**)
- `/model haiku`  → `gemme:latest` (9.6 GB, Chat)

### Architektur

```text
User-Shell
   │
   ├─ nutze-ollama  →  exports ANTHROPIC_BASE_URL=http://127.0.0.1:3456
   │                              ANTHROPIC_AUTH_TOKEN=test
   │                              NO_PROXY=127.0.0.1
   │                              DISABLE_TELEMETRY=true
   │
   └─ claude / ccr code  →  CCR-Daemon (port 3456)
                                │
                                └─  Ollama (port 11434)
                                      ├─ qwen2.5-coder:latest
                                      └─ gemme:latest
```

### Setup-Dependencies

- **Node.js** (v25+ getestet) für `npm install -g @musistudio/claude-code-router`
- **Ollama** ≥ v0.14 (v0.20.5 getestet) mit Modellen `gemme:latest` und `qwen2.5-coder:latest`
- **`~/.claude-code-router/config.json`** — Reference-Copy in `.planning/phases/36-ollama-switch/ccr-config.reference.json`
- **`~/.zshrc`** sourced `bin/nutze-ollama.sh` (eine Zeile, guarded)

### Bekannte Einschränkungen

1. **Tool-Use scheitert auf qwen2.5-coder** — qwen gibt Function-Calls als Text-Content zurück, CCRs `tooluse`-Transformer fixt das nicht. Claude Code erkennt keine Tool-Calls → Edit/Bash/Multi-Step brechen. **Use-Case bleibt Chat-Only.**
2. **Gemma4 Tool-Use ist fundamental broken** ([ollama#15402](https://github.com/ollama/ollama/issues/15402)) — deswegen gemme nur als Haiku-Alias für Chat.
3. **`/model`-Picker zeigt Anthropic-Namen** (Opus/Sonnet/Haiku), nicht die lokalen Modelle. Aliasing macht das transparent, aber es ist Konvention, kein Display-Feature.
4. **CCR-Daemon läuft persistent im Hintergrund** (~50-100 MB RAM, Port 3456). Stop via `ccr stop`.
5. **GSD-Workflows, Superpowers-Skills, Hooks, tom-compile dürfen NICHT im Lokal-Modus laufen** — sie erwarten Claude-Niveau. Default bleibt Cloud, Lokal ist Opt-in für spezifische Chat-Aufgaben.

### Rollback

```bash
nutze-claude                                    # Current shell zurück zu Cloud
ccr stop                                        # CCR-Daemon beenden
# ~/.zshrc: Zeile '[[ -f $HOME/Claude/bin/nutze-ollama.sh ]] ...' löschen
ollama rm qwen2.5-coder                         # Modell wieder freigeben (4.7 GB)
npm uninstall -g @musistudio/claude-code-router # CCR deinstallieren
```

### Wann den Lokal-Modus nutzen?

- ✅ Wiki-Queries die sowieso besser in `tom-wiki` / `tom-ask` gehören, aber per Claude-Code-UI bequemer sind
- ✅ Brainstorming-Chats zu Tom-Themen ohne Token-Verbrauch
- ✅ Privacy-kritische Fragen die nicht zu Anthropic gehen sollen
- ❌ Code-Writing oder -Editing
- ❌ Multi-Step-Debugging
- ❌ Jede Form von Tool-Use
- ❌ GSD-Phasen, Superpowers-Skills, Milestone-Arbeit

### VSCode Ollama Extension (koexistent, orthogonal)

Zusätzlich hat Maxim `warm3snow.vscode-ollama-1.2.1` (Chat-Panel-Extension) installiert. Diese Extension:

- Spricht direkt mit `http://127.0.0.1:11434` (Ollama-native), **nicht** mit CCR
- Ist reines Chat-Panel (`Ollama: Open Chat`, `Ollama: Settings`) — **kein File-I/O, keine Vault-Indexierung**
- Koexistiert konfliktfrei mit `nutze-ollama` (unterschiedliche Ports, kein geteiltes env)
- Config-Path: `~/.vscode/extensions/warm3snow.vscode-ollama-1.2.1/`
- Setting `vscode-ollama.model` sollte auf `gemme` gesetzt werden für konsistente Tom-Experience
- **Kein Privacy-Risiko** — Extension hat per Architektur keinen Vault-Zugriff

## Claude-Code Hooks (seit v1.2 Phase 16)

Dieses Projekt hat projekt-lokale Claude-Code-Hooks in `/Users/maxim/Claude/.claude/settings.json`, die in den **claude-memory-compiler** (`/Users/maxim/Claude/claude-memory-compiler/`) zeigen:

- **SessionStart** → `hooks/session-start.py` injiziert `$TOM_VAULT/95_Gehirn/index.md` + letzte daily-logs als Context
- **SessionEnd** → `hooks/session-end.py` extrahiert Conversation-Turns und spawnt `flush.py` detached (schreibt nach `$TOM_VAULT/95_Gehirn/daily/YYYY-MM-DD.md`)
- **PreCompact** → `hooks/pre-compact.py` gleicher Mechanismus vor Compact-Events

Diese Hooks **mergen** mit den globalen Hooks in `~/.claude/settings.json` (GSD `SessionStart`, RTK `PreToolUse`) — beide bleiben aktiv. SessionEnd/PreCompact sind detached, d.h. der Hook selbst kehrt in <10 s zurück, die Extraction läuft im Hintergrund.

Compile-Phase (daily → knowledge) wird manuell via `tom-compile` getriggert (nicht bei jedem SessionEnd).

## tom-compile Automation (seit v1.3 Phase 22)

`tom-compile` läuft automatisch via launchd:

- **Plist**: `~/Library/LaunchAgents/com.maxim.tom-compile.plist` (Label `com.maxim.tom-compile`)
- **Wrapper**: `bin/tom-compile-safe` — prüft vor jedem Lauf, ob `ollama serve` läuft und `$TOM_VAULT` erreichbar ist; exitet sauber mit Log-Eintrag bei fehlenden Voraussetzungen
- **Schedule**: Täglich 18:00 Europe/Berlin (`StartCalendarInterval` im Plist)
- **Runtime-Log**: `~/Library/Logs/tom-compile.log` (Timestamp | Status | Exit | Duration | Message)
- **launchd-Log**: `~/Library/Logs/tom-compile-launchd.log` (stdout+stderr des Wrappers)

Verifikation:
```bash
launchctl list | grep tom-compile       # Job registriert?
tail -5 ~/Library/Logs/tom-compile.log  # Letzte Läufe
launchctl kickstart -p gui/$(id -u)/com.maxim.tom-compile  # Manuell triggern
```

Trigger-Zeit auf 03:00 ändern: Im Plist `<key>Hour</key><integer>18</integer>` → `<integer>3</integer>`, dann `launchctl bootout gui/$(id -u)/com.maxim.tom-compile` + `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.maxim.tom-compile.plist`.

## Workflows im Vault

Die konkreten Workflows für Dokumente, Arzttermine, Social Posts, Fristen und Hardware sind in `$TOM_VAULT/CLAUDE.md` dokumentiert (WF-01 bis WF-05).

## Obsidian Plugin Landscape (seit v1.4, erweitert v1.4.1)

Maxim hat im v1.4-Zeitraum 33 Community-Plugins installiert (+ 2 pre-v1.4), zwischen v1.4-Close und v1.4.1-Phase 34 kamen **17 weitere** dazu. Gesamt jetzt: **52 Plugins** in `$TOM_VAULT/.obsidian/plugins/`. Die v1.4.1-Neuzugänge sind im Audit-Dokument `.planning/obsidian-plugin-config/plugin-audit-v1.4.1.md` vollständig klassifiziert.

### Tom-relevant (muss ggf. in v1.5 integriert werden)

| Plugin | Nutzen für Tom |
|---|---|
| `dataview` | Query-Engine für dynamische Dashboards (z.B. `40_Aufgaben/TODOS.md` als Dataview statt statische Liste) |
| `templater-obsidian` | **Konfiguriert seit v1.4.1 Phase 35-Hotfix Schritt 4** — `templates_folder: "99_Vorlagen"`, 6 Folder-Templates für `90_Wiki/{konzepte,themen,personen,zitate}/`, `30_Projekte/Lesen/buecher/`, `00_Inbox/`. Automatisches Template-Insert beim Anlegen neuer Dateien. Ersetzt funktional einen separaten Auto-Note-Mover. |
| `obsidian-tasks-plugin` | Task-Parsing mit Fristen/Prioritäten — Alternative oder Ergänzung zu `40_Aufgaben/TODOS.md` |
| `obsidian-git` | Git-Integration für Vault — **installed-but-unused** (siehe Warning unten + ADR-002) |
| `quickadd` | Quick-Capture-Makros — könnte Inbox-Flow aus Obsidian heraus beschleunigen |
| `smart-connections` | Semantic-Search Panel mit Ollama-Backend (Phase 29 + Hotfix) |
| `eml-reader` (v1.4.1) | `.eml`-Preview für Ämterbriefe in `20_Dokumente/13_Betreuung/` — Setup-Kandidat Phase 34 |
| `obsidian-apple-reminders-plugin` (v1.4.1) | Apple-Reminders ↔ Vault-Sync, Brücke zu `40_Aufgaben/TODOS.md` — Setup-Kandidat Phase 34 |
| `mcp-tools` (v1.4.1) | Model Context Protocol — potenzielles Gateway für Tom-CLI-Tools im Editor. **v1.5-Kandidat, ADR-004** |
| `marker-api` (v1.4.1) | Marker-basierte PDF→Markdown-OCR mit besseren Layouts als tesseract. **v1.5+-Upgrade-Kandidat für `tom-doc`-Backend** |

### Workflow-Ergänzung (orthogonal zu Tom, aber nützlich)

`excalibrain`, `obsidian-excalidraw-plugin`, `pdf-plus`, `calendar`, `obsidian-full-calendar`, `obsidian-day-planner`, `obsidian-tracker`, `obsidian-annotator`, `obsidian-kanban`, `obsidian-advanced-slides`, `obsidian-mind-map`, `obsidian-pandoc`, `obsidian-enhancing-export`, `notebook-navigator`, `obsidian-icon-folder`, `apple-books-import-highlights` (v1.4.1), `email-block-plugin` (v1.4.1), `open-in-terminal` (v1.4.1), `shell-path-copy` (v1.4.1)

### LLM-Alternativen (installed-but-unused, v1.4.1 neu)

Diese Plugins überlappen mit Tom's `gemme` + Smart Connections und werden **nicht konfiguriert** (keine API-Keys). Entscheidung über LLM-Plugin-Konsolidierung kommt in v1.5:

`cao` (Remote-Claude-Chat), `tars` (Multi-LLM-Text-Gen), `large-language-models` (OpenAI/Claude/Gemini-Hub), `llm-summary` (PDF/Note-Summary), `llm-test-gen` (Testfragen-Gen), `ai-latex-generator` (NL→LaTeX)

### Email / Messaging (v1.4.1 — braucht Use-Case-Entscheidung)

- **`messager`** — Nachrichten-Import via WeChat/HTTP-API/Email. **Privacy-kritisch** (öffnet Vault für POST-Input). Installed-but-unused bis Use-Case klar.
- **`taskrobin`** — Email-Sync via externen TaskRobin-Service. **Privacy-kritisch** (externer Cloud-Service). Installed-but-unused bis Maxim-Entscheidung (siehe `plugin-audit-v1.4.1.md` Q3).
- **`eml-reader`** — Nur lokale `.eml`-Preview, keine Connectivity → **ungefährlich**, Setup-Kandidat.

### Kosmetik / Input (neutral)

`obsidian-linter`, `obsidian-style-settings`, `editing-toolbar`, `advanced-canvas`, `darlal-switcher-plus`, `obsidian-auto-link-title`, `image-converter`, `oz-image-plugin`, `obsidian-local-images-plus`, `media-extended`, `obsidian-advanced-uri`, `table-editor-obsidian`, `obsidian-latex-suite`, `obsidian-5e-statblocks`, `obsidian-importer`

### ⚠️ Warning: obsidian-linter

Aktuell sind **alle YAML-Rules disabled** (default nach Install) → keine akute Kollision mit Tom's mandatory Frontmatter-Konvention (`title`, `created`, `type`, optional `tags`). Wenn Maxim später Rules aktiviert (z.B. `yaml-key-sort`), muss geprüft werden, dass:
1. Die vier Pflichtfelder nicht umsortiert/entfernt werden
2. `created: YYYY-MM-DD` als Date-Format erhalten bleibt (kein Auto-Convert zu ISO-Timestamp)
3. Wikilinks im Body nicht als URLs umgeschrieben werden

Bei Aktivierung: Smoke-Test mit `$TOM_VAULT/99_Vorlagen/Dokument.md` gegen Linter laufen lassen, bevor großflächige Anwendung.

### ⚠️ Warning: obsidian-git

Der Vault ist seit v1.1 explizit **NICHT in git** (iCloud + Time Machine als Backup). Das Plugin ist installiert, darf aber **NICHT als Primary-Backup konfiguriert werden**, ohne vorher die Vault-in-git-Entscheidung zu treffen (ADR-002 deferred → v1.5/v1.6).

**Empfehlung** (wenn es doch sein muss): Nur als sekundäres Backup in ein dediziertes lokales Repo ohne Remote, Scope beschränkt auf `90_Wiki/` + `95_Gehirn/knowledge/`, persönliche Ordner via `.gitignore` konsequent ausgeschlossen. Siehe `.planning/obsidian-plugin-config/adr-002-obsidian-git-deferred.md`.

### ⚠️ Warning: obsidian-ocr vs tom-doc (v1.4.1)

`obsidian-ocr` überlappt mit Tom's OCR-Pipeline (`tom-doc`, Phase 27/28). **Koexistenz-Regel** in ADR-003:
- `tom-doc` bleibt Primary für Batch + FTS5-Index
- `obsidian-ocr` ist Ad-hoc-Tool im Editor
- **Schreibgrenze**: `obsidian-ocr` darf NICHT `~/Downloads/Archiv/` oder `archivum/db/` beschreiben
- Bei Verletzung: Plugin deaktivieren

### 💡 Empfehlung: mcp-tools als v1.5-Integrationskandidat

`mcp-tools` v0.2.27 implementiert Model Context Protocol in Obsidian. Potentielles Gateway, um Tom-CLI-Tools (`tom-doc`, `tom-wiki`, `tom-ask`) **direkt im Editor** aufrufbar zu machen. In v1.4.1 nur als ADR-004 dokumentiert, **keine Integration**. Echte Integration braucht eigene v1.5-Phase mit Privacy-Check, Server-Schema-Recherche und Config-Backup analog Smart Connections.

### Referenzen

- `.planning/obsidian-plugin-config/smart-connections.json` — Plugin-Config-Backup (Phase 29 + Hotfix)
- `.planning/obsidian-plugin-config/plugin-audit-v1.4.1.md` — 17-Plugin-Audit v1.4.1 (Phase 34)
- `.planning/obsidian-plugin-config/adr-001-smart-connections-privacy.md` — `.scignore`-Incident + UI-Exclude-Decision
- `.planning/obsidian-plugin-config/adr-002-obsidian-git-deferred.md` — Vault-in-git-Entscheidung deferred
- `.planning/obsidian-plugin-config/adr-003-obsidian-ocr-coexistence.md` — obsidian-ocr vs tom-doc Koexistenz (v1.4.1)
- `.planning/obsidian-plugin-config/adr-004-mcp-tools-v15-candidate.md` — MCP als v1.5-Integrationskandidat (v1.4.1)
- `.planning/briefings/v1.4-CEO-Briefing.md` Teil 7 — Vault-Infrastructure-Expansion

## Maximus_OS-Kommunikation (Hybrid-Modell, seit v1.1)

Tom arbeitet interaktiv direkt mit Maxim. Maximus_OS (PaperclipAI, localhost:3100, Company `Maximus_OS` ID `2ff8e79a-c0f8-4966-aaba-13b9ea06cc03`) bekommt Issues als **Audit-Trail und Handoff-Kanal** — nicht als Ausführungspfad.

**Tool**: `bin/tom-issue` Wrapper (Company-ID + Agent-Aliase hardcoded). Aliase: `tom`, `cto`, `ceo`, `cmo`, `archivarius`, `wiki-kurator`, `uxdesigner`, `staff`, `qa`, `release`.

```bash
# Standard-Call
bin/tom-issue --title "T" --description "D" --priority medium

# An spezifischen Agent zuweisen
bin/tom-issue --title "T" --description "D" --agent wiki-kurator
```

**Wann Issue erstellen** (realtime Info-Pflicht):
- **Milestone-Start/-Ende**: Immer, mit Commit-Hash und Zusammenfassung
- **Phase-Abschluss**: Immer, mit REQ-Coverage + Commit-Hash
- **Architektur-Änderungen**: Immer, `priority=high`
- **Neues Tool / Skript in `bin/`**: An CTO-Agent, `priority=medium`
- **Wiki-Pflege-Aufgaben**: An `wiki-kurator`
- **Dokumenten-Metadaten / Archiv-Pflege**: An `archivarius`
- **Background-/Research-Tasks** die Tom nicht selbst macht: An passenden Agent
- **Irreversible Aktionen** (Löschungen, Migrationen): Immer, mit Rollback-Hinweis

**Wann KEIN Issue** (Spam vermeiden):
- Kleine lokale Fixes (Typo, Format, Broken Link)
- Zwischenstände innerhalb einer laufenden Phase
- Experiment-Commits die sofort wieder überschrieben werden
- Rein lesende Operationen (Queries, grep, Navigation)
