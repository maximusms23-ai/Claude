# Milestones

## v1.0 — Tom Bootstrap (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Claude-Rolle zu "Tom" umstellen + Obsidian-Vault als Lebens-Zentrale strukturieren
**Phases:** 1–7
**Status:** ✓ Shipped (commit `525c073`)

## v1.1 — Maximus_OS Integration + Ollama Gemma Revival (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Vault-Single-Source (iCloud), Hybrid-Integration mit Maximus_OS/PaperclipAI, lokales Gemma-Model gegen neuen Vault mit RAG
**Phases:** 8–13 (6 Phasen, 35 Requirements)
**Status:** ✓ Shipped

**Commits:**
- Phase 8 — `43d1f7a` refactor(vault): iCloud als single source
- Phase 9 — `611f9c2` feat(tools): tom-issue wrapper + Maximus_OS Kommunikationsregeln
- Phase 10 — `05e4fee` feat(llm): ollama + gemma4:e4b
- Phase 11 — `46b752a` feat(gemma): custom model + RAG auf iCloud-Vault
- Phase 12 — `810b63b` feat(tools): tom-ask wrapper
- Phase 13 — `ec4a62a` docs: Tom v1.1 Abschluss-Doku

**Maximus_OS Audit-Trail:** FAM-106, FAM-107, FAM-108, FAM-109, FAM-110, FAM-112, FAM-113

## v1.2 — Karpathy Wiki + claude-memory-compiler (Complete)

**Started:** 2026-04-10
**Completed:** 2026-04-10
**Goal:** Hybrid Wissens-System mit Karpathy Index-first Retrieval für `90_Wiki/` (external), privatem `95_Gehirn/` (internal) mit Auto-Capture aus Claude-Code-Konversationen, RAG als Fallback mit dritter `gehirn`-Collection, Multi-Projekt-Nutzung via `wiki_path`-Konvention.
**Phases:** 14–21 (8 Phasen, 43 Requirements)
**Status:** ✓ Shipped

**Commits:**
- Phase 14 — `f27402d` feat(tools): clone + patch claude-memory-compiler
- Phase 15 — `60bb16a` feat(vault): 95_Gehirn Brain-Struktur + Privacy-Regeln
- Phase 16 — `1da397f` feat(hooks): project-level SessionEnd/PreCompact/SessionStart
- Phase 17 — `a76af5e` docs(wiki): rewrite 90_Wiki/index.md als Karpathy-Retrieval-Index
- Phase 18 — `92ccf35` feat(rag): add 95_Gehirn/knowledge als dritte RAG-Collection
- Phase 19 — `d1a1e9e` feat(tools): tom-wiki / tom-compile / tom-lint Wrapper
- Phase 20 — `12dbfda` docs: multi-project wiki_path convention
- Phase 21 — (diesem folgend) docs: Tom v1.2 Abschluss-Doku

**Maximus_OS Audit-Trail:** FAM-119, FAM-120, FAM-121, FAM-122, FAM-123, FAM-124, FAM-125

**Neue Tools:** `tom-wiki`, `tom-compile`, `tom-lint` (zusätzlich zu v1.1 `tom-issue`, `tom-ask`)

Siehe `.planning/ROADMAP.md` für Phasen-Details.
