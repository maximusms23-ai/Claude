---
title: API Anything
created: 2026-10-31
type: projekt
aliases:
  - api-anything
tags:
  - agenten
  - mcp
  - automatisierung
  - web
---

# API Anything

Open-Source-Werkzeug (MIT, TypeScript, Node ≥ 22.13), mit dem KI-Agenten **Websites ohne öffentliche API wie eine API aufrufen** können. Statt einen Browser zu steuern, lernt es die Anfrage, die das Frontend der Seite selbst stellt, und spielt sie danach als einfachen HTTP-Request ab. Gelernte Operationen landen in einem **gemeinsamen Katalog**, den alle Installationen nutzen, prüfen und reparieren.

- **Repo**: [goodnight000/api-anything](https://github.com/goodnight000/api-anything) (ca. 1.900 ★, Stand 2026-10-31)
- **npm**: `api-anything` (Version 0.3.1)
- **Katalog**: <https://api-anything-registry.forth-site.workers.dev>
- **Quelle**: [[api-anything-github]]
- **Konzept dahinter**: [[Website-als-API]]

## Kernidee

> „Wenn ein Agent eine Website ohne API braucht, lernt er eine. Jeder andere Agent bekommt sie umsonst.“

Vorbild ist reCAPTCHA: Arbeit, die ohnehin anfällt, wird für alle nutzbar gemacht. Der erste Agent, der eine Seite braucht, lernt die Operation; jeder folgende Aufruf ist eine „Stimme“, ob sie noch funktioniert; wer eine kaputte Operation repariert, repariert sie für alle.

## Ablauf: Lernen → Aufrufen → Reparieren

| Phase | Was passiert |
|---|---|
| **Lernen** | Headless-Browser lädt die Seite je einmal mit zwei Beispiel-Eingaben. Der Teil der Anfrage, der sich ändert, wird zum Parameter („Slot“). Cookies/Tokens werden zu Referenzen (`cookie:name`). Kein LLM nötig. |
| **Aufrufen** | Slots füllen, Request per Node-`fetch` senden (**Tier 1**). Blockt die Seite, Fetch aus einer Browser-Seite heraus; als letztes Mittel Seite rendern und Antwort mitlesen. |
| **Reparieren** | Passt die Antwort nicht mehr (rotierte ID, verschobenes Feld): erst die Reparatur einer anderen Installation aus dem Katalog nehmen, sonst neu lernen – gespeichert wird nur nach erfolgreichem Replay. |

Details: [[Website-als-API]].

## Einrichtung

```sh
npx -y api-anything setup            # verbindet MCP-Server mit Claude Code, Codex, Cursor, Claude Desktop
npx -y api-anything setup --no-share # dasselbe, aber ohne Beitrag zum Katalog
```

Manuell für Claude Code:

```sh
npm install -g api-anything
claude mcp add --scope user api-anything -- api-anything mcp
```

Projektweit über `.mcp.json` im Repo-Root:

```json
{
  "mcpServers": {
    "api-anything": { "command": "npx", "args": ["-y", "api-anything@0.3.1", "mcp"] }
  }
}
```

Ein Chromium-Browser (Chrome, Brave, Edge …) wird **nur zum Lernen** neuer Seiten gebraucht; geteilte Operationen laufen ohne.

## Nutzung

### Per MCP (aus dem Agenten)

| Tool | Zweck |
|---|---|
| `find_sites` | Lokal und im Katalog nach Bedarf, Domain oder URL suchen |
| `list_operations` | Operationen einer Seite mit JSON-Schema der Argumente |
| `call_operation` | Lesende Operation aufrufen (sendet nie Schreibzugriffe) |
| `learn_site` | Neue Lese-Operation aus Seiten-URL + drei Werten lernen |
| `call_write_operation` | Nur mit `--allow-writes` verfügbar |
| `login` | Session aus vorhandenem Browserprofil importieren |
| `site_status`, `get_job`, `get_result` | Diagnose, lange Jobs, gekürzte Antworten |

### Per CLI

```sh
api-anything search book ratings                       # Katalog durchsuchen
api-anything ops goodreads                             # Operationen + Parameter
api-anything call hacker-news search query=sqlite      # JSON-Antwort, tier 1
api-anything call goodreads getBook bookId=50202953 --dry   # Request ansehen, ohne zu senden
```

### Als Bibliothek

```ts
import { call } from "api-anything";
const r = await call("goodreads", "searchBooks", { q: "piranesi" });
if (r.ok) console.log(r.tier, r.data);
else console.log(r.class, r.reason, r.next);
```

### Neue Seite beibringen

```sh
api-anything add hn-demo links \
  --trigger 'https://news.ycombinator.com/from?site={domain}' \
  --example domain=github.com --example2 domain=github.io --match path=/from \
  --html '{"items":"tr.athing","fields":{"title":".titleline > a","url":".titleline > a@href"}}'
```

## Antwortformat

Jede Antwort ist strukturiertes JSON, damit Agenten ohne Prosa-Parsing reagieren können: `class` (`ok`, `drift`, `auth`, `rate`, `blocked`, `input`, …), `retry` (`safe`, `after_wait`, …), `nextCall` (nächster Schritt, z. B. `login`, `relearn`), `nextPage`/`hasMore` für Paginierung.

## Sicherheit & Datenschutz

- **Secrets bleiben lokal**: Specs enthalten nur Referenzen (`cookie:ct0`), nie Werte; eine Spec mit Live-Credential wird nicht gespeichert.
- **Schreibzugriffe** sind standardmäßig aus, werden nur einmal gesendet, Wiederholung innerhalb 10 Min. wird als `duplicate` abgelehnt; Kartenzahlungen werden nie gelernt.
- **Vertrauen durch Nutzung**: Neue Operation wird erst „live“, wenn Installationen aus 2 anderen Netzen sie erfolgreich aufrufen; ersetzt wird sie erst bei Fehlern aus ≥ 3 Netzen. Mit Login gelernte Operationen werden nur geteilt, wenn 3 Installationen in 3 Netzen exakt dasselbe lernten.
- **Was das Gerät verlässt**: Suchanfragen an den Katalog (immer); bei aktivem Teilen zusätzlich öffentlich gelernte Lese-Operationen, Aufruf-Reports (ohne Argumente/Daten) und Reparaturen. Bis zu 20 Hintergrund-Checks pro Tag.
- Geteilte Specs sind **Fremdinhalte** – Name und Beschreibung können eine andere Seite imitieren; immer die `domain` prüfen.

## Katalog-Umfang (2026-10-31)

107 Lese-Operationen über 55 Seiten, u. a. Reddit, X, YouTube, Hacker News, Google Flights, Google Maps, Airbnb, Amazon, IKEA, Zalando, Goodreads, Steam, Netflix, JustWatch, Eventbrite, Coursera, Nasdaq, TradingView. 97 von 99 Operationen ohne Account lieferten am Stichtag Daten.

## Grenzen

- Kennt nur Operationen, die jemand gelernt hat – keine vollständigen Seiten.
- `learn_site` lernt nur Lese-Operationen aus einem Seitenaufruf pro Wert; Daten nach Klicks/Tippen brauchen `capture`/`add` mit `--steps`.
- Kein CAPTCHA-Lösen; Reparatur kann scheitern (`blocked`).
- Nutzungsbedingungen der jeweiligen Seite gelten – Verantwortung liegt beim Nutzer.

## Benchmark (laut Projekt)

Gleicher Agent, gleiche Google-Flights-Aufgabe: mit API Anything **1,5–2× schneller**, **etwa halb so viele Tokens**, 20 von 20 Antworten korrekt (gemessen mit Claude Code, 2026-09-28, wenige Dutzend Läufe). Goodreads-Exploration per Skill: 6,3 Min. und 1,19 $ für Suche, Buchdetails, Autorenbücher und Rezensionen.

## Einsatz in diesem Vault

- **Recherche-Quelle für das Wiki**: Agenten (z. B. *Wiki-Kurator* in [[PaperclipAI]]) können strukturierte Daten von Seiten ohne API abrufen und als Quellen in `wiki/quellen/` erfassen.
- **Ergänzung zum Web Clipper** (siehe [[Werkzeuge]]): Clipper speichert ganze Artikel, API Anything liefert gezielte Datenfelder (Bewertungen, Preise, Listen).
- **Lokale Modelle**: Über MCP auch mit lokalen Agenten-Setups rund um [[Ollama]] nutzbar.

## Status der Integration

| Schritt | Status |
|---|---|
| Wiki-Dokumentation (Projekt, Quelle, Konzept) | erledigt (2026-10-31) |
| Skill unter `.claude/skills/api-anything/` | offen – benötigt Freigabe |
| MCP-Server in `.mcp.json` | offen – benötigt Freigabe |
| `setup` auf dem eigenen Rechner ausführen | offen – lokal durch den Nutzer |

## Siehe auch

- [[Website-als-API]] — Konzept: Web-Frontends als aufrufbare Operationen
- [[Agenten-OS]] — Werkzeuge als Ressource, die das Agenten-OS bereitstellt
- [[PaperclipAI]] — Agentenplattform, deren Recherche-Agenten davon profitieren
