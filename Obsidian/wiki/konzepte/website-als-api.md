---
title: Website-als-API
created: 2026-10-31
type: konzept
aliases:
  - Website als API
tags:
  - agenten
  - web
  - automatisierung
---

# Website-als-API

Ansatz, eine Website ohne offizielle Schnittstelle so zu behandeln, als hätte sie eine: Man beobachtet, welche HTTP-Anfragen das **eigene Frontend** der Seite stellt, macht daraus eine parametrisierte Vorlage und ruft diese künftig direkt auf – ohne Browser, ohne Klicks, ohne Screenshot-Auswertung.

Referenzimplementierung: [[api-anything|API Anything]].

## Warum?

Ein Agent, der eine Seite per Browser bedient, zahlt jeden Schritt (Laden, Klicken, Lesen) mit Zeit und Tokens. Ein einzelner HTTP-Request liefert dieselben Daten oft in 0,1–1 s als JSON.

## Bausteine

| Baustein | Erklärung |
|---|---|
| **Differenz-Lernen** | Seite wird mit zwei Beispielwerten geladen; was sich zwischen den Requests unterscheidet, wird zum Parameter („Slot“). Der Rest bleibt Byte für Byte erhalten. |
| **Holdout-Prüfung** | Ein dritter, ungesehener Wert prüft, ob die Operation verallgemeinert. Liefert Beispiel 2 die Daten von Beispiel 1, gilt die Operation als `unproven`. |
| **Transport-Tiers** | Tier 1: reiner HTTP-Request. Höhere Tiers: Fetch aus Browser-Kontext, schließlich vollständiges Rendern. Es wird nur so weit eskaliert wie nötig. |
| **Credential-Referenzen** | Vorlagen speichern `cookie:name` statt Werten; Sessions kommen aus dem lokalen Browserprofil. |
| **Selbstheilung** | Bei „Drift“ (geänderte Felder, rotierte IDs) wird neu gelernt und erst nach erfolgreichem Replay gespeichert. |
| **Crowd-Verifikation** | Jeder Aufruf ist ein Report; Operationen werden durch erfolgreiche Nutzung aus mehreren Netzen „live“ und durch gehäufte Fehler ersetzt. |

## Abgrenzung

- **Scraping**: liest gerendertes HTML; Website-als-API nutzt bevorzugt die strukturierten (meist JSON-)Antworten, die das Frontend ohnehin abruft.
- **Browser-Agenten**: steuern UI-Elemente; hier wird die UI nur einmal zum Lernen benutzt.
- **Offizielle APIs / MCP-Server**: haben Vorrang, wenn vorhanden – API Anything zeigt sie in der Suche neben gelernten Operationen an.

## Risiken

- Nutzungsbedingungen der Seite können automatisierten Zugriff untersagen.
- Geteilte Vorlagen sind fremder Code/fremde Daten → Domain prüfen, Schreibzugriffe nur explizit erlauben.
- Bot-Schutz und CAPTCHAs setzen Grenzen.

## Siehe auch

- [[api-anything|API Anything]]
- [[Agenten-OS]]
- [[api-anything-github]] (Quelle)
