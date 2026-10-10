---
title: Apple-Firmware brcmfmac
aliases:
  - Apple-Firmware brcmfmac
  - brcmfmac
created: 2026-10-10
type: konzept
tags:
  - t2linux
  - wlan
  - bluetooth
  - firmware
---

# Apple-Firmware brcmfmac

`brcmfmac` ist der Linux-Treiber fuer Broadcom-Funkchips.
Er ist im Hauptzweig des Kernels enthalten.
Er braucht aber eine Firmwaredatei. Diese Datei stammt von Apple.

## Warum die Firmware fehlt

Apple liefert die Firmware nur mit macOS aus.
Sie ist nicht frei weitergebbar.
Linux-Distributionen duerfen sie deshalb nicht mitliefern.

Ohne Firmware gilt:

- Es entsteht keine WLAN-Schnittstelle.
- Es entsteht kein Bluetooth-Adapter.

## Chips nach Modell

| Modell | Funkchip | Firmware noetig |
| --- | --- | --- |
| Macs 2018 | BCM4364 | ja |
| Macs 2019 und 2020 | BCM4377 | ja |

Beim MacBookPro16,1 ist BCM4377 zu erwarten.
Pruefe den Chip so:

```bash
lspci -nn | grep -i network
sudo journalctl -k --grep=brcmfmac
```

## Fuenf Bezugswege

Das offizielle Werkzeug heisst `get-apple-firmware`.
Es kommt aus dem Paket `apple-firmware-script`, siehe [[t2-ubuntu-repo]].

| Methode | Voraussetzung |
| --- | --- |
| 1 | macOS laeuft, Firmware wird auf die EFI-Partition gelegt |
| 2 | macOS laeuft, Firmware wird als Archiv erzeugt |
| 3 | macOS laeuft, Firmware wird als Paket erzeugt |
| 4 | macOS liegt auf der Platte, wird direkt gelesen |
| 5 | kein macOS noetig, Wiederherstellungsabbild wird geladen |

Methode 5 ist der einzige Weg ohne macOS.
Sie braucht eine Internetverbindung.
Sie laedt ein Wiederherstellungsabbild von Apple.
macOS wird dabei nicht installiert.
Waehle eine Fassung zwischen Monterey und Sonoma.
Nur diese Fassungen enthalten vollstaendige Firmwaredateien.

## Bluetooth-Einschraenkung

Bei BCM4377 stoert eine 2,4-GHz-WLAN-Verbindung die Bluetooth-Verbindung.
Zwei Abhilfen sind bekannt:

1. Nutze ein 5-GHz-WLAN.
2. Schalte WLAN ab, solange Bluetooth benoetigt wird.

## Verweise

- Thema: [[T2Linux]]
- Projekt: [[MAXIMUS T2 Installer]]
- Quelle: [[t2linux-wiki]]
