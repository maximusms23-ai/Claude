---
description: Deliverable aus der Wissensbasis bauen (Slides, Plot, Report, Canvas)
argument-hint: <slides|plot|report|canvas> <Thema>
---

Baue dieses Deliverable: $ARGUMENTS

Starte den Agenten `output-builder`. Zielorte und Formate:

| Art | Format | Ziel |
|-----|--------|------|
| slides | Marp (`marp: true`) | `Obsidian/output/slides/` |
| plot | Python/matplotlib + PNG | `Obsidian/output/plots/` |
| report | Markdown mit Frontmatter | `Obsidian/output/reports/` |
| canvas | JSON Canvas | `Obsidian/output/canvas/` |

Ist die Art nicht genannt, leite sie aus dem Thema ab und sag, welche du gewaehlt hast. Inhalt kommt aus der Wissensbasis — fehlt Material, benenne die Luecke statt sie zu erfinden.
