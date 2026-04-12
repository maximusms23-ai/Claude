"""Leichtgewichtiger Logger fuer RAG-Interaktionen als Trainingsdaten."""

import json
from datetime import datetime
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).parent / "../rag"))
from config import TRAINING_DATA_PATH


LOG_PATH = TRAINING_DATA_PATH / "interactions.jsonl"


def log_interaction(query: str, response: str, sources: list[str]):
    """Eine RAG-Interaktion als JSONL loggen."""
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    entry = {
        "query": query,
        "response": response,
        "sources": sources,
        "timestamp": datetime.now().isoformat(),
        "rating": None,
    }
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")
