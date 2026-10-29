# Coding Conventions

**Analysis Date:** 2026-04-08

## Naming Patterns

**Files:**
- Lowercase with underscores: `config.py`, `index.py`, `query.py`
- Descriptive names reflecting module purpose

**Functions:**
- Lowercase with underscores: `parse_frontmatter()`, `chunk_text()`, `index_wiki()`, `query()`
- Verb-first for action functions: `parse_*`, `chunk_*`, `index_*`, `query()`
- Single responsibility per function

**Variables:**
- Lowercase with underscores: `wiki_path`, `chunk_size`, `total_chunks`, `context_parts`
- Loop variables use clear names: `filepath`, `chunk`, `meta`, `doc`
- Set/list names plural: `md_files`, `chunks`, `ids`, `documents`, `embeddings`
- Configuration constants UPPERCASE: `WIKI_PATH`, `CHUNK_SIZE`, `TOP_K`

**Types:**
- Type hints used throughout function signatures
- Return types explicitly annotated: `-> tuple[dict, str]`, `-> list[str]`, `-> str`
- Parameter types required: `text: str`, `size: int`, `question: str`

## Code Style

**Formatting:**
- No linting/formatting tool configured
- Observed standards: PEP 8 style (4-space indentation, line length ~80-100)
- Blank lines: Two between module-level definitions, one between functions
- String quotes: Double quotes for docstrings, single for regular strings

**Linting:**
- No `.pylintrc`, `.flake8`, or `setup.cfg` detected
- Conventions followed by observation only (not enforced)

## Import Organization

**Order:**
1. Standard library imports (sys, yaml, pathlib)
2. Third-party packages (chromadb, ollama)
3. Local imports (from config import ...)

**Path Aliases:**
- None detected — all imports use standard package paths
- Relative imports for local modules: `from config import WIKI_PATH, ...`

**Example from `index.py`:**
```python
import sys
import yaml
import chromadb
import ollama

from config import WIKI_PATH, CHROMA_PATH, EMBED_MODEL, CHUNK_SIZE, CHUNK_OVERLAP
```

## Error Handling

**Patterns:**
- Specific exception catching: `except yaml.YAMLError:` for known errors
- Generic exception suppression only when appropriate: `except Exception: pass` (line 53, `index.py`)
- Error messages printed to console, then `sys.exit(1)` for fatal errors
- Path existence checking before operations: `if not wiki_path.exists(): ... sys.exit(1)`

**Examples from codebase:**
```python
# Specific exception handling (index.py:16-19)
try:
    meta = yaml.safe_load(parts[1]) or {}
except yaml.YAMLError:
    meta = {}

# Fatal error with exit (index.py:38-40)
if not wiki_path.exists():
    print(f"Wiki-Pfad nicht gefunden: {wiki_path}")
    sys.exit(1)

# Generic suppression for cleanup (index.py:51-54)
try:
    client.delete_collection("wiki")
except Exception:
    pass
```

## Logging

**Framework:** `print()` statements only — no logging library

**Patterns:**
- Status messages: `print(f"Gefunden: {len(md_files)} Dateien")`
- Progress tracking: `print(f"  {rel_path}: {len(chunks)} Chunks")`
- Summary on completion: `print(f"\nIndexierung abgeschlossen: {len(md_files)} Dateien, {total_chunks} Chunks")`
- Error messages before exit: `print(f"Fehler: Kein Index gefunden. ...")`

All user-facing output is in German; code output includes counts and technical details.

## Comments

**When to Comment:**
- Minimal comments — code is generally self-documenting through naming
- Configuration files use inline comments: `# Pfade`, `# Modelle`, `# Chunking`
- No inline comments in main logic — function docstrings explain purpose

**Docstrings:**
- Module-level docstrings present: `"""Wiki-Dateien in ChromaDB indexieren."""`
- Function-level docstrings present: `"""YAML-Frontmatter parsen und vom Body trennen."""`
- Single-line docstring format (one-liner, no extended descriptions)
- Docstrings in German, describing what function does

**Example from `index.py`:**
```python
def parse_frontmatter(text: str) -> tuple[dict, str]:
    """YAML-Frontmatter parsen und vom Body trennen."""
```

## Function Design

**Size:** Functions are compact, typically 5-20 lines
- `parse_frontmatter()`: 11 lines
- `chunk_text()`: 8 lines (plus return)
- `index_wiki()`: 70 lines (largest, handles orchestration)

**Parameters:**
- Minimal parameters; uses imported constants for configuration
- Default values for optional params: `size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP`
- Tuple unpacking for multiple returns: `meta, body = parse_frontmatter(text)`

**Return Values:**
- Consistent return types (never mixed `None` and value)
- Tuple returns for related data: `tuple[dict, str]`
- List returns for collections: `list[str]`
- Single value returns: `str`

## Module Design

**Exports:**
- No `__all__` declarations detected
- Main modules export functions and use `if __name__ == "__main__":` entry point
- Configuration module (`config.py`) exports constants only

**Barrel Files:**
- None used — single-file modules for each concern

**Entry Points:**
- `index.py`: `if __name__ == "__main__": index_wiki()`
- `query.py`: `if __name__ == "__main__":` parses args and calls `query()`
- `config.py`: Configuration only, no main entry

## Language & Localization

**Convention:**
- Content (docstrings, comments, print messages): German
- Code identifiers (function names, variables, imports): English
- Technical terms: English (e.g., `chunk`, `embedding`, `metadata`)

**Example:**
```python
def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """Text in ueberlappende Chunks aufteilen."""  # German docstring
    chunks = []  # English identifier
```

---

*Convention analysis: 2026-04-08*
