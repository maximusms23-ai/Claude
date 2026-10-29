# TOM-PATCHES.md — Lokale Modifikationen

Dieses Clone von [coleam00/claude-memory-compiler](https://github.com/coleam00/claude-memory-compiler) hat lokale Patches, damit das Tool in Tom's iCloud-Vault schreibt statt in das Tool-Repo selbst. Alle Patches sind so minimal wie möglich, um Upstream-Merges einfach zu halten.

Eingeführt in **Tom v1.2 Phase 14** (2026-04-10).

## Patches

### 1. `scripts/config.py` — Pfade auf `$TOM_VAULT/95_Gehirn/`

**Was:** `TOM_VAULT`-Env-Var eingeführt; alle Content-Pfade (`DAILY_DIR`, `KNOWLEDGE_DIR`, etc.) zeigen jetzt auf `$TOM_VAULT/95_Gehirn/` statt `ROOT_DIR/` (das Tool-Repo).

**Warum:** Separation of concerns. Das Tool-Repo enthält Code (git-tracked). Der Vault enthält Daten (iCloud, backup via Time Machine). Daten sollen **nicht** versehentlich ins Tool-Repo committed werden.

**Unveränderbar:**
- `SCRIPTS_DIR`, `TOOL_ROOT`, `HOOKS_DIR`, `AGENTS_FILE` — das sind Tool-Pfade
- `STATE_FILE` — bleibt im Tool-Repo damit `state.json` git-trackable ist

**Backwards-compat:** `ROOT_DIR` ist auf `VAULT_ROOT` aliased, falls ein Upstream-Script noch `ROOT_DIR / "daily"` o.ä. konstruiert.

**Zusätzlich:** `TIMEZONE = "Europe/Berlin"` statt `"America/Chicago"`.

### 2. `hooks/session-start.py` — Import Paths statt Hardcode

**Was:** `DAILY_DIR`, `KNOWLEDGE_DIR`, `INDEX_FILE` werden jetzt via `sys.path.insert` + `from config import ...` geladen.

**Warum:** Upstream hatte `ROOT = Path(__file__).parent.parent; DAILY_DIR = ROOT / "daily"` — das würde trotz `config.py`-Patch weiter auf das Tool-Repo zeigen.

### 3. `hooks/session-end.py` — Import Paths statt Hardcode

Gleiche Änderung wie 2, nur für `DAILY_DIR`. `SCRIPTS_DIR` und `STATE_DIR` bleiben lokal (Tool-Repo-Paths).

### 4. `scripts/flush.py` — Import Paths statt Hardcode

Gleiche Änderung wie 2, nur für `DAILY_DIR`. Der Rest (`STATE_FILE`, `LOG_FILE`) bleibt im Tool-Repo.

### 5. `tom_tools/wiki_query.py` — Neues Modul

**Was:** Eigenes Query-Modul das lokal via Ollama (`qwen2.5:3b`) statt Claude Agent SDK läuft. Nimmt `--brain` oder `--root` Parameter.

**Warum:**
- `scripts/query.py` ist an `KNOWLEDGE_DIR` gebunden (= `95_Gehirn/knowledge/`); für `tom-wiki` brauchen wir aber auch `90_Wiki/` als Quelle
- Lokale Ollama-Inferenz ist kostenlos und offline, Claude Agent SDK kostet Subscription-Quota

Aufruf via `uv run python -m tom_tools.wiki_query "Frage"`. Wird von `bin/tom-wiki` im Parent-Repo aufgerufen.

### 6. `pyproject.toml` — `ollama` Dependency

**Was:** `uv add ollama` → `ollama>=0.6.1` ergänzt.

**Warum:** Dependency für `tom_tools/wiki_query.py`.

### 7. `tom_tools/wiki_query.py` — v1.3 Quality-Pass (Phase 23)

**Eingefuehrt:** 2026-04-10, Phase 23.

**Was geaendert:**

1. **Verschaerfter System-Prompt** — Verlangt jetzt explizit:
   - Mindestens eine Quelldatei zitieren (Dateiname oder `[[wikilink]]`)
   - Keine generischen Floskeln, keine Wikipedia-Synthese
   - Bei fehlender Info ehrlich sagen + tom-ask als Fallback empfehlen
   - Format: 3-8 Saetze plus Quellenzeile

2. **Keyword-Context-Filter** — Statt alle Artikel in den Prompt zu kippen:
   - `extract_keywords(question)` tokenisiert die Frage (lowercased, Stopwords raus, min 3 Zeichen)
   - `score_article(content, keywords)` bewertet jeden Artikel nach Treffern in Titel/Headern/erstem Absatz/Body
   - `collect_wiki_content(root, question)` laedt nur Index + Top-K=5 Artikel mit Score > 0
   - Fallback: Wenn nichts matched, bleibt nur der Index drin (mit Hinweis-Marker)

3. **Neue Konstanten:** `TOP_K = 5`, `MIN_KEYWORD_LEN = 3`, `STOPWORDS` (deutsche + englische Basisliste).

**Warum:** Karpathy Index-first wird bei wachsendem Wiki verduennt — wenn alle Artikel in den Prompt gehen, antwortet `qwen2.5:3b` generisch statt praezise. Schmaler Filter + harter Prompt = praezise Antworten ohne RAG-Umstieg. Schwelle fuer RAG-Primary bleibt bei 1500 Artikel (Phase 25 dokumentiert das).

**Smoke-Test (Phase 23 Abnahme):**

```bash
tom-wiki "Was ist TurboQuant?"
# Erwartet: Antwort enthaelt "turboquant.md" oder "[[turboquant]]"
```

Tatsaechliches Ergebnis (vor/nach):

- **VORHER:** Generische Synthese ueber alle Artikel, keine Datei-Referenz, Antwort > 15 Saetze.
- **NACHHER:** 3-8 Saetze, schliesst mit `Quelle: konzepte/turboquant.md` (explizit zitiert). Volltext siehe Maximus_OS-Issue Phase 23.

Smoke-Test Auszug (NACHHER):

> TurboQuant ist ein von Google Research entwickelter KV-Cache-Quantisierungsalgorithmus, der den Key-Value-Cache während der Inferenz auf bis zu 3 Bit komprimiert. [...] Die niedrigste Stufe, `turbo3`, erreicht eine Kompression von 4.9x des KV-Cache-Speichers.
> Quelle: konzepte/turboquant.md

**Backwards-compat:** `bin/tom-wiki` Wrapper unveraendert, CLI-Surface (`python -m tom_tools.wiki_query "Frage"`) unveraendert. Nur die interne Signatur `collect_wiki_content(root)` wurde zu `collect_wiki_content(root, question)` erweitert — wird nur aus `query()` aufgerufen.

**Nicht gemerged:** Diese Aenderungen sind Tom-spezifisch und gehen NICHT upstream zu coleam00/claude-memory-compiler — `wiki_query.py` ist von vornherein ein Tom-only Modul (siehe Patch 5).

## 8. Anthropic-SDK Subscription-Quota Clarification (Phase 26)

**Eingefuehrt:** 2026-04-10, Phase 26 (Milestone v1.3 Close).

**Frage aus v1.2 offen:** Verbraucht `tom-compile` (das via `claude_agent_sdk` die `scripts/compile.py` ausfuehrt) die aktive Claude-Code/Max-Subscription-Quota, oder triggert es separates API-Billing ueber `ANTHROPIC_API_KEY`?

**Recherche-Ergebnis (2026-04-10, Stand):**

1. **Default-Pfad laut Anthropic-Dokumentation:** `claude_agent_sdk` erwartet einen API-Key und rechnet per-Token gegen die Organization ab. Subscription-Billing (Pro/Max) ist fuer programmatische Aufrufe **nicht offiziell unterstuetzt**. Open Feature-Request: `anthropics/claude-agent-sdk-python#559` ("Agent SDK should support Max plan billing, not just API keys").
2. **April-2026-Cutoff:** Anthropic hat ab **2026-04-04** klargestellt, dass Subscription-Quotas "no longer cover third-party tools", also auch SDK-basierte Agents nicht mehr pauschal abdecken (mehrere unabhaengige Drittquellen, siehe Sources).
3. **Empirische Beobachtung in Tom v1.3:** `scripts/flush.log` und der erste launchd-Run (Phase 22, `tom-compile-safe`, Exit 0, Dauer 17 s) zeigen, dass `claude_agent_sdk` **den gebundelten Claude-Code-CLI** aus `claude_agent_sdk/_bundled/claude` aufruft (siehe `INFO Using bundled Claude Code CLI: .../site-packages/claude_agent_sdk/_bundled/claude`). Dieser Pfad nutzt dieselbe OAuth-Session wie das installierte Claude Code auf der Maschine — d.h. solange Maxim per Max-Subscription im Claude-Code angemeldet ist, uebernimmt der bundled CLI seine Auth.
4. **Konflikt:** Punkt 1/2 (offizielle Doku) und Punkt 3 (Empirie) widersprechen sich. Der bundled CLI ist de facto Claude Code; Anthropic’s "Agent SDK only supports API Keys" bezieht sich auf den **direkten SDK-Pfad ohne bundled CLI**, nicht auf die bundled-CLI-Route. Fuer `claude-memory-compiler` / `tom-compile` gilt also vermutlich: **Max-Subscription deckt die Kosten**, solange der bundled Claude-CLI benutzt wird und die Maschine in einer aktiven Claude-Code-Session ist.

**Konsequenz fuer Tom:**

- **Vorlaeufige Entscheidung:** `tom-compile` darf in v1.3 **taeglich** per launchd laufen. Maxim hat Max-Subscription, und die bundled-CLI-Route aus dem SDK laeuft auf derselben OAuth-Session.
- **Monitoring-Pflicht:** Wenn `~/Library/Logs/tom-compile.log` ploetzlich Auth-Fehler oder 401/403 zeigt, heisst das: Der bundled-Pfad wurde von Anthropic gekappt. Dann sofort `launchctl bootout gui/$(id -u)/com.maxim.tom-compile`, `ANTHROPIC_API_KEY` setzen und per API-Key weiterfahren (oder das Feature pausieren).
- **Kein Cost-Guard noetig fuer v1.3.** Wird in v1.4 neu evaluiert, falls Anthropic den bundled-Pfad stoert oder die Subscription-Konditionen erneut aendert.
- **Falls Maxim irgendwann ohne Max-Subscription ist:** `tom-compile` bricht mit Auth-Fehler und muss auf API-Key umgestellt werden (`ANTHROPIC_API_KEY` in `~/.zshrc` + Environment-Passthrough im launchd-Plist).

**Ehrlichkeits-Disclaimer:** Dies ist die bestmoegliche Interpretation aus offizieller Doku + Empirie per 2026-04-10. Es gibt **keine schriftliche Anthropic-Aussage**, die den bundled-CLI-Pfad fuer `claude_agent_sdk` explizit als subscription-covered bestaetigt. Falls das in v1.4 wichtig wird, ist der einzige sichere Test ein expliziter Billing-Check im Claude-Console nach ein paar Compile-Laeufen — wenn dort Token auftauchen, laeuft es ueber API-Key; wenn nicht, laeuft es ueber Subscription.

**Sources:**
- [Agent SDK overview — Claude API Docs](https://platform.claude.com/docs/en/agent-sdk/overview)
- [anthropics/claude-agent-sdk-python#559 — "Agent SDK should support Max plan billing, not just API keys"](https://github.com/anthropics/claude-agent-sdk-python/issues/559)
- [Claude Code Pricing 2026 — NxCode](https://www.nxcode.io/resources/news/claude-code-pricing-2026-free-api-costs-max-plan)
- [OpenClaw + Claude Code Costs 2026 — ShareUHack](https://www.shareuhack.com/en/posts/openclaw-claude-code-oauth-cost)

## Upstream-Updates mergen

Wenn Cole Medin den Upstream updatet:

1. `cd claude-memory-compiler`
2. `git init && git remote add upstream https://github.com/coleam00/claude-memory-compiler && git fetch upstream`
3. Lokale Änderungen stashen (via `git stash` — die sind nicht in git weil dieses Clone kein `.git` hat; stattdessen manuell backuppen)
4. `git reset --hard upstream/main`
5. Patches oben 1–6 erneut anwenden
6. Smoke-Tests: `uv run scripts/lint.py --structural-only` und `tom-wiki "Test"`
7. `cd .. && git add claude-memory-compiler && git commit -m "chore: sync memory-compiler upstream"`

Alternativ, wenn Upstream sich stark ändert: frisch klonen und Patches neu applizieren — dauert <10 Minuten.

## Nicht gepatcht

Bewusst **nicht** geändert:

- `scripts/compile.py` — arbeitet korrekt via `config.py`-Import
- `scripts/lint.py` — gleich
- `scripts/query.py` — bleibt original (nutzt Claude Agent SDK, wird ggf. später für Brain-Queries genutzt)
- `hooks/pre-compact.py` — nutzt `ROOT` nur als `uv run --directory`, nicht für Daten-Writes
- `AGENTS.md`, `README.md` — Upstream-Doku, bleibt authentisch

## Siehe auch

- `/Users/maxim/Claude/CLAUDE.md` Sektion "Claude-Code Hooks (seit v1.2 Phase 16)"
- `$TOM_VAULT/95_Gehirn/CLAUDE.md` Privacy-Regeln
- `.planning/phases/14-tool-install/14-VERIFICATION.md`
- `.planning/phases/16-hook-integration/16-VERIFICATION.md`
- `.planning/phases/19-wrapper/19-VERIFICATION.md`
