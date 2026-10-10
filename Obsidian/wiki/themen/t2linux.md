---
title: T2Linux
created: 2026-10-10
aliases:
  - T2Linux
  - T2 Linux
type: thema
tags:
  - t2linux
  - linux
  - apple
  - macbookpro16-1
  - hardware
---

# T2Linux

T2Linux ist ein Gemeinschaftsprojekt. Es bringt Linux auf Apple-Macs mit
T2-Sicherheitschip. Betroffen sind Intel-Macs der Baujahre 2018 bis 2020.

## Warum ein eigenes Projekt

Der Apple-T2-Chip steuert zentrale Hardware. Dazu gehoeren Tastatur,
Trackpad, Touch Bar, Kamera, Audio und die Luefterwerte.
Ein normaler Linux-Kernel kennt diesen Chip nicht.
Die Geraete bleiben deshalb ohne Funktion.

Das Projekt loest das mit zwei Bausteinen:

1. Ein Kernel mit zusaetzlichen Patches. Er stellt den T2-Chip als
   virtuellen USB-Hostadapter bereit. Siehe [[t2bce]].
2. Eine Paketquelle mit Treibern, Diensten und Konfigurationsdateien.
   Siehe [[t2-ubuntu-repo]].

## Zustand der Hardwareunterstuetzung

Stand 2026-10-10. Quelle: Zustandsseite des Projekts, siehe [[t2linux-wiki]].

| Funktion | Zustand | Anmerkung |
| --- | --- | --- |
| Interne SSD | arbeitsfaehig | im Hauptzweig seit Kernel 5.4 |
| Bildschirm, Intel-Grafik | arbeitsfaehig | — |
| Tastatur | arbeitsfaehig | kein Treiber im Hauptzweig, haengt an [[t2bce]] |
| Trackpad | arbeitsfaehig | ohne Force Touch, ohne Handballenerkennung |
| Touch Bar | arbeitsfaehig | Treiber seit Kernel 6.15 im Hauptzweig |
| Kamera | arbeitsfaehig | ueber den USB-Pfad des T2-Chips |
| Audio | arbeitsfaehig | Mikrofon bauartbedingt sehr leise |
| WLAN | arbeitsfaehig | braucht Apple-Firmware, siehe [[Apple-Firmware brcmfmac]] |
| Bluetooth | eingeschraenkt | stoert bei BCM4377 mit 2,4-GHz-WLAN |
| Thunderbolt | arbeitsfaehig | braucht `pcie_ports=native` |
| Ruhezustand | eingeschraenkt | modellabhaengig fehlerhaft |
| Hybride Grafik | eingeschraenkt | dedizierte Grafik laesst sich nicht abschalten |
| AMD-Grafik | eingeschraenkt | Abstuerze bei Aufloesungswechsel moeglich |
| T2 Secure Enclave | eingeschraenkt | nur in macOS angelegte Fingerabdruecke |
| T2-Video-Encoder | nicht arbeitsfaehig | kein Treiber |

## Kernelreihen fuer Ubuntu 24.04

Die Paketquelle liefert vier Reihen. Alle sind fuer `noble` gebaut.

| Paket | Reihe | Hoechste Fassung am 2026-10-10 |
| --- | --- | --- |
| `linux-t2-lts` | Langzeitpflege | 6.18.54-1-noble |
| `linux-t2` | Hauptentwicklung | 7.2.9-2-noble |
| `linux-t2-xanmod-lts` | Xanmod, Langzeitpflege | 6.18.51-xanmod1-noble |
| `linux-t2-xanmod` | Xanmod, Hauptentwicklung | 7.2.9-xanmod1-noble |

## Bekannte Fehler beim MacBookPro16,1

| Bericht | Inhalt | Quellenart |
| --- | --- | --- |
| Kernel-Repository 179 | "Scheduling while atomic" im Audio-Pfad. Folge sind unerwartete Neustarts. | Projektbericht |
| Kernel-Repository 215 | Nullzeigerzugriff beim Aufwachen aus S3. Betrifft die Reihe 7.2. | Projektbericht |
| `t2linux/kernel` 31 | Zustandsspeicher fuer den Ruhezustand zu klein. Folge sind minutenlange Haenger. Gemessen auf 6.18.52 LTS. | Projektbericht |
| CachyOS-Bericht | Tastatur, Trackpad und Touch Bar brachen auf Kernel 7.1.2 ab. Auf LTS 6.18.37 arbeiteten sie wieder. | andere Distribution, mittelbar |
| Omarchy-Bericht | `gmux` kann den internen Bildschirm an die AMD-Grafik legen. Folge ist ein Haenger beim Sitzungsstart. | andere Distribution, mittelbar |
| Omarchy-Bericht | `s2idle` weckt die Radeon-Grafik nicht auf. Empfohlen ist `deep`. | andere Distribution, mittelbar |
| CachyOS-Bericht | Der Bildschirm bleibt nach dem Aufwachen dunkel, wenn `apple-set-os` fehlt. | andere Distribution, mittelbar |

Die Berichte anderer Distributionen stuetzen zwei Entscheidungen
unabhaengig: die Wahl der LTS-Reihe und den Ausschluss von `apple-bce`.

## Waerme und Luefterregelung

Der Core i9-9880H im MacBookPro16,1 erreichte im Audit **98 Grad Celsius**.
Die Ursache ist nicht geklaert.
Zwei Punkte sind dabei wichtig.

1. Die Temperatursensoren liefern erst, wenn `coretemp` und `applesmc`
   geladen sind. Vorher ist `/sys/class/thermal` leer.
2. Die Luefterregelung liegt unter Linux beim Dienst `t2fanrd`.
   Die Firmware regelt nicht selbst.

Daraus folgt eine Regel fuer jeden Lasttest:

| Bedingung | Begruendung |
| --- | --- |
| gueltige Temperaturmessung | Ohne Messwert gibt es keine Abbruchsicherung. |
| drehender Luefter | Ein lesbarer Wert allein beweist keine Kuehlung. |
| aktiver Dienst `t2fanrd` | Ohne Dienst steigt die Drehzahl nicht unter Last. |
| gesonderte Freigabe | Ein unbeaufsichtigter Lasttest ist bei 98 Grad gefaehrlich. |

Ein leerer Sensorpfad darf **nicht** als 0 Grad gelten.
Dieser Fehler stand in [[MAXIMUS T2 Installer]] bis zur Fassung 4.1.
Die Fassung 4.2 behebt ihn.

## Notwendige Kernelparameter

```
intel_iommu=on iommu=pt pm_async=off
```

Ohne diese Parameter bleibt der Audio- und Eingabepfad haengen.
Fuer Thunderbolt kommt `pcie_ports=native` hinzu.

## Pruefung am Geraet

Zwei Angaben gelten erst nach einer Messung am Geraet:

1. Der Funkchip. Lies ihn mit `lspci -nn | grep -i network` und mit
   `journalctl -k --grep=brcmfmac`.
2. Der Treiber des internen Bildschirms. Lies ihn unter
   `/sys/class/drm/card*-eDP-*`.
3. Die Temperatursensoren. Lies sie unter `/sys/class/thermal/thermal_zone*/temp`
   und `/sys/class/hwmon/hwmon*/temp*_input`.
4. Die Luefterdrehzahlen. Lies sie unter `/sys/class/hwmon/hwmon*/fan*_input`.
   Pruefe zusaetzlich `systemctl is-active t2fanrd`.

## Verweise

- Projekt: [[MAXIMUS T2 Installer]]
- Treiberstapel: [[t2bce]]
- Firmware: [[Apple-Firmware brcmfmac]]
- Paketquelle: [[t2-ubuntu-repo]]
- Kernel: [[T2-Debian-and-Ubuntu-Kernel]]
- Zustandsseite: [[t2linux-wiki]]
- Betreuer der Paketquelle: [[Aditya Garg]]
