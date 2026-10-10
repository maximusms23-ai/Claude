---
title: Wiederherstellung nach einer fehlgeschlagenen Installation
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, wiederherstellung, rollback]
---

# Wiederherstellung

## 1. Ergebnis zuerst

Mit dieser Anleitung stellst du den Zustand von vor der Installation her.
Du brauchst dafür kein Startmedium, solange das System startet.

## 2. Welche Lage hast du?

| Lage | Gehe zu |
| --- | --- |
| Das System startet. Der T2-Kernel läuft, einzelne Geräte fehlen. | Abschnitt 4 |
| Das System startet nur mit dem Ubuntu-Kernel. | Abschnitt 5 |
| Das System startet nicht. Das GRUB-Menü erscheint. | `GRUB-NOTSTART.txt`, Fall 1 |
| Das GRUB-Menü erscheint nicht. | `GRUB-NOTSTART.txt`, Fall 2 bis 5 |

## 3. Wo liegen die Sicherungen?

| Inhalt | Pfad |
| --- | --- |
| Sicherungen | `/var/backups/maximus-t2/<Zeitstempel>/` |
| Letzte Sicherung | `/var/lib/maximus-t2/last-backup` |
| Zustand der Installation | `/var/lib/maximus-t2/install-state` |
| Protokolle | `/var/log/maximus-t2/` |

Inhalt einer Sicherung:

| Datei | Inhalt |
| --- | --- |
| `etc-default-grub` | die GRUB-Einstellungen |
| `grub.cfg` | das erzeugte GRUB-Menü |
| `sources.list`, `sources.list.d/` | die Paketquellen |
| `modprobe.d/`, `modules-load.d/` | die Treiberkonfiguration |
| `initramfs-modules` | die Modulliste der Initialramdisk |
| `dpkg-selections.txt` | alle installierten Pakete |
| `kernel-packages.txt` | alle Kernelpakete mit Fassung |
| `boot-listing.txt` | alle Dateien in `/boot` |
| `cmdline-before.txt` | die Kernelparameter vor der Änderung |
| `firmware-brcm.txt` | die vorhandenen Firmwaredateien |
| `apt-holds-before.txt` | die vorher geschützten Pakete |

## 4. Teilweise Störung: einzelne Geräte fehlen

Nimm nicht gleich alles zurück. Arbeite in dieser Reihenfolge.

1. Lies den Abnahmebericht:

   ```bash
   ls -t /var/log/maximus-t2/HARDWARE_TEST_REPORT-*.md | head -1
   ```

2. Prüfe die geladenen Module:

   ```bash
   lsmod | grep -E 't2bce|appletb|applesmc|brcmfmac'
   ```

3. Prüfe die Kernelmeldungen:

   ```bash
   sudo journalctl -k -b 0 | grep -iE 't2bce|brcmfmac|applesmc|amdgpu' | tail -40
   ```

4. Prüfe die Kernelparameter:

   ```bash
   cat /proc/cmdline
   ```

5. Suche die Störung in dieser Tabelle.

| Fehlerbild | Nächster Schritt |
| --- | --- |
| Kein Ton, Karte heißt nur `AppleT2` | Entferne `t2-apple-audio-dsp-speakers161`. Der Kernel liefert die Aufteilung nicht. |
| Kein Ton, Parameter fehlen | Ergänze `intel_iommu=on iommu=pt pm_async=off`. Führe `sudo update-grub` aus. |
| Kein WLAN | Die Firmware fehlt. Siehe `firmware/README.md`. |
| Bluetooth bricht ab | Schalte 2,4-GHz-WLAN ab. Nutze 5 GHz. |
| Lüfter dreht nicht | `sudo systemctl status t2fanrd`. Prüfe `/etc/t2fand.conf`. |
| Grafikabstürze | Siehe `config/grub/OPTIONAL-PARAMS.md`. |
| Unerwartete Neustarts | Siehe Abschnitt 6. |

## 5. Vollständiger Rückfall

Das Gerät läuft mit dem Ubuntu-Kernel. Du willst alles zurücknehmen.

1. Schließe die Samsung T7 an.
2. Wechsle in das Paketverzeichnis.
3. Simuliere zuerst:

   ```bash
   sudo bash scripts/rollback.sh --dry-run
   ```

4. Lies die Ausgabe. Prüfe jeden angekündigten Schritt.
5. Führe den Rückfall aus:

   ```bash
   sudo bash scripts/rollback.sh
   ```

6. Prüfe vor dem Neustart:

   ```bash
   grep -c menuentry /boot/grub/grub.cfg
   ls /boot/vmlinuz-*
   cat /etc/default/grub | grep CMDLINE
   ```

7. Starte neu.

Der T2-Kernel bleibt dabei installiert.
Er wird nur nicht mehr gestartet.
Das ist der sicherste Weg, weil kein Startpfad entfernt wird.

Willst du die T2-Pakete wirklich entfernen:

```bash
sudo bash scripts/rollback.sh --purge-t2
```

Das Skript prüft dabei, dass kein Ubuntu-Kernel in der Entfernungsliste steht.
Es bricht ab, wenn das doch der Fall wäre.

## 6. Unerwartete Neustarts

Fehlerbericht 179 beschreibt plötzliche Neustarts auf diesem Modell.
Die Ursache liegt im Audio-Pfad des T2-Treibers.

### Schritt 1: Beweise sammeln

Schalte dauerhafte Protokolle ein:

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

Prüfe nach einem Neustart:

```bash
sudo journalctl -k -b -1 | tail -60
sudo journalctl -k -b -1 | grep -iE 'atomic|BUG:|Oops|panic'
ls /sys/fs/pstore/
```

### Schritt 2: Gegenprobe

Sperre nur das Audio-Modul. Tastatur und Touch Bar bleiben nutzbar.

```bash
echo 'blacklist t2bce_audio' | sudo tee /etc/modprobe.d/zz-t2-audio-test.conf
sudo update-initramfs -u
sudo reboot
```

Treten danach keine Neustarts mehr auf, ist der Audio-Pfad die Ursache.

### Schritt 3: Entscheidung

| Ergebnis | Maßnahme |
| --- | --- |
| Neustarts hören auf | Lass das Audio-Modul gesperrt. Bewerte Audio als FAIL. Melde den Befund an das Projekt. |
| Neustarts bleiben | Entferne die Sperre. Führe den vollständigen Rückfall aus. Melde den Befund. |

Sperre entfernen:

```bash
sudo rm /etc/modprobe.d/zz-t2-audio-test.conf
sudo update-initramfs -u
```

## 7. Grenzen

1. Zwei vorhandene Kernel sind keine Garantie für einen Start.
2. Ein beschädigter Bootloader verhindert den Start trotz vorhandener Kernel.
3. Ein Live-USB-Medium ist weiterhin der einzige vollständige Rückfall.
   Erstelle es, sobald das Gerät wieder läuft.
