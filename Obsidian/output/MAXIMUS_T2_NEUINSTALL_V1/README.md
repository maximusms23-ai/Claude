---
title: MAXIMUS T2 Neuinstallation V1
created: 2026-10-10
type: anleitung
tags: [maximus, t2linux, macbookpro16-1, neuinstallation, ubuntu]
---

# MAXIMUS T2 Neuinstallation V1

Startfähiges Installationsmedium für eine vollständige Ubuntu-Neuinstallation
auf einem Apple-Mac mit T2-Chip.

Fassung **1.0.0** vom 2026-10-10.

## 1. Ergebnis zuerst

| Status | Wert | Begründung |
| --- | --- | --- |
| Abbild gebaut | **JA** | `maximus-t2-neuinstall-v1.iso`, Prüfsumme in `manifest.json` |
| EFI-Start geprüft | **JA** | unter OVMF gestartet, GRUB-Menü erschienen |
| Automatisierung geprüft | **JA** | der gestartete Installer hat die Preseed nachweislich geladen |
| T7 vorbereitet | **NEIN** | diese Bauumgebung hat keinen Zugriff auf Datenträger |
| Installation am Mac bestanden | **NEIN** | es gab keine Installation auf dem Gerät |
| Hardware am Gerät geprüft | **NEIN** | es gab keinen Test am Gerät |

**Die Samsung T7 ist nicht beschrieben.** Der Grund steht in Abschnitt 8.

## 2. Was dieses Paket ist

Es nimmt das geprüfte Installationsabbild des Projekts **t2linux** und
ergänzt es um:

- einen deutschen Startpunkt **"Ubuntu mit T2-Unterstützung neu installieren"**,
- einen Assistenten für die Zielauswahl mit Löschumfang und Freigabe,
- eine Preseed-Datei für Sprache, Tastatur, Zeitzone und Offline-Betrieb,
- die T2-Zusatzpakete, die das Projekt-Abbild nicht mitbringt,
- einen Funktionsbericht nach dem ersten Start.

Es ist **kein** zweiter Installer. Es nutzt den Installer, der im Abbild
steckt.

## 3. Die gewählte Installationsbasis

| Teil | Wert | Nachweis |
| --- | --- | --- |
| Projekt | t2linux / T2-Ubuntu | `https://github.com/t2linux/T2-Ubuntu` |
| Fassung | `v7.1.8-1` | neuester Tag des Zweigs LTS |
| Abbild | `ubuntu-24.04-7.1.8-t2-noble.iso` | 2 461 433 856 Byte |
| SHA-256 | `5792a22a…22aa1241` | stimmt mit `sha256-ubuntu-24.04` des Projekts überein |
| Betriebssystem | Ubuntu 24.04.5 LTS "Noble Numbat", amd64 | `README.diskdefines` im Abbild |
| T2-Kernel | `linux-image-7.1.8-1-t2-noble` | `casper/filesystem.manifest` |
| Rückfallkernel | `linux-image-6.8.0-138-generic` | ebenda |
| Installer | **ubiquity 24.04.5** mit `ubiquity-casper 1.498` | ebenda |

**Warum diese Fassung:** Sie ist die aktuelle Fassung des Projekts für
Ubuntu 24.04 LTS. Die T2-Treiber sind schon im Abbild. Eingabegeräte und
Datenträger arbeiten deshalb bereits beim Start, ohne externe Tastatur.

## 4. Warum kein Autoinstall und kein NoCloud

Autoinstall und NoCloud gehören zu **subiquity**, dem Installer der
Server-Abbilder von Ubuntu.

Dieses Abbild enthält **ubiquity**, nicht subiquity. Gemessen in
`casper/filesystem.manifest`:

```
ubiquity 24.04.5
ubiquity-casper 1.498
ubiquity-frontend-gtk 24.04.5
```

Ubiquity versteht **debian-installer-Preseed**. Das Abbild nutzt diesen Weg
selbst: Seine eigenen Menüeinträge tragen `file=/cdrom/preseed/mbp.seed`.

Dieses Paket geht denselben Weg. Für den unbeaufsichtigten Lauf nutzt es das
Frontend `noninteractive`. Dieses Frontend ist im Abbild vorhanden und setzt
den automatischen Betrieb selbst. Belegt im Quelltext von
`/usr/lib/ubiquity/bin/ubiquity`:

```python
# Noninteractive implies automatic mode.
if f == 'noninteractive':
    os.environ['UBIQUITY_AUTOMATIC'] = '1'
```

## 5. Ablauf vom Anschließen bis zum ersten Ubuntu-Start

### 5.0 Einmalig vorher: T2-Starteinstellungen

Ohne diesen Schritt startet der Mac nicht von der T7.
**Keine Datei auf der T7 kann das ersetzen.**

Die Anleitung steht in `recovery/T2-STARTEINSTELLUNGEN.md`.

Kurz: macOS-Wiederherstellung mit **Command-R**, dann
**Dienstprogramme → Startsicherheitsdienstprogramm**:
Sicherer Systemstart auf **Keine Sicherheit**, externes Booten **erlauben**.

### 5.0b Einmalig vorher: Firmware und Daten sichern

1. Sichere deine persönlichen Daten auf einen Datenträger,
   der **nicht** die T7 ist.
2. Sichere die Apple-Firmware für WLAN und Bluetooth.
   Anleitung: `iso-overlay/maximus/firmware/ANLEITUNG.md`.
3. **Lege die einzige Firmwarekopie niemals nur auf die T7.**
   Die T7 wird beim Erstellen des Mediums überschrieben.

### 5.1 Medium erstellen (auf dem Baurechner)

```bash
bash build/01-fetch-base.sh          # Projekt-ISO holen und prüfen
bash build/02-fetch-payload.sh       # T2-Pakete und Sprachpakete holen
bash build/03-remaster-iso.sh \
  --base build/base/ubuntu-24.04-7.1.8-t2-noble.iso \
  --overlay iso-overlay \
  --out maximus-t2-neuinstall-v1.iso
bash tests/boot-efi.sh --iso maximus-t2-neuinstall-v1.iso --out /tmp/start --entry 7
```

Erst danach auf die T7 schreiben:

```bash
bash build/04-write-to-t7.sh --iso maximus-t2-neuinstall-v1.iso --dry-run
bash build/04-write-to-t7.sh --iso maximus-t2-neuinstall-v1.iso
```

Das Schreibskript erkennt die T7 über Modell, Seriennummer und stabile
Kennung. Es nimmt keinen Gerätenamen an. Es fragt vor dem Schreiben nach
einer Freigabe und zeigt den Löschumfang.

### 5.2 Am Mac

1. Schließe die Samsung T7 an. Nutze bei Bedarf den USB-C-Adapter.
2. Schalte den Mac ein und halte die **Wahltaste (⌥)**.
3. Wähle den orangen Eintrag **EFI Boot**. Bei zwei Einträgen zuerst den
   rechten.
4. Das Startmenü erscheint. Wähle
   **"Ubuntu mit T2-Unterstützung neu installieren"**.

   Der **Vorgabeeintrag ist das Live-System, nicht die Installation.**
   Ein erneuter Start von der T7 löst deshalb keine zweite Löschung aus.

5. Der Assistent erscheint auf dem Textbildschirm. Er zeigt:
   - alle Datenträger mit Modell, Seriennummer, stabiler Kennung und
     Partitionen,
   - welche Partition was enthält, auch macOS,
   - welches Gerät das laufende Medium ist. **Es ist von der Auswahl
     ausgeschlossen.**
6. Wähle das Ziel und die Betriebsart:

   | Betriebsart | Wirkung | Läuft selbsttätig durch |
   | --- | --- | --- |
   | 1 — ganze Platte | löscht alles auf dem Ziel, auch macOS | **ja** |
   | 2 — eine Partition | andere Partitionen bleiben, auch macOS | nein, Partitionswahl von Hand |

   Betriebsart 2 ist kein Mangel. Das Projekt t2linux verlangt neben einem
   vorhandenen macOS ausdrücklich die Partitionswahl von Hand. Eine
   selbsttätige Wahl würde macOS mit entfernen.

7. Der Assistent zeigt den **Löschumfang**. Liegt macOS auf dem Ziel, dann
   verlangt er eine eigene Freigabe `MACOS-LOESCHEN`.
8. Die Freigabe verlangt einen Teil der **stabilen Kennung** des Ziels.
   Ein bloßes "ja" genügt nicht.
9. Der Assistent fragt **einmal** nach Benutzername, Rechnername und
   Passwort. **Es gibt kein fest eingebautes Passwort.**
10. Unmittelbar vor dem Schreiben prüft er die Kennung erneut. Hat sich die
    Zuordnung geändert, dann bricht er ab und wählt **keinen Ersatz**.
11. Danach läuft die Installation ohne weitere Routinefragen durch.

### 5.3 Nach der Installation

1. Fahre herunter. Zieh die T7 ab.
2. Starte mit gehaltener **Wahltaste**. Wähle **EFI Boot**.
3. Beim ersten Start schreibt der Funktionsbericht nach
   `/var/log/maximus-funktionsbericht.md`.
4. Fehlt WLAN, dann hole die Firmware nach:

   ```bash
   sudo get-apple-firmware get_from_macos     # mit vorhandenem macOS
   sudo get-apple-firmware get_from_online    # mit Kabelnetz
   ```

## 6. Was automatisch eingerichtet wird

| Bereich | Wert |
| --- | --- |
| Sprache | Deutsch, `de_DE.UTF-8` |
| Tastatur | `de`, Modell `pc105` |
| Zeitzone | `Europe/Berlin`, Uhr auf UTC |
| Startparameter | `pm_async=off intel_iommu=on iommu=pt pcie_ports=native` |
| Module im Initramfs | `t2bce_dma`, `t2bce_core`, `t2bce_vhci`, soweit im Kernel vorhanden |
| Dienste | `t2fanrd` (Lüfter), `tiny-dfr` (Touch Bar) |
| Paketquelle | t2linux, Schlüssel per `Signed-By` gebunden |
| Erster Start | Funktionsbericht, **ohne** CPU-Lasttest |

## 7. Temperatur und Lüfter

Im früheren Audit wurden **98 °C** gemessen. Die Ursache ist nicht geklärt.

Daraus folgt in diesem Paket:

- Die Installation erzeugt **keine** CPU-Last.
- Der erste Systemstart erzeugt **keine** CPU-Last.
- Ein fehlender Sensorwert gilt **niemals** als 0 °C. Der Bericht meldet
  dann `FEHLGESCHLAGEN`.
- Ein laufender Lüfter allein gilt **nicht** als funktionierende Regelung.
  Ohne Last meldet der Bericht höchstens `VORBEREITET`.
- Ein Lasttest braucht eine eigene Entscheidung und eine funktionierende
  Überwachung. Er ist in diesem Paket **nicht** eingebaut.

## 8. Warum die T7 nicht beschrieben ist

Diese Bauumgebung ist ein Container ohne Durchgriff auf Datenträger.
Gemessen:

```
lsblk: nur virtio-Geraete (vda bis vdf), kein /dev/sd*, kein /dev/nvme*
lsusb: Programm nicht vorhanden, kein USB-Bus sichtbar
/sys/class/dmi/id/product_name: nicht lesbar
```

Eine Samsung T7 ist hier **nicht sichtbar**. Nach Auftragsabschnitt 9 ist
deshalb genau diese Aktion angehalten. Alles andere ist gebaut und geprüft.

**Nächster ausführbarer Schritt:** Das Abbild liegt bereit. Es muss auf einem
Rechner mit echtem Zugriff auf die T7 geschrieben werden. Das Skript
`build/04-write-to-t7.sh` erledigt das, mit Erkennung und Freigabe.

## 9. Dateien

| Pfad | Inhalt |
| --- | --- |
| `build/01-fetch-base.sh` | Projekt-ISO holen, Prüfsumme prüfen |
| `build/02-fetch-payload.sh` | T2-Pakete und Sprachpakete mit Vertrauenskette holen |
| `build/03-remaster-iso.sh` | Abbild umbauen, Apple-Partition-Map erhalten |
| `build/04-write-to-t7.sh` | T7 erkennen und beschreiben |
| `build/grub/grub.cfg` | Startmenü |
| `iso-overlay/preseed/` | Preseed für ubiquity |
| `iso-overlay/maximus/` | Assistent, Nachbereitung, Funktionsbericht, Pakete |
| `recovery/` | Starteinstellungen und Wiederherstellung |
| `tests/` | Starttest und Prüfläufe |
| `reports/` | Prüfprotokolle |
