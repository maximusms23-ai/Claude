# Multi-Projekt-Nutzung — `wiki_path` Konvention

Tom's Wissensbasis (`$TOM_VAULT/90_Wiki/` öffentlich + `$TOM_VAULT/95_Gehirn/` privat) ist **shared** über alle Projekte auf Maxims Mac. Jedes Projekt kann das Wissen abfragen und zur Füllung des `95_Gehirn/` beitragen.

## Für konsumierende Projekte (nur lesen)

Füge in die `CLAUDE.md` deines Projekts folgende Sektion ein:

```markdown
## Wissensquelle: Tom-Vault

Dieses Projekt teilt den Wissensstand mit Tom (`~/Claude`). Bei Wissensfragen
die nicht projekt-spezifisch sind, nutze diese Tools:

**Primary (Index-first, lokal via `qwen2.5:3b` — kostenlos)**:
- `tom-wiki "Frage"` — liest `$TOM_VAULT/90_Wiki/` und synthetisiert
- `tom-wiki --brain "Frage"` — liest `$TOM_VAULT/95_Gehirn/` (wenn privates Konversations-Wissen relevant ist)

**Fallback (Qwen RAG, langsamer)**:
- `tom-ask "Frage"` — Cosine-Similarity über alle indizierten Chunks

**Pfade**:
- `$TOM_VAULT` = `/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/Obsidian_Valuet/Obsidian_Zentralw/`
- Tools liegen in `~/bin/` (Symlinks auf `~/Claude/bin/`)

**Kaskade**: (1) projekt-lokale Files direkt lesen, (2) tom-wiki, (3) tom-wiki --brain,
(4) tom-ask. Nicht jede Frage braucht das Brain — siehe `~/Claude/CLAUDE.md` Sektion
"Wissens-Kaskade".
```

## Für beitragende Projekte (schreiben ins Brain)

Wenn dein Projekt **eigene daily-Logs** aus Claude-Code-Sessions hinterlassen soll (empfohlen wenn du regelmäßig mit Claude Code dort arbeitest), lege eine projekt-lokale `.claude/settings.json` an, die auf den zentralen `claude-memory-compiler` zeigt:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run --directory /Users/maxim/Claude/claude-memory-compiler python hooks/session-start.py",
            "timeout": 15
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run --directory /Users/maxim/Claude/claude-memory-compiler python hooks/pre-compact.py",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "uv run --directory /Users/maxim/Claude/claude-memory-compiler python hooks/session-end.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Alle Projekte, die das tun, schreiben in **denselben** `$TOM_VAULT/95_Gehirn/daily/` — `compile.py` kompiliert alle projekt-übergreifend in dieselbe `knowledge/`-Struktur. Das ist Absicht: Wissen ist global, nicht projekt-lokal.

## Abgrenzung: Was gehört wo hin?

| Inhalt | Ort |
|---|---|
| Projekt-spezifische Architektur (z.B. welche Libraries verwendet) | `CLAUDE.md` im Projekt-Root |
| Projekt-spezifische TODOs, Bugs | `.planning/` im Projekt-Root (GSD) |
| Allgemeine Tech-Patterns, Lessons über Projekte hinweg | `$TOM_VAULT/95_Gehirn/` (via Auto-Capture) |
| Öffentliches/externes Wissen (Konzepte, Papers) | `$TOM_VAULT/90_Wiki/` (manuell kuratiert) |
| Persönliches (Familie, Eltern, Finanzen) | `$TOM_VAULT/10_..80_/` (privat, nie Brain nie Wiki) |

## Privacy-Warnung

Das `95_Gehirn/` ist **NICHT** publiziert (MkDocs `docs_dir: 90_Wiki`), aber enthält ggf. Inhalte aus Claude-Code-Konversationen. Prüfe beim Onboarding neuer Projekte, ob die Konversationen dort PII, Secrets oder Firmen-Interna enthalten können. Wenn ja: **kein Auto-Capture-Hook** in diesem Projekt aktivieren. Siehe `$TOM_VAULT/95_Gehirn/CLAUDE.md` für die vollständige Whitelist/Blacklist.

## Test aus einem zweiten Projekt heraus

```bash
cd ~/irgendein-anderes-projekt
tom-wiki "Was ist Ollama?"        # sollte aus Tom's 90_Wiki antworten
tom-ask "Gemma 4 Varianten?"      # sollte aus RAG antworten
```

Beides muss ohne cwd-Abhängigkeit funktionieren — die Wrapper setzen `TOM_VAULT` und `cd` selbst in den richtigen Working-Dir.
