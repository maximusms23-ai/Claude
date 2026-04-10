# Gemma Sub-Projekt — Instructions für Claude Code

Dieses Unterverzeichnis `/Users/maxim/Claude/Gemma/` ist das Tooling-Projekt rund um das lokale Gemme-Modell (Ollama + RAG + Training + Eval). Es lebt im Tom-Repo aber wird hier als **eigenständiges Projekt** mit eigener CLAUDE.md geführt, damit Claude Code in Sub-Sessions direkt die richtigen Regeln findet — und um die Multi-Projekt-`wiki_path`-Konvention (v1.2) zu demonstrieren.

## Scope

- **Hauptaufgaben**: Gemme-Modell trainieren/evaluieren, RAG-Pipeline pflegen, Self-Instruct-Datensammlung
- **Nicht hier**: Tom's Lebens-Vault, Maximus_OS-Integration, Wiki-Kuration — das ist alles im Parent-Repo `/Users/maxim/Claude/`

## Wissensquelle: Tom-Vault

Dieses Projekt teilt den Wissensstand mit Tom (`/Users/maxim/Claude`). Bei Wissensfragen die nicht rein Gemma/Training-spezifisch sind, nutze diese Tools:

**Primary (Index-first, lokal via gemme — kostenlos)**:
- `tom-wiki "Frage"` — liest `$TOM_VAULT/90_Wiki/` und synthetisiert über gemme
- `tom-wiki --brain "Frage"` — liest `$TOM_VAULT/95_Gehirn/` (privat, Konversations-Wissen)

**Fallback (Gemma RAG, ChromaDB)**:
- `tom-ask "Frage"` — Cosine-Similarity über drei Collections (`wiki`, `clippings`, `gehirn`)

**Pfade**:
- `$TOM_VAULT` = `/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw/`
- Tools liegen in `~/bin/` (Symlinks auf `/Users/maxim/Claude/bin/`)

## Wissens-Kaskade (identisch zum Parent-Repo)

1. **Projekt-Files direkt** (`Gemma/rag/config.py`, `README.md` etc.)
2. **`tom-wiki "Frage"`** für bekannte Themen aus dem öffentlichen Wiki (z.B. Ollama, Gemma 4, Quantisierung)
3. **`tom-wiki --brain "Frage"`** für Konversations-Wissen aus früheren Gemma-Sessions
4. **`tom-ask "Frage"`** als Fallback für fuzzy Queries

Siehe `/Users/maxim/Claude/CLAUDE.md` Sektion "Wissens-Kaskade" für volle Doku.

## Projekt-spezifische Commands

```bash
cd /Users/maxim/Claude/Gemma

# RAG indexieren (alle 3 Collections)
cd rag && python3 index.py

# Eval laufen
python3 eval/run_eval.py

# Training-Daten sammeln
python3 training/collector.py --limit 5

# Custom Model bauen
ollama create gemme -f modelfile/Modelfile
```

## Wichtige Dateien

- `rag/config.py` — Pfade + Modelle + Chunking + TOP_K
- `rag/index.py` — 3-Collection-Indexer (wiki, clippings, gehirn)
- `rag/query.py` — RAG-Query über alle 3 Collections
- `modelfile/Modelfile` — Ollama Custom Model definition
- `training/collector.py` — Self-Instruct Q&A generator
- `eval/run_eval.py` — Baseline-Eval-Framework
- `README.md` — volle Setup-Doku

## Multi-Projekt-Notiz

Dieses CLAUDE.md wurde in v1.2 Phase 20 angelegt, um die `wiki_path`-Konvention zu demonstrieren. Die Integration mit dem zentralen `$TOM_VAULT/95_Gehirn/` bedeutet: Alle Gemma-Sessions können in Tom's Brain landen (sofern die projekt-lokalen Hooks aktiviert sind — aktuell noch nicht, weil Gemma-Sessions via Parent-Repo laufen).
