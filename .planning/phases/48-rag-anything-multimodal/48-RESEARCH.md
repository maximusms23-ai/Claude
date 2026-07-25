# Phase 48: RAG-Anything — Multimodaler Dokumenten-RAG — Research

**Researched:** 2026-04-14
**Domain:** Multimodal RAG (HKUDS/RAG-Anything, MinerU, LightRAG, Ollama, FastMCP)
**Confidence:** MEDIUM (Python version constraint well-verified; RAG-Anything Ollama integration partially documented with known dependency friction)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RAG16-01 | RAG-Anything (HKUDS/RAG-Anything) geklont + lokal installiert (Dependencies: MinerU, LightRAG, Python 3.10+) | Python 3.13 available at /opt/homebrew/bin/python3.13; venv with python3.13 required; uv recommended installer |
| RAG16-02 | Evaluation mit 10 repräsentativen Dokumenten aus ~/Downloads/Archiv/ (PDFs mit Tabellen, Bildern, Formeln) | Archiv/06 Arzt/ has Kardiologie/Orthopaedie/Krankenhaus subdirs; 07 Verträge, 09 Rente_Steuer, 11 Finanzen are strong candidates |
| RAG16-03 | Neuer Subcommand `tom-doc multi-search` integriert (parallel zu FTS5, non-destructive) | bin/tom-doc delegates to archivum/ocr_pipeline.py via exec; new case block + Python wrapper pattern established |
| RAG16-04 | MCP-Erweiterung `tom_doc_multi_search` in mcp-server/tom_mcp.py | @mcp.tool decorator pattern is trivial to extend; existing _run_tool async helper reusable |
| RAG16-05 | Query gegen PDF mit Tabelle liefert korrekte Zahlen; `tom-doc search` weiterhin funktional | Non-destructive: RAG-Anything uses its own working dir; FTS5 SQLite untouched |
| RAG16-06 | Privacy: komplett lokal, kein Cloud-Abfluss verifiziert | RAG-Anything + Ollama = fully local; MinerU models download once then run offline |
</phase_requirements>

---

## Summary

Phase 48 erweitert `tom-doc` um multimodale RAG-Fähigkeiten für PDFs mit Tabellen, Bildern und Formeln. Das Haupt-Framework ist HKUDS/RAG-Anything (15.7k Sterne), das auf LightRAG aufbaut und MinerU für Dokumenten-Parsing verwendet.

Die kritische technische Hürde: **Das System-Python ist 3.14, MinerU unterstützt nur Python 3.10–3.13.** Python 3.13 ist aber bereits unter `/opt/homebrew/bin/python3.13` installiert. Die Lösung ist ein dediziertes venv mit `python3.13 -m venv`. RAG-Anything selbst erfordert laut PyPI Python >=3.9, sodass 3.13 vollständig kompatibel ist.

Die Ollama-Integration ist offiziell unterstützt (dediziertes `ollama_integration_example.py` im Repo), verlangt aber spezifische Konfiguration: LLM-Calls laufen über den OpenAI-kompatiblen Ollama-Endpoint (`/v1`), Embeddings über den nativen `/api/embed`-Endpoint. Das bestehende `nomic-embed-text` Modell ist bereits in Ollama installiert (274MB) und kann direkt verwendet werden. Für multimodale Bildverarbeitung wird ein Vision-Modell benötigt — `qwen2.5vl:7b` (~6GB) wäre der natürliche Kandidat, aber 16GB RAM auf dem M4 Mac mini ist eng für parallelen Betrieb.

**Primary recommendation:** RAG-Anything in Python 3.13 venv installieren (via `python3.13 -m venv`), `nomic-embed-text` + `qwen2.5:3b` für Text-RAG verwenden, `qwen2.5vl:7b` optional für Bildverarbeitung (Swap-Risiko beachten). Docling als MinerU-Alternative evaluieren — einfachere Installation, keine `ray`-Dependency.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| raganything | >=0.1.0 (PyPI aktuell) | All-in-One multimodaler RAG | Baut auf LightRAG auf, unterstützt Ollama nativ |
| lightrag-hku | >=1.0 (PyPI aktuell) | RAG-Kern mit Knowledge-Graph | Basis von RAG-Anything, Ollama-kompatibel |
| mineru[all] | 2.x (Python 3.10–3.13) | PDF→Markdown mit Tabellen/Formeln/Bildern | Beste Tabellen-Extraktion, Apple Silicon unterstützt |
| nomic-embed-text | latest (Ollama) | 768-dim Embeddings | Bereits installiert, passt zu RAG-Anything Ollama-Beispiel |
| qwen2.5:3b | already installed | LLM für RAG-Synthese | Bereits im Einsatz, kein Download nötig |
| fastmcp | 3.x (existing) | MCP-Server-Framework | Bereits im Einsatz; @mcp.tool trivial erweiterbar |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| qwen2.5vl:7b | Ollama (~6GB) | Vision-LLM für Bildseiten/Formeln | Nur wenn Bilder/Formeln in PDFs abgefragt werden; 16GB RAM = Swap-Risiko |
| docling[all] | latest | Alternative zu MinerU für Office-Docs | Wenn MinerU-Install scheitert; schneller (8s vs 14s) aber schwächere Tabellen |
| uv | latest | Fast Python-Package-Manager | Empfohlen für RAG-Anything Installation (UV_HTTP_TIMEOUT=120) |
| LibreOffice | latest (brew cask) | Office-Dokument-Processing | Nur wenn .docx/.xlsx/.pptx aus Archiv verarbeitet werden sollen |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| MinerU | Docling | Docling ist schneller und einfacher zu installieren; MinerU ist präziser bei Tabellen und Formeln (LaTeX-Output) |
| MinerU | PyMuPDF4LLM | Kein OCR, kein Advanced-Layout; nur für einfache Text-PDFs |
| nomic-embed-text (768d) | BAAI/bge-small-en-v1.5 (existing) | bge-small nutzt HuggingFace direkt (kein Ollama-Embed-Endpoint) — Dimension-Mismatch mit RAG-Anything wenn es 768d erwartet |
| qwen2.5vl:7b | llama3.2-vision | llama3.2-vision ist kleiner; qwen2.5vl:7b ist stärker bei deutschen Dokumenten |
| RAG-Anything | LightRAG standalone | LightRAG allein hat kein multimodales Parsing; RAG-Anything = LightRAG + MinerU |

**Installation (in Python 3.13 venv):**
```bash
# venv mit Python 3.13 anlegen
/opt/homebrew/bin/python3.13 -m venv /Users/maxim/Claude/rag-anything-env

# aktivieren
source /Users/maxim/Claude/rag-anything-env/bin/activate

# pip updaten + uv installieren
pip install --upgrade pip uv

# RAG-Anything und MinerU installieren
uv pip install 'raganything[all]'
uv pip install -U 'mineru[all]'

# Ollama Embedding-Modell (bereits installiert)
ollama pull nomic-embed-text   # bereits vorhanden

# LibreOffice für Office-Dokumente (optional)
brew install --cask libreoffice

# Verify
mineru --version
python -c "from raganything import RAGAnything; print('OK')"
```

**Version verification:**
```bash
# Aktuelle Versionen prüfen (Training-Daten können veraltet sein)
pip index versions raganything 2>/dev/null | head -3
pip index versions lightrag-hku 2>/dev/null | head -3
pip index versions mineru 2>/dev/null | head -3
```

---

## Architecture Patterns

### Recommended Project Structure

```
/Users/maxim/Claude/
├── rag-anything-env/        # Python 3.13 venv (gitignored)
├── archivum/                # Bestehend: FTS5 OCR-Pipeline
│   ├── ocr_pipeline.py      # Bestehend: FTS5 index + search
│   ├── db/archivum.db       # Bestehend: SQLite FTS5
│   └── rag-anything/        # NEU: RAG-Anything Working-Dir
│       ├── index/           # LightRAG Knowledge-Graph + Vektoren
│       ├── cache/           # MinerU parsed output cache
│       └── multi_search.py  # NEU: Python-Wrapper für multi-search
├── bin/
│   └── tom-doc              # Bestehend: shell wrapper (neue Case hinzufügen)
└── mcp-server/
    └── tom_mcp.py           # Bestehend: +1 @mcp.tool Funktion
```

### Pattern 1: Python 3.13 venv Isolation

**What:** RAG-Anything und MinerU laufen in einem dedizierten venv mit Python 3.13, vollständig isoliert vom System-Python 3.14 und den bestehenden LangChain/ChromaDB-Packages.
**When to use:** Immer — MinerU setzt Python <3.14 voraus, System hat 3.14. Isolation verhindert Konflikte mit bestehendem Stack.
**Example:**
```bash
# venv erstellen (einmalig)
/opt/homebrew/bin/python3.13 -m venv /Users/maxim/Claude/rag-anything-env

# tom-doc multi-search ruft den venv-Python direkt auf
/Users/maxim/Claude/rag-anything-env/bin/python \
  /Users/maxim/Claude/archivum/rag-anything/multi_search.py "$QUERY"
```

### Pattern 2: RAG-Anything mit Ollama (OpenAI-kompatibler Endpoint)

**What:** RAG-Anything nutzt Ollamas OpenAI-kompatible API für LLM-Calls und den nativen Embed-Endpoint für Embeddings.
**When to use:** Standard-Konfiguration für diesen Stack.
**Example:**
```python
# Source: github.com/HKUDS/RAG-Anything/examples/ollama_integration_example.py
import os
from functools import partial
from lightrag.llm.ollama import ollama_complete_if_cache, ollama_embed
from raganything import RAGAnything

OLLAMA_HOST = "http://localhost:11434"
LLM_MODEL = "qwen2.5:3b"        # bereits installiert
EMBED_MODEL = "nomic-embed-text" # bereits installiert, 768-dim
EMBED_DIM = 768

rag = RAGAnything(
    working_dir="./rag-anything/index",
    llm_model_func=partial(
        ollama_complete_if_cache,
        model=LLM_MODEL,
        host=OLLAMA_HOST,
    ),
    embedding_func=partial(
        ollama_embed,
        embed_model=EMBED_MODEL,
        host=OLLAMA_HOST,
    ),
    embedding_dim=EMBED_DIM,
    parse_method="auto",  # MinerU auto-detection
)
```

### Pattern 3: tom-doc multi-search als Shell-Subcommand

**What:** Neuer `case` Block in `bin/tom-doc` ruft via `exec` den venv-Python mit dem multi_search.py-Wrapper auf.
**When to use:** Non-destructive — FTS5 `search` bleibt unverändert, `multi-search` ist neuer Code-Pfad.
**Example:**
```bash
# In bin/tom-doc (nach bestehendem 'show' case):
  multi-search)
    [[ $# -ge 1 ]] || { echo "error: 'multi-search' braucht eine Query" >&2; exit 1; }
    query="$1"
    shift
    VENV_PYTHON="/Users/maxim/Claude/rag-anything-env/bin/python"
    MULTI_SEARCH="/Users/maxim/Claude/archivum/rag-anything/multi_search.py"
    exec "$VENV_PYTHON" "$MULTI_SEARCH" --query "$query" "$@"
    ;;
```

### Pattern 4: FastMCP Tool hinzufügen

**What:** `@mcp.tool` Decorator auf async Funktion — FastMCP generiert automatisch Name, Schema und Docstring.
**When to use:** Standard-Pattern für jeden neuen MCP-Tool im bestehenden Server.
**Example:**
```python
# In mcp-server/tom_mcp.py — nach tom_doc_show Funktion einfügen:
@mcp.tool
async def tom_doc_multi_search(query: str, limit: int = 5) -> str:
    """Multimodaler RAG-Suche ueber persoenliche Dokumente (Tabellen, Bilder, Formeln).

    Nutzt RAG-Anything (LightRAG + MinerU) fuer semantische Suche ueber PDFs
    mit komplexen Layouts. Parallel zu FTS5-Suche, non-destructive.
    Braucht laufendes Ollama + initialisierte RAG-Anything-Index.

    Args:
        query: Suchfrage (natuerlichsprachlich, Deutsch oder Englisch).
        limit: Maximale Anzahl Treffer (default 5).
    """
    tool = _resolve_tool("tom-doc")
    return await _run_tool(
        [tool, "multi-search", query, "--limit", str(limit)],
        timeout=180,  # MinerU-Processing braucht Zeit
    )
```

### Anti-Patterns to Avoid

- **System-Python direkt nutzen:** `python3 archivum/rag-anything/multi_search.py` schlägt fehl, weil System-Python 3.14 MinerU nicht unterstützt. Immer venv-Python explizit angeben.
- **BAAI/bge-small-en-v1.5 als Embedding-Modell in RAG-Anything:** Das bestehende RAG-Setup (ChromaDB) nutzt bge-small via HuggingFace direkt. RAG-Anything erwartet ein via Ollama-Embed-Endpoint erreichbares Modell. `nomic-embed-text` (bereits in Ollama) verwenden, nicht bge-small.
- **RAG-Anything-Index über ~/Downloads/Archiv/ gesamthaft anlegen:** Der erste Index-Build ist langsam (MinerU verarbeitet jede PDF). Schrittweise mit 10 Evaluations-Dokumenten starten, nicht `--all`.
- **LightRAG 32k context requirement mit qwen2.5:3b ignorieren:** LightRAG braucht mind. 32k Kontext. `OLLAMA_NUM_CTX=32768` via Modelfile oder env setzen — Standardwert von Ollama (8k) reicht nicht.
- **Vorhandene FTS5-Suche ersetzen:** RAG-Anything ist additiv — `tom-doc search` (FTS5) bleibt Primary für Keyword-Suche, `tom-doc multi-search` ergänzt für semantische Fragen.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF→Markdown mit Tabellen | Eigener pdftotext+Regex Parser | MinerU | Tabellen-Reconstruction, LaTeX-Formel-Extraktion, merged cells — unmöglich mit simplem Text-Extrakt |
| Multimodaler Knowledge-Graph | Eigene Vector-DB-Logik | LightRAG (via RAG-Anything) | Graph-based retrieval für komplex vernetzte Dokumente; Entity-Relation-Linking out of the box |
| Vision-LLM Bild-Parsing | Eigener PIL+Prompt Loop | RAG-Anything modalprocessors | Modalprocessors handhaben Images, Tables, Equations automatisch mit konfigurierbaren Vision-Models |
| MCP-Tool-Schema | Manuelle JSON-Schema-Definitionen | @mcp.tool Decorator + Type Hints | FastMCP generiert Schema aus Python-Signature — null Boilerplate |

**Key insight:** RAG-Anything ist genau die Abstraktionsschicht, die verhindert, dass multimodales Parsing selbst implementiert werden muss. MinerU allein liefert strukturierten Output; LightRAG macht daraus einen queryable Knowledge-Graph.

---

## Common Pitfalls

### Pitfall 1: Python-Version-Konflikt (MinerU vs. System-Python)

**What goes wrong:** `pip install mineru` im System-Python (3.14) schlägt fehl oder installiert, aber MinerU inkompatibel mit Python 3.14.
**Why it happens:** MinerU setzt explizit `python_requires=">=3.10,<3.14"` — Python 3.14 ist ausgeschlossen.
**How to avoid:** Immer `/opt/homebrew/bin/python3.13 -m venv rag-anything-env` für die Installation verwenden. Venv-Python-Path explizit in tom-doc und MCP-Server referenzieren.
**Warning signs:** `ImportError` oder `AttributeError` beim `import mineru` unter Python 3.14.

### Pitfall 2: Ollama num_ctx zu klein für LightRAG

**What goes wrong:** LightRAG-Queries produzieren abgeschnittene Ergebnisse oder Fehler.
**Why it happens:** LightRAG benötigt mind. 32k Token Kontext-Fenster. Ollama-Default für qwen2.5:3b ist 8k.
**How to avoid:** `num_ctx=32768` in Ollama-Konfiguration setzen. Option A: Modelfile anpassen. Option B: LLM-Funktion in RAG-Anything mit `options={"num_ctx": 32768}` konfigurieren.
**Warning signs:** Queries geben `None` zurück oder Antworten enden abrupt.

### Pitfall 3: Embedding-Dimension-Mismatch

**What goes wrong:** RAG-Anything kann nicht querien, weil Index-Dimension (768, nomic-embed-text) nicht mit Konfiguration übereinstimmt.
**Why it happens:** Wenn `embedding_dim` in RAGAnything-Konstruktor falsch gesetzt; oder wenn zwischen Indexierung und Query unterschiedliche Modelle verwendet werden.
**How to avoid:** `EMBED_DIM = 768` fest kodieren (nomic-embed-text). Nach Embedding-Modell-Wechsel: Index-Verzeichnis löschen und neu aufbauen.
**Warning signs:** `VectorDimensionMismatch` oder leere Query-Ergebnisse.

### Pitfall 4: MinerU Download beim ersten Lauf (kein offlines Setup)

**What goes wrong:** Erster `mineru`-Aufruf lädt ML-Modelle herunter (~mehrere GB) — dauert lange, scheitert ohne Internetverbindung.
**Why it happens:** MinerU nutzt PDF-Erkennung-Modelle (Layout, OCR) die beim ersten Lauf auto-downloaded werden.
**How to avoid:** Ersten MinerU-Run mit einem einfachen Test-PDF ausführen und Modelle im Voraus cachen. Danach komplett offline. Cache-Verzeichnis dokumentieren.
**Warning signs:** Hängt bei erstem `process_document_complete()` Call ohne Output.

### Pitfall 5: 16GB RAM Grenze bei Vision-Modell

**What goes wrong:** Paralleler Betrieb von qwen2.5:3b (LLM), nomic-embed-text (Embeddings) und qwen2.5vl:7b (Vision) führt zu Swap und starker Verlangsamung.
**Why it happens:** M4 Mac mini hat 16GB RAM — qwen2.5vl:7b braucht ~8GB, qwen2.5:3b ~2GB, System ~4GB.
**How to avoid:** Für Phase 48 Evaluation: Text-only RAG (qwen2.5:3b + nomic-embed-text) testen zuerst. Vision-Modell nur bei Bedarf laden (`ollama run qwen2.5vl:7b` explizit, danach stoppen). Alternativ: multimodales Parsing über MinerU (text+table extraction) ohne Vision-LLM.
**Warning signs:** `ollama ps` zeigt mehrere große Modelle resident; System-Lüfter springt an.

### Pitfall 6: RAG-Anything working_dir vs. bestehende Archivum-Struktur

**What goes wrong:** RAG-Anything schreibt LightRAG-Graph-Daten in ein confuses Verzeichnis oder überschreibt bestehende Caches.
**Why it happens:** RAG-Anything erwartet einen dedizierten `working_dir` für Knowledge-Graph und Vektoren.
**How to avoid:** Dedizierten Working-Dir `archivum/rag-anything/index/` verwenden — getrennt von `archivum/ocr-cache/` und `archivum/db/`. `.gitignore` um `archivum/rag-anything/` ergänzen (enthält große Index-Dateien).

---

## Code Examples

Verified patterns from official sources:

### RAGAnything Initialization mit Ollama

```python
# Source: github.com/HKUDS/RAG-Anything examples/ollama_integration_example.py
from functools import partial
from lightrag.llm.ollama import ollama_complete_if_cache, ollama_embed
from raganything import RAGAnything

WORKING_DIR = "/Users/maxim/Claude/archivum/rag-anything/index"
OLLAMA_HOST = "http://localhost:11434"

async def init_rag():
    rag = RAGAnything(
        working_dir=WORKING_DIR,
        llm_model_func=partial(
            ollama_complete_if_cache,
            model="qwen2.5:3b",
            host=OLLAMA_HOST,
            options={"num_ctx": 32768},  # LightRAG braucht >= 32k!
        ),
        embedding_func=partial(
            ollama_embed,
            embed_model="nomic-embed-text",
            host=OLLAMA_HOST,
        ),
        embedding_dim=768,  # nomic-embed-text = 768-dim
    )
    return rag
```

### Dokument Indexieren + Querien

```python
# Source: github.com/HKUDS/RAG-Anything README
import asyncio

async def index_and_query(pdf_path: str, query: str):
    rag = await init_rag()

    # Dokument indexieren (MinerU parsed, LightRAG indexiert)
    await rag.process_document_complete(
        file_path=pdf_path,
        output_dir="/Users/maxim/Claude/archivum/rag-anything/cache",
        parse_method="auto",  # MinerU auto-detection
    )

    # Querien
    result = await rag.aquery(query, mode="hybrid")
    return result

asyncio.run(index_and_query(
    "/Users/maxim/Downloads/Archiv/06 Arzt/Kardiologie/befund.pdf",
    "Welche Blutwerte sind auffällig?"
))
```

### FastMCP Tool ergänzen (Pattern ohne Server-Neuschreiben)

```python
# Source: gofastmcp.com — @mcp.tool decorator pattern
# In mcp-server/tom_mcp.py nach bestehenden Tools einfach anfügen:

@mcp.tool
async def tom_doc_multi_search(query: str, limit: int = 5) -> str:
    """[docstring — wie oben im Architecture-Pattern]"""
    tool = _resolve_tool("tom-doc")
    return await _run_tool(
        [tool, "multi-search", query, "--limit", str(limit)],
        timeout=180,
    )
```

### MinerU CLI Verifikation

```bash
# Source: opendatalab.github.io/MinerU/quick_start/
# Nach Installation im venv:
source /Users/maxim/Claude/rag-anything-env/bin/activate
mineru --version

# Test-Lauf (erstes Mal: lädt Models herunter)
mineru -p /tmp/test.pdf -o /tmp/mineru-out -b pipeline
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| pdftotext + SQLite FTS5 (Keyword-Search) | MinerU + LightRAG Knowledge-Graph (Semantic-Search) | 2024–2025 | Tabellen, Bilder, Formeln werden strukturiert extrahiert statt als Roh-Text |
| Cloud Vision APIs für Bild-PDFs | Lokale VLMs (qwen2.5vl, llama3.2-vision) via Ollama | 2025 | Privacy-konformes multimodales Parsing ohne Cloud-Abfluss |
| Separate Embedding-Services | Ollama unified Endpoint (`/api/embed`) | 2024 | Ein Daemon für LLM + Embeddings |
| OpenAI-only RAG Frameworks | OpenAI-kompatible Local Endpoints | 2024–2025 | LightRAG/RAG-Anything transparent auf Ollama umschaltbar |
| MinerU 1.x (Config-File-basiert) | MinerU 2.x (CLI-Parameter, vereinfacht) | 2025 | `mineru -p ... -o ... -b pipeline` statt komplexes JSON-Config |

**Deprecated/outdated:**
- **MinerU 1.x Config-Dateien**: 2.x nutzt reine CLI-Parameter, altes `magic-pdf.json` ist obsolet.
- **`magic-pdf` Binary**: Frühere MinerU-Versionen nutzten `magic-pdf` statt `mineru` als CLI-Entrypoint. Aktuelle Doku zeigt `mineru`.

---

## Open Questions

1. **Ollama `num_ctx=32768` mit qwen2.5:3b auf 16GB RAM**
   - What we know: qwen2.5:3b benötigt ~2GB für Model-Weights; 32k Kontext benötigt zusätzlichen KV-Cache RAM
   - What's unclear: Ob 16GB ausreicht, wenn RAG-Anything, MinerU und Ollama mit 32k ctx parallel laufen
   - Recommendation: Erster Evaluations-Run mit `num_ctx=16384` testen; nur erhöhen wenn LightRAG Fehler zeigt. `ollama ps` und Activity Monitor monitoren.

2. **RAG-Anything Index-Größe für 10 Evaluation-Dokumente**
   - What we know: LightRAG baut einen Knowledge-Graph (Entities + Relations) plus Vektor-Index
   - What's unclear: Disk-Footprint pro PDF; ob `archivum/` das aufnehmen kann ohne .gitignore-Probleme
   - Recommendation: `archivum/rag-anything/` in `.gitignore` aufnehmen; Disk-Usage nach Eval-Lauf monitoren.

3. **Welche 10 Dokumente aus Archiv für Evaluation?**
   - What we know: Archiv/06 Arzt/ hat Kardiologie/Orthopädie/Krankenhaus-Unterordner; 09 Rente_Steuer und 11 Finanzen sind für Tabellen geeignet
   - What's unclear: Ob die konkreten PDFs wirklich Tabellen/Bilder/Formeln enthalten (Arztberichte sind oft Scan-PDFs)
   - Recommendation: Wave 0 — 3 PDFs aus 06 Arzt, 3 aus 09 Rente_Steuer, 2 aus 11 Finanzen, 2 aus 07 Verträge auswählen. Vor der Evaluation mit `pdfinfo` prüfen ob mehrseitig + nicht trivial.

4. **Docling vs. MinerU — endgültige Wahl**
   - What we know: Docling ist schneller (8s vs. 14s) und einfacher zu installieren; MinerU ist präziser bei Tabellen und konvertiert Formeln zu LaTeX
   - What's unclear: Ob deutsche Arzt-/Steuer-Dokumente für MinerU oder Docling besser geeignet sind
   - Recommendation: MinerU als Primary (RAG16-01 spezifiziert MinerU), Docling als Fallback wenn MinerU-Install scheitert. `parser="docling"` ist in RAG-Anything konfigurierbar.

5. **Privacy-Verifikation (RAG16-06)**
   - What we know: Ollama + RAG-Anything + MinerU sind vollständig lokal; MinerU-Models werden einmalig heruntergeladen
   - What's unclear: Ob MinerU optionale Cloud-Fallback-Calls macht (z.B. für OCR); ob LightRAG telemetry-Calls sendet
   - Recommendation: `tcpdump` oder Netzwerk-Monitor während eines Indexierungs-Laufs laufen lassen. MinerU `--backend pipeline` erzwingt lokale Pipeline ohne externe Calls.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash + Python assert (kein pytest installiert für Phase 48 scope) |
| Config file | none — smoke tests als inline Bash |
| Quick run command | `source rag-anything-env/bin/activate && python -c "from raganything import RAGAnything; print('OK')"` |
| Full suite command | `tom-doc multi-search "Test" && tom-doc search "Test"` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RAG16-01 | RAG-Anything + MinerU importierbar | smoke | `source rag-anything-env/bin/activate && python -c "from raganything import RAGAnything; import mineru; print('OK')"` | ❌ Wave 0 |
| RAG16-02 | 10 Dokumente indexiert, Abfragen erfolgreich | manual | `python archivum/rag-anything/multi_search.py --query "Test" --eval` | ❌ Wave 0 |
| RAG16-03 | `tom-doc multi-search "query"` funktioniert | integration | `tom-doc multi-search "Gehalt"` | ❌ Wave 0 |
| RAG16-04 | MCP-Tool `tom_doc_multi_search` aufrufbar | integration | Cursor MCP-Panel: Tool grün + Testcall | ❌ Wave 0 |
| RAG16-05 | `tom-doc search` weiterhin funktional | regression | `tom-doc search "Arbeitsvertrag" --limit 3` | ✅ (bestehend) |
| RAG16-06 | Kein Cloud-Abfluss während Index-Run | manual | `sudo tcpdump -i any -c 100 'not host 127.0.0.1 and not host ::1'` während Index-Run | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `tom-doc search "Arbeitsvertrag" --limit 3` (Regression: FTS5 läuft noch)
- **Per wave merge:** `tom-doc multi-search "Blutwerte" && tom-doc search "Arbeitsvertrag"`
- **Phase gate:** Beide Commands grün + `tom_doc_multi_search` in Cursor grün

### Wave 0 Gaps

- [ ] `archivum/rag-anything/multi_search.py` — implementieren (Query-Wrapper + Argparse)
- [ ] `rag-anything-env/` — venv mit Python 3.13 anlegen und Packages installieren
- [ ] `archivum/rag-anything/index/` — Working-Dir anlegen (gitignored)
- [ ] `.gitignore` — `archivum/rag-anything/` eintragen
- [ ] MinerU Modell-Download — erster Lauf, Models cachen (`~/.cache/mineru/`)

---

## Sources

### Primary (HIGH confidence)

- GitHub HKUDS/RAG-Anything — Installation, Ollama-Example, MinerU-Dependency bestätigt
- PyPI raganything — Python >=3.9, `[all]` extras, Docling-Support
- PyPI mineru — Python 3.10–3.13 Requirement, Apple Silicon GPU Support, macOS >=14.0
- opendatalab.github.io/MinerU/quick_start/ — Installation, GPU/CPU-Betrieb, macOS-Anforderungen

### Secondary (MEDIUM confidence)

- dev.to/aairom/unlock-rag-anythings-power-with-ollama — Ollama Integration Pattern, Docling als Alternative; Autor beschreibt laufende Dependency-Probleme
- github.com/HKUDS/RAG-Anything examples/ollama_integration_example.py — Modell-Konfiguration (llama3.2, nomic-embed-text, Dimension 768)
- gofastmcp.com — @mcp.tool Decorator Pattern (HIGH für FastMCP-Teil)
- lightrag-hku PyPI — Python >=3.10, Ollama-kompatibel, 32k Kontext-Anforderung

### Tertiary (LOW confidence)

- WebSearch Ergebnis: "LightRAG benötigt 32k Kontext" — aus mehreren Community-Quellen, nicht aus offiziellem Docs direkt
- WebSearch: RAG-Anything + Ollama "dependency challenges" — einzelner Blog-Post mit ungelösten Problemen; Ausgangsbasis ist veralteter Ollama-Stand

---

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — RAG-Anything/MinerU gut dokumentiert; Ollama-Integration offiziell aber "Dependency Challenges" in Community bekannt
- Architecture: HIGH — bestehender tom-doc Shell-Pattern und FastMCP @mcp.tool Pattern sehr klar
- Pitfalls: HIGH — Python-Version-Constraint (3.14 vs. 3.13) direkt aus PyPI-Metadata verifiziert; num_ctx-Problem aus LightRAG-Docs
- Privacy: HIGH — alle genannten Tools sind open-source und local-first; nur MinerU Model-Download beim ersten Lauf ist online

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (raganything/mineru bewegen sich schnell; PyPI-Versionen monatlich prüfen)
