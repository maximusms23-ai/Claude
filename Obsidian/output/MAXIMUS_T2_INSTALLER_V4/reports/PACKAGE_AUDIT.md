---
title: Paketprüfung MAXIMUS T2Linux Installer V4
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, paketprüfung, integrität]
---

# Paketprüfung

## 1. Ergebnis zuerst

| Prüffeld | Ergebnis |
| --- | --- |
| Paketabhängigkeiten | PASS |
| Offline-Auflösbarkeit | PASS |
| Integrität der Paketdateien | PASS |
| Signaturprüfung der Quellen | PASS |
| ShellCheck | PASS |
| Dateipfade | PASS |
| Installationsreihenfolge | PASS |
| Schreibzugriffe | PASS |
| Bootloader-Risikoanalyse | PASS mit Auflage |
| Rückfallfunktionen | PASS mit Auflage |
| Skript- und Einheitstests | PASS (102 von 102) |
| Offline-Fähigkeit insgesamt | **PARTIAL** |

Die Einzelergebnisse der Skripttests stehen in Abschnitt 12.

## 2. Paketabhängigkeitsprüfung

| Angabe | Wert |
| --- | --- |
| Angeforderte Pakete | 33 |
| Aufgelöste Pakete | 482 |
| Dateien im Paket | 485 (einschließlich Rückfallkernel) |
| Entfernte Pakete in der Simulation | 0 |
| Nicht erfüllbare Abhängigkeiten | 0 |
| Konflikte | 0 |

Der Zielbestand war bei der Prüfung leer.
Das ist der strengste Fall. Auf dem Zielgerät sind viele dieser Pakete
bereits installiert. APT installiert dann nur die fehlenden.

## 3. Offline-Auflösbarkeit

### FRAGESTELLUNG

Lässt sich der gesamte Stapel ohne Netzzugang installieren?

### UMSETZUNG

Versuchsaufbau:

```
Isolierte Paketverwaltung
  dpkg-Status:     leer
  Paketquellen:    NUR file:///.../packages ./
  Netzzugang:      keiner
  Architektur:     amd64
```

Ergebnis: `0 upgraded, 482 newly installed, 0 to remove, 0 not upgraded`.

Dieselbe Prüfung führt `scripts/preflight.sh` auf dem Zielgerät aus.
Dort nutzt sie die echte `dpkg`-Statusdatei des MacBooks.
Damit prüft sie gegen den tatsächlichen Paketbestand des Zielgeräts.

### MEHRWERT

Die Offline-Fähigkeit auf Paketebene ist bewiesen, nicht behauptet.

## 4. Integritätsprüfung sämtlicher Paketdateien

| Prüfung | Umfang | Ergebnis |
| --- | --- | --- |
| SHA-256 gegen den signierten T2-Index | 14 Dateien | alle übereinstimmend |
| SHA-256 durch APT gegen die Ubuntu-Indizes | 471 Dateien | alle übereinstimmend |
| `packages/SHA256SUMS.debs` | 485 Zeilen | erzeugt und geprüft |

Drei Prüfpunkte nutzen diese Liste:

1. `scripts/selftest.sh` vor der Übertragung auf die Samsung T7.
2. `scripts/deploy-to-t7.sh` nach der Übertragung, direkt auf der SSD.
3. `scripts/preflight.sh` und `scripts/install.sh` auf dem Zielgerät.

Bei einer Abweichung bricht die Installation mit Code 13 ab.

## 5. Prüfung aller Dateipfade

| Prüfung | Ergebnis |
| --- | --- |
| Pflichtdateien vorhanden | 31 von 31 |
| Pflichtverzeichnisse vorhanden | 4 von 4 |
| Pfade in `install.sh` verweisen auf vorhandene Dateien | ja |
| Relative Pfade statt fester Pfade | ja, alle Skripte leiten die Paketwurzel ab |
| Pfade mit Leerzeichen | in Anführungszeichen gesetzt, von ShellCheck bestätigt |

## 6. Prüfung der Installationsreihenfolge

Die Reihenfolge in `scripts/install.sh` ist festgelegt und geprüft.

```
 1. Vorpruefung                       -> Abbruch bei falschem Modell oder System
 2. Pruefsummen pruefen               -> Abbruch bei Abweichung
 3. Paketliste gegen Konflikte pruefen-> Abbruch bei Konfliktpaket
 4. Boot-Konfiguration sichern        -> vor jeder Aenderung
 5. Vorhandene Kernel schuetzen       -> apt-mark hold
 6. Lokale Paketquelle einrichten
 7. Installation simulieren           -> Abbruch bei Entfernungen
 8. Benutzerfreigabe                  -> Eingabe JA erforderlich
 9. Pakete installieren
10. Kernelabbild pruefen              -> Abbruch, falls es fehlt
11. Konfigurationsdateien schreiben
12. Luefterdienst einrichten
13. Kernelparameter in GRUB ergaenzen
14. Initialramdisk und GRUB-Menue erzeugen
15. Syntax der GRUB-Konfiguration pruefen -> Abbruch bei Fehler
16. T2-Eintrag im Menue pruefen       -> Abbruch, falls er fehlt
17. Einmaligen Teststart setzen
```

Wichtige Eigenschaften dieser Reihenfolge:

1. Die Sicherung liegt **vor** der ersten Änderung.
2. Der Kernelschutz liegt **vor** der Paketinstallation.
3. Die Freigabe liegt **nach** der Simulation. Du entscheidest mit Kenntnis
   des genauen Umfangs.
4. Die Prüfung des GRUB-Menüs liegt **vor** dem Teststart.

## 7. Prüfung auf Schreibzugriffe außerhalb des Zielverzeichnisses

### Freigabeliste

Die Datei `scripts/lib/common.sh` führt die erlaubten Schreibziele.
Der Test 9 in `scripts/selftest.sh` prüft jeden Schreibpfad aus
`install.sh` gegen diese Liste.

Erlaubte Ziele:

```
/etc/apt            /etc/default          /etc/modprobe.d
/etc/modules-load.d /etc/initramfs-tools  /etc/pipewire
/etc/NetworkManager /etc/udev/rules.d     /etc/systemd
/etc/t2fand.conf    /boot                 /usr
/lib/modules        /var/lib/dpkg         /var/cache/apt
/var/backups/maximus-t2  /var/lib/maximus-t2  /var/log/maximus-t2
```

Die Ziele unter `/usr`, `/lib/modules`, `/boot`, `/var/lib/dpkg` und
`/var/cache/apt` schreibt ausschließlich `dpkg` während der Paketinstallation.

### Verbotene Befehle

Kein Skript enthält `mkfs`, `dd if=`, `sgdisk`, `parted`, `wipefs`, `fdisk`,
`efibootmgr` oder `nvram`.
Kein Skript enthält `rm -rf /`.
Kein Skript leitet einen Download in eine Shell.

Der Test 9 prüft dies bei jedem Lauf.

### Simulationsbetrieb

Im Betrieb `--dry-run` schreibt `install.sh` nichts.
Jeder Befehl läuft durch die Funktion `run`. Sie gibt den Befehl nur aus.
Jedes Schreiben läuft durch `write_file`. Sie nennt nur Quelle und Ziel.

## 8. Bootloader-Risikoanalyse

### FRAGESTELLUNG

Wie groß ist das Risiko, dass das Gerät nicht mehr startet?

### UMSETZUNG

| Risikoquelle | Bewertung | Gegenmaßnahme |
| --- | --- | --- |
| Fehlerhafte `grub.cfg` | mittel | Syntaxprüfung mit `bash -n`, Abbruch vor dem Neustart, Sicherung vorhanden |
| Fehlendes Kernelabbild | mittel | Prüfung auf `/boot/vmlinuz-6.18.54-1-t2-noble`, Abbruch |
| Fehlende Initialramdisk | mittel | `update-initramfs` wird geprüft, Abbruch bei Fehler |
| Entfernter Ubuntu-Kernel | hoch, wenn eingetreten | `apt-mark hold`, Abbruch der Simulation bei `Remv` |
| Unsichtbares GRUB-Menü | hoch, wenn eingetreten | `GRUB_TIMEOUT=10`, `GRUB_TIMEOUT_STYLE=menu` |
| Dauerhaft falscher Standardkernel | mittel | `GRUB_DEFAULT=saved`, `GRUB_SAVEDEFAULT=false`, Teststart über `grub-reboot` wirkt nur einmal |
| Veränderte EFI-Partition | hoch, wenn eingetreten | Kein Skript greift auf EFI zu. Test 9 prüft das. |
| Veränderter NVRAM | hoch, wenn eingetreten | Kein Skript nutzt `efibootmgr` oder `nvram`. Test 9 prüft das. |
| Veränderte Partitionstabelle | hoch, wenn eingetreten | Kein Skript nutzt `parted`, `sgdisk`, `fdisk`. Test 9 prüft das. |
| Interne Tastatur im GRUB-Menü | **nicht behebbar** | Der T2-Chip liefert die Tastatur erst unter Linux. Eine USB-Tastatur ist erforderlich. |

### Auflage

Das Ergebnis lautet **PASS mit Auflage**.

Die Auflage hat zwei Teile:

1. Schließe eine USB-Tastatur **vor** dem ersten Neustart an.
2. Drucke `recovery/GRUB-NOTSTART.txt` aus und lege das Blatt bereit.

Begründung: Zwei vorhandene Kernel sind keine Garantie für einen Start.
Ein beschädigter Bootloader verhindert den Start trotz vorhandener Kernel.
Ohne Live-USB-Medium ist die Notstartanleitung der einzige Rückfallweg.

## 9. Prüfung der Rückfallfunktionen

| Stufe | Rückfall | Nachweis |
| --- | --- | --- |
| 1 | T2-Kernel 6.18.53-1-t2-noble | liegt im Paket, 112 MB |
| 2 | Ubuntu-Kernel 7.0.0-38-generic | durch `apt-mark hold` geschützt |
| 3 | Ubuntu-Kernel 7.0.0-31-generic | durch `apt-mark hold` geschützt |
| 4 | Konfigurationsrückfall | `scripts/rollback.sh` mit Simulationsbetrieb |
| 5 | Notstart über die GRUB-Eingabeaufforderung | `recovery/GRUB-NOTSTART.txt`, Fall 3 und 4 |
| 6 | Live-USB-Medium | **nicht vorhanden**, Anleitung in Fall 5 |

Das Skript `rollback.sh` wurde geprüft:

| Prüfung | Ergebnis |
| --- | --- |
| Syntax und ShellCheck | ohne Befund |
| Simulationsbetrieb | vorhanden |
| Schutz vor Entfernung eines Ubuntu-Kernels | vorhanden, bricht ab |
| Rückschreiben der `grub.cfg` bei Fehler | vorhanden |
| Syntaxprüfung nach dem Rückschreiben | vorhanden |

Ergebnis: **PASS mit Auflage**.
Die Auflage: Erstelle ein Live-USB-Medium, sobald das Gerät stabil läuft.

## 10. Offline-Bewertung

### FRAGESTELLUNG

Ist die Installation vollständig offline möglich?

### UMSETZUNG

| Teilbereich | Offline möglich | Begründung |
| --- | --- | --- |
| T2-Kernel und Treiber | ja | 14 Paketdateien liegen im Paket |
| Audio, Lüfter, Touch Bar | ja | alle Pakete liegen im Paket |
| Alle Ubuntu-Abhängigkeiten | ja | 471 Paketdateien liegen im Paket |
| Prüfwerkzeuge für die Abnahme | ja | 24 Paketdateien liegen im Paket |
| Kernelparameter und Konfiguration | ja | liegen als Dateien im Paket |
| **Apple-WLAN- und Bluetooth-Firmware** | **nein** | gehört Apple, nicht weitergebbar |

Ergebnis: **PARTIAL**.

Eine vollständige Offline-Fähigkeit wird nicht behauptet.
Der Online-Schritt ist genau benannt:

| Angabe | Wert |
| --- | --- |
| Was | macOS-Wiederherstellungsabbild von Apple |
| Wann | einmalig, nach der Installation |
| Wie | `sudo get-apple-firmware`, Methode 5 |
| Netzweg | iPhone-USB-Tethering |
| Umfang | mehrere Hundert Megabyte |
| Anleitung | `../firmware/README.md` |

### MEHRWERT

Du kennst den einen Schritt, der Netzzugang braucht.
Alles andere läuft ohne Netz.

## 11. Kritische Qualitätsprüfung

### Vergleich mit der bisherigen besten Fassung

| Entscheidung | Vorher (V3-Annahme) | Jetzt (V4) | Bewertung |
| --- | --- | --- | --- |
| Kernel | `linux-t2-lts` 6.18.54, ungeprüft übernommen | 6.18.54, gegen 7.2.9-2 und Xanmod bewertet | VERBESSERUNG |
| Treibermodule | `apple-bce`, `applesmc-t2` genannt | bewusst ausgeschlossen, zweifach automatisch geprüft | VERBESSERUNG |
| Modulnamen | `apple-bce` | `t2bce_dma`, `t2bce_core`, `t2bce_vhci` | KORREKTUR |
| Audio | allgemeine Konfiguration | `t2-apple-audio-dsp-speakers161`, modellbezogen | VERBESSERUNG |
| Firmware | als lieferbar angenommen | als PARTIAL gekennzeichnet | KORREKTUR |
| Funkchip | BCM4364 angenommen | BCM4377 erwartet, Prüfung im Skript | KORREKTUR |
| Ruhezustand | nicht behandelt | bewusst abgeschaltet, mit Begründung | VERBESSERUNG |
| Rückfall | zwei Ubuntu-Kernel | drei Kernel, Rückfallskript, Notstartblatt | VERBESSERUNG |

Es wurde keine REPAIR_REGRESSION festgestellt.
Keine bisherige Lösung wurde durch eine schlechtere ersetzt.

### Dokumentierte Hardwareeinschränkungen

Siehe `../COMPATIBILITY_MATRIX.md`.
Dort sind 24 Hardwarefunktionen mit ihrer Erwartung und ihrer
nachgewiesenen Einschränkung aufgeführt.
Sechs Funktionen dürfen ohne Einzeltest nicht als arbeitsfähig gelten.

## 12. Skript- und Einheitstests

Das Skript `scripts/selftest.sh` fasst 13 Testgruppen zusammen.
Ergebnis am Prüftag: **102 bestanden, 0 fehlgeschlagen, 0 übersprungen**.

| Testgruppe | Werkzeug | Ergebnis |
| --- | --- | --- |
| 1 Pflichtdateien und Verzeichnisse | eigener Test | 35 von 35 vorhanden |
| 2 Syntax aller Skripte | `bash -n` | 9 von 9 ohne Fehler |
| 3 Statische Analyse | ShellCheck 0.9.0, `-x -s bash` | 9 von 9 ohne Befund |
| 4 Aufrufbarkeit | eigener Test | 7 von 7 |
| 5 Konfliktpakete | eigener Test | keines in der Liste |
| 6 Kernelparameter | eigener Test | 3 von 3 vorhanden |
| 7 Module der Initialramdisk | eigener Test | 3 von 3 vorhanden |
| 8 GRUB-Menüerkennung | Einheitstest mit Vorlage | 3 Fälle bestanden |
| 9 Schreibpfade und verbotene Befehle | Mustersuche mit Gegenprobe | alle Pfade in der Freigabeliste |
| 9b GRUB-Konfiguration | Einheitstest mit 3 Vorlagen | 13 Fälle bestanden |
| 10 Quellenliste der T2-Pakete | eigener Test | 14 Einträge, alle HTTPS und SHA-256 |
| 11 `manifest.json` | `python3 json` | gültiges JSON |
| 12 Prüfsummen | `sha256sum -c` | Rahmenwerk und 485 Paketdateien |

### 12.1 Einheitstest der GRUB-Konfiguration

Die Bearbeitung von `/etc/default/grub` ist der riskanteste Schritt.
Sie liegt deshalb in `scripts/lib/grub-config.sh` und ist einzeln prüfbar.
Die Tests arbeiten auf Kopien von Vorlagen, nie auf der echten Datei.

| Fall | Prüfung | Ergebnis |
| --- | --- | --- |
| 1 | Leere Parameterzeile: alle 4 Parameter werden ergänzt | PASS |
| 1 | Datei und ausgegebene Zeile stimmen überein | PASS |
| 2 | Ein zweiter Aufruf ändert nichts | PASS |
| 3 | Ein fremder Parameter (`mitigations=off`) bleibt erhalten | PASS |
| 3 | Ein bereits gesetzter Parameter wird nicht verdoppelt | PASS |
| 3 | Fehlende Parameter werden ergänzt | PASS |
| 4 | Eine fehlende Parameterzeile wird angelegt | PASS |
| 5 | Eine fehlende Datei wird mit Rückgabe 1 gemeldet | PASS |
| 6 | Alle Menüschlüssel werden gesetzt | PASS |
| 6 | `GRUB_TIMEOUT` wird von 0 auf 10 gesetzt | PASS |
| 6 | Ein auskommentierter Schlüssel wird aktiviert | PASS |
| 6 | Fremde Zeilen bleiben unverändert | PASS |
| 7 | Ein zweiter Aufruf der Schlüsselfunktion ändert nichts | PASS |

Das Installationsskript prüft nach der Bearbeitung zusätzlich, dass jeder
geforderte Parameter wirklich gesetzt ist. Fehlt einer, bricht es mit
Code 16 ab, noch vor `update-grub`.

### 12.2 Negativtests der Sperren

Jede Sperre wurde ausgelöst und der Rückgabecode gemessen.

| Aufruf | Erwartete Sperre | Gemessener Code |
| --- | --- | --- |
| `preflight.sh --quick` auf falscher Hardware | Modell, Rückfallkernel, GRUB | 12 |
| `install.sh --dry-run` | Vorprüfung fehlgeschlagen | 12 |
| `install.sh --dry-run --skip-preflight` | Modellsperre | 10 |
| `install.sh --unbekannt` | Aufruffehler | 2 |
| `rollback.sh --dry-run` ohne Sicherung | keine Sicherung gefunden | 17 |
| `deploy-to-t7.sh --dry-run` ohne SSD | Samsung T7 nicht gefunden | 4 |
| `deploy-to-t7.sh --list` | nur Auflistung, kein Schreiben | 0 |
| `verify.sh --non-interactive` | Abnahme unvollständig | 19 |
| `grub-entry.sh` ohne Argument | Aufruffehler | 2 |

Der Lauf von `verify.sh` bestätigte dabei die thermische Sperre:
Die Lüfterprüfung schlug fehl. Der Lasttest wurde als BLOCKED geführt und
**nicht** gestartet.

### 12.3 Zwei Befunde aus dem Test, bereits behoben

| Befund | Ursache | Behebung |
| --- | --- | --- |
| `preflight.sh` brach mit Code 1 ab, wenn `/lib/firmware/brcm` fehlt | `set -o pipefail` zusammen mit `find` auf einem fehlenden Verzeichnis | neue Funktion `mt2_count_files` in `scripts/lib/common.sh`, überall eingesetzt |
| `deploy-to-t7.sh` benötigte `rsync` | `rsync` ist nicht auf jedem System vorhanden | Rückfall auf `tar`, die Prüfsummenprüfung nach der Übertragung bleibt gleich |

### 12.4 Nicht prüfbar in der Bauumgebung

| Pfad | Grund | Wo er geprüft wird |
| --- | --- | --- |
| `install.sh` ab Schritt 4 | Die Modellsperre greift korrekt und bricht vorher ab | `install.sh --dry-run` auf dem MacBookPro16,1 |
| `deploy-to-t7.sh` ab Schritt 3 | Die Samsung T7 ist im Container nicht sichtbar | `deploy-to-t7.sh --dry-run` auf dem RTX-Rechner |
| alle Hardwaretests in `verify.sh` | keine T2-Hardware vorhanden | `verify.sh` auf dem MacBookPro16,1 |

Diese Pfade sind bewusst nicht als geprüft ausgewiesen.
Beide Skripte haben dafür einen Simulationsbetrieb.
