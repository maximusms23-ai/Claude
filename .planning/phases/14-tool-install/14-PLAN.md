# Phase 14: Tool-Install — Plan

**Status:** Ready for execution

## Goal

`claude-memory-compiler` ist lokal installiert, gegen `$TOM_VAULT/95_Gehirn/` konfiguriert, und ein Struktur-Lint läuft grün.

## Requirements Covered

- TOOL-01: Clone nach `/Users/maxim/Claude/claude-memory-compiler/`
- TOOL-02: `uv sync` erfolgreich
- TOOL-03: `scripts/config.py` gepatcht auf `$TOM_VAULT/95_Gehirn/`
- TOOL-04: Smoke-Test `uv run scripts/lint.py --structural-only` fehlerfrei
- TOOL-05: Maximus_OS-Issue an CTO mit Commit-Hash

## Tasks

### T1. Clone Upstream Repo
```bash
cd /Users/maxim/Claude
git clone https://github.com/coleam00/claude-memory-compiler
```
→ TOOL-01

### T2. uv sync
```bash
cd claude-memory-compiler && uv sync
```
→ TOOL-02

### T3. Config patchen
- `scripts/config.py` editieren: `TOM_VAULT`-Env-Var, Pfade auf `$TOM_VAULT/95_Gehirn/`
- Backup mit Git (diff wird sichtbar)
→ TOOL-03

### T4. Smoke-Test
```bash
cd claude-memory-compiler && uv run scripts/lint.py --structural-only
```
Erwartet: läuft ohne Fehler (leere Struktur → strukturell OK)
→ TOOL-04

### T5. CTO-Issue
```bash
bin/tom-issue --title "Phase 14: claude-memory-compiler installed + patched" \
  --description "Tool cloned, uv sync done, config.py patched to $TOM_VAULT/95_Gehirn/" \
  --agent cto --priority medium
```
→ TOOL-05

### T6. Commit
```
feat(tools): clone + patch claude-memory-compiler
```

## Success Criteria

1. `/Users/maxim/Claude/claude-memory-compiler/` existiert als Git-Repo
2. `uv sync` exit 0
3. `scripts/config.py` zeigt auf `$TOM_VAULT/95_Gehirn/`
4. `uv run scripts/lint.py --structural-only` exit 0
5. CTO-Issue im Maximus_OS-Dashboard sichtbar
