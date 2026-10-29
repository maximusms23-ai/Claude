# Phase 16: Hook-Integration - Context

**Gathered:** 2026-04-10
**Status:** Complete

<domain>
Projekt-lokale Claude-Code-Hooks zeigen auf claude-memory-compiler-Hooks und schreiben automatisch daily-Entries nach `95_Gehirn/daily/`, ohne globale GSD+RTK-Hooks zu brechen.
</domain>

<decisions>
### Claude's Discretion
Upstream-Hook-Files mussten zusätzlich gepatcht werden, weil sie lokal ROOT/DAILY_DIR definieren statt aus `config.py` zu importieren — sonst würden sie trotz `config.py`-Patch weiter ins Tool-Repo schreiben. Fix: `sys.path.insert` + `from config import DAILY_DIR/INDEX_FILE/...`.

Absolute Pfade in `settings.json` mit `uv run --directory` damit der Hook aus beliebigem cwd läuft.
</decisions>

<code_context>
### Integration Points
- Globale `~/.claude/settings.json` hat `SessionStart → gsd-check-update.js` und `PreToolUse → rtk-rewrite.sh`
- Projekt-lokale Hooks mergen — beide bleiben aktiv
</code_context>
