---
title: "Incident-Management – Illustrationen (Shot-List & Prompts)"
created: 2026-10-28
type: output
tags:
  - illustration
  - incident-management
  - xiaohei
---

# Incident-Management – Shot-List & Prompts

Zu [[incident-management|Incident-Management]]. Stil: Skill `/007`. Jeden Prompt **einzeln** in ein Bildmodell geben; den gemeinsamen Stilblock aus `../releasemanagement/prompts.md` an der markierten Stelle einsetzen.

| # | Datei | Nach Abschnitt | Kernaussage | Struktur | Was Xiaohei tut | Status |
|---|---|---|---|---|---|---|
| 1 | `01-erst-eimer-dann-rohr.png` | Typischer Ablauf | Erst Schaden stoppen, dann Ursache suchen | Vorher/Nachher | stellt erst einen Eimer unter das Leck, erst danach schaut er mit Lupe ins Rohr | **stark** |
| 2 | `02-sirene-mit-drehregler.png` | Schweregrade | Nicht jeder Alarm ist gleich laut | Konzept-Metapher | dreht an einer alten Sirene einen Regler von SEV3 auf SEV1 | **stark** |
| 3 | `03-dirigent.png` | Eskalieren & Kommunizieren | Einer führt, alle anderen arbeiten | Rollen-Zustand | steht als Dirigent auf einer Kiste vor einem Chaos-Orchester | optional |
| 4 | `04-scherben-kleben.png` | Nachbereiten / Postmortem | Aus dem Fehler lernen, nicht Schuldige suchen | Konzept-Metapher | klebt eine zerbrochene Tasse und schreibt Notizen auf die Bruchkanten | **stark** |

---

## 1 · Erst Eimer, dann Rohr

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: The first rule of incident management: contain the damage before investigating the cause.
Structure type: before/after (two steps).
Core idea: When production breaks, first stop the damage (rollback, switch off), only then search for the root cause.
Composition: A single horizontal hand-drawn pipe runs across the image with one crack in the middle, water dripping. Left scene: Xiaohei hastily pushes a bucket under the drip with both thin arms, deadpan. Small orange arrow to the right. Right scene, same pipe: the bucket is in place and calm, and now Xiaohei holds a large magnifying glass to the crack. Wide empty white space above the pipe.
Suggested elements: cracked pipe / bucket / dripping water / magnifying glass
German handwritten labels: "1. stoppen" (orange) / "2. verstehen" (blue) / "Leck" (red) / "nicht umgekehrt" (red)
```

## 2 · Sirene mit Drehregler

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Incident severity levels.
Structure type: concept metaphor.
Core idea: Not every error deserves the same alarm; severity decides how many people are woken up and how fast.
Composition: An old hand-cranked siren on a pole in the center-left, with a big rotary dial attached showing three positions. Xiaohei hangs onto the dial with both arms, turning it to the highest position, deadpan. Sound lines from the siren grow from 1 to 3 waves. On the right, three small sleeping figures in beds: one wakes at the first wave, all wake at the third.
Suggested elements: hand siren / rotary dial / sound waves / sleeping on-call figures
German handwritten labels: "SEV3 – später" (blue) / "SEV2 – bald" (orange) / "SEV1 – alle!" (red) / "wer wird geweckt?"
```

## 3 · Dirigent

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: The incident commander role.
Structure type: role state.
Core idea: During an incident one person leads and communicates, everyone else works on clear tasks instead of shouting at once.
Composition: Four small box-shaped figures holding odd instruments (a wrench, a phone, a laptop, a megaphone), with chaotic scribble sound lines between them on the left side. Xiaohei stands on a wooden crate in front of them as a deadpan conductor, raising a baton; on the right side the sound lines turn into one clean orange line leading to a small status board.
Suggested elements: crate / baton / figures with tools / status board
German handwritten labels: "einer führt" (orange) / "alle reden" (red) / "Status alle 30 Min" (blue) / "klare Aufgaben"
```

## 4 · Scherben kleben

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Blameless postmortem.
Structure type: concept metaphor.
Core idea: After the incident, the team learns from the break instead of looking for someone to blame; each crack becomes a lesson.
Composition: A large cup in the center that was broken and is now glued back together, its crack lines clearly visible. Xiaohei sits on the rim with a tiny pen and writes small notes directly along the crack lines, deadpan. A small pointing finger from the left edge, clearly cut out by a red crossed-out line. A blue thread from the cup to a small notebook on the right.
Suggested elements: glued cup / visible cracks / tiny pen / crossed-out pointing finger / notebook
German handwritten labels: "Was ist passiert?" / "Warum?" (blue) / "Schuldige suchen" (red, crossed out) / "nie wieder so" (orange)
```

---

## Prüfen nach dem Generieren

- Ist Xiaohei die handelnde Figur und nicht nur Deko?
- Weißer Hintergrund, viel Leerraum, kein PPT-Look, kein Titel oben links?
- Deutsche Labels richtig geschrieben? Sonst neu generieren oder Labels reduzieren.
