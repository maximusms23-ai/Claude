---
title: MAXIMUS T2Linux Offline Installer V4
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, macbookpro16-1, offline-installer]
---

# MAXIMUS T2Linux Offline Installer V4

Installationspaket für Apple MacBookPro16,1 (2019) unter Ubuntu 24.04.5 LTS.

## 1. Ergebnis zuerst

| Status | Wert |
| --- | --- |
| PACKAGE_READY | **erteilt** |
| INSTALLATION_READY | nicht erteilt |
| HARDWARE_READY | nicht erteilt |
| MAXIMUS_WORKER_READY | nicht erteilt |
| Offline-Fähigkeit | **PARTIAL** (die Apple-Firmware fehlt) |

Dieses Paket installiert kein Ubuntu neu.
Es installiert einen Kernel mit Apple-T2-Treibern und die passenden
Konfigurationsdateien.

## 2. Was dieses Paket leistet

| Hardware | Maßnahme |
| --- | --- |
| Apple T2 | Kernel `linux-t2-lts` 6.18.54-1-t2-noble |
| Tastatur, Trackpad, Touch Bar, Kamera | Treiberstapel `t2bce` im Kernel |
| Touch Bar, anpassbar | Dienst `tiny-dfr` 0.3.7-4 |
| WLAN BCM4377 | Treiber `brcmfmac` im Kernel, Firmware über ein Werkzeug |
| Bluetooth | Treiber im Kernel, `bluez` 5.72 |
| Lautsprecher und Mikrofon | `apple-t2-audio-config` 0.5.1 und zwei DSP-Pakete für das 16-Zoll-Modell |
| Lüfter | `applesmc` im Kernel, Dienst `t2fanrd` 0.1.0-4 |
| Intel UHD 630 | `i915` |
| Radeon Pro 5500M | `amdgpu` und Mesa aus Ubuntu noble |
| Energieverwaltung | Ruhezustand bewusst abgeschaltet |

## 3. Vor dem Start lesen

| Thema | Datei |
| --- | --- |
| Welche Quelle wurde wie geprüft | `SOURCE_AUDIT.md` |
| Was funktioniert und was nicht | `COMPATIBILITY_MATRIX.md` |
| Wie das Paket gebaut wurde | `reports/BUILD_REPORT.md` |
| Welche Prüfungen bestanden sind | `reports/PACKAGE_AUDIT.md` |
| Was bei einem Fehlstart zu tun ist | `recovery/GRUB-NOTSTART.txt` |
| Wie du Änderungen zurücknimmst | `recovery/RESTORE.md` |
| Wie du die WLAN-Firmware beschaffst | `firmware/README.md` |

## 4. Zwei Voraussetzungen vor dem ersten Neustart

1. Schließe eine **USB-Tastatur** an.
   Die interne Tastatur arbeitet im GRUB-Menü nicht.
   Der T2-Chip liefert sie erst, wenn Linux läuft.
2. Drucke **`recovery/GRUB-NOTSTART.txt`** aus.
   Ein Live-USB-Medium ist nicht vorhanden.

## 5. Ablauf

### 5.1 Auf dem Baurechner

Voraussetzung: Ubuntu 24.04 (noble) für amd64, echt oder im Container.

```bash
# 1. Paketnutzlast herstellen (etwa 472 MB)
bash scripts/fetch-packages.sh

# 2. Paket prüfen
bash scripts/selftest.sh

# 3. Übertragung simulieren
sudo bash scripts/deploy-to-t7.sh --dry-run

# 4. Übertragen
sudo bash scripts/deploy-to-t7.sh
```

Das Skript `deploy-to-t7.sh` erkennt die Samsung T7 über Modell, Hersteller
und Seriennummer. Es formatiert nicht. Es löscht nicht.
Es bricht ab, wenn die SSD nicht eindeutig erkannt wird.

### 5.2 Auf dem MacBookPro16,1

```bash
# 1. Samsung T7 anschließen und in das Paketverzeichnis wechseln
cd <Einhängepunkt>/MAXIMUS_T2_INSTALLER_V4

# 2. System und Hardware prüfen
sudo bash scripts/preflight.sh

# 3. Installation simulieren (ändert nichts)
sudo bash scripts/install.sh --dry-run

# 4. Installieren (fragt nach Freigabe)
sudo bash scripts/install.sh

# 5. Neu starten. Der Teststart geht EINMALIG in den T2-Kernel.
sudo reboot

# 6. Hardware abnehmen
sudo bash scripts/verify.sh

# 7. WLAN-Firmware nachholen, siehe firmware/README.md
sudo get-apple-firmware
```

Bei einem Fehler:

```bash
sudo bash scripts/rollback.sh --dry-run
sudo bash scripts/rollback.sh
```

## 6. Installationsablauf als Schema

```
[Samsung T7 anschliessen]
           |
           v
[System und Hardware pruefen]        preflight.sh
           |
           v
[Pakete und Pruefsummen validieren]  485 Dateien, SHA-256
           |
           v
[Boot-Konfiguration sichern]         /var/backups/maximus-t2/
           |
           v
[Installation simulieren]            install.sh --dry-run
           |
           v
[Benutzerfreigabe]                   Eingabe JA
           |
           v
[T2-Kernel und Treiber installieren]
           |
           v
[Kontrollierter Teststart]           grub-reboot, wirkt einmalig
           |
           v
[Hardwarefunktionen testen]          verify.sh
           |
           v
[Erfolgreiche Abnahme?]
       /         \
     Nein         Ja
      |            |
      v            v
[Diagnose und   [Worker fuer
 Rueckfall]      MAXIMUS freigeben]
 rollback.sh     erst nach Dauerbetrieb
```

## 7. Skripte

| Skript | Läuft auf | Zweck | Simulation |
| --- | --- | --- | --- |
| `scripts/fetch-packages.sh` | Baurechner | Paketnutzlast herstellen | — |
| `scripts/selftest.sh` | überall | Paket prüfen, 12 Testgruppen | ändert nie etwas |
| `scripts/deploy-to-t7.sh` | Baurechner | auf die Samsung T7 übertragen | `--dry-run` |
| `scripts/preflight.sh` | MacBook | System und Hardware prüfen | ändert nie etwas |
| `scripts/install.sh` | MacBook | installieren | `--dry-run` |
| `scripts/verify.sh` | MacBook | Hardware abnehmen | `--non-interactive` |
| `scripts/rollback.sh` | MacBook | zurücknehmen | `--dry-run` |

Hilfsbibliotheken ohne eigenen Start:

| Datei | Inhalt |
| --- | --- |
| `scripts/lib/common.sh` | Rückgabecodes, Ausgabe, Pfade, Prüffunktionen |
| `scripts/lib/grub-entry.sh` | ermittelt den GRUB-Menüeintrag eines Kernels |
| `scripts/lib/grub-config.sh` | bearbeitet `/etc/default/grub`, einzeln geprüft |
| `scripts/tests/` | Testvorlagen für die Einheitstests |

## 8. Rückgabecodes

| Code | Bedeutung |
| --- | --- |
| 0 | Erfolg |
| 2 | Falscher Aufruf |
| 3 | Rootrechte fehlen |
| 4 | Paketstruktur unvollständig |
| 10 | Falsches Mac-Modell |
| 11 | Falsche Ubuntu-Version oder Architektur |
| 12 | Paketabhängigkeiten fehlen |
| 13 | Prüfsumme falsch |
| 14 | Lokale Paketquelle fehlerhaft |
| 15 | Benutzerfreigabe fehlt |
| 16 | GRUB-Fehler |
| 17 | Sicherung fehlgeschlagen |
| 19 | Hardwaretest fehlgeschlagen oder unvollständig |
| 20 | Abbruch durch Benutzer |

## 9. Was dieses Paket nicht tut

1. Es installiert kein Ubuntu neu.
2. Es formatiert keinen Datenträger.
3. Es verändert keine Partitionstabelle.
4. Es verändert EFI und NVRAM nicht.
5. Es entfernt keinen vorhandenen Kernel.
6. Es nutzt keine `curl | bash`-Kette.
7. Es legt keinen global vertrauten APT-Schlüssel ab.
8. Es liefert keine Apple-Firmware mit.
9. Es verändert keine MAXIMUS-Dienste und keine KI-Modelle.

## 10. Vier Statusstufen

| Status | Bedeutung | Nachweis |
| --- | --- | --- |
| PACKAGE_READY | Das Paket ist erstellt und geprüft. | `reports/BUILD_REPORT.md` |
| INSTALLATION_READY | Die Voraussetzungen am MacBook sind bestätigt. | Lauf von `preflight.sh` |
| HARDWARE_READY | Die Hardwarefunktionen sind erfolgreich getestet. | `reports/HARDWARE_TEST_REPORT.md` |
| MAXIMUS_WORKER_READY | Der Worker ist funktional abgenommen. | Dauerbetriebsnachweis |

Kein Status wird ohne Nachweis erteilt.

## 11. Bekannte Risiken in Kurzform

| Risiko | Nachweis | Was das Paket dagegen tut |
| --- | --- | --- |
| Unerwartete Neustarts | Fehlerbericht 179 | Diagnoseanleitung, Gegenprobe über Modulsperre |
| Ruhezustand hängt | Fehlerbericht 31 und 215 | Ruhezustand abgeschaltet |
| 98 Grad Celsius CPU-Temperatur | MAXIMUS-Audit | Lüfterkurve 55 bis 80 Grad, Lasttest bricht bei 90 Grad ab |
| Kein WLAN | fehlende Apple-Firmware | geprüftes Werkzeug und Anleitung |
| Grafikabstürze | T2Linux-Zustandsseite | optionale Parameter dokumentiert |
| Kein Live-USB-Medium | MAXIMUS-Audit | Notstartanleitung, drei Kernel als Rückfall |
