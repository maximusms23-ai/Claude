---
title: Kompatibilitätsmatrix MacBookPro16,1 unter Ubuntu 24.04
created: 2026-10-10
type: referenz
tags: [maximus, t2linux, kompatibilität, macbookpro16-1]
---

# Kompatibilitätsmatrix

Zielgerät: Apple MacBookPro16,1, Baujahr 2019.
Betriebssystem: Ubuntu 24.04.5 LTS, amd64.
Kernel: `linux-t2-lts` 6.18.54-1-t2-noble.

## Legende

| Zeichen | Bedeutung |
| --- | --- |
| ERWARTET_PASS | Die Quellen führen die Funktion als arbeitsfähig. Der Test steht aus. |
| ERWARTET_PARTIAL | Die Quellen führen die Funktion als eingeschränkt. |
| ERWARTET_FAIL | Die Quellen führen die Funktion als nicht arbeitsfähig. |
| OFFEN | Der Zustand ist von der Firmware oder vom Test abhängig. |

**Wichtig:** Diese Spalte ist eine Erwartung aus den Quellen.
Sie ist **kein** Testergebnis.
Das Testergebnis steht ausschließlich in `reports/HARDWARE_TEST_REPORT.md`.

## 1. Eingabe und Anzeige

| Hardware | Maßnahme im Paket | Erwartung | Nachgewiesene Einschränkung |
| --- | --- | --- | --- |
| Interne Tastatur | `linux-t2-lts`, Modul `t2bce_vhci`, Laden in der Initialramdisk | ERWARTET_PASS | Kein Treiber im Hauptzweig. Die Funktion hängt an `t2bce`. |
| Trackpad | `linux-t2-lts`, `libinput-tools` zur Prüfung | ERWARTET_PARTIAL | Force Touch fehlt. Die Handballenerkennung fehlt. |
| Touch Bar | `linux-t2-lts`, `tiny-dfr` 0.3.7-4, `hid-appletb-kbd mode=1` | ERWARTET_PASS | Die Grundfassung zeigt nur Funktions- oder Medientasten. Treiber seit Kernel 6.15 im Hauptzweig. |
| Tastaturbeleuchtung | `linux-t2-lts` | ERWARTET_PASS | — |
| Interner Bildschirm | `i915` | ERWARTET_PASS | — |
| Touch ID | `t2-touchid` 0.1.0-3 | ERWARTET_PARTIAL | Nur Fingerabdrücke, die in macOS angelegt wurden. Auf dem Zielgerät ist macOS entfernt. Damit ist die Funktion praktisch ERWARTET_FAIL. |

## 2. Funk

| Hardware | Maßnahme im Paket | Erwartung | Nachgewiesene Einschränkung |
| --- | --- | --- | --- |
| WLAN | Treiber `brcmfmac` im Kernel. Firmware über `apple-firmware-script`. | OFFEN | Ohne Apple-Firmware keine Funktion. Die Firmware liegt nicht im Paket. |
| Bluetooth | Treiber im Kernel. Dieselbe Firmware. `bluez` 5.72. | ERWARTET_PARTIAL | Bei einem BCM4377-Chip stört eine 2,4-GHz-WLAN-Verbindung die Bluetooth-Verbindung. Nutze 5 GHz oder schalte WLAN ab. |

Hinweis zum Funkchip: Der frühere MAXIMUS-Bericht nennt BCM4364.
Für das MacBookPro16,1 ist jedoch BCM4377 zu erwarten.
Prüfe den Chip auf dem Zielgerät:

```bash
lspci -nn | grep -i network
sudo journalctl -k --grep=brcmfmac
```

Die Firmwaredateien heißen je nach Chip `brcmfmac4364*` oder `brcmfmac4377*`.
Das Werkzeug `get-apple-firmware` wählt den passenden Namen selbst.

## 3. Medien

| Hardware | Maßnahme im Paket | Erwartung | Nachgewiesene Einschränkung |
| --- | --- | --- | --- |
| Kamera | `linux-t2-lts`, Prüfung mit `ffmpeg` und `v4l-utils` | ERWARTET_PASS | Kein Treiber im Hauptzweig. Die Kamera hängt am USB-Pfad des T2-Chips. |
| Lautsprecher | `apple-t2-audio-config` 0.5.1, `t2-apple-audio-dsp-speakers161` 0.2.0-1 | ERWARTET_PASS | Die Filterkette gilt nur für das 16-Zoll-Modell 2019. Ein falsches Profil kann die Hochtöner schädigen. |
| Kopfhörerbuchse | `apple-t2-audio-config` | ERWARTET_PASS | Unter PulseAudio ist die Umschaltung unzuverlässig. Das Paket setzt PipeWire. |
| Internes Mikrofon | `t2-apple-audio-dsp-mic` 0.4.0-1 | ERWARTET_PARTIAL | Die Eingangslautstärke ist bauartbedingt sehr gering. Ein Kerneltreiber kann das nicht ausgleichen. |
| T2-Video-Encoder | keine | ERWARTET_FAIL | Kein Treiber vorhanden. Wird unter macOS für Sidecar genutzt. |

## 4. Grafik

| Hardware | Maßnahme im Paket | Erwartung | Nachgewiesene Einschränkung |
| --- | --- | --- | --- |
| Intel UHD 630 | `i915`, `mesa-utils`, `vainfo` | ERWARTET_PASS | — |
| Radeon Pro 5500M | `amdgpu`, Mesa aus Ubuntu noble | ERWARTET_PARTIAL | Das Abschalten der dedizierten Grafik funktioniert nicht. Ein Wechsel der Auflösung und `DRI_PRIME` können Abstürze auslösen. Gegenmittel in `config/grub/OPTIONAL-PARAMS.md`. |
| Externe Radeon RX 5700 XT | keine | NICHT_GEPLANT | Die Karte war beim Audit nicht angeschlossen. Sie gehört zur erweiterten Planung. |

## 5. Kühlung und Energie

| Hardware | Maßnahme im Paket | Erwartung | Nachgewiesene Einschränkung |
| --- | --- | --- | --- |
| Lüfter | `applesmc` im Kernel, `t2fanrd` 0.1.0-4, Kurve 55 bis 80 Grad Celsius | ERWARTET_PASS | Ohne Dienst laufen die Lüfter oft auf Grundlast. |
| CPU-Temperatur | `lm-sensors`, Lasttest mit `stress-ng`, Abbruch bei 90 Grad Celsius | OFFEN | Das letzte Audit meldete 98 Grad Celsius und mehrfache Drosselung. |
| Ruhezustand | bewusst abgeschaltet durch `config/power/99-maximus-t2-sleep.conf` | ERWARTET_FAIL | Bericht 31: minutenlange Hänger. Bericht 215: Absturz beim Aufwachen. Die Radeon-Grafik kann in `s2idle` hängen. |
| Akku | `upower`, `acpi` | ERWARTET_PASS | — |

## 6. Anschlüsse und Datenträger

| Hardware | Maßnahme im Paket | Erwartung | Nachgewiesene Einschränkung |
| --- | --- | --- | --- |
| Interne SSD | im Kernel seit 5.4 | ERWARTET_PASS | Die APFS-Datenvolumen von macOS sind nicht lesbar. Auf dem Zielgerät ohne Belang. |
| USB-C und USB | `xhci` im Kernel | ERWARTET_PASS | — |
| Thunderbolt | im Kernel, Parameter `pcie_ports=native` | ERWARTET_PARTIAL | Ohne den Parameter kann Thunderbolt ausfallen. |
| Interne T2-Netzwerkschnittstelle | `t2-ncm` 0.1.0-2, udev-Regel, NetworkManager-Regel | ERWARTET_PASS | Ohne die Regel erscheinen wiederkehrende Verbindungsmeldungen. |
| iPhone-USB-Tethering | `network-manager` aus Ubuntu | ERWARTET_PASS | Dies ist der Netzwerkweg für den Firmwarebezug. |

## 7. Keine pauschale Freigabe

Diese Funktionen dürfen **nicht** ohne Einzeltest als arbeitsfähig gelten:

1. Touch ID.
2. Bluetooth.
3. Gesten auf dem Trackpad.
4. Ruhezustand und Aufwachen.
5. Umschaltung zwischen interner und dedizierter Grafik.
6. Dauerbetrieb über mehrere Stunden.

Ein nicht getestetes Gerät erhält niemals PASS.
