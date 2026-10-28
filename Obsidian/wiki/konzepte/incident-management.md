---
title: "Incident-Management"
created: 2026-10-28
type: konzept
aliases:
  - Error-Management
  - Fehlermanagement
  - Störungsmanagement
tags:
  - devops
  - betrieb
  - softwareentwicklung
---

# Incident-Management

**Incident-Management** (Fehler- bzw. Störungsmanagement) regelt, was passiert, wenn im laufenden Betrieb etwas kaputtgeht: Fehler früh erkennen, schnell eindämmen, sauber beheben und daraus lernen. Ziel ist nicht „nie Fehler“, sondern **kurze Ausfälle und keine Wiederholung**.

## Typischer Ablauf

| Schritt | Was passiert | Wer |
|---|---|---|
| 1. Erkennen | Monitoring schlägt Alarm oder ein Nutzer meldet sich | Monitoring, Support |
| 2. Einstufen | Wie schlimm? Schweregrad festlegen (z. B. SEV1 = alles steht, SEV3 = kleiner Fehler) | Bereitschaft (On-Call) |
| 3. Eskalieren | passende Leute holen, einen *Incident Commander* bestimmen | On-Call |
| 4. Eindämmen | Schaden stoppen, oft per Rollback oder Feature-Flag aus — noch keine Ursachenforschung | Technik |
| 5. Kommunizieren | Status an Nutzer und Team, regelmäßig | Incident Commander |
| 6. Beheben | eigentliche Ursache finden und reparieren | Technik |
| 7. Nachbereiten | *Postmortem*: Was ist passiert, warum, was ändern wir? Ohne Schuldzuweisung | ganzes Team |

Merksatz: **Erst stabilisieren, dann verstehen.**

## Schweregrade (Beispiel)

- **SEV1** — Kerndienst komplett ausgefallen, sofort alle Hände
- **SEV2** — wichtige Funktion gestört, zeitnah
- **SEV3** — Einzelfehler mit Umweg, im normalen Arbeitsfluss

## Kennzahlen

- **MTTD** (Mean Time to Detect) — wie schnell wird ein Fehler bemerkt?
- **MTTR** (Mean Time to Recover) — wie schnell läuft es wieder?
- Anzahl wiederholter Incidents — lernt das Team aus Postmortems?

## Bausteine

- Monitoring & Alarme, die nicht ständig falsch klingeln
- Bereitschaftsplan (On-Call) mit klarer Erreichbarkeit
- Runbooks: kurze Schritt-für-Schritt-Anleitungen für bekannte Störungen
- Statusseite für Nutzer
- Fehlerkultur ohne Schuldige (*blameless*)

## Typische Fehler

- Alle suchen sofort die Ursache, niemand stoppt den Schaden
- Keiner führt, alle reden durcheinander
- Alarm-Müdigkeit: zu viele Fehlalarme, echte werden übersehen
- Postmortem fällt aus oder sucht einen Schuldigen

## In Maximus_OS

In [[Agenten-OS|Maximus_OS]] wäre der **Release Engineer** für Rollback zuständig, der **QA Engineer** für die Reproduktion, der **CTO** als Incident Commander. Ein Postmortem kann als Issue angelegt und vom Wiki-Kurator ins Wiki übernommen werden.

## Illustrationen

Shot-List und Bild-Prompts im Xiaohei-Stil: `output/illustrations/incident-management/prompts.md` (Skill `/007`).

## Siehe auch

- [[Releasemanagement]] — Rollback als Brücke zwischen Release und Incident
- [[Agenten-OS]] — Rollen in Maximus_OS
