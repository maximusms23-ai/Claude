# Phase 18: RAG-Erweiterung um gehirn-Collection - Context

**Status:** Complete

<domain>
Gemma-RAG-Pipeline indiziert additiv eine dritte ChromaDB-Collection `gehirn` aus `$TOM_VAULT/95_Gehirn/knowledge/` und durchsucht sie zusammen mit `wiki` und `clippings`.
</domain>

<decisions>
### Quelle beschränkt auf knowledge/
Nur kompilierte Artikel aus `95_Gehirn/knowledge/{concepts,connections,qa}/` werden indiziert. Rohe `daily/`-Logs bleiben außen vor — sie sind zu verrauscht für Cosine-Similarity.

### Additiver Patch
Drei minimal-invasive Änderungen in `config.py`, `index.py`, `query.py`. Keine Refactoring, Reuse von `index_directory()`.
</decisions>
