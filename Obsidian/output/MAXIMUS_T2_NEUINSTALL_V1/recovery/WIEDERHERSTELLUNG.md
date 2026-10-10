---
title: Wiederherstellung und Rückweg
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, wiederherstellung]
---

# Wiederherstellung und Rückweg

## Das Wichtigste zuerst

**Eine Sicherung einzelner GRUB-Dateien stellt kein gelöschtes macOS wieder her.**

Wenn du macOS löschst, dann brauchst du für den Rückweg:

1. Eine Internetverbindung per **Kabel oder WLAN am Mac selbst**.
2. Die macOS-Internetwiederherstellung (**Command-Option-R** beim Start).
3. Zeit. Das Abbild wird vollständig neu geladen.

Deine **persönlichen Daten** stellt das nicht wieder her.
Dafür brauchst du eine eigene Sicherung.

## Vor dem Löschen: drei Sicherungen

| Was | Warum | Wohin |
| --- | --- | --- |
| Persönliche Daten | Die Installation löscht sie | Ein Datenträger, der **nicht** die T7 ist |
| Apple-Firmware für WLAN und Bluetooth | Ohne macOS ist sie nicht mehr abrufbar | Ein Datenträger, der **nicht** die T7 ist |
| macOS-Wiederherstellungsschlüssel und Apple-ID | Für die Internetwiederherstellung | Papier oder Passwortspeicher |

**Lege die einzige Kopie der Firmware niemals nur auf die T7.**
Die T7 wird beim Erstellen des Mediums überschrieben.

Die Anleitung zur Firmware liegt in `iso-overlay/maximus/firmware/ANLEITUNG.md`.

## Nach einer unvollständigen Installation

Der Assistent legt bei einem Fehler die Datei
`/var/log/maximus-installation-unvollstaendig` an.

Dann gilt:

1. **Starte das Zielsystem nicht.** Es ist nicht startfähig.
2. Lies `/var/log/installer/debug` und
   `/var/log/maximus-t2-neuinstall.log`. Beide liegen im Live-System.
3. Sichere beide Protokolle auf einen anderen Datenträger.
4. Es wird **nichts selbsttätig wiederholt**. Eine Wiederholung würde
   weitere Datenbereiche verändern.

### Erneut versuchen

1. Starte wieder von der T7.
2. Wähle **"Ubuntu mit T2-Unterstützung neu installieren"**.
3. Der Assistent prüft das Ziel erneut und fragt erneut nach der Freigabe.

### Zurück zu macOS

1. Starte mit **Command-Option-R**.
2. Wähle **Festplattendienstprogramm**.
3. Lösche die interne SSD als **APFS**.
4. Beende das Festplattendienstprogramm.
5. Wähle **macOS neu installieren**.

## Wenn der Mac gar nicht mehr startet

1. Halte beim Start die **Wahltaste (⌥)**. Erscheint ein Startmenü,
   dann ist die Firmware in Ordnung.
2. Erscheint nichts, dann setze den NVRAM zurück:
   **Command-Option-P-R** beim Start, vier Töne lang halten.
3. Hilft das nicht, dann ist die Einstellung im
   Startsicherheitsdienstprogramm zu prüfen. Siehe
   `T2-STARTEINSTELLUNGEN.md`.

## Was dieses Paket NICHT kann

- Es stellt kein gelöschtes macOS wieder her.
- Es stellt keine persönlichen Daten wieder her.
- Es kann die Einstellung im T2-Chip nicht setzen.
- Es kann rEFInd nicht ohne macOS installieren.
