---
title: T2-Debian-and-Ubuntu-Kernel
aliases:
  - T2-Debian-and-Ubuntu-Kernel
created: 2026-10-10
type: quelle
tags:
  - quelle
  - t2linux
  - kernel
---

# T2 Debian and Ubuntu Kernel

| Feld | Wert |
| --- | --- |
| Projekt | T2 Debian and Ubuntu Kernel |
| Herausgeber | t2linux |
| Repository | `https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel` |
| Typ | Repository |
| Commit | `4af5919a5e2f7ffccbd0c54e8b6d7d149e5c49b1` |
| Abgerufen am | 2026-10-10 |
| Pruefergebnis | BESTAETIGT |

## Inhalt

Das Projekt baut Kernelpakete fuer Debian, Ubuntu und Linux Mint.
Die Patches stammen aus `https://github.com/t2linux/linux-t2-patches`,
Commit `65fdd4d492d7e219a05742ce4768f16e5ba4f976`.

Die fertigen Pakete liegen in [[t2-ubuntu-repo]].

## Genutzte Fassung

| Feld | Wert |
| --- | --- |
| Paket | `linux-image-6.18.54-1-t2-noble` |
| Fassung | 6.18.54-1 |
| Gebaut am | 2026-09-25 |
| Groesse | 112 MB |
| SHA-256 | `9bb660d61b73b7a2d11dcd7f1277ce8f3041a5d9e2cb4e1c50cab7e601dffadb` |

## Fehlerberichte zum MacBookPro16,1

| Bericht | Inhalt | Stand |
| --- | --- | --- |
| 179 | "Scheduling while atomic" im Audio-Pfad von `apple_bce`, unerwartete Neustarts | offen |
| 215 | Nullzeigerzugriff in `t2bce_dma_reserve_submission` beim Aufwachen aus S3, Reihe 7.2.6 und 7.2.7 | offen |

Die Berichte waren ueber die GitHub-Programmierschnittstelle nicht
abrufbar. Sie wurden mittelbar ueber eine Websuche erfasst.
Das Pruefergebnis dieser Einzelangaben lautet deshalb MITTELBAR.

## Verwendet in

- [[MAXIMUS T2 Installer]]
- [[T2Linux]]
- [[t2bce]]
