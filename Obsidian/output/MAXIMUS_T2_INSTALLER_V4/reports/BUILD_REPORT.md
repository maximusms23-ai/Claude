---
title: Baubericht MAXIMUS T2Linux Installer V4
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, baubericht]
---

# Baubericht

## 1. Ergebnis zuerst

Das Installationspaket ist erstellt und geprüft.
Status: **PACKAGE_READY**.

Zwei Einschränkungen sind zu beachten.

1. Das Paket liegt **nicht** auf der Samsung T7. Siehe Abschnitt 7.
2. Die Offline-Fähigkeit ist **PARTIAL**. Die Apple-Firmware fehlt. Siehe
   `../firmware/README.md`.

## 2. Bauumgebung

| Angabe | Wert |
| --- | --- |
| Betriebssystem | Ubuntu 24.04.5 LTS (noble) |
| Architektur | amd64 / x86_64 |
| Kernel der Bauumgebung | 6.18.44 |
| Prozessor | Intel Xeon, 4 Kerne |
| Hauptspeicher | 15 GB |
| Freier Speicherplatz | 29 GB |
| Isolation | eigenständiger Container, ohne Zugriff auf andere Dienste |

### FRAGESTELLUNG

Ist diese Bauumgebung für das Zielgerät gültig?

### UMSETZUNG

Ja. Die Bauumgebung ist Ubuntu 24.04.5 für amd64.
Das Zielgerät ist Ubuntu 24.04.5 für amd64.
Die Paketauflösung erfolgt damit gegen genau denselben Paketbestand.

Auf der Bauumgebung wurde **kein** T2-Kernel installiert.
Es wurden nur Pakete geladen und eingeordnet.
Es wurden keine Modelle und keine Dienste verändert.

### MEHRWERT

Die aufgelösten Abhängigkeiten gelten ohne Umrechnung für das Zielgerät.

### Abweichung von der Auftragsannahme

Der Auftrag nennt einen RTX-4080-Rechner.
Diese Bauumgebung hat keine Grafikkarte und kein `lspci`.
Das ist für den Paketbau ohne Belang. Es wird nichts kompiliert.
Der Paketbau benötigt nur eine passende Ubuntu-Umgebung und Netzzugang.

## 3. Paketbestand

| Stufe | Pakete | Umfang | Quelle |
| --- | --- | --- | --- |
| `packages/t2linux/` | 14 | 236 MB | T2-Repositorien (gemeinsam und noble) |
| `packages/ubuntu/` | 24 | 9,2 MB | Ubuntu noble, noble-updates, noble-security |
| `packages/dependencies/` | 447 | 227 MB | Ubuntu noble, noble-updates, noble-security |
| **Gesamt** | **485** | **472 MB** | — |

Das Rahmenwerk ohne Nutzlast umfasst 37 Dateien und 452 KB.

### Gewählter Kernel

| Angabe | Wert |
| --- | --- |
| Paket | `linux-t2-lts` 6.18.54-1-noble |
| Kernelversion | 6.18.54-1-t2-noble |
| Abbild | `linux-image-6.18.54-1-t2-noble` 6.18.54-1, 112 MB, gebaut am 2026-09-25 |
| Kopfdateien | `linux-headers-6.18.54-1-t2-noble` 6.18.54-1, 10,2 MB |
| T2-Rückfall | `linux-t2-lts` 6.18.53-1-noble, vollständig im Paket |

Die Begründung der Kernelwahl steht in `../SOURCE_AUDIT.md`, Abschnitt 4.

### T2-Pakete im Einzelnen

| Paket | Fassung | Zweck |
| --- | --- | --- |
| `linux-t2-lts` | 6.18.54-1-noble | Sammelpaket des Kernels |
| `linux-image-6.18.54-1-t2-noble` | 6.18.54-1 | Kernelabbild mit T2-Treibern |
| `linux-headers-6.18.54-1-t2-noble` | 6.18.54-1 | Kopfdateien |
| `linux-t2-lts` | 6.18.53-1-noble | Rückfallkernel |
| `linux-image-6.18.53-1-t2-noble` | 6.18.53-1 | Rückfallabbild |
| `linux-headers-6.18.53-1-t2-noble` | 6.18.53-1 | Rückfall-Kopfdateien |
| `tiny-dfr` | 0.3.7-4-noble | Dienst für die Funktionsreihe der Touch Bar |
| `t2fanrd` | 0.1.0-4 | Lüfterdienst |
| `apple-t2-audio-config` | 0.5.1 | ALSA-UCM-Profile `AppleT2x2`, `x4`, `x6` |
| `t2-apple-audio-dsp-speakers161` | 0.2.0-1 | Lautsprecherkette für das 16-Zoll-Modell 2019 |
| `t2-apple-audio-dsp-mic` | 0.4.0-1 | Mikrofonkette |
| `apple-firmware-script` | 1.4-3 | Befehl `get-apple-firmware` |
| `t2-ncm` | 0.1.0-2 | interne USB-Netzwerkschnittstelle des T2-Chips |
| `t2-touchid` | 0.1.0-3 | Touch ID, nur mit in macOS angelegten Fingerabdrücken |

### Bewusst ausgeschlossen

`apple-bce`, `apple-touchbar`, `applesmc-t2`, `bcm5974-t2`, `apfs-dkms`,
`broadcom-wl`.

Begründung: Der Kernel `linux-t2-lts` enthält diese Treiber fest eingebaut.
Der Herausgeber warnt ausdrücklich vor einer zusätzlichen Installation.
Für WLAN ist `brcmfmac` zuständig, nicht `broadcom-wl`.

## 4. Abhängigkeitsauflösung

### FRAGESTELLUNG

Reicht ein Paketdownload als Nachweis der Offline-Fähigkeit?

### UMSETZUNG

Nein. Ein Download belegt nur, dass Dateien vorliegen.
Der Nachweis erfolgt deshalb in drei Schritten.

1. **Auflösung gegen einen leeren Paketbestand.**
   Eine isolierte Paketverwaltung mit leerer `dpkg`-Statusdatei löste alle
   33 angeforderten Pakete auf. Ergebnis: 482 Pakete.
   Ein leerer Bestand ist der strengste Fall. Er erzwingt die vollständige
   Abhängigkeitskette, auch `libc6` und `dpkg`.
2. **Auflösung ausschließlich aus der lokalen Quelle.**
   Eine zweite isolierte Paketverwaltung kannte **nur** die Datei
   `file://.../packages ./`. Kein Netzzugang. Ergebnis: dieselben
   482 Pakete, keine fehlende Abhängigkeit.
3. **Gegenprobe auf Entfernungen.**
   Die Simulation enthält keine Zeile `Remv`. Es wird kein Paket entfernt.
   Das Installationsskript bricht ab, falls eine solche Zeile auftritt.

Die 485 Dateien im Paket sind drei mehr als die 482 der Auflösung.
Die drei zusätzlichen Dateien sind der Rückfallkernel 6.18.53.
Er wird nicht automatisch installiert.

### MEHRWERT

Die Offline-Fähigkeit auf Paketebene ist gemessen, nicht angenommen.

## 5. Integritäts- und Sicherheitsprüfung

### Vertrauenskette

| Stufe | Nachweis | Ergebnis |
| --- | --- | --- |
| GPG-Schlüssel | Fingerabdruck `9F9873A566A73E27CFF0294FE2E496114ACDBFD4` | bestätigt |
| `InRelease` gemeinsames Repositorium | GPG-Prüfung | gültig |
| `InRelease` noble-Repositorium | GPG-Prüfung | gültig |
| `Packages`-Index | SHA-256 aus der signierten `Release`-Datei | übereinstimmend |
| 14 T2-Paketdateien | SHA-256 aus dem `Packages`-Index | alle übereinstimmend |
| 471 Ubuntu-Paketdateien | APT prüft gegen die signierten Ubuntu-Indizes | alle übereinstimmend |
| Ubuntu-Archivschlüssel | `/usr/share/keyrings/ubuntu-archive-keyring.gpg` über `signed-by` | genutzt |

### Umsetzung von `signed-by`

Alle Paketquellen der Bauumgebung nutzen `signed-by`.
Kein Schlüssel liegt in `/etc/apt/trusted.gpg.d/`.
Ein Schlüssel gilt damit nur für die Quelle, zu der er gehört.

Die Vorlage für den Online-Rückfallweg auf dem Zielgerät liegt in
`../config/apt/t2-online.list.template`. Sie nutzt ebenfalls `signed-by`.

## 6. Skript- und Strukturprüfung

| Prüfung | Werkzeug | Ergebnis |
| --- | --- | --- |
| Eigenprüfung gesamt | `scripts/selftest.sh`, 13 Testgruppen | **102 bestanden, 0 fehlgeschlagen** |
| Syntax aller Skripte | `bash -n` | 9 von 9 ohne Fehler |
| Statische Analyse | ShellCheck 0.9.0, `-x -s bash` | 9 von 9 ohne Befund |
| Einheitstest GRUB-Menüerkennung | Testgruppe 8 | 3 Fälle bestanden |
| Einheitstest GRUB-Konfiguration | Testgruppe 9b | 13 Fälle bestanden |
| Schreibpfade und verbotene Befehle | Testgruppe 9 | alle Pfade in der Freigabeliste |
| Konfliktpakete | Testgruppe 5 | keines in der Liste |
| Dateipfade | Testgruppe 1 | 35 von 35 vorhanden |
| Prüfsummen | Testgruppe 12 | Rahmenwerk und 485 Paketdateien |
| Negativtests der Sperren | 9 Aufrufe | alle Rückgabecodes wie geplant |

Die Einzelergebnisse stehen in `PACKAGE_AUDIT.md`, Abschnitt 12.

Das Bauskript `fetch-packages.sh` wurde vollständig durchlaufen.
Alle zehn Schritte endeten mit Erfolg.

Zwei Befunde aus dem Test wurden behoben.
Sie stehen in `PACKAGE_AUDIT.md`, Abschnitt 12.3.

## 7. Nicht erledigt: Übertragung auf die Samsung T7

### FRAGESTELLUNG

Warum liegt das Paket nicht auf der Samsung T7?

### UMSETZUNG

Die Bauumgebung ist ein Container ohne USB-Durchgriff.
Die Prüfung ergab:

| Prüfung | Befund |
| --- | --- |
| `lsblk` | nur virtuelle Geräte `vda` bis `vdf` |
| `lsusb` | nicht vorhanden |
| USB-Bus | nicht durchgereicht |
| Samsung T7 | nicht sichtbar |

Nach Abschnitt 7 des Auftrags ist in diesem Fall der Schreibvorgang zu
stoppen. Genau das ist geschehen. Es wurde nichts geschrieben.

Das Paket wurde stattdessen in das Git-Repositorium gelegt, Zweig
`claude/maximus-strata-validation-c44vzz`, Pfad
`Obsidian/output/MAXIMUS_T2_INSTALLER_V4/`.

Dein nächster Schritt auf dem RTX-4080-Rechner:

```bash
git clone <repo-url> maximus-claude
cd maximus-claude/Obsidian/output/MAXIMUS_T2_INSTALLER_V4
bash scripts/fetch-packages.sh
bash scripts/selftest.sh
sudo bash scripts/deploy-to-t7.sh --dry-run
sudo bash scripts/deploy-to-t7.sh
```

Das Skript `deploy-to-t7.sh` erkennt die Samsung T7 über Modell, Hersteller
und Seriennummer. Es nimmt keinen Gerätenamen an. Es formatiert nicht.
Es löscht nicht. Es bricht ab, wenn die SSD nicht eindeutig ist.

### MEHRWERT

Die Übertragung bleibt vollständig nachvollziehbar und prüfbar.
Sie läuft dort, wo die SSD tatsächlich angeschlossen ist.

## 8. Offene Risiken

| Nr. | Risiko | Nachweis | Gegenmaßnahme im Paket |
| --- | --- | --- | --- |
| 1 | Unerwartete Neustarts aus dem Audio-Pfad | Fehlerbericht 179, MacBookPro16,1 | Anleitung in `../recovery/RESTORE.md`, Abschnitt 6 |
| 2 | Ruhezustand hängt oder stürzt ab | Fehlerbericht 31 und 215 | Ruhezustand wird abgeschaltet |
| 3 | CPU erreichte 98 Grad Celsius | MAXIMUS-Audit | `t2fanrd` mit Kurve 55 bis 80 Grad, Lasttest bricht bei 90 Grad ab |
| 4 | Kein WLAN ohne Apple-Firmware | T2Linux-Wiki | Anleitung und geprüfte Werkzeuge in `../firmware/` |
| 5 | Abstürze der Radeon Pro 5500M | T2Linux-Zustandsseite | Optionale Parameter in `../config/grub/OPTIONAL-PARAMS.md` |
| 6 | Kein Live-USB-Medium vorhanden | MAXIMUS-Audit | Notstartanleitung in `../recovery/GRUB-NOTSTART.txt` |
| 7 | Beschädigter Bootloader trotz zweier Kernel | allgemein | Sicherung vor jeder Änderung, Syntaxprüfung, kein Eingriff in EFI und NVRAM |
| 8 | Funkchip möglicherweise BCM4377 statt BCM4364 | Bauart des Modells | `preflight.sh` liest den Chip aus und meldet ihn |

## 9. Statusbewertung

| Status | Wert | Begründung |
| --- | --- | --- |
| PACKAGE_READY | **erteilt** | 485 Pakete geprüft, Offline-Auflösung nachgewiesen, 8 Skripte ohne Befund |
| INSTALLATION_READY | **nicht erteilt** | Die Vorprüfung auf dem MacBook ist noch nicht gelaufen |
| HARDWARE_READY | **nicht erteilt** | Es liegt kein Hardwaretest vor |
| MAXIMUS_WORKER_READY | **nicht erteilt** | Es liegt kein Dauerbetriebsnachweis vor |
| Offline-Fähigkeit | **PARTIAL** | Die Apple-Firmware benötigt einmalig Netzzugang |
