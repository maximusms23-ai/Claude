---
title: t2-ubuntu-repo
aliases:
  - t2-ubuntu-repo
created: 2026-10-10
type: quelle
tags:
  - quelle
  - t2linux
  - paketquelle
---

# APT-Repositorium fuer T2-Macs

| Feld | Wert |
| --- | --- |
| Projekt | APT repository for T2 Macs |
| Herausgeber | [[Aditya Garg]] |
| Repository | `https://github.com/AdityaGarg8/t2-ubuntu-repo` |
| Typ | Paketquelle |
| Commit | `6068d948b4df9ac63d2da2ada7e2a4f5f9e52393` |
| Abgerufen am | 2026-10-10 |
| Pruefergebnis | BESTAETIGT |

## Zwei getrennte Paketquellen

| Quelle | Adresse | Inhalt |
| --- | --- | --- |
| gemeinsam | `https://adityagarg8.github.io/t2-ubuntu-repo ./` | Treiber, Audio, Luefter, Werkzeuge |
| release-bezogen | `https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/noble ./` | Kernel und `tiny-dfr` fuer Ubuntu 24.04 |

Beide Quellen sind einzeln hinzuzufuegen.
Die release-bezogene Quelle wechselt mit jeder Ubuntu-Fassung.

## Signatur

| Feld | Wert |
| --- | --- |
| Verfahren | GPG, RSA 4096 Bit |
| Fingerabdruck | `9F98 73A5 66A7 3E27 CFF0 294F E2E4 9611 4ACD BFD4` |
| Inhaber | Aditya Garg |
| Erzeugt | 2022-09-25 |
| Pruefung `InRelease` | gueltig, beide Quellen |

Nutze den Schluessel nur mit `signed-by` je Quelle.
Lege ihn nicht in `/etc/apt/trusted.gpg.d/` ab.
Ein Schluessel dort gilt sonst fuer alle Paketquellen.

## Genutzte Pakete

| Paket | Fassung | Zweck |
| --- | --- | --- |
| `linux-t2-lts` | 6.18.54-1-noble | Kernel mit T2-Treibern |
| `tiny-dfr` | 0.3.7-4-noble | Funktionsreihe der Touch Bar |
| `t2fanrd` | 0.1.0-4 | Luefterdienst |
| `apple-t2-audio-config` | 0.5.1 | ALSA-UCM-Profile |
| `t2-apple-audio-dsp-speakers161` | 0.2.0-1 | Lautsprecherkette, 16 Zoll 2019 |
| `t2-apple-audio-dsp-mic` | 0.4.0-1 | Mikrofonkette |
| `apple-firmware-script` | 1.4-3 | Befehl `get-apple-firmware` |
| `t2-ncm` | 0.1.0-2 | interne T2-Netzwerkschnittstelle |
| `t2-touchid` | 0.1.0-3 | Touch ID |

## Bewusst nicht genutzte Pakete

`apple-bce`, `apple-touchbar`, `applesmc-t2`, `bcm5974-t2`, `apfs-dkms`.

Grund: Der T2-Kernel enthaelt diese Treiber bereits.
Der Herausgeber warnt ausdruecklich vor einer doppelten Installation.
Siehe [[t2bce]].

## Verwendet in

- [[MAXIMUS T2 Installer]]
- [[T2Linux]]
