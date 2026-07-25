# Phase 14: Tool-Install - Context

**Gathered:** 2026-04-10
**Status:** Ready for planning

<domain>
## Phase Boundary

`claude-memory-compiler` ist lokal installiert, gegen `$TOM_VAULT/95_Gehirn/` konfiguriert, und ein Struktur-Lint läuft grün.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
Pure Infrastructure-Phase — alle Implementation-Choices sind im Ermessen von Claude, solange sie dem User-Plan folgen.

- Clone-Location: `/Users/maxim/Claude/claude-memory-compiler/` (git-tracked)
- Config-Patch bewahrt Upstream-Struktur, fügt `TOM_VAULT`-Env-Var nur an Pfadvariablen
- `state.json` bleibt im Tool-Repo (git-trackable)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/tom-issue` als Template für CTO-Issue
- `uv` ist systemweit installiert (`/opt/homebrew/bin/uv`)
- Python 3.13 erfüllt Memory-Compiler-Anforderung (3.12+)

### Integration Points
- `$TOM_VAULT` Env-Var muss gesetzt sein
- Tool schreibt später in `$TOM_VAULT/95_Gehirn/` — das Verzeichnis wird in Phase 15 angelegt, daher Smoke-Test mit `--structural-only`

</code_context>

<specifics>
## Specific Ideas

Upstream-Repo: https://github.com/coleam00/claude-memory-compiler

Config-Patch exakt wie im User-Plan:
```python
VAULT_ROOT = Path(os.environ.get("TOM_VAULT", "...")) / "95_Gehirn"
DAILY_DIR = VAULT_ROOT / "daily"
KNOWLEDGE_DIR = VAULT_ROOT / "knowledge"
INDEX_FILE = VAULT_ROOT / "index.md"
LOG_FILE = VAULT_ROOT / "log.md"
STATE_FILE = Path(__file__).parent / "state.json"
```

</specifics>

<deferred>
## Deferred Ideas

- Actual Compile-Test: kommt in Phase 16 (erst wenn Hooks daily-logs schreiben) oder später manuell
- `TOM-PATCHES.md` Doku kommt in Phase 21 (Abschluss-Doku)

</deferred>
