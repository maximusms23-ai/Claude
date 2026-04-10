"""Wiki-Dateien in ChromaDB indexieren."""

import sys
import yaml
import chromadb
import ollama

from config import WIKI_PATH, CLIPPINGS_PATH, GEHIRN_PATH, CHROMA_PATH, EMBED_MODEL, CHUNK_SIZE, CHUNK_OVERLAP


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """YAML-Frontmatter parsen und vom Body trennen."""
    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) >= 3:
            try:
                meta = yaml.safe_load(parts[1]) or {}
            except yaml.YAMLError:
                meta = {}
            return meta, parts[2].strip()
    return {}, text


def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """Text in ueberlappende Chunks aufteilen."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + size
        chunks.append(text[start:end])
        start = end - overlap
    return [c for c in chunks if c.strip()]


def index_directory(client, collection_name: str, base_path, source_prefix: str) -> tuple[int, int]:
    """Markdown-Dateien aus einem Verzeichnis indexieren."""
    base = base_path.resolve()
    if not base.exists():
        print(f"Pfad nicht gefunden: {base}")
        return 0, 0

    md_files = sorted(base.rglob("*.md"))
    if not md_files:
        print(f"Keine Markdown-Dateien in {base}")
        return 0, 0

    print(f"\n[{collection_name}] Gefunden: {len(md_files)} Dateien")

    try:
        client.delete_collection(collection_name)
    except Exception:
        pass
    collection = client.create_collection(collection_name)

    total_chunks = 0

    for filepath in md_files:
        rel_path = filepath.relative_to(base)
        text = filepath.read_text(encoding="utf-8")
        meta, body = parse_frontmatter(text)

        title = meta.get("title", filepath.stem)
        tags = meta.get("tags", [])
        if isinstance(tags, list):
            tags = ", ".join(str(t) for t in tags)

        chunks = chunk_text(body)
        if not chunks:
            continue

        print(f"  {rel_path}: {len(chunks)} Chunks")

        ids = []
        documents = []
        metadatas = []
        embeddings = []

        for i, chunk in enumerate(chunks):
            chunk_id = f"{source_prefix}/{rel_path}:{i}"
            response = ollama.embed(model=EMBED_MODEL, input=chunk)
            embedding = response["embeddings"][0]

            ids.append(chunk_id)
            documents.append(chunk)
            metadatas.append({
                "source": f"{source_prefix}/{rel_path}",
                "title": str(title),
                "tags": str(tags),
                "chunk_index": i,
            })
            embeddings.append(embedding)

        collection.add(
            ids=ids,
            documents=documents,
            metadatas=metadatas,
            embeddings=embeddings,
        )
        total_chunks += len(chunks)

    print(f"[{collection_name}] Abgeschlossen: {len(md_files)} Dateien, {total_chunks} Chunks")
    return len(md_files), total_chunks


def index_all():
    """Wiki, Clippings und Gehirn-Knowledge indexieren.

    Seit Tom v1.2 Phase 18: dritte Collection `gehirn` für kompilierte
    Artikel aus 95_Gehirn/knowledge/. Die rohen daily-logs bleiben außen vor.
    """
    client = chromadb.PersistentClient(path=str(CHROMA_PATH.resolve()))

    wiki_files, wiki_chunks = index_directory(client, "wiki", WIKI_PATH, "wiki")
    clip_files, clip_chunks = index_directory(client, "clippings", CLIPPINGS_PATH, "clippings")
    geh_files, geh_chunks = index_directory(client, "gehirn", GEHIRN_PATH, "gehirn")

    total_files = wiki_files + clip_files + geh_files
    total_chunks = wiki_chunks + clip_chunks + geh_chunks
    print(f"\nGesamt: {total_files} Dateien, {total_chunks} Chunks")


if __name__ == "__main__":
    index_all()
