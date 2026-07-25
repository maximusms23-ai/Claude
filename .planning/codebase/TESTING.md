# Testing Patterns

**Analysis Date:** 2026-04-08

## Test Framework

**Runner:**
- Not configured — no test framework detected

**Assertion Library:**
- Not used — no test framework

**Run Commands:**
- No test commands defined
- Manual testing via command-line invocation:
  ```bash
  cd Gemma/rag
  python3 index.py          # Index wiki into ChromaDB
  python3 query.py "Frage"  # Query the index
  ```

## Test File Organization

**Location:**
- No test files present in codebase
- No separate `tests/` directory

**Naming:**
- Not applicable — no tests

**Structure:**
- Not applicable — no tests

## Test Structure

**Manual Testing Approach:**
The codebase relies on manual testing via command-line invocation. Key testable operations:

**1. Indexing (`index.py`):**
- Invoked as: `python3 index.py`
- Verifiable outputs:
  - File count: `Gefunden: {N} Dateien`
  - Per-file chunk count: `{rel_path}: {N} Chunks`
  - Total summary: `Indexierung abgeschlossen: {N} Dateien, {N} Chunks`
  - Side effect: Creates/updates ChromaDB at `chroma_db/`

**2. Querying (`query.py`):**
- Invoked as: `python3 query.py "Frage"`
- Verifiable outputs:
  - Answer text from Gemme model
  - Sources list with titles and file paths
  - Return value: `str` containing answer + sources

**3. Configuration (`config.py`):**
- Not directly tested — used as import
- Verification: Check that constants are readable (`WIKI_PATH`, `CHROMA_PATH`, etc.)

## Mocking

**Framework:**
- Not configured

**Patterns:**
- No mocks currently in place
- External dependencies (chromadb, ollama) are called directly

**What to Mock (if tests were added):**
- `ollama.embed()` — expensive external call, varies by input
- `ollama.chat()` — external model inference, non-deterministic
- `chromadb.PersistentClient()` — could use in-memory for testing
- File I/O — use temporary directories or fixtures

**What NOT to Mock:**
- YAML parsing — test real YAML handling
- Text chunking logic — deterministic, should run as-is
- Frontmatter extraction — verify real behavior

## Fixtures and Factories

**Test Data:**
- No fixtures defined
- Configuration uses real paths from environment

**If Testing Were Implemented:**
Consider creating fixtures in `Gemma/rag/fixtures/` or `Gemma/rag/test_data/`:

```python
# Example fixture for markdown with frontmatter
SAMPLE_MARKDOWN_WITH_FRONTMATTER = """---
title: Test Article
created: 2026-04-08
type: concept
tags: [test, example]
---
This is test content for chunking."""

# Example fixture for embedded chunk
SAMPLE_CHUNK = "This is a text chunk for embedding."

# Example fixture for query results structure
SAMPLE_QUERY_RESULTS = {
    "documents": [["chunk1", "chunk2", "chunk3", "chunk4", "chunk5"]],
    "metadatas": [
        [
            {"source": "test/file.md", "title": "Test", "tags": "test"},
            # ... more metadata
        ]
    ]
}
```

## Coverage

**Requirements:**
- No coverage target defined
- No `.coveragerc` file
- No automated coverage tracking

**View Coverage (if implemented):**
```bash
pip install coverage pytest pytest-cov
pytest --cov=Gemma/rag --cov-report=html
```

## Test Types

**Unit Tests (if implemented):**
- Scope: Individual functions in isolation
- Examples to test:
  - `parse_frontmatter()`: Various YAML formats, missing frontmatter, malformed YAML
  - `chunk_text()`: Text shorter than chunk size, exact boundaries, overlaps
  - Configuration loading: Path resolution, constant availability

**Integration Tests (if implemented):**
- Scope: Functions working with real dependencies
- Examples:
  - Full indexing pipeline: Read → Parse → Chunk → Embed → Store
  - Query pipeline: Embed → Search → Retrieve → Answer
  - Round-trip: Index a test wiki, query it, verify results

**E2E Tests:**
- Not currently used
- Would be challenging without external services (Ollama, ChromaDB)

## Common Patterns

**Async Testing:**
- Not applicable — no async code in codebase

**Error Testing:**
- Would need to test exit behavior for missing paths/files

**Example (if implemented):**
```python
def test_index_wiki_missing_path(tmp_path, monkeypatch):
    """Should exit with code 1 if wiki path doesn't exist."""
    monkeypatch.setattr("config.WIKI_PATH", tmp_path / "nonexistent")
    with pytest.raises(SystemExit) as exc_info:
        index_wiki()
    assert exc_info.value.code == 1
```

## Recommendations for Adding Tests

**Phase 1 (Essential):**
1. Install pytest: `pip install pytest` to `requirements-dev.txt`
2. Create `Gemma/rag/test_config.py` — verify configuration loading
3. Create `Gemma/rag/test_index.py`:
   - Test `parse_frontmatter()` with valid/invalid YAML
   - Test `chunk_text()` with various sizes/overlaps
4. Create integration test: Index small test wiki, verify output

**Phase 2 (Mocking):**
1. Install `pytest-mock`: `pip install pytest-mock`
2. Mock Ollama calls in integration tests
3. Use in-memory ChromaDB for faster tests

**Phase 3 (Coverage):**
1. Install `pytest-cov`
2. Target: 80%+ coverage of `index.py` and `query.py`
3. Run: `pytest --cov=Gemma/rag Gemma/rag/`

---

*Testing analysis: 2026-04-08*
