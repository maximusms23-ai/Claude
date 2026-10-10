---
title: Apple-Firmware für WLAN und Bluetooth beschaffen
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, firmware, brcmfmac]
---

# Apple-Firmware für WLAN und Bluetooth

## 1. Ergebnis zuerst

Dieses Paket enthält **keine** Apple-Firmware.
Die Firmware gehört Apple. Sie ist nicht frei weitergebbar.
Der Ordner `verified/` ist deshalb leer.

Daraus folgt: Die Offline-Installation ist **PARTIAL**.
Für WLAN und Bluetooth brauchst du einmalig eine Internetverbindung.

## 2. FRAGESTELLUNG

Wie kommt die Firmware auf das MacBook, wenn macOS entfernt ist?

## 3. UMSETZUNG

### 3.1 Warum Methode 5

Das offizielle Werkzeug kennt fünf Methoden.

| Methode | Voraussetzung | Für dieses Gerät |
| --- | --- | --- |
| 1 bis 3 | macOS muss laufen | nicht möglich |
| 4 | macOS muss auf der Platte liegen | nicht möglich |
| 5 | Internetverbindung | **einzige Möglichkeit** |

Methode 5 lädt ein macOS-Wiederherstellungsabbild von Apple.
Sie entnimmt daraus die Firmwaredateien.
macOS wird dabei **nicht** installiert.

### 3.2 Was das Paket mitbringt

| Datei | Zweck | Prüfsumme in |
| --- | --- | --- |
| Paket `apple-firmware-script` 1.4-3 | liefert den Befehl `get-apple-firmware` | `packages/SHA256SUMS.debs` |
| `tools/fetch-macOS-v2.py` | lädt das Abbild von Apple | `tools/SHA256SUMS` |
| `tools/firmware.sh.reference` | Lesefassung des Werkzeugs zur Prüfung | `tools/SHA256SUMS` |
| Pakete `curl`, `dmg2img`, `python3` | Abhängigkeiten der Methode 5 | `packages/SHA256SUMS.debs` |

Das Werkzeug wurde vor der Aufnahme gelesen und bewertet.
Ergebnis der Prüfung:

- Es lädt genau zwei Dinge aus dem Netz: das Hilfsskript `fetch-macOS-v2.py`
  und das Wiederherstellungsabbild von den Apple-Servern.
- Es schreibt die Firmware nach `/lib/firmware/brcm`.
- Es verändert weder Partitionen noch EFI noch NVRAM.
- Das Hilfsskript stammt aus dem Projekt OpenCorePkg (`macrecovery`).
  Es ist in `tools/` mit festgelegter Prüfsumme hinterlegt.

### 3.3 Arbeitsschritte auf dem MacBook

Voraussetzung: Der T2-Kernel läuft. Die Installation ist abgeschlossen.

1. Verbinde das iPhone per USB. Aktiviere das Tethering.
2. Prüfe die Verbindung:

   ```bash
   ping -c 3 archive.ubuntu.com
   ```

3. Prüfe die Prüfsummen der Werkzeuge:

   ```bash
   cd firmware/tools
   sha256sum -c SHA256SUMS
   ```

4. Stelle das Hilfsskript bereit. So lädt das Werkzeug es nicht erneut:

   ```bash
   sudo mkdir -p /root/firmware-work
   sudo cp fetch-macOS-v2.py /root/firmware-work/
   ```

5. Starte das Werkzeug:

   ```bash
   sudo get-apple-firmware
   ```

6. Wähle: **"Download a macOS Recovery Image from Apple and extract the
   firmware from there"**.
7. Wähle eine macOS-Fassung zwischen **Monterey** und **Sonoma**.
   Nur diese Fassungen enthalten vollständige Firmwaredateien.
8. Warte. Der Download umfasst mehrere Hundert Megabyte.
9. Starte das Gerät neu.

### 3.4 Erfolg prüfen

```bash
ls -l /lib/firmware/brcm/brcmfmac*
sudo journalctl -k --grep=brcmfmac
```

Erwartete Meldung:

```
brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4377/4 wl0: ...
brcmfmac 0000:01:00.0 wlp1s0f0: renamed from wlan0
```

Meldungen mit `Direct firmware load for ... failed with error -2` sind normal.
Das Werkzeug probiert mehrere Dateinamen durch.
Entscheidend ist die Zeile mit `Firmware: BCM...`.

Prüfe danach:

```bash
nmcli device status
sudo iw dev
bluetoothctl show
```

### 3.5 Firmware sichern

Sichere die Firmware danach auf die Samsung T7.
Dann brauchst du den Download nicht erneut.

```bash
sudo tar -C /lib/firmware -czf <T7-Pfad>/apple-firmware-backup.tar.gz brcm
```

Diese Sicherung ist deine persönliche Kopie.
Gib sie nicht weiter.

## 4. MEHRWERT

Du kennst den einzigen gültigen Weg für ein Gerät ohne macOS.
Du prüfst jedes Werkzeug vor dem Start gegen eine Prüfsumme.
Du lädst das Abbild nur einmal.

## 5. Grenzen

| Grenze | Folge |
| --- | --- |
| Rechtlich | Apple-Firmware darf nicht mitgeliefert werden. |
| Technisch | Der Download benötigt eine Internetverbindung. |
| Modellbezogen | Für iMac19,1, iMac19,2 und iMacPro1,1 funktioniert Methode 5 nicht. Das Zielgerät ist nicht betroffen. |
