---
title: "ADR-003: obsidian-ocr Koexistenz mit tom-doc"
created: 2026-04-10
type: adr
status: accepted
tags: [adr, obsidian, ocr, tom-doc, v1.4.1]
---

# ADR-003: `obsidian-ocr` Koexistenz mit `tom-doc`

**Status:** Accepted
**Date:** 2026-04-10
**Milestone:** v1.4.1 (Phase 34 — Plugin-Audit)
**Deciders:** Maxim, Tom

## Context

Im v1.4.1-Plugin-Audit wurde `obsidian-ocr` v2.0.1 (Jonas Mohr) als eines der 17 neu installierten Plugins erfasst. Das Plugin fügt Obsidian OCR-Fähigkeiten hinzu — d.h. es liest PDFs oder Bilder im Vault und hinterlegt die extrahierten Texte typischerweise in einer plugin-eigenen SQLite-DB oder als Sidecar-Files.

Tom betreibt bereits eine eigene OCR-Pipeline (`tom-doc`, Phase 27/28 v1.4):

- Quellen: `~/Downloads/Archiv/` (via `$TOM_VAULT/Archiv` Symlink) + `$TOM_VAULT/raw/`
- OCR-Toolchain: `pdftotext` (first) → `ocrmypdf+tesseract` (fallback)
- Index: SQLite FTS5 in `/Users/maxim/Claude/archivum/db/archivum.db`
- OCR-Cache: `/Users/maxim/Claude/archivum/ocr-cache/<sha256>.txt`
- CLI: `bin/tom-doc index|search|list|show`

Frage: Sollen beide OCR-Pipelines parallel laufen, oder schließen sie sich aus?

## Decision

**Koexistenz mit klarer Aufgabenteilung:**

- **`tom-doc` bleibt Primary** für Batch-Indexing und Volltext-Suche über das komplette Archiv. Der FTS5-Index ist die Quelle der Wahrheit für `tom-doc search` und alle Tom-Workflows.
- **`obsidian-ocr` ist Ad-hoc-Tool im Editor** — für einzelne Seiten, schnelle Handschrift-Erkennung oder Quick-Extract aus einem Bild im aktuellen Note-Kontext.
- **Schreibgrenze:** `obsidian-ocr` darf **NICHT** Files nach `~/Downloads/Archiv/`, `/Users/maxim/Claude/archivum/db/` oder `/Users/maxim/Claude/archivum/ocr-cache/` schreiben. Wenn das Plugin das versucht (per Symlink-Traversal oder expliziter Pfad-Angabe), muss es deaktiviert werden.
- **Index-Kollision vermeiden:** Wenn `obsidian-ocr` einen eigenen Index anlegt, lebt der innerhalb von `.obsidian/plugins/obsidian-ocr/` und bleibt plugin-intern. Kein Cross-Write in Tom's FTS5-DB.

## Rationale

- `tom-doc` hat validiertes Privacy-Modell (DB liegt im Repo-Bereich, nicht im iCloud-Vault, SHA256-basierte Idempotenz).
- `obsidian-ocr` hat Vorteile im Editor-Kontext (keine CLI nötig, sofortige Anzeige im aktuellen Note).
- Statt eines Plugins auszuschließen, nutzen wir beide für das, wofür sie gut sind: Batch-Pipeline + Ad-hoc-Editor-OCR.
- Die Schreibgrenze verhindert, dass zwei Systeme denselben Zustand verwalten und dabei driften.

## Consequences

- Maxim hat zwei OCR-Wege: `tom-doc` für "ich suche einen bestimmten Brief von Amt X" und `obsidian-ocr` für "ich habe gerade ein Foto eines Arztberichts eingebettet und brauche den Text im Note".
- Bei jedem `obsidian-ocr`-Update muss geprüft werden, ob neue Features die Schreibgrenze verletzen (z.B. "Export to external folder"-Feature).
- Wenn Maxim nach 2 Wochen feststellt, dass `obsidian-ocr` nie genutzt wird → deaktivieren, installed-but-unused markieren.
- In v1.5+ kann `marker-api` als potenzieller `tom-doc`-Backend-Upgrade geprüft werden (bessere OCR-Qualität als tesseract) — Entscheidung dort berührt ADR-003 nicht, weil es ein Backend-Swap in `tom-doc` ist, nicht ein Plugin-Swap.

## Status-Check

- [x] Plugin installiert, nicht aktiv konfiguriert (v1.4.1 Phase 34)
- [ ] Schreibgrenze empirisch testen wenn Maxim das Plugin aktiviert
- [ ] Re-Review nach 2 Wochen aktiver Nutzung oder nächstem Plugin-Update

## References

- Phase 27 SUMMARY — `tom-doc`-Pipeline
- CLAUDE.md "Obsidian Plugin Landscape"
- `plugin-audit-v1.4.1.md` — 17-Plugin-Tabelle Zeile 13
