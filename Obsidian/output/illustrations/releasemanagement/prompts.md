---
title: "Releasemanagement – Illustrationen (Shot-List & Prompts)"
created: 2026-10-28
type: output
tags:
  - illustration
  - releasemanagement
  - xiaohei
---

# Releasemanagement – Shot-List & Prompts

Zu [[releasemanagement|Releasemanagement]]. Stil: Skill `/007`. Jeden Prompt **einzeln** in ein Bildmodell geben (ChatGPT / GPT-Image, Gemini, Midjourney …); Ergebnisse hier ablegen.

| # | Datei | Nach Abschnitt | Kernaussage | Struktur | Was Xiaohei tut | Status |
|---|---|---|---|---|---|---|
| 1 | `01-schleusen.png` | Der Weg einer Version | Eine Version steigt Stufe für Stufe von Test bis Produktion | Workflow | kurbelt Schleusentore, ein Boot „v2.4“ steigt Kammer für Kammer | **stark** |
| 2 | `02-zahlenschloss.png` | Versionsnummern | MAJOR ist schwer zu drehen, PATCH ganz leicht | Konzept-Metapher | stemmt sich gegen das große Rad eines Zahlenschlosses, das kleine dreht er mit dem Finger | **stark** |
| 3 | `03-kanarienvogel.png` | Ausroll-Strategien → Canary | Erst 5 % der Nutzer, dann alle | Vorher/Nachher | lässt einen Vogelkäfig in einen Schacht, hinter ihm wartet eine Menschenschlange | **stark** |
| 4 | `04-drachen-zurueckholen.png` | Phase 8: Rollback | Ein Release muss jederzeit zurückholbar sein | Konzept-Metapher | kurbelt einen abstürzenden Drachen an der Schnur zurück | optional |
| 5 | `05-go-no-go-waage.png` | Phase 5: Freigabe | Go/No-Go ist eine Abwägung | Konzept-Metapher | balanciert auf einer Waage zwischen „neue Funktionen“ und „offene Bugs“ | optional |

---

## Gemeinsamer Stilblock

In jeden Prompt an der markierten Stelle einsetzen:

```text
Visual DNA:
Pure white background. Minimalist black hand-drawn line art. Slightly wobbly pen lines. Lots of empty white space. Sparse red/orange/blue handwritten German annotations. Clean absurd product-sketch feeling. No gradients, no shadows, no paper texture, no complex background, no commercial vector style, no PPT infographic look, no cute mascot poster, no children's illustration, no realistic UI.

Recurring IP character required:
Xiaohei (小黑), a small solid-black absurd creature with white dot eyes, tiny thin legs, blank serious expression, slightly uneven hand-drawn body shape. Xiaohei must perform the core conceptual action, not decorate the scene. Serious, deadpan, slightly bizarre, not cute.

Color use:
Black for main line art and Xiaohei. Orange for main flow/path/arrows. Red only for key warnings/problems/results. Blue only for secondary notes or system state.

Constraints:
One image explains only one core structure. Main subject around 40%-60% of the canvas. At least 35% blank white space. At most 5-8 short handwritten German labels, spelled exactly as given. No title in the top-left corner. Do not write the structure type on the image. Not a formal diagram, course slide, or dense explainer. Clear but not instructional, interesting but not childish, strange but clean.
```

---

## 1 · Schleusen

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: The path of a software release from code to users.
Structure type: workflow.
Core idea: A new version does not jump to production; it is lifted step by step through test, staging and approval, like a boat through canal locks.
Composition: A simple hand-drawn canal running from lower left to upper right with three lock chambers, each a step higher. A small paper boat with "v2.4" written on its sail sits in the middle chamber. Xiaohei stands on the lock wall, deadpan, turning a big crank wheel that opens the next gate; water pours in as a few wobbly lines. At the top right the canal ends at a tiny crowd of stick-figure users. Orange arrow follows the canal upward. Lots of empty white space top-left and bottom-right.
Suggested elements: lock chambers / crank wheel / paper boat / small user crowd
German handwritten labels: "Test" / "Staging" / "Freigabe" / "Nutzer" / "Stufe für Stufe" (orange)
```

## 2 · Zahlenschloss

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Semantic versioning (MAJOR.MINOR.PATCH).
Structure type: concept metaphor.
Core idea: The three numbers of a version have very different weight: changing MAJOR is heavy and breaks things, PATCH is tiny and easy.
Composition: A large old combination lock lying on its side in the center with three number wheels showing "2 . 4 . 1". The left wheel is huge and heavy, the middle wheel medium, the right wheel tiny. Xiaohei pushes against the huge left wheel with its whole body, legs straining, deadpan; at the same time one thin arm casually flicks the tiny right wheel with one finger. Small red cracks next to the big wheel. Orange curved arrows show the turning direction.
Suggested elements: giant combination lock / three wheels of different size / cracks
German handwritten labels: "MAJOR – bricht was" (red) / "MINOR – neu" / "PATCH – Fix" / "schwer" / "leicht" (blue)
```

## 3 · Kanarienvogel

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Canary release.
Structure type: before/after (first few, then all).
Core idea: A new version is first given to a small share of users; only if nothing goes wrong does everyone get it.
Composition: In the center a simple vertical mine shaft drawn as two wobbly lines going down. Xiaohei kneels at the edge and very carefully lowers a small birdcage on a rope into the shaft; inside the cage a tiny bird holds a little flag "v2.4". Behind Xiaohei on the right, a long queue of tiny stick-figure users waits behind a rope barrier. A blue dotted line from the cage up to a small dial on Xiaohei's side, needle in the safe zone.
Suggested elements: mine shaft / birdcage on rope / waiting user queue / small dial
German handwritten labels: "erst 5 %" (orange) / "alles ok?" (blue) / "dann alle" (orange) / "warten" 
```

## 4 · Drachen zurückholen

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Rollback.
Structure type: concept metaphor.
Core idea: Every release needs a way back; when it crashes, you pull it back to the last good version.
Composition: A kite with "v2.4" on it tumbles in the upper right, drawn with a few red scribbles of trouble. A long string runs down to Xiaohei in the lower left, who stands firmly and rapidly cranks a large fishing-reel-like spool, deadpan. On the ground next to Xiaohei lies a neatly folded older kite labelled "v2.3". Orange arrow along the string pointing back to Xiaohei.
Suggested elements: falling kite / string / big reel / folded old kite
German handwritten labels: "stürzt ab" (red) / "zurückholen" (orange) / "v2.3 bereit" (blue) / "Plan B"
```

## 5 · Go/No-Go-Waage

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Release approval (go/no-go decision).
Structure type: concept metaphor.
Core idea: Releasing is a weighing decision between the value of new features and the risk of open bugs.
Composition: A large old-fashioned beam balance in the center. Left pan: a few small gift-box shaped objects. Right pan: a handful of tiny bugs (insects) drawn as scribbly dots with legs. Xiaohei stands on top of the balance beam in the middle, arms out, balancing like a tightrope walker, deadpan, looking down at the needle. The needle points slightly toward the gift side.
Suggested elements: beam balance / gift boxes / small bugs / needle
German handwritten labels: "neue Funktionen" / "offene Bugs" (red) / "Go?" (orange) / "No-Go?" (blue)
```

---

## Prüfen nach dem Generieren

- Ist Xiaohei die handelnde Figur und nicht nur Deko?
- Weißer Hintergrund, viel Leerraum, kein PPT-Look, kein Titel oben links?
- Deutsche Labels richtig geschrieben (Umlaute: „stürzt“, „zurückholen“)? Sonst neu generieren oder Labels reduzieren.
