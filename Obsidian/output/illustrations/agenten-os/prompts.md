---
title: "Agenten-OS – Illustrationen (Shot-List & Prompts)"
created: 2026-10-27
type: output
tags:
  - illustration
  - agenten
  - xiaohei
---

# Agenten-OS – Shot-List & Prompts

Zu [[agenten-os|Agenten-OS]]. Stil: Skill `/007` (Xiaohei, 16:9, weißer Grund, Handzeichnung, wenige rot/orange/blaue Notizen).
Jeden Prompt **einzeln** in ein Bildmodell geben (ChatGPT / GPT-Image, Gemini, Midjourney …). Ergebnisse hier ablegen als `01-hausverwaltung.png` usw.

| # | Datei | Nach Abschnitt | Kernaussage | Struktur | Was Xiaohei tut | Status |
|---|---|---|---|---|---|---|
| 1 | `01-hausverwaltung.png` | Einleitung | Das OS verwaltet Agenten wie eine Hausverwaltung ihre Mieter | Konzept-Metapher | hängt als Hausmeister am Schlüsselbund und verteilt Schlüssel & Post an die Fenster | **stark** |
| 2 | `02-wecker-statt-zettelchaos.png` | Die fünf Aufgaben → 1 | Ohne OS: Chaos; mit OS: Agenten werden der Reihe nach geweckt | Vorher/Nachher | links unter Zetteln begraben, rechts zieht er eine riesige Wecker-Kurbel | **stark** |
| 3 | `03-kontext-und-keller.png` | Die fünf Aufgaben → 2 | Kontextfenster ist klein, Langzeitgedächtnis liegt im Keller | System-Ausschnitt | schleppt Kisten die Kellertreppe hoch, nur eine passt auf den kleinen Tisch | **stark** |
| 4 | `04-drehkreuz-und-budget.png` | Die fünf Aufgaben → 4 | Rechte und Budget werden am Eingang geprüft | Konzept-Metapher | Pförtner am Drehkreuz, wirft Münzen in ein Glas, hält einem Agenten die Hand vor | optional |
| 5 | `05-maximus-mobile.png` | Beispiel: Maximus_OS | Die Agenten-Hierarchie muss im Gleichgewicht bleiben | Methoden-Schichten | steht auf einer Leiter und balanciert ein Mobile mit CEO oben | optional |

---

## Gemeinsamer Stilblock

Wird in jeden Prompt unten bereits eingesetzt:

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

## 1 · Hausverwaltung

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: What an agent operating system is.
Structure type: concept metaphor.
Core idea: An agent OS manages AI agents the way a building caretaker manages tenants: it hands out keys (permissions) and mail (tasks), and knows who lives where.
Composition: A tall, narrow, slightly crooked hand-drawn apartment building in the center-left, with 5 small windows. In each window a simple box-shaped "agent" with a tiny role sign. Xiaohei hangs from a huge oversized key ring on a rope in front of the building, deadpan, pushing a letter into one window with one thin arm while holding a key towards another. An orange arrow runs from a mailbag at the bottom up to the windows. Large empty white space on the right.
Suggested elements: crooked building / windows with agents / giant key ring / mailbag / letters
German handwritten labels: "Agenten" / "Schlüssel = Rechte" / "Post = Aufgaben" / "Hausmeister = OS"
```

## 2 · Wecker statt Zettelchaos

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Without an agent OS vs. with an agent OS (scheduling).
Structure type: before/after.
Core idea: Without an OS, every agent is a separate chat that starts from zero and the human drowns in notes. With an OS, agents are woken up one after another when it's their turn.
Composition: Left half: Xiaohei almost buried under a messy pile of sticky notes and 4 floating chat bubbles, only the white dot eyes and thin legs visible. Single orange arrow in the middle pointing right. Right half: Xiaohei calmly turning a giant crank on an oversized old alarm clock; from the clock, thin orange lines go to 3 sleeping box-shaped agents, one of them is awake and has a small "!" above it.
Suggested elements: sticky-note pile / chat bubbles / giant alarm clock with crank / sleeping agents
German handwritten labels: "ohne OS" / "alles neu erklären" (red) / "mit OS" / "wecken, wenn dran" / "schläft" (blue)
```

## 3 · Kontext und Keller

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Memory management in an agent OS.
Structure type: system detail.
Core idea: The context window is a tiny desk; long-term memory is a big cellar archive. The OS decides which box goes up to the desk right now.
Composition: Upper part: a very small desk with one box-shaped agent sitting at it, the desk only has room for one box. A steep hand-drawn staircase leads down to a cellar in the lower part, full of stacked cardboard boxes. Xiaohei is halfway up the staircase, carrying one box that is clearly too heavy, deadpan. One other box is falling off the desk edge back down. Orange arrow along the staircase upward, small blue arrow downward.
Suggested elements: tiny desk / staircase / cellar with boxes / falling box
German handwritten labels: "Kontext" / "Langzeitgedächtnis" / "nur das Nötige" (orange) / "vergessen?" (red) / "zurück ins Archiv" (blue)
```

## 4 · Drehkreuz und Budget

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: Permissions and budget in an agent OS.
Structure type: concept metaphor.
Core idea: Before an agent may use a tool, the OS checks permission and budget, and asks a human for risky actions.
Composition: A simple turnstile in the center. Behind it on a low shelf: a hammer, an envelope, a coin. In front of it two box-shaped agents queue. Xiaohei stands at the turnstile as a gatekeeper, one thin arm raised flat towards the second agent (stop), with the other arm dropping a coin into a nearly empty glass jar. The first agent passes through along an orange arrow towards the envelope. Small red bell next to the jar.
Suggested elements: turnstile / tool shelf / coin jar / bell / queue of agents
German handwritten labels: "darf" (orange) / "darf nicht" (red) / "Budget" / "Mensch fragen" (blue)
```

## 5 · Maximus-Mobile

```text
Generate one standalone 16:9 horizontal German article illustration.

[Gemeinsamer Stilblock einfügen]

Theme: An example agent company (Maximus_OS) with a role hierarchy.
Structure type: layered method.
Core idea: Agents are organized like a team: a CEO on top, a CTO with engineers below, researchers on the side. The OS keeps this hierarchy in balance.
Composition: A hanging baby-mobile made of thin sticks and strings, slightly tilted. Top: a small box agent with a crown-like paper hat. One branch: a box agent with a wrench and 3 tiny boxes hanging below it. Other branch: 3 box agents with magnifying glasses/books. Xiaohei stands on a wobbly step ladder on the right, very carefully adding a tiny weight to the lighter side with tweezers, deadpan. Orange curved arrows show the tasks going down the strings; one blue arrow shows a report going up.
Suggested elements: mobile / step ladder / tweezers / small weight
German handwritten labels: "CEO" / "CTO" / "Wiki-Kurator" / "Aufgaben ↓" (orange) / "Bericht ↑" (blue) / "im Gleichgewicht halten" (red)
```

---

## Prüfen nach dem Generieren

- Ist Xiaohei die handelnde Figur und nicht nur Deko?
- Weißer Hintergrund, viel Leerraum, kein PPT-Look, kein Titel oben links?
- Sind die deutschen Labels richtig geschrieben? Wenn nicht: neu generieren oder weniger Labels verwenden.
