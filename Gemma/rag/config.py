"""Zentrale Konfiguration fuer die RAG-Pipeline.

Seit Tom v1.1 Phase 11: Pfade zeigen auf den iCloud-Vault ($TOM_VAULT),
nicht mehr auf das alte Research-Wiki. 90_Wiki/ ist oeffentliches Wissen,
Clippings bleiben als Quellmaterial indizierbar.
"""

import os
from pathlib import Path

# $TOM_VAULT aus Env-Var, Fallback auf iCloud-Pfad (seit v1.1)
TOM_VAULT = Path(
    os.environ.get(
        "TOM_VAULT",
        "/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw",
    )
)

# Pfade (v1.1: iCloud-Vault canonical; v1.2 Phase 18: + 95_Gehirn/knowledge/)
WIKI_PATH = TOM_VAULT / "90_Wiki"
CLIPPINGS_PATH = TOM_VAULT / "Clippings"
# 95_Gehirn/knowledge/ enthält kompilierte Konzept-Artikel aus Claude-Code-
# Konversationen (via claude-memory-compiler). NICHT die rohen daily-logs —
# die sind zu verrauscht für RAG.
GEHIRN_PATH = TOM_VAULT / "95_Gehirn" / "knowledge"
CHROMA_PATH = Path(__file__).parent / "chroma_db"
TRAINING_DATA_PATH = Path(__file__).parent / "../training/data"

# Modelle
MODEL = os.environ.get("TOM_LOCAL_MODEL", "qwen2.5:3b")
EMBED_MODEL = os.environ.get("TOM_RAG_EMBED_MODEL", "BAAI/bge-small-en-v1.5")
OLLAMA_BASE_URL = os.environ.get("TOM_OLLAMA_BASE_URL", "http://127.0.0.1:11434")
CHAT_TEMPERATURE = float(os.environ.get("TOM_LOCAL_TEMPERATURE", "0.2"))
CHAT_NUM_CTX = int(os.environ.get("TOM_LOCAL_NUM_CTX", "16384"))

# Chunking
CHUNK_SIZE = 500
CHUNK_OVERLAP = 50

# Retrieval
TOP_K = 5
