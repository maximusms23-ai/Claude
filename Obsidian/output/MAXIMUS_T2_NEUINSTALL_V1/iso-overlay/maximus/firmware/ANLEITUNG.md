---
title: Apple-Firmware sichern und übernehmen
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, firmware, wlan, bluetooth]
---

# Apple-Firmware sichern und übernehmen

## Warum

WLAN und Bluetooth des MacBookPro16,1 brauchen eine Firmware von Apple.
Diese Firmware ist **nicht frei weitergebbar**. Sie liegt deshalb **nicht**
in diesem Paket und **nicht** in einem öffentlichen Repositorium.

Du musst sie selbst aus deinem Gerät holen.

## Grundregel

**Hole die Firmware, BEVOR du macOS löschst.**

Nach dem Löschen geht es nur noch über ein Kabelnetz und ein
Wiederherstellungsabbild von Apple. Das ist langsamer und braucht Netz.

## Weg 1: aus dem vorhandenen macOS (empfohlen)

Dieser Weg braucht kein Netz.

1. Starte von der Samsung T7.
2. Wähle **"Try or Install Ubuntu"**. Das ist das Live-System.
3. Öffne ein Terminal.
4. Führe aus:

   ```bash
   sudo get-apple-firmware get_from_macos
   ```

5. Die Dateien landen in `/lib/firmware/brcm`.
6. **Sichere sie sofort auf einen Datenträger, der NICHT die T7 ist:**

   ```bash
   mkdir -p /pfad/zur/sicherung/brcm
   sudo cp -a /lib/firmware/brcm/. /pfad/zur/sicherung/brcm/
   sha256sum /pfad/zur/sicherung/brcm/* > /pfad/zur/sicherung/brcm.sha256
   ```

7. Prüfe die Vollständigkeit:

   ```bash
   ls /pfad/zur/sicherung/brcm | wc -l
   sha256sum -c /pfad/zur/sicherung/brcm.sha256
   ```

## Weg 2: aus einem Wiederherstellungsabbild von Apple

Dieser Weg braucht ein **Kabelnetz**. WLAN geht ja noch nicht.
Als Kabelnetz reicht die USB-Verbindung zu einem iPhone.

```bash
sudo get-apple-firmware get_from_online
```

## Die Firmware ins Installationsmedium übernehmen

Lege die geprüften Dateien vor dem Bau des Mediums hierhin:

```
iso-overlay/maximus/firmware/verified/
```

Das Skript `postinstall.sh` kopiert sie dann in das Zielsystem nach
`/lib/firmware/brcm`.

**Prüfe vorher die Prüfsummen.** Eine falsche Firmware kann den Treiber
zum Absturz bringen.

## Was tun ohne Firmware

Die Installation läuft auch ohne Firmware durch. WLAN und Bluetooth bleiben
dann ohne Funktion. Der Funktionsbericht meldet das als `FEHLGESCHLAGEN`.

Du kannst die Firmware nach dem ersten Start nachholen:

```bash
sudo get-apple-firmware get_from_macos     # nur mit vorhandenem macOS
sudo get-apple-firmware get_from_online    # mit Kabelnetz
```

## Hinweis zum Repositorium

Lade diese Dateien **nicht** in ein öffentliches Repositorium.
Das Verzeichnis `verified/` ist in `.gitignore` eingetragen.
