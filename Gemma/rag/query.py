"""Fragen an die RAG-Pipeline stellen."""

import sys
from pathlib import Path

import chromadb

from config import CHROMA_PATH, TOP_K
from langchain_stack import chat, embed_query

sys.path.insert(0, str(Path(__file__).parent / "../training"))
from interaction_logger import log_interaction

SYSTEM_PROMPT = """Du bist Tom, ein Assistent fuer eine deutschsprachige Wissensbasis.
Beantworte Fragen basierend auf dem bereitgestellten Kontext.
Wenn der Kontext keine Antwort enthaelt, sage das ehrlich.
Antworte auf Deutsch."""


def query(question: str) -> str:
    """Frage via RAG beantworten."""
    chroma_path = CHROMA_PATH.resolve()
    if not chroma_path.exists():
        print("Fehler: Kein Index gefunden. Zuerst `python3 index.py` ausfuehren.")
        sys.exit(1)

    client = chromadb.PersistentClient(path=str(chroma_path))

    # Frage embedden
    query_embedding = embed_query(question)

    # Drei Collections durchsuchen (wiki + clippings + gehirn seit v1.2 Phase 18)
    context_parts = []
    sources = set()

    for col_name in ["wiki", "clippings", "gehirn"]:
        try:
            collection = client.get_collection(col_name)
        except Exception:
            continue
        results = collection.query(
            query_embeddings=[query_embedding],
            n_results=TOP_K,
        )
        for doc, meta in zip(results["documents"][0], results["metadatas"][0]):
            context_parts.append(f"[{meta['title']}]\n{doc}")
            sources.add(f"{meta['title']} ({meta['source']})")

    context = "\n\n---\n\n".join(context_parts)

    # Prompt an das lokale Qwen-Modell senden
    prompt = f"""Kontext aus der Wissensbasis:

{context}

---

Frage: {question}"""

    answer = chat(SYSTEM_PROMPT, prompt)

    # Interaktion loggen
    log_interaction(question, answer, sorted(sources))

    # Quellen anhaengen
    source_list = "\n".join(f"  - {s}" for s in sorted(sources))
    return f"{answer}\n\nQuellen:\n{source_list}"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 query.py \"Deine Frage\"")
        sys.exit(1)

    question = " ".join(sys.argv[1:])
    print(query(question))
