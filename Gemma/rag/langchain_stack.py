"""LangChain-backed local model helpers for Tom's RAG stack."""

from __future__ import annotations

from functools import lru_cache

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_ollama import ChatOllama

from config import CHAT_NUM_CTX, CHAT_TEMPERATURE, EMBED_MODEL, MODEL, OLLAMA_BASE_URL


@lru_cache(maxsize=1)
def embedding_client() -> HuggingFaceEmbeddings:
    return HuggingFaceEmbeddings(
        model_name=EMBED_MODEL,
        encode_kwargs={"normalize_embeddings": True},
        model_kwargs={"device": "cpu"},
    )


def embed_documents(texts: list[str]) -> list[list[float]]:
    return embedding_client().embed_documents(texts)


def embed_query(text: str) -> list[float]:
    return embedding_client().embed_query(text)


@lru_cache(maxsize=1)
def chat_model() -> ChatOllama:
    return ChatOllama(
        model=MODEL,
        base_url=OLLAMA_BASE_URL,
        temperature=CHAT_TEMPERATURE,
        num_ctx=CHAT_NUM_CTX,
    )


def chat(system_prompt: str, user_prompt: str) -> str:
    response = chat_model().invoke(
        [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt),
        ]
    )
    content = response.content
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
                continue
            if isinstance(item, dict):
                text = item.get("text")
                if isinstance(text, str):
                    parts.append(text)
        return "\n".join(part.strip() for part in parts if part and part.strip()).strip()
    return str(content).strip()
