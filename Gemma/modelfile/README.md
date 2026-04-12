# Ollama Modelfiles (Tom)

| Datei | Basis | Zweck |
|-------|--------|--------|
| `Modelfile` | `qwen2.5:3b` | Tom-Qwen (`gemme`), RAG/Wiki, `num_ctx` 16384 |
| `Modelfile.gemme-fast` | `qwen2.5:1.5b-instruct` | Schneller Pfad (Clipper, Kurzaufgaben), `num_ctx` 8192 |

Erzeugen:

```bash
ollama create gemme -f Gemma/modelfile/Modelfile
ollama create gemme-fast -f Gemma/modelfile/Modelfile.gemme-fast
```

## RAM / Kontext

- Kleineres **`num_ctx`** reduziert Speicherbedarf; siehe [Ollama FAQ](https://docs.ollama.com/faq).
- Nicht mehrere große Modelle gleichzeitig warm halten: `ollama ps` prüfen; ggf. `keep_alive` in Clients anpassen.
