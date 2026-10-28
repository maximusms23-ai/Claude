---
title: "Releasemanagement"
created: 2026-10-28
type: konzept
aliases:
  - Release Management
  - Release-Management
tags:
  - softwareentwicklung
  - devops
  - deployment
---

# Releasemanagement

**Releasemanagement** regelt, wie eine neue Software-Version vom fertigen Code sicher zu den Nutzern kommt: geplant, geprüft, nachvollziehbar und jederzeit rückholbar. Es beantwortet vier Fragen: *Was* kommt in die Version, *wann* geht sie raus, *an wen* zuerst, und *was tun*, wenn es schiefgeht?

## Der Weg einer Version

![[01-schleusen.png]]
*Xiaohei kurbelt die Version v2.4 Schleuse für Schleuse von Test über Staging und Freigabe zu den Nutzern.*

| Phase | Was passiert | Typische Werkzeuge |
|---|---|---|
| 1. Planen | Umfang festlegen, Termin, Verantwortliche | Issues, Roadmap, Milestones |
| 2. Bauen | Code zusammenführen, Build erzeugen | Git-Branch/Tag, CI |
| 3. Testen | automatische Tests, manuelle Abnahme | CI, QA |
| 4. Staging | Probelauf in einer produktionsnahen Umgebung | Staging-Server |
| 5. Freigabe | Go/No-Go-Entscheidung | Checkliste, Approval |
| 6. Ausrollen | Version an Nutzer verteilen | Deployment, App-Store, Paket |
| 7. Beobachten | Fehler, Last, Feedback überwachen | Logs, Monitoring |
| 8. Rollback | bei Problemen auf alte Version zurück | vorheriger Tag, Feature-Flag aus |

Dazu gehören **Release Notes / Changelog**: was ist neu, was ist kaputt gegangen, was muss der Nutzer tun.

## Versionsnummern (Semantic Versioning)

![[02-zahlenschloss.png]]
*MAJOR ist schwer zu drehen und bricht etwas, PATCH dreht man nebenbei.*

Format `MAJOR.MINOR.PATCH`, z. B. `2.4.1`:

- **MAJOR** (`3.0.0`) — inkompatible Änderung, Nutzer müssen etwas anpassen
- **MINOR** (`2.5.0`) — neue Funktion, rückwärtskompatibel
- **PATCH** (`2.4.2`) — Fehlerbehebung

Alternative: Kalender-Versionen (CalVer) wie `2026.403.0` bei [[PaperclipAI]].

## Ausroll-Strategien

![[03-kanarienvogel.png]]
*Canary Release: erst 5 % der Nutzer, dann alle.*

- **Big Bang** — alle bekommen die neue Version gleichzeitig. Einfach, aber riskant.
- **Canary Release** — erst ein kleiner Teil der Nutzer (z. B. 5 %), dann schrittweise mehr. Benannt nach dem Kanarienvogel im Bergwerk, der Gefahr früh anzeigt.
- **Blue-Green** — zwei identische Umgebungen; umgeschaltet wird per Weiche, zurück genauso schnell.
- **Feature Flags** — Code ist schon ausgeliefert, die Funktion wird aber erst per Schalter freigegeben.

## Rollen

![[05-waage.png]]
*Go/No-Go: neue Funktionen gegen offene Bugs abwägen.*

Release Manager (koordiniert, entscheidet Go/No-Go), Entwickler, QA (prüft), Betrieb/DevOps (rollt aus, beobachtet). In [[Agenten-OS|Maximus_OS]] bilden Staff Engineer → QA Engineer → Release Engineer genau diese Kette unter dem CTO ab.

## Typische Fehler

![[04-drachen.png]]
*Ohne Rollback-Plan kein Release: v2.4 stürzt ab, v2.3 liegt bereit.*

- Kein Rollback-Plan („geht schon gut“)
- Zu große Releases: viele Änderungen auf einmal, Fehlerursache schwer zu finden
- Freitagnachmittag-Deployments
- Release Notes fehlen, Nutzer werden überrascht

## Illustrationen

Shot-List und Bild-Prompts im Xiaohei-Stil: `output/illustrations/releasemanagement/prompts.md` (Skill `/007`).

## Siehe auch

- [[Incident-Management]] — was passiert, wenn ein Release Probleme macht
- [[Agenten-OS]] — Release Engineer als Agent in Maximus_OS
- [[PaperclipAI]] — Beispiel für Kalender-Versionierung
