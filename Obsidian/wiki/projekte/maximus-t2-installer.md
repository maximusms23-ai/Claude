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
Fassung V4, erstellt am 2026-10-10.

Speicherort im Repositorium:
`Obsidian/output/MAXIMUS_T2_INSTALLER_V4/`

## Zweck

Das Paket bringt einen Kernel mit Apple-T2-Treibern auf das MacBook.
Es installiert Ubuntu **nicht** neu.
Es laedt alle Pakete vorab, damit die Installation ohne Netz laeuft.

## Status

| Status | Wert | Nachweis |
| --- | --- | --- |
| PACKAGE_READY | erteilt | `reports/BUILD_REPORT.md` |
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

| Skript | Laeuft auf | Zweck |
| --- | --- | --- |
| `fetch-packages.sh` | Baurechner | Paketnutzlast herstellen |
| `selftest.sh` | ueberall | 13 Testgruppen, 102 Tests |
| `deploy-to-t7.sh` | Baurechner | auf die Samsung T7 uebertragen |
| `preflight.sh` | MacBook | System und Hardware pruefen |
| `install.sh` | MacBook | installieren, mit Simulationsbetrieb |
| `verify.sh` | MacBook | Hardware abnehmen |
| `rollback.sh` | MacBook | Aenderungen zuruecknehmen |

## Sicherheitsregeln

1. Es wird kein Datentraeger formatiert.
2. Es wird keine Partitionstabelle veraendert.
3. EFI und NVRAM bleiben unberuehrt.
4. Vorhandene Ubuntu-Kernel werden gegen Entfernung geschuetzt.
5. Die Bootkonfiguration wird vor jeder Aenderung gesichert.
6. Der Teststart in den T2-Kernel wirkt nur einmal.
7. Es wird keine `curl | bash`-Kette genutzt.
8. Jede Paketquelle nutzt einen eigenen Signaturschluessel.

## Offene Punkte

| Punkt | Naechster Schritt |
| --- | --- |
| Paket liegt nicht auf der Samsung T7 | `deploy-to-t7.sh` auf dem RTX-Rechner ausfuehren |
| Installation nicht erfolgt | `preflight.sh` und `install.sh --dry-run` auf dem MacBook |
| Hardwaretest fehlt | `verify.sh` nach dem Teststart |
| WLAN-Firmware fehlt | `get-apple-firmware`, Methode 5 |
| Kein Live-USB-Rettungsmedium | Startmedium erstellen, sobald das Geraet laeuft |

## Verweise

- Thema: [[T2Linux]]
- Treiberstapel: [[t2bce]]
- Firmware: [[Apple-Firmware brcmfmac]]
- Quellen: [[t2-ubuntu-repo]], [[T2-Debian-and-Ubuntu-Kernel]], [[t2linux-wiki]]
