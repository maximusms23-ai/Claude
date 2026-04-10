# Phase 15: Brain-Struktur - Context

**Gathered:** 2026-04-10
**Status:** Complete

<domain>
## Phase Boundary

Privates `95_Gehirn/` im iCloud-Vault ist angelegt, hat Privacy-Regeln, und ist explizit vom MkDocs-Publish-Scope ausgenommen. Vault-Files leben in iCloud (NICHT git-tracked) — Verification liegt im Planning-Repo.
</domain>

<decisions>
### Claude's Discretion
Pure Infrastructure-Phase, Struktur 1:1 aus User-Plan. Privacy-Regeln sind explizit dokumentiert und physisch durch `mkdocs.yml docs_dir: 90_Wiki` erzwungen.
</decisions>

<code_context>
### Integration Points
- `claude-memory-compiler/scripts/config.py` (Phase 14) zeigt schon auf genau diese Pfade
- `mkdocs.yml` beschränkt Publish-Scope auf `90_Wiki/` — alles andere inkl. `95_Gehirn/` bleibt privat
</code_context>
