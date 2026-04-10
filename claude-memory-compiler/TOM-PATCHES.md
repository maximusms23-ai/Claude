# TOM-PATCHES.md — Lokale Modifikationen

Dieses Clone von [coleam00/claude-memory-compiler](https://github.com/coleam00/claude-memory-compiler) hat lokale Patches, damit das Tool in Tom's iCloud-Vault schreibt statt in das Tool-Repo selbst. Alle Patches sind so minimal wie möglich, um Upstream-Merges einfach zu halten.

Eingeführt in **Tom v1.2 Phase 14** (2026-04-10).

## Patches

### 1. `scripts/config.py` — Pfade auf `$TOM_VAULT/95_Gehirn/`

**Was:** `TOM_VAULT`-Env-Var eingeführt; alle Content-Pfade (`DAILY_DIR`, `KNOWLEDGE_DIR`, etc.) zeigen jetzt auf `$TOM_VAULT/95_Gehirn/` statt `ROOT_DIR/` (das Tool-Repo).

**Warum:** Separation of concerns. Das Tool-Repo enthält Code (git-tracked). Der Vault enthält Daten (iCloud, backup via Time Machine). Daten sollen **nicht** versehentlich ins Tool-Repo committed werden.

**Unveränderbar:**
- `SCRIPTS_DIR`, `TOOL_ROOT`, `HOOKS_DIR`, `AGENTS_FILE` — das sind Tool-Pfade
- `STATE_FILE` — bleibt im Tool-Repo damit `state.json` git-trackable ist

**Backwards-compat:** `ROOT_DIR` ist auf `VAULT_ROOT` aliased, falls ein Upstream-Script noch `ROOT_DIR / "daily"` o.ä. konstruiert.

**Zusätzlich:** `TIMEZONE = "Europe/Berlin"` statt `"America/Chicago"`.

### 2. `hooks/session-start.py` — Import Paths statt Hardcode

**Was:** `DAILY_DIR`, `KNOWLEDGE_DIR`, `INDEX_FILE` werden jetzt via `sys.path.insert` + `from config import ...` geladen.

**Warum:** Upstream hatte `ROOT = Path(__file__).parent.parent; DAILY_DIR = ROOT / "daily"` — das würde trotz `config.py`-Patch weiter auf das Tool-Repo zeigen.

### 3. `hooks/session-end.py` — Import Paths statt Hardcode

Gleiche Änderung wie 2, nur für `DAILY_DIR`. `SCRIPTS_DIR` und `STATE_DIR` bleiben lokal (Tool-Repo-Paths).

### 4. `scripts/flush.py` — Import Paths statt Hardcode

Gleiche Änderung wie 2, nur für `DAILY_DIR`. Der Rest (`STATE_FILE`, `LOG_FILE`) bleibt im Tool-Repo.

### 5. `tom_tools/wiki_query.py` — Neues Modul

**Was:** Eigenes Query-Modul das lokal via Ollama (`gemme`) statt Claude Agent SDK läuft. Nimmt `--brain` oder `--root` Parameter.

**Warum:**
- `scripts/query.py` ist an `KNOWLEDGE_DIR` gebunden (= `95_Gehirn/knowledge/`); für `tom-wiki` brauchen wir aber auch `90_Wiki/` als Quelle
- Lokale Ollama-Inferenz ist kostenlos und offline, Claude Agent SDK kostet Subscription-Quota

Aufruf via `uv run python -m tom_tools.wiki_query "Frage"`. Wird von `bin/tom-wiki` im Parent-Repo aufgerufen.

### 6. `pyproject.toml` — `ollama` Dependency

**Was:** `uv add ollama` → `ollama>=0.6.1` ergänzt.

**Warum:** Dependency für `tom_tools/wiki_query.py`.

## Upstream-Updates mergen

Wenn Cole Medin den Upstream updatet:

1. `cd claude-memory-compiler`
2. `git init && git remote add upstream https://github.com/coleam00/claude-memory-compiler && git fetch upstream`
3. Lokale Änderungen stashen (via `git stash` — die sind nicht in git weil dieses Clone kein `.git` hat; stattdessen manuell backuppen)
4. `git reset --hard upstream/main`
5. Patches oben 1–6 erneut anwenden
6. Smoke-Tests: `uv run scripts/lint.py --structural-only` und `tom-wiki "Test"`
7. `cd .. && git add claude-memory-compiler && git commit -m "chore: sync memory-compiler upstream"`

Alternativ, wenn Upstream sich stark ändert: frisch klonen und Patches neu applizieren — dauert <10 Minuten.

## Nicht gepatcht

Bewusst **nicht** geändert:

- `scripts/compile.py` — arbeitet korrekt via `config.py`-Import
- `scripts/lint.py` — gleich
- `scripts/query.py` — bleibt original (nutzt Claude Agent SDK, wird ggf. später für Brain-Queries genutzt)
- `hooks/pre-compact.py` — nutzt `ROOT` nur als `uv run --directory`, nicht für Daten-Writes
- `AGENTS.md`, `README.md` — Upstream-Doku, bleibt authentisch

## Siehe auch

- `/Users/maxim/Claude/CLAUDE.md` Sektion "Claude-Code Hooks (seit v1.2 Phase 16)"
- `$TOM_VAULT/95_Gehirn/CLAUDE.md` Privacy-Regeln
- `.planning/phases/14-tool-install/14-VERIFICATION.md`
- `.planning/phases/16-hook-integration/16-VERIFICATION.md`
- `.planning/phases/19-wrapper/19-VERIFICATION.md`
