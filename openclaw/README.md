# OpenClaw — Referenz (Repo)

Live-Konfiguration liegt **nicht** im Git-Clone, sondern unter **`~/.openclaw/openclaw.json`** (Ollama/OpenClaw schreibt dort).

## Tom-Standard (Phase 38+)

- **Modell:** `qwen2.5:3b` (Chat + Tool-Use, kompatibel mit lokalem Stack)
- **Referenz-Kopie:** [`openclaw.json.reference`](openclaw.json.reference) — nach `~/.openclaw/openclaw.json` kopieren und anpassen (nur als Vorlage; Schema kann sich mit Ollama-Versionen ändern)

## Offizielle Doku

- [Ollama: OpenClaw](https://docs.ollama.com/integrations/openclaw)

## Verifikation

```bash
ollama list | grep qwen2.5:3b
# optional: ollama launch openclaw --help
```

Siehe auch: [`.planning/phases/38-local-toolupgrade/SUMMARY.md`](../.planning/phases/38-local-toolupgrade/SUMMARY.md).
