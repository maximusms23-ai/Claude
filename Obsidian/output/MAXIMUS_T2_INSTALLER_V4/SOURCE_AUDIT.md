---
title: Quellenprüfung MAXIMUS T2Linux Installer V4
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, quellenprüfung, macbookpro16-1]
---

# Quellenprüfung

Stand: 2026-10-10. Alle Angaben wurden am Prüftag abgerufen und geprüft.

## 1. Zusammenfassung

Die Prüfung umfasst sieben Quellen.
Fünf Quellen sind vollständig bestätigt.
Zwei Quellen waren nur mittelbar erreichbar.

| Quelle | Prüfergebnis |
| --- | --- |
| APT-Repositorium für T2 Macs (gemeinsam) | BESTÄTIGT |
| APT-Repositorium für T2 Macs (noble) | BESTÄTIGT |
| T2 Debian and Ubuntu Kernel | BESTÄTIGT |
| linux-t2-patches | BESTÄTIGT |
| T2Linux-Wiki (Quelltext im Git) | BESTÄTIGT |
| Fehlerberichte auf GitHub | MITTELBAR |
| Apple-Firmware (Wiederherstellungsabbild) | NICHT BEZOGEN |

## 2. Vertrauenskette der Paketquellen

Die Prüfung folgt vier Stufen. Jede Stufe wurde einzeln nachgewiesen.

```
[1] GPG-Schlüssel
      Fingerabdruck 9F9873A566A73E27CFF0294FE2E496114ACDBFD4
      Inhaber: Aditya Garg <gargaditya08@live.com>
      RSA 4096 Bit, erzeugt am 2022-09-25
              |
              v
[2] InRelease-Datei
      GPG-Signatur geprüft -> "Good signature"
              |
              v
[3] Packages-Index
      SHA-256 aus der signierten Release-Datei -> stimmt überein
              |
              v
[4] Jede einzelne Paketdatei
      SHA-256 aus dem Packages-Index -> stimmt bei allen 14 Dateien überein
```

### Nachweis Stufe 3

| Repositorium | SHA-256 laut Release | Gemessen | Ergebnis |
| --- | --- | --- | --- |
| gemeinsam | `fe3fa76d671e605293abf2cd4d7c208ecac7c23197ff66b112b0c3853778b811` | gleich | OK |
| noble | `f324dc120338e4b5545121783fb9872d53b6ab65ad8de4bdd707c7f2e7fd9378` | gleich | OK |

## 3. Quellen im Einzelnen

### 3.1 APT-Repositorium für T2 Macs (gemeinsames Repositorium)

| Feld | Wert |
| --- | --- |
| Projekt | APT repository for T2 Macs |
| Herausgeber | Aditya Garg (AdityaGarg8) |
| Repository-URL | `https://github.com/AdityaGarg8/t2-ubuntu-repo` |
| Paketquelle | `https://adityagarg8.github.io/t2-ubuntu-repo ./` |
| Commit | `6068d948b4df9ac63d2da2ada7e2a4f5f9e52393` |
| Veröffentlichungsdatum | 2026-10-04 (Commit), Release-Datei 2026-09-19 |
| Signatur | GPG, Fingerabdruck 9F98 73A5 66A7 3E27 CFF0 294F E2E4 9611 4ACD BFD4 |
| Hardwarekompatibilität | alle T2-Macs, Pakete architekturunabhängig oder amd64 |
| Entnommene Pakete | `apple-firmware-script` 1.4-3, `apple-t2-audio-config` 0.5.1, `t2-apple-audio-dsp-mic` 0.4.0-1, `t2-apple-audio-dsp-speakers161` 0.2.0-1, `t2fanrd` 0.1.0-4, `t2-ncm` 0.1.0-2, `t2-touchid` 0.1.0-3 |
| Bekannte Fehler | Das Repositorium enthält auch `apple-bce`, `apple-touchbar`, `applesmc-t2`, `bcm5974-t2` und `apfs-dkms`. Diese Pakete erzeugen Konflikte mit dem T2-Kernel. |
| Prüfergebnis | BESTÄTIGT. Signatur gültig, alle Prüfsummen stimmen. |

### 3.2 APT-Repositorium für T2 Macs (noble)

| Feld | Wert |
| --- | --- |
| Paketquelle | `https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/noble ./` |
| Release-Datum | 2026-10-05 23:29:56 UTC |
| Signatur | GPG, gleicher Schlüssel wie 3.1, Signatur gültig |
| Entnommene Pakete | `linux-t2-lts` 6.18.54-1-noble, `linux-headers-6.18.54-1-t2-noble`, `linux-image-6.18.54-1-t2-noble`, dieselben Pakete in 6.18.53-1 als Rückfall, `tiny-dfr` 0.3.7-4-noble |
| Verfügbare Kernelreihen | LTS 6.18.51 bis 6.18.54, Mainline 7.2.4 bis 7.2.9-2, Xanmod-Varianten |
| Bekannte Fehler | Die Suspend-Korrekturen aus den Treiberzweigen sind in diesen Paketen noch nicht enthalten. |
| Prüfergebnis | BESTÄTIGT. |

### 3.3 T2 Debian and Ubuntu Kernel

| Feld | Wert |
| --- | --- |
| Projekt | T2 Debian and Ubuntu Kernel |
| Herausgeber | t2linux |
| Repository-URL | `https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel` |
| Commit (HEAD) | `4af5919a5e2f7ffccbd0c54e8b6d7d149e5c49b1` |
| Gewählte Fassung | `linux-image-6.18.54-1-t2-noble`, gebaut am 2026-09-25 |
| Hardwarekompatibilität | T2-Macs, amd64. Enthält die T2-Treiber fest eingebaut. |
| Bekannte Fehler | Fehlerbericht 179 und 215. Siehe Abschnitt 4. |
| Prüfergebnis | BESTÄTIGT. Die Paketdatei stimmt mit dem signierten Index überein. |

### 3.4 linux-t2-patches

| Feld | Wert |
| --- | --- |
| Projekt | linux-t2-patches |
| Herausgeber | t2linux |
| Repository-URL | `https://github.com/t2linux/linux-t2-patches` |
| Commit (HEAD) | `65fdd4d492d7e219a05742ce4768f16e5ba4f976` |
| Rolle | Quelle der Patches, die in die Kernelpakete einfließen |
| Prüfergebnis | BESTÄTIGT als Quelle. Die Patches wurden nicht einzeln bewertet. |

### 3.5 T2Linux-Wiki

| Feld | Wert |
| --- | --- |
| Projekt | t2linux wiki |
| Repository-URL | `https://github.com/t2linux/wiki` |
| Abgerufene Seiten | `docs/state.md`, `docs/guides/postinstall.md`, `docs/guides/wifi-bluetooth.md`, `docs/guides/audio-config.md`, `docs/guides/fan.md`, `docs/guides/hybrid-graphics.md`, `docs/tools/firmware.sh` |
| Hinweis | Die Webseite `wiki.t2linux.org` war aus der Bauumgebung nicht erreichbar. Der Quelltext wurde direkt aus dem Git-Repositorium gelesen. Der Inhalt ist derselbe. |
| Prüfergebnis | BESTÄTIGT. |

### 3.6 Fehlerberichte auf GitHub

Die GitHub-Programmierschnittstelle war aus der Bauumgebung gesperrt.
Die Berichte wurden daher über eine Websuche erfasst.
Das Prüfergebnis lautet deshalb MITTELBAR.

| Bericht | Modell | Inhalt | Stand |
| --- | --- | --- | --- |
| `t2linux/T2-Debian-and-Ubuntu-Kernel` 179 | MacBookPro16,1 | "Scheduling while atomic" im Audio-Pfad von `apple_bce`. Folge sind plötzliche Neustarts ohne Fehlerbild. Ein Kernelwechsel von 6.18.2 auf 6.19.5 half nicht. Das Sperren von `apple_bce` beendete die Neustarts, deaktivierte aber Audio und Touch Bar. | offen, etwa 222 Tage alt |
| `t2linux/T2-Debian-and-Ubuntu-Kernel` 215 | MacBookPro16,1 | Absturz beim Aufwachen aus S3. Nullzeigerzugriff in `t2bce_dma_reserve_submission` auf `linux-t2` 7.2.6 und 7.2.7. | offen, etwa 15 Tage alt |
| `t2linux/kernel` 31 | MacBookPro16,1 | Der Zustandsspeicher für den Ruhezustand ist mit 8 KiB zu klein. Folge sind minutenlange Hänger oder ein Verlust des internen USB-Busses. Gemessen auf 6.18.52 LTS. | offen |
| `t2linux/T2-Ubuntu` 195 | MacBookPro15,1 | Abstürze beim Ruhezustand durch die AMD-Grafik und einen Geisterbildschirm. Betrifft das 16,1 nur mittelbar. | offen |

## 4. Kernelauswahl

### FRAGESTELLUNG

Welche Kernelreihe ist für das MacBookPro16,1 die beste gültige Wahl?
Der bisherige Kandidat war `linux-t2-lts` 6.18.54.

### UMSETZUNG

Drei Kandidaten standen zur Wahl.

| Kandidat | Höchste Fassung | Vorteil | Nachgewiesenes Risiko |
| --- | --- | --- | --- |
| `linux-t2-lts` | 6.18.54-1-noble | Langzeitpflege, kleinere Änderungsschritte | Bericht 31: Hänger im Ruhezustand, gemessen auf 6.18.52 |
| `linux-t2` (Mainline) | 7.2.9-2-noble | neuester Treiberstand, neuere `amdgpu`-Fassung | Bericht 215: Absturz beim Aufwachen auf **genau diesem Modell**, Reihe 7.2.6/7.2.7 |
| `linux-t2-xanmod-lts` | 6.18.51-xanmod1 | veränderte Planung für Interaktivität | älter als die LTS-Reihe, zusätzliche Abweichung vom Standard |

Entscheidung: **`linux-t2-lts` 6.18.54-1-noble**.

Begründung in drei Schritten:

1. Beide Reihen haben Fehler im Ruhezustand. Der Ruhezustand wird bei der
   Installation ohnehin abgeschaltet. Dieser Fehler wiegt daher gleich.
2. Die Reihe 7.2 hat zusätzlich einen Absturz beim Aufwachen, der genau für
   das MacBookPro16,1 gemeldet ist. Dieser Bericht ist 15 Tage alt und offen.
3. 6.18.54 ist die höchste Fassung der LTS-Reihe im noble-Repositorium.
   Die Touch-Bar-Treiber sind seit Kernel 6.15 im Hauptzweig. Die Reihe 6.18
   enthält sie vollständig.

Der Kandidat 6.18.54 wurde also nicht ungeprüft übernommen.
Er wurde gegen zwei Alternativen bewertet und bestätigt.

Zusätzlich liegt `linux-t2-lts` 6.18.53-1-noble im Paket.
Dieser Kernel dient als T2-Rückfall, falls 6.18.54 nicht startet.

### MEHRWERT

Du startest mit der Reihe, für die kein modellbezogener Absturz offen ist.
Du hast drei Rückfallstufen: 6.18.53-t2, Ubuntu 7.0.0-38 und Ubuntu 7.0.0-31.

## 5. Treiberpakete: bewusst nicht verwendet

### FRAGESTELLUNG

Welche Pakete der T2-Quellen dürfen nicht installiert werden?

### UMSETZUNG

Das Herausgeber-Dokument warnt ausdrücklich.
Der Kernel `linux-t2-lts` enthält diese Treiber bereits fest eingebaut.

| Paket | Grund für den Ausschluss |
| --- | --- |
| `apple-bce` | Im Kernel enthalten, hier als Nachfolger `t2bce`. Zusätzlich die Ursache in Bericht 179. |
| `apple-touchbar` | Im Kernel enthalten. |
| `applesmc-t2` | Im Kernel enthalten. |
| `bcm5974-t2` | Im Kernel enthalten. |
| `apfs-dkms` | Im Kernel enthalten. Auf dem Zielgerät ist kein macOS mehr vorhanden. |
| `broadcom-wl` | Falscher Treiber. Für den Chip BCM4377 ist `brcmfmac` zuständig. |

Das Skript `scripts/install.sh` prüft die Installationsliste gegen diese
Namen und bricht bei einem Treffer ab.
Das Skript `scripts/selftest.sh` prüft dasselbe vor der Übertragung.

### MEHRWERT

Du vermeidest doppelte Treiber und die daraus folgenden Startfehler.
Die Regel ist zweifach automatisch durchgesetzt.

## 6. Nicht bezogene Quelle: Apple-Firmware

Die WLAN- und Bluetooth-Firmware stammt von Apple.
Sie ist nicht frei weitergebbar.
Sie liegt deshalb **nicht** in diesem Paket.

Das Paket enthält stattdessen:

- das geprüfte Werkzeug `apple-firmware-script` 1.4-3,
- eine Kopie des Hilfsskripts `fetch-macOS-v2.py` mit festgelegter Prüfsumme,
- eine Anleitung in `firmware/README.md`.

Die Offline-Fähigkeit ist deshalb als **PARTIAL** gekennzeichnet.
Siehe `reports/PACKAGE_AUDIT.md`, Abschnitt "Offline-Bewertung".

## 7. Ausgeschlossene Bezugswege

| Bezugsweg | Entscheidung | Grund |
| --- | --- | --- |
| `curl ... \| bash` | ausgeschlossen | Kein nachvollziehbarer Inhalt zur Laufzeit. |
| `git clone` fremder Audio-Skripte | ausgeschlossen | Das Paket `apple-t2-audio-config` liefert denselben Inhalt mit Prüfsumme. |
| Global vertraute APT-Schlüssel in `/etc/apt/trusted.gpg.d/` | ausgeschlossen | Ein solcher Schlüssel gilt für alle Quellen. Das Paket nutzt `signed-by` je Quelle. |
| Unbekannte Installationsskripte | ausgeschlossen | Verstoß gegen die Vorgabe aus Abschnitt 5 des Auftrags. |
