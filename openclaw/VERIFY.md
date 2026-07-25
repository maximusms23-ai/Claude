# Verify

Nach der Einrichtung sollten diese Checks gruen sein:

```bash
openclaw config validate
openclaw models status
openclaw status --all
openclaw gateway probe
```

Erwartung:

- `openclaw config validate` ist gruen
- `openclaw models status` zeigt `Default: ollama/qwen2.5:3b`
- `~/.openclaw/openclaw.json` zeigt `ollama/qwen2.5:3b` als primaeres OpenClaw-Modell
- `models.providers.ollama.baseUrl` zeigt auf `http://127.0.0.1:11434`
- Gateway ist ueber `ws://127.0.0.1:18789` erreichbar
- `Gateway service` ist installiert
- `tools.web.search.enabled = true`
- `tools.web.search.provider = "ollama"`
- `tools.web.fetch.enabled = true`

Rollback:

1. Backup-Datei aus `~/.openclaw/openclaw.json.pre-sonnet45-20260411` zurueckkopieren
2. Gateway neu starten

Wichtiger Hinweis:

OpenClaw nutzt in diesem Setup wieder die native Ollama-Modell-API als Hauptprovider.

Web-Hinweis:

Web-Suche und Web-Fetch bleiben ueber die installierten Ollama-Tools aktiv.
Der Modellpfad fuer OpenClaw selbst laeuft dabei direkt ueber `ollama/qwen2.5:3b`.
