---
title: Energieverwaltung und Ruhezustand
created: 2026-10-10
type: referenz
---

# Energieverwaltung und Ruhezustand

## FRAGESTELLUNG

Darf der Ruhezustand beim ersten Start aktiv sein?

## UMSETZUNG

Nein. Das Installationsskript schaltet den selbsttätigen Ruhezustand ab.

Begründung aus den Quellen:

- Der Zustand des T2-Projekts führt **Suspend** als teilweise funktionsfähig.
- Für das MacBookPro16,1 ist ein hängender Ruhezustand über mehrere Minuten
  dokumentiert. Dabei laufen die Lüfter, der Bildschirm bleibt dunkel.
- Für die Kernelreihe 7.2 ist ein Absturz beim Aufwachen aus S3 auf genau
  diesem Modell dokumentiert.
- Die Radeon Pro 5500M kann im Zustand `s2idle` hängen bleiben.

Ein hängender Ruhezustand ist bei diesem Gerät ein Temperaturrisiko.
Das letzte Audit meldete 98 Grad Celsius.

### Standby später prüfen

1. Bestehe zuerst die thermische Abnahme.
2. Sichere alle offenen Dateien.
3. Entferne `/etc/systemd/logind.conf.d/99-maximus-t2-sleep.conf`.
4. Lade die Konfiguration neu: `sudo systemctl restart systemd-logind`.
5. Löse den Ruhezustand bewusst aus: `sudo systemctl suspend`.
6. Warte 60 Sekunden. Wecke das Gerät mit der externen Tastatur.
7. Prüfe das Protokoll: `sudo journalctl -k -b 0 | grep -iE 'pm:|t2bce|amdgpu'`.
8. Bewerte das Ergebnis als PASS, PARTIAL oder FAIL.

### Thermische Grundsicherung

Das Installationsskript aktiviert `t2fanrd`.
Es setzt vorsichtige Werte: Anlauf bei 55 Grad, Volllast bei 80 Grad.

## MEHRWERT

Du vermeidest einen bekannten Datenverlust- und Temperaturpfad.
Die Abschaltung ist eine einzelne Datei und jederzeit umkehrbar.
