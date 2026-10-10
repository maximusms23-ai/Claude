---
title: MAXIMUS T2 Neuinstallation
aliases:
  - MAXIMUS T2 Neuinstallation
  - MAXIMUS_T2_NEUINSTALL_V1
created: 2026-10-10
type: projekt
tags:
  - maximus
  - t2linux
  - macbookpro16-1
  - neuinstallation
  - ubuntu
---

# MAXIMUS T2 Neuinstallation

Startfaehiges Installationsmedium fuer eine vollstaendige Ubuntu-Neuinstallation
auf einem Apple-Mac mit T2-Chip.
Fassung **1.0.0** vom 2026-10-10.

Speicherort: `Obsidian/output/MAXIMUS_T2_NEUINSTALL_V1/`

Abgrenzung zu [[MAXIMUS T2 Installer]]: Jenes Paket setzt ein bereits
installiertes Ubuntu voraus und ergaenzt dort die T2-Treiber.
Dieses Paket installiert Ubuntu neu.

## Gewaehlte Basis

| Teil | Wert |
| --- | --- |
| Projekt | [[T2Linux]] / T2-Ubuntu |
| Tag | `v7.1.8-1` |
| Abbild | `ubuntu-24.04-7.1.8-t2-noble.iso`, 2 461 433 856 Byte |
| Pruefsumme | bestaetigt gegen die Liste des Projekts |
| Betriebssystem | Ubuntu 24.04.5 LTS noble, amd64 |
| T2-Kernel | `linux-image-7.1.8-1-t2-noble` |
| Rueckfallkernel | `linux-image-6.8.0-138-generic` |
| Installer im Abbild | **ubiquity 24.04.5**, nicht subiquity |

Die T2-Treiber liegen im Abbild. Tastatur, Trackpad und Datentraeger
arbeiten deshalb schon beim Start, ohne externe Tastatur.

## Warum kein Autoinstall

Autoinstall und NoCloud gehoeren zu **subiquity**, dem Installer der
Server-Abbilder. Dieses Abbild enthaelt **ubiquity**. Nachgewiesen in
`casper/filesystem.manifest`.

Ubiquity versteht debian-installer-Preseed. Das Abbild nutzt diesen Weg
selbst: seine eigenen Menueeintraege tragen `file=/cdrom/preseed/mbp.seed`.

## Befund: ubiquity ohne Grafik kann nicht gefuehrt partitionieren

Gemessen im Prueflauf. `ubiquity noninteractive` endete in einer Schleife:

```
Kein Root-Dateisystem: Es wurde kein Root-Dateisystem festgelegt.
```

Ursache im Quelltext `/usr/lib/ubiquity/plugins/ubi-partman.py`:

```python
class PageNoninteractive(PageBase):
    def set_part_page(self, p):
        pass
```

`PageGtk` und `PageKde` haben `set_autopartition_options` und
`get_autopartition_choice`. `PageNoninteractive` hat beide nicht.

**Folge:** Betriebsart 1 teilt die Platte selbst auf und packt dasselbe
Live-Abbild `casper/filesystem.squashfs` aus, das ubiquity sonst kopiert.
Betriebsart 2 nutzt weiter ubiquity mit Grafik und Partitionswahl von Hand.

## Zwei Betriebsarten

| Betriebsart | Wirkung | Laeuft selbsttaetig durch |
| --- | --- | --- |
| 1 — ganze Platte | loescht alles auf dem Ziel, auch macOS | ja |
| 2 — eine Partition | andere Partitionen bleiben, auch macOS | nein |

Das Projekt t2linux verlangt neben einem vorhandenen macOS ausdruecklich
die Partitionswahl von Hand. Eine selbsttaetige Wahl wuerde macOS mit
entfernen.

## Sicherheitsregeln

1. Das laufende Installationsmedium ist niemals Ziel.
2. Es wird keine Platte nach Groesse oder Nummer gewaehlt.
3. Nur eine stabile Kennung unter `/dev/disk/by-id` gilt als Ziel.
4. Die Kennung wird unmittelbar vor dem Schreiben erneut geprueft.
5. Bei unklarer Zuordnung haelt der Assistent an und waehlt keinen Ersatz.
6. Liegt macOS auf dem Ziel, verlangt Betriebsart 1 die Freigabe `MACOS-LOESCHEN`.
7. Der Vorgabeeintrag im Startmenue ist das Live-System, nicht die Installation.
8. Eine fertige Installation auf dem Ziel wird erkannt und verlangt eine zweite Freigabe.
9. Es gibt kein fest eingebautes Passwort.
10. Die Installation erzeugt keine CPU-Last.
11. Ein fehlender Temperaturwert gilt niemals als 0 Grad Celsius.
12. Ein laufender Luefter allein gilt nicht als funktionierende Regelung.

## Startkette

Das Abbild traegt MBR, GPT **und eine Apple-Partition-Map**.
Nur die APM macht das Medium im Mac-Startmanager sichtbar.

`xorriso ... replay` kann die APM nicht erzeugen. Gemessen:
`Cannot make proposal to produce APM of loaded image`.
Das Abbild wird deshalb mit der Aufrufzeile des Projekts neu gebaut,
einschliesslich `-isohybrid-apm-hfsplus`.

## Stand der Pruefung

| Punkt | Stand |
| --- | --- |
| Abbild gebaut, APM erhalten | bestanden |
| EFI-Start unter OVMF | bestanden |
| Eigene Menueeintraege sichtbar | bestanden |
| Installer laedt die Preseed wirklich | bestanden, ueber die debconf-Datenbank belegt |
| Ausschluss des laufenden Mediums | bestanden |
| Falsche Freigabe bricht ab | bestanden, Rueckgabecode 15 |
| Neuinstallation auf leere Testplatte, ohne Netz | bestanden bis zur Nachbereitung |
| T7 beschrieben | **nein**, kein Zugriff auf Datentraeger |
| Start am echten Mac | **nein** |
| Hardware am Geraet | **nein** |

**Eine virtuelle Maschine beweist keine funktionierende T2-Hardware.**

## Temperatur

Die frueher gemessenen 98 Grad Celsius bleiben ein offener Befund.
Weder die Installation noch der erste Systemstart erzeugen CPU-Last.
Siehe [[T2Linux]], Abschnitt Waerme und Luefterregelung.

## Verweise

- Thema: [[T2Linux]]
- Treiberstapel: [[t2bce]]
- Firmware: [[Apple-Firmware brcmfmac]]
- Schwesterprojekt: [[MAXIMUS T2 Installer]]
- Quellen: [[t2-ubuntu-repo]], [[T2-Debian-and-Ubuntu-Kernel]], [[t2linux-wiki]]
