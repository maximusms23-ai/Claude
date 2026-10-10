---
title: Installationsbericht (Vorlage)
created: 2026-10-10
type: vorlage
tags: [maximus, t2linux, installation]
---

# Installationsbericht

**Dies ist eine Vorlage. Sie enthält noch kein Ergebnis.**

Status: NOT_TESTED.
Die Installation auf dem MacBookPro16,1 hat noch nicht stattgefunden.

Fülle dieses Blatt nach der Installation aus.
Die Skripte schreiben ihre Protokolle nach `/var/log/maximus-t2/`.

## 1. Rahmendaten

| Angabe | Wert |
| --- | --- |
| Datum | |
| Ausgeführt von | |
| Modell laut `/sys/class/dmi/id/product_name` | |
| Ubuntu-Version | |
| Kernel vor der Installation | |
| Paketquelle (Pfad auf der Samsung T7) | |
| USB-Tastatur angeschlossen | ja / nein |
| `GRUB-NOTSTART.txt` ausgedruckt | ja / nein |

## 2. Vorprüfung

Befehl: `sudo bash scripts/preflight.sh`

| Angabe | Wert |
| --- | --- |
| Rückgabecode | |
| Erfolgreich | |
| Warnungen | |
| Fehler | |
| Protokoll | |

Besondere Befunde:

| Befund | Bewertung |
| --- | --- |
| | |

## 3. Simulation

Befehl: `sudo bash scripts/install.sh --dry-run`

| Angabe | Wert |
| --- | --- |
| Rückgabecode | |
| Angekündigte neue Pakete | |
| Angekündigte Entfernungen (muss 0 sein) | |
| Angekündigte Schreibziele | |

## 4. Installation

Befehl: `sudo bash scripts/install.sh`

| Angabe | Wert |
| --- | --- |
| Rückgabecode | |
| Installierte Pakete | |
| Sicherungsverzeichnis | |
| Geschützte Kernelpakete | |
| Ergänzte Kernelparameter | |
| GRUB-Eintrag für den Teststart | |
| Protokoll | |

## 5. Teststart

| Angabe | Wert |
| --- | --- |
| GRUB-Menü erschienen | ja / nein |
| Gestarteter Kernel (`uname -r`) | |
| Anmeldung möglich | ja / nein |
| Interne Tastatur beim Anmelden nutzbar | ja / nein |
| Auffällige Kernelmeldungen | |

## 6. Firmware

| Angabe | Wert |
| --- | --- |
| Methode | 5 (Wiederherstellungsabbild) |
| Netzweg | |
| Gewählte macOS-Fassung | |
| Firmwaredateien in `/lib/firmware/brcm` | |
| Erkannter Funkchip | |
| Sicherung auf die Samsung T7 erstellt | ja / nein |

## 7. Abnahme

Befehl: `sudo bash scripts/verify.sh`

| Angabe | Wert |
| --- | --- |
| Rückgabecode | |
| PASS | |
| PARTIAL | |
| FAIL | |
| BLOCKED | |
| NOT_TESTED | |
| Bericht | |

## 8. Statusbewertung

| Status | Wert | Nachweis |
| --- | --- | --- |
| PACKAGE_READY | erteilt | `BUILD_REPORT.md` |
| INSTALLATION_READY | | |
| HARDWARE_READY | | |
| MAXIMUS_WORKER_READY | | |

Erteile keinen Status ohne Nachweis.

## 9. Abweichungen und Vorfälle

| Nr. | Beschreibung | Maßnahme | Ergebnis |
| --- | --- | --- | --- |
| | | | |
