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

# Pfade (v1.1: iCloud-Vault canonical)
WIKI_PATH = TOM_VAULT / "90_Wiki"
CLIPPINGS_PATH = TOM_VAULT / "Clippings"
CHROMA_PATH = Path(__file__).parent / "chroma_db"
TRAINING_DATA_PATH = Path(__file__).parent / "../training/data"

# Modelle
MODEL = "gemme"
EMBED_MODEL = "nomic-embed-text"

# Chunking
CHUNK_SIZE = 500
CHUNK_OVERLAP = 50

# Retrieval
TOP_K = 5
