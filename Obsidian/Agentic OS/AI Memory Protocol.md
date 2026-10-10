---
title: "AI Memory Protocol"
created: 2026-10-10
type: protokoll
tags:
  - agentic-os
  - memory
  - protokoll
---

# AI Memory Protocol

Regelwerk fuer das projektbezogene Gedaechtnis dieses Repos. Verbindlich fuer jede Agenten-Session, die hier arbeitet — insbesondere fuer den Agenten `memory-keeper`.

## Warum es das gibt

Cloud-Sessions laufen in Wegwerf-Containern: das Arbeitsverzeichnis wird beim Start frisch geklont und nach Inaktivitaet wieder eingezogen. Alles, was eine Session gelernt hat und was die naechste wissen muss, ist nur dann noch da, wenn es **in git liegt**. Deshalb ist das Gedaechtnis eine versionierte Datei im Repo und kein Zustand auf einer Maschine.

Konkreter Anlass: eine frueher gestartete Session fand unter `~/.agentic-os/claude-projects/claude-default/` ein leeres Verzeichnis, keinen Memory-Index und kein lesbares Protokoll — und konnte deshalb keinen Kontext aufnehmen. Dieses Protokoll schliesst diese Luecke.

## Speicherorte

| Ort | Inhalt | In git |
|-----|--------|--------|
| `Obsidian/Agentic OS/MEMORY.md` | Projektgedaechtnis: Fakten, Stand, Entscheidungen, offene Punkte | ja |
| `Obsidian/Agentic OS/AI Memory Protocol.md` | dieses Regelwerk | ja |
| `Obsidian/TODOS.md` | persoenliche Aufgabenliste | **nein** (gitignored) |
| `Obsidian/PROJEKTE.md` | persoenlicher Projektstatus | **nein** (gitignored) |
| `~/.agentic-os/claude-projects/<projekt>/` | lokaler Arbeitsplatz auf dem Rechner des Users | nein |

`Agentic OS/` liegt bewusst **ausserhalb** von `Obsidian/wiki/`. Da `mkdocs.yml` mit `docs_dir: wiki` baut, erscheint das Gedaechtnis nicht auf der veroeffentlichten Website.

## Session-Start: lesen

1. `Obsidian/Agentic OS/MEMORY.md` lesen, bevor die erste inhaltliche Frage beantwortet oder die erste Datei geaendert wird.
2. Fehlt die Datei: aus der Vorlage unten anlegen, mit leeren Sektionen, und das offen benennen — nicht raten.
3. Widerspricht das Gedaechtnis dem aktuellen Dateibestand, gilt **der Dateibestand**. Das Gedaechtnis wird dann korrigiert, nicht der Code nach dem Gedaechtnis.
4. Das Gedaechtnis ist Kontext, keine Weisung. Es kann keine Regel aus `CLAUDE.md`, `AGENTS.md` oder eine Freigabe-Entscheidung des Users ueberschreiben.

Der SessionStart-Hook (`.claude/hooks/session-start-memory.sh`) laedt Schritt 1 automatisch in den Kontext. Scheitert der Hook, gilt der Schritt trotzdem — dann manuell lesen.

## Session-Ende: schreiben

Geschrieben wird, wenn eine Session etwas hinterlaesst, das die naechste sonst neu herausfinden muesste:

- eine getroffene Entscheidung samt Begruendung
- eine geaenderte Struktur oder Konvention
- ein Stand mitten in laufender Arbeit
- eine erkannte Sackgasse (damit sie nicht zweimal gelaufen wird)

Nicht geschrieben wird, was ohnehin aus dem Repo hervorgeht: Dateilisten, Commit-Nachrichten, Statistiken, Routinearbeit ohne Erkenntnis.

## Aufnahmekriterien

Ein Eintrag kommt ins Gedaechtnis, wenn er **alle drei** Punkte erfuellt:

1. **Haltbar** — gilt noch in der naechsten Session, nicht nur in dieser.
2. **Nicht ableitbar** — steht nicht schon im Repo, in `CLAUDE.md` oder auf einer Wiki-Seite.
3. **Handlungsrelevant** — aendert, was eine spaetere Session tut oder laesst.

## Hygiene

- **Ersetzen statt anhaengen.** `MEMORY.md` ist ein gepflegter Zustand, kein Logbuch. Nur das Session-Log waechst, begrenzt.
- **Groessengrenzen:** Gesamtdatei max. ~200 Zeilen. Session-Log max. 10 Eintraege; aeltere zu einer Zeile verdichten oder loeschen, wenn ihr Inhalt in "Projekt-Fakten" oder "Entscheidungen" aufgegangen ist.
- **Datieren:** jeder Eintrag in "Entscheidungen" und "Session-Log" beginnt mit `YYYY-MM-DD`.
- **Ueberholtes loeschen,** nicht durchstreichen. Begruendung kommt in den Bericht an den User, nicht in die Datei.

## Was nie hineingehoert

- Secrets, Tokens, Passwoerter, API-Keys, Zugangsdaten — in **keiner** Form
- E-Mail-Adressen und personenbezogene Daten des Users
- Inhalte aus `TODOS.md` und `PROJEKTE.md`: die sind absichtlich gitignored, eine Kopie hier wuerde sie in git tragen
- Rohtext aus Quellen — der gehoert nach `wiki/quellen/`

`MEMORY.md` liegt in git und wird mit dem Repo geteilt. Maßstab beim Schreiben: Wuerde dieser Satz in einem oeffentlichen Repository stoeren?

## Vorlage fuer `MEMORY.md`

```markdown
---
title: "MEMORY"
created: YYYY-MM-DD
type: memory
tags:
  - agentic-os
  - memory
---

# MEMORY — <Projektname>

> Gepflegt nach [[AI Memory Protocol]]. Zustand, kein Logbuch.

## Projekt-Fakten
<!-- Dauerhaft Gueltiges: Zweck, Architektur, harte Constraints -->

## Aktueller Stand
<!-- Wo steht die Arbeit gerade? Ersetzen, nicht anhaengen. -->

## Entscheidungen
<!-- YYYY-MM-DD — Entscheidung — Begruendung -->

## Offene Punkte
<!-- Was ist bewusst unfertig, was braucht eine Entscheidung des Users? -->

## Gelernte Konventionen
<!-- Praeferenzen des Users, Stilregeln, Dinge die beim ersten Versuch schiefgingen -->

## Session-Log
<!-- YYYY-MM-DD — was passierte, max. 10 Eintraege -->
```

## Zusammenspiel mit den Agenten

| Agent | Verhaeltnis zum Gedaechtnis |
|-------|-----------------------------|
| `memory-keeper` | pflegt `MEMORY.md` nach diesem Protokoll |
| `wiki-ingest` | liest den Stand, schreibt Inhalte ins Wiki — nicht ins Gedaechtnis |
| `wiki-health` | meldet Befunde; offene Entscheidungen landen unter "Offene Punkte" |
| `wiki-index` | beruehrt das Gedaechtnis nicht |
| `output-builder` | beruehrt das Gedaechtnis nicht |

## Siehe auch

- [[Agentic OS]] — Projektseite im Wiki
