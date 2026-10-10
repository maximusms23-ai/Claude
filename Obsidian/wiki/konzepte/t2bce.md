---
title: t2bce
created: 2026-10-10
aliases:
  - t2bce
  - apple-bce
type: konzept
tags:
  - t2linux
  - kernel
  - treiber
---

# t2bce

t2bce ist der Treiberstapel fuer den Apple-T2-Chip unter Linux.
Die Abkuerzung steht fuer "T2 Buffer Copy Engine".

## Aufgabe

Der T2-Chip haengt am PCI-Bus. Er stellt dort keine normalen USB-Anschluesse
bereit. t2bce uebersetzt das. Es meldet dem Kernel einen virtuellen
USB-Hostadapter. Erst dadurch erscheinen die internen Geraete.

Daran haengen:

- interne Tastatur
- Trackpad
- Touch Bar
- Kamera
- Audio (Lautsprecher, Mikrofon, Kopfhoererbuchse)

## Module

| Modul | Aufgabe |
| --- | --- |
| `t2bce_dma` | direkter Speicherzugriff zum T2-Chip |
| `t2bce_core` | Grundfunktionen und Nachrichtenwarteschlangen |
| `t2bce_vhci` | virtueller USB-Hostadapter |
| `t2bce_audio` | Audiogeraet des T2-Chips |

Die drei erstgenannten Module muessen in der Initialramdisk liegen.
Nur dann arbeitet die interne Tastatur schon in der ersten Startphase.
Das ist bei verschluesselten Datentraegern und bei der Fehlersuche wichtig.

Eintrag in `/etc/initramfs-tools/modules`:

```
t2bce_dma
t2bce_core
t2bce_vhci
```

## Vorgaenger apple-bce

t2bce ist der Nachfolger von `apple-bce`.
`apple-bce` war ein DKMS-Modul. Es wurde getrennt vom Kernel gebaut.

Wichtige Regel: Wer einen T2-Kernel (`linux-t2`, `linux-t2-lts`) nutzt,
darf `apple-bce` **nicht** zusaetzlich installieren.
Dasselbe gilt fuer `apple-touchbar`, `applesmc-t2`, `bcm5974-t2` und
`apfs-dkms`. Diese Treiber sind im Kernel enthalten.
Eine doppelte Installation erzeugt Konflikte.

## Ruhezustand

t2bce verwaltet den Ruhezustand des Chips selbst.
Die Module duerfen vor dem Ruhezustand **nicht** entladen werden.
Ein erzwungenes Entladen reisst aktive Warteschlangen ab.
Interne Geraete sind danach nicht mehr erreichbar.

Aeltere Anleitungen fuer `apple-bce` empfahlen das Entladen.
Diese Anleitungen sind fuer t2bce falsch.

## Verweise

- Thema: [[T2Linux]]
- Kernel: [[T2-Debian-and-Ubuntu-Kernel]]
- Projekt: [[MAXIMUS T2 Installer]]
