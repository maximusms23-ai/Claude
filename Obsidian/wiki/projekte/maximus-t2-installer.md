---
title: MAXIMUS T2 Installer
aliases:
  - MAXIMUS T2 Installer
  - MAXIMUS_T2_INSTALLER_V4
created: 2026-10-10
type: projekt
tags:
  - maximus
  - t2linux
  - installer
  - macbookpro16-1
---

# MAXIMUS T2 Installer

Offline-Installationspaket fuer Apple MacBookPro16,1 unter Ubuntu 24.04.5 LTS.
Fassung **4.2.1** vom 2026-10-10.
Die Fassung 4.2 behebt vier gemeldete Sicherheitsbefunde und vier Fehler
aus dem Code-Review der Korrekturen.
Die Fassung 4.2.1 schliesst drei Luecken in den Nachweisen.
Einzelheiten: `reports/RELEASE_V4_2.md`, die drei Luecken in Abschnitt 11.
Die Fassung 4.1 behob funf gemeldete, zwei selbst gefundene und
siebzehn im Code-Review gefundene Fehler der Fassung 4.0.
Einzelheiten: `reports/RELEASE_V4_1.md`.

Speicherort im Repositorium:
`Obsidian/output/MAXIMUS_T2_INSTALLER_V4/`

## Zweck

Das Paket bringt einen Kernel mit Apple-T2-Treibern auf das MacBook.
Es installiert Ubuntu **nicht** neu.
Es laedt alle Pakete vorab, damit die Installation ohne Netz laeuft.

## Status

| Status | Wert | Nachweis |
| --- | --- | --- |
| SOURCE_READY | erteilt | `reports/RELEASE_V4_2.md`, Abschnitt 1 |
| PACKAGE_READY | erteilt | `reports/RELEASE_V4_2.md`, Abschnitt 5 |
| INSTALLATION_READY | nicht erteilt | Vorpruefung am Zielgeraet fehlt |
| HARDWARE_READY | nicht erteilt | Hardwaretest fehlt |
| MAXIMUS_WORKER_READY | nicht erteilt | Dauerbetriebsnachweis fehlt |
| Offline-Faehigkeit | PARTIAL | Apple-Firmware fehlt, siehe [[Apple-Firmware brcmfmac]] |

## Inhalt

| Stufe | Pakete | Umfang |
| --- | --- | --- |
| T2-Pakete | 14 | 236 MB |
| angeforderte Ubuntu-Pakete | 24 | 9,2 MB |
| mittelbare Abhaengigkeiten | 447 | 227 MB |
| **Gesamt** | **485** | **472 MB** |

Die Paketdateien liegen nicht im Git-Repositorium.
Eine einzelne Kerneldatei ist 112 MB gross.
Das Bauskript stellt die Nutzlast auf dem Baurechner her.

## Gewaehlter Kernel

`linux-t2-lts` 6.18.54-1-noble, Kernelversion 6.18.54-1-t2-noble.

Der Kandidat `linux-t2` 7.2.9-2-noble wurde abgelehnt.
Grund: Fuer die Reihe 7.2 ist ein Absturz beim Aufwachen aus dem
Ruhezustand gemeldet, und zwar fuer genau dieses Modell.
Siehe [[T2Linux]], Abschnitt zu den bekannten Fehlern.

## Skripte

Rufe jedes Skript mit `bash` auf. Die Samsung T7 nutzt exFAT.
exFAT speichert keine Unix-Rechte. Das Ausfuehrungsbit geht verloren.

| Skript | Laeuft auf | Zweck |
| --- | --- | --- |
| `fetch-packages.sh` | Baurechner | Paketnutzlast herstellen |
| `selftest.sh` | ueberall | 17 Testgruppen, 150 Tests |
| `regression.sh` | ueberall | 17 Gruppen, 213 Regressionstests |
| `make-inventory.sh` | ueberall | Fallliste aus dem Quelltext erzeugen |
| `deploy-to-t7.sh` | Baurechner | auf die Samsung T7 uebertragen |
| `preflight.sh` | MacBook | System und Hardware pruefen |
| `install.sh` | MacBook | installieren, mit Simulationsbetrieb |
| `verify.sh` | MacBook | Hardware abnehmen, Lasttest nur mit `--thermal-test` |
| `rollback.sh` | MacBook | Aenderungen zuruecknehmen |

## Korrekturen der Fassung 4.1

| Bereich | Fehler in 4.0 | Korrektur |
| --- | --- | --- |
| GRUB-Pruefung | `bash -n` war fuer `grub.cfg` zustaendig gemacht | `grub-script-check` |
| Offline-Installation | Simulation und Installation liefen gegen die Systemquellen | eine gepinnte lokale Quelle fuer beides |
| Rueckfall | `apt-get autoremove` und Paketnamensmuster | nur aufgezeichnete Aenderungen |
| Sicherung | wurde ungeprueft zurueckgeschrieben | Siegelpruefung mit Abbruch |
| Pruefsummen | wurden still ueberschrieben | Abbruch, Uebernahme nur mit Freigabe |
| exFAT | nur eine Warnung | Erkennung, Pruefung am Ziel, Startblatt |
| Pfade mit Leerzeichen | brachen die Paketquelle | werden kodiert |
| Bootvorgabe | unbestimmt | ausdruecklich gesetzt |

## Korrekturen der Fassung 4.2

Ein Sicherheits-Review fand vier Fehler. Alle vier sind bestaetigt.

| Schwere | Bereich | Fehler in 4.1 | Korrektur |
| --- | --- | --- | --- |
| KRITISCH | Temperaturueberwachung | `max_temp_c` gab ohne Sensor den Wert 0 aus. Der CPU-Lasttest lief ohne Abbruchsicherung. | Der Lasttest hat fuenf Sperren. Er laeuft nur mit `--thermal-test` und gesonderter Freigabe. |
| HOCH | Simulation | Die Vorpruefung und der Dry-Run schrieben nach `/var/lib/maximus-t2`. Gemessen: 12 Pfade. | Die Paketverwaltung liegt im temporaeren Verzeichnis. Gemessen: 0 Pfade. |
| HOCH | Sicherung | 16 Befehle ignorierten Kopierfehler. | Pflicht- und Wahldateien getrennt. Pruefung Byte fuer Byte vor dem Siegeln. |
| MITTEL | Git-Anleitung | Der Klonbefehl landete auf `main`. Dort fehlt `Obsidian/output/`. | `git clone --branch` mit dem Entwicklungszweig. |

Das Code-Review der Korrekturen fand vier weitere Fehler:
`pipefail` verfaelschte eine Zaehlung, `mt2_apt` haette ohne Pin die
Systemquellen genutzt, zwei Sensoraufrufe konnten zwei Werte liefern,
und der Rueckfall liess ein Protokollverzeichnis liegen.

### Temperaturregel

Das Geraet erreichte im Audit **98 Grad Celsius**.
Daraus folgt die Regel fuer den CPU-Lasttest:

| Merkmal | Wert |
| --- | --- |
| Lasttest in der Standardabnahme | laeuft nicht |
| Option | `--thermal-test` |
| Abbruchgrenze | 85 Grad Celsius |
| Hoechste Ruhetemperatur | 70 Grad Celsius |
| Messabstand | 1 Sekunde |
| Abbruch bei Sensorausfall | nach zwei Ausfaellen |
| Weitere Bedingungen | drehender Luefter, aktiver Dienst `t2fanrd`, Benutzerfreigabe |

Ohne Lasttest erhalten die Prueffelder CPU und Luefterregelung
`NOT_TESTED`. Ein nicht getestetes Geraet erhaelt niemals `PASS`.

## Korrekturen der Fassung 4.2.1

Eine Pruefung des Release-Berichts fand drei Luecken. Alle drei bestaetigt.

| Bereich | Luecke | Korrektur |
| --- | --- | --- |
| Testzahlen | `skip` zaehlte einen Eintrag je Bereich. Ein Lauf meldete 158 statt 203 Faelle. 45 Faelle waren nicht nachlesbar. | Fallverzeichnis aus dem Quelltext. Jeder uebersprungene Fall erhaelt eine eigene Zeile. Schlussrechnung bei jedem Lauf. |
| Formulierung | "Keine Qualitaetsverschlechterung" galt dem ganzen Vorhaben. | Die Aussage traegt jetzt ihren Pruefumfang. |
| Wiederherstellung | Ein durchgefuehrter Rueckfall war nicht bewiesen. | Gruppe R18 fuehrt einen echten Rueckfall in einem eigenen Mount-Namensraum aus. |

### Nachweis der Wiederherstellung

`scripts/tests/restore-probe.sh` aendert Dateien wie eine Installation.
Danach ruft es `rollback.sh --yes` auf. Das ist keine Simulation.

| Messung | gueltige Sicherung | beschaedigte Sicherung |
| --- | --- | --- |
| Rueckgabecode | 0 | 13 |
| `/etc/default/grub` zurueck | ja | nein |
| `/boot/grub/grub.cfg` zurueck | ja | nein |
| neue Datei entfernt | ja | nein |

Die Probe laeuft in einem eigenen Mount-Namensraum.
Das Wirtsystem bleibt unveraendert. Fall `R18.10` weist das nach.

Nicht geprueft sind `update-grub`, `update-initramfs` und das Bootverhalten.
Diese Programme fehlen in der Bauumgebung.

### Nachvollziehbarkeit

`reports/TESTFALL_INVENTAR.md` nennt alle 213 Faelle.
Jede Zeile traegt Kennung, Gruppe, Bezeichnung und die Quellzeile.
Der Fall `R17.2` prueft bei jedem Lauf, ob die Datei zum Quelltext passt.

Siehe [[t2bce]] und [[T2Linux]] fuer die Hardwareseite.

## Sicherheitsregeln

1. Es wird kein Datentraeger formatiert.
2. Es wird keine Partitionstabelle veraendert.
3. EFI und NVRAM bleiben unberuehrt.
4. Vorhandene Ubuntu-Kernel werden gegen Entfernung geschuetzt.
5. Die Bootkonfiguration wird vor jeder Aenderung gesichert.
6. Der Teststart in den T2-Kernel wirkt nur einmal.
7. Es wird keine `curl | bash`-Kette genutzt.
8. Jede Paketquelle nutzt einen eigenen Signaturschluessel.
9. Es wird kein Eintrag in `/etc/apt/sources.list.d` abgelegt.
10. Es wird kein `apt-get autoremove` ausgefuehrt.
11. Bei der Installation wird kein Paket aus dem Netz geladen.
12. Die Vorpruefung und die Simulation aendern keine Systemdatei.
13. Ohne vollstaendige Sicherung beginnt keine Installation.
14. Ohne gueltige Temperaturmessung laeuft kein Lasttest.
15. Ohne nachgewiesene Luefterregelung laeuft kein Lasttest.

## Offene Punkte

| Punkt | Naechster Schritt |
| --- | --- |
| Paket liegt nicht auf der Samsung T7 | `deploy-to-t7.sh` auf dem RTX-Rechner ausfuehren |
| Installation nicht erfolgt | `preflight.sh` und `install.sh --dry-run` auf dem MacBook |
| Hardwaretest fehlt | `verify.sh` nach dem Teststart, ohne Lasttest |
| `update-grub` und Bootpfad unerprobt | braucht das Zielgeraet |
| Luefterregelung unbewertet | erst danach `verify.sh --thermal-test` |
| WLAN-Firmware fehlt | `get-apple-firmware`, Methode 5 |
| Kein Live-USB-Rettungsmedium | Startmedium erstellen, sobald das Geraet laeuft |

## Verweise

- Thema: [[T2Linux]]
- Treiberstapel: [[t2bce]]
- Firmware: [[Apple-Firmware brcmfmac]]
- Quellen: [[t2-ubuntu-repo]], [[T2-Debian-and-Ubuntu-Kernel]], [[t2linux-wiki]]
