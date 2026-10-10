---
title: Prüfprotokoll MAXIMUS T2 Neuinstallation V1
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, pruefung]
---

# Prüfprotokoll

Alle Angaben stammen aus tatsächlich ausgeführten Läufen in dieser
Bauumgebung. Jede Messung ist mit ihrer Quelle genannt.

## 1. Geräte- und Werkzeugprüfung

| Prüfung | Ergebnis | Messung |
| --- | --- | --- |
| Bauumgebung | Ubuntu 24.04.5 LTS, amd64, 4 Kerne, 15 GB RAM | `/etc/os-release`, `nproc`, `free` |
| Modellkennung der Bauumgebung | **nicht lesbar** | `/sys/class/dmi/id/product_name` fehlt |
| Blockgeräte | nur `vda` bis `vdf` (virtio) | `lsblk` |
| USB-Bus | **nicht sichtbar** | `lsusb` nicht vorhanden |
| `/dev/sd*`, `/dev/nvme*` | **nicht vorhanden** | `ls` |
| Samsung T7 | **nicht sichtbar** | siehe oben |
| Hardware-Virtualisierung | **nicht vorhanden** (`/dev/kvm` fehlt) | `ls -l /dev/kvm` |

**Folge:** Diese Umgebung kann die T7 nicht beschreiben. Alle Startproben
laufen in Software-Emulation (TCG), nicht auf echter T2-Hardware.

## 2. Auswahl der Installationsbasis

| Prüfung | Ergebnis |
| --- | --- |
| Quelle | `github.com/t2linux/T2-Ubuntu`, Zweig `LTS` |
| Neuester Tag | `v7.1.8-1` (`git ls-remote --tags`) |
| Abbild | `ubuntu-24.04-7.1.8-t2-noble.iso`, in vier Teilen veröffentlicht |
| Veröffentlichte Prüfsumme | `5792a22aaca9a18822f3f8e6b8046e7867cc3f02052cf4ac38be55ed22aa1241` |
| Gemessene Prüfsumme | `5792a22aaca9a18822f3f8e6b8046e7867cc3f02052cf4ac38be55ed22aa1241` |
| Ergebnis | **BESTÄTIGT** |

### Startkette des Originals

```
System area summary: MBR cyl-align-on GPT APM
APM partition name :   1  EFI
APM partition type :   1  Apple_HFS
APM partition path :   1  /EFI/efiboot.img
El Torito boot img :   1  BIOS  /boot/grub/bios.img
El Torito boot img :   2  UEFI  /EFI/efiboot.img
```

Die **Apple-Partition-Map** macht das Medium im Mac-Startmanager sichtbar.

### Enthaltener Installer

```
ubiquity 24.04.5
ubiquity-casper 1.498
ubiquity-frontend-gtk 24.04.5
casper 1.498
linux-image-7.1.8-1-t2-noble 7.1.8-1
linux-image-6.8.0-138-generic 6.8.0-138.138
```

Quelle: `casper/filesystem.manifest` im Abbild, 1553 Pakete.

**Folge:** Autoinstall und NoCloud sind nicht anwendbar. Sie gehören zu
subiquity. Die Automatisierung läuft über debian-installer-Preseed.

### Nachweis des Mechanismus im Quelltext

Aus `/scripts/casper-bottom/24preseed` des mitgelieferten Initramfs:

```sh
file=*)
    locations="${x#file=} $locations"
...
if [ "$locations" ]; then
    for item in $locations; do
        casper-set-selections "/root$item"
    done
fi
if db_get preseed/early_command && [ "$RET" ]; then
    ...
    sh -c "$EARLY"
fi
```

Aus `/usr/lib/ubiquity/bin/ubiquity` des Live-Systems:

```python
# Noninteractive implies automatic mode.
if f == 'noninteractive':
    os.environ['UBIQUITY_AUTOMATIC'] = '1'
```

## 3. Bau des Abbilds

| Prüfung | Ergebnis |
| --- | --- |
| `xorriso ... replay` erhält die APM | **NEIN** |
| Messung | `xorriso : SORRY : Cannot make proposal to produce APM of loaded image` |
| Folge | Das Abbild wird mit der Original-Aufrufzeile neu gebaut |
| Entscheidende Option | `-isohybrid-apm-hfsplus` |
| APM im Ergebnis | **vorhanden** |

### Startkette des gebauten Abbilds

```
System area summary: MBR cyl-align-on GPT APM
APM partition name :   1  EFI
APM partition type :   1  Apple_HFS
APM partition path :   1  /EFI/efiboot.img
El Torito boot img :   1  BIOS  /boot/grub/bios.img
El Torito boot img :   2  UEFI  /EFI/efiboot.img
```

Die Struktur stimmt mit dem Original überein.

## 4. EFI-Starttest

Umgebung: QEMU mit OVMF, Maschine `q35`, ohne KVM.

| Prüfung | Ergebnis | Messung |
| --- | --- | --- |
| OVMF findet den Starter | **bestanden** | `BdsDxe: starting Boot0001 "UEFI QEMU DVD-ROM"` |
| GRUB startet | **bestanden** | `GNU GRUB version 2.12` nach etwa 6 Sekunden |
| Eigene Menüeinträge sichtbar | **bestanden** | `Ubuntu mit T2-Unterstuetzung neu installieren`, `MAXIMUS Selbsttest` |
| Vorgabeeintrag | **Live-System**, nicht die Installation | `set default="0"` |

## 5. Nachweis, dass der Installer die Preseed lädt

Gestartet wurde der Eintrag "MAXIMUS Selbsttest".

```
Begin: Loading preseed file... ...
MAXIMUS: PRESEED-GELADEN-UND-EARLY-COMMAND-AUSGEFUEHRT medium=/root/cdrom
MAXIMUS: Assistent eingerichtet: /opt/maximus/wizard.sh auf tty1
```

Danach wurde die debconf-Datenbank des laufenden Live-Systems abgefragt:

```
MAXIMUS-SELBSTTEST: kernel=7.1.8-1-t2-noble
MAXIMUS-SELBSTTEST: DATEI-OK /opt/maximus/wizard.sh
MAXIMUS-SELBSTTEST: DATEI-OK /opt/maximus/postinstall.sh
MAXIMUS-SELBSTTEST: DATEI-OK /opt/maximus/lib/common.sh
MAXIMUS-SELBSTTEST: DATEI-OK /opt/maximus/firstboot/report.sh
MAXIMUS-SELBSTTEST: DEBCONF-OK debian-installer/locale = de_DE.UTF-8
MAXIMUS-SELBSTTEST: DEBCONF-OK time/zone = Europe/Berlin
MAXIMUS-SELBSTTEST: DEBCONF-OK keyboard-configuration/layoutcode = de
MAXIMUS-SELBSTTEST: DEBCONF-OK netcfg/get_hostname = macbook-t2
MAXIMUS-SELBSTTEST: DEBCONF-OK apt-setup/use_mirror = false
MAXIMUS-SELBSTTEST: DEBCONF-OK debian-installer/add-kernel-opts = pm_async=off intel_iommu=on iommu=pt pcie_ports=native
MAXIMUS-SELBSTTEST: UBIQUITY-VORHANDEN /usr/bin/ubiquity
MAXIMUS-SELBSTTEST: FRONTEND-NONINTERACTIVE-VORHANDEN ja
MAXIMUS-SELBSTTEST: LAUFENDES-MEDIUM /dev/sr0
MAXIMUS-SELBSTTEST: ZIELKANDIDATEN-ANZAHL 0
MAXIMUS-SELBSTTEST: TEMPERATURREGEL-OK kein Sensor vorhanden, Bericht meldet FEHLGESCHLAGEN statt 0 Grad
```

**Bewertung:** Die Werte stehen in der debconf-Datenbank des gestarteten
Installers. Eine Datei neben dem Abbild allein würde das nicht bewirken.
Der Nachweis ist damit erbracht.

## 6. Fehler, die diese Prüfläufe gefunden haben

| Nummer | Befund | Messung | Korrektur |
| --- | --- | --- | --- |
| 1 | `getty@tty1` überdeckte den Assistenten mit einer Anmeldeaufforderung | Bildschirmabzug zeigte `ubuntu login:` statt des Assistenten | `Conflicts=getty@tty1.service` in der Dienstdatei |
| 2 | Der Zähler der Prüfantworten stand still | Jede Frage las Zeile 1; die Freigabe scheiterte mit Code 15 | Der Zähler liegt jetzt in einer Datei. `ask()` läuft in einer Befehlsersetzung, also in einer Unterschale. |
| 3 | Die Spiegelung auf die Konsole griff nie | Muster `maximus\\.` trifft einen Rückstrich, nicht den Punkt | Muster `maximus[.]` |
| 4 | `partman` bekam eine Verknüpfung statt eines Gerätepfads | Vorsorglich erkannt | `partman-auto/disk` erhält den aufgelösten Pfad, der gerade geprüft wurde |

Befund 2 ist dieselbe Fehlerklasse, die schon in MAXIMUS V4.2 auftrat:
eine Variable, die in einer Unterschale gesetzt wird, geht verloren.

## 7. Nachweis der Sicherheitslogik

Aus dem Prüflauf, Bildschirmabzug der Textkonsole:

```
=== Schritt 4: Loeschumfang waehlen ===
Geloescht wird: ALLES auf /dev/vda (/dev/disk/by-id/virtio-MAXIMUSTESTZIEL01)
Erhalten bleibt: nichts auf diesem Geraet.
Andere Geraete werden nicht angefasst.
[  OK  ] Auf dem Ziel liegt kein macOS-Dateisystem.

=== Schritt 5: Schutz vor einer zweiten Loeschung ===
[  OK  ] Auf dem Ziel liegt keine fertige MAXIMUS-Installation.

=== Schritt 6: Freigabe ===
Gib zur Freigabe genau dies ein: ESTZIEL01
[  OK  ] Die Freigabekennung stimmt.

=== Schritt 8: Stabile Kennung erneut pruefen ===
[  OK  ] Die Kennung zeigt unveraendert auf /dev/vda.

=== Schritt 9: Preseed zur Laufzeit erzeugen ===
[  OK  ] Laufzeit-Preseed erzeugt: 31 Zeilen (nicht auf dem Medium)

=== Schritt 10: Installation starten ===
[  OK  ] Preseed geladen. Die Passwortzeilen sind geloescht.
[ INFO ] Frontend 'noninteractive'. Dieses Frontend setzt den automatischen Betrieb.
```

**Gegenprobe mit falscher Freigabe** (Lauf 2, vor der Korrektur von Befund 2):

```
Gib zur Freigabe genau dies ein: ESTZIEL01
Eingabe (oder ABBRUCH): 1
[FEHLER] Die Eingabe stimmt nicht. Erwartet war: ESTZIEL01
[FEHLER] Die Freigabe fehlt oder stimmt nicht.
         Abhilfe: Es wurde nichts geaendert.
         Rueckgabecode: 15
```

Der Assistent hat mit einer falschen Freigabe **nichts geschrieben**.

**Ausschluss des laufenden Mediums:** Der Selbsttest meldete
`LAUFENDES-MEDIUM /dev/sr0` und zählte null Zielkandidaten, obwohl das
Medium ein Blockgerät ist.

## 8. Befund: ubiquity kann ohne Grafik nicht geführt partitionieren

Dies ist der wichtigste Befund dieser Prüfläufe.

**Gemessen.** Der Prüflauf startete `ubiquity noninteractive` mit einer
Preseed, die `partman-auto/disk`, `partman-auto/method regular` und
`partman-auto/choose_recipe atomic` setzte. Die Zielplatte blieb leer.
Aus `/var/log/installer/debug` der laufenden Maschine:

```
Kein Root-Dateisystem: Es wurde kein Root-Dateisystem festgelegt.
Bitte beheben Sie dies im Partitionierungsmenü.
```
(wiederholt in einer Schleife)

**Ursache, belegt im Quelltext.** In
`/usr/lib/ubiquity/plugins/ubi-partman.py` des Live-Systems:

```python
class PageNoninteractive(PageBase):
    def set_part_page(self, p):
        pass
```

`PageGtk` (Zeile 826) und `PageKde` (Zeile 1807) haben
`set_autopartition_options` und `get_autopartition_choice`.
`PageNoninteractive` (Zeile 1835) hat beide **nicht**.

Dazu `run()` in derselben Datei:

```python
elif question == 'partman-auto/select_disk':
    if self.auto_state is not None:
        ...
        self.extra_options['use_device'] = (self.some_device_desc, disks)
        # Back up to autopartitioning question.
        self.succeeded = False
        return False
```

Die geführte Partitionierung geht immer über die Benutzeroberfläche zurück.
Ohne Oberfläche endet der Ablauf bei `partman/choose_partition` ohne
Wurzeldateisystem.

**Folge für dieses Paket.** Betriebsart 1 nutzt nicht ubiquity, sondern
`maximus/install-direct.sh`. Dieses Skript tut dasselbe, was ubiquity sonst
tut: Es teilt die Platte auf, legt die Dateisysteme an und packt **dasselbe**
Live-Abbild `casper/filesystem.squashfs` aus. Jeder Schritt ist einzeln
protokolliert.

Betriebsart 2 nutzt weiter ubiquity, dort mit Oberfläche und mit
Partitionswahl von Hand. Das ist genau der Weg, den das Projekt t2linux
neben einem vorhandenen macOS verlangt.

## 9. Prüflauf der Neuinstallation auf eine leere Testplatte

Umgebung: QEMU ohne KVM, **Netzwerk abgeschaltet**, leere 24-GiB-Testplatte
mit der Seriennummer `MAXIMUSTESTZIEL01`, Installationsmedium als CD-ROM.

Gemessener Ablauf (Spiegelung der Assistentenausgabe auf die serielle
Schnittstelle):

```
=== 2. Partitionstabelle anlegen ===
[  OK  ] Partitionstabelle angelegt
=== 5. Betriebssystem auspacken ===
[  OK  ] Ausgepackt
=== 8. System einrichten ===
[  OK  ] Sprache: de_DE.UTF-8
[  OK  ] Tastatur: de (pc105)
[  OK  ] Zeitzone: Europe/Berlin
[  OK  ] Benutzer maximus angelegt und Passwort gesetzt.
[  OK  ] Das Konto root ist gesperrt.
=== 9. Bootloader einrichten ===
[  OK  ] GRUB in die EFI-Partition geschrieben (auch als EFI/BOOT/BOOTX64.EFI).
[  OK  ] vorhanden: /boot/efi/EFI/BOOT/BOOTX64.EFI (966664 Byte)
[  OK  ] vorhanden: /boot/efi/EFI/ubuntu/grubx64.efi (2660232 Byte)
=== 10. Ergebnis ===
[  OK  ] Das Betriebssystem ist installiert.
=== Nachbereitung im Zielsystem ===
[  OK  ] Zielsystem eingehaengt: /dev/vda2
```

Wachstum der Testplatte während des Laufs:
`0 MB → 1062 MB → 5185 MB → 5530 MB → 5613 MB → 5919 MB`

**Bewertet:** Die Neuinstallation auf eine leere Platte läuft nach der
Freigabe ohne weitere Fragen durch. Sie braucht kein Netz. Der Pfad
`EFI/BOOT/BOOTX64.EFI` ist der Pfad, den der Startmanager des Mac findet.

### Zwei weitere Fehler, die dieser Lauf gefunden hat

| Nummer | Befund | Messung | Korrektur |
| --- | --- | --- | --- |
| 5 | Die T2-Zusatzpakete wurden nicht gefunden | `[ WARN ] Es liegen keine T2-Zusatzpakete auf dem Medium.` obwohl acht Pakete im Abbild lagen | `early.sh` notiert im Initramfs `/root/cdrom`. Im Live-System heißt derselbe Ort `/cdrom`. `postinstall.sh` bestimmt den Pfad jetzt zur Laufzeit. |
| 6 | Ein Anführungszeichen blieb im Startparameter stehen | `Startparameter: quiet splash" pm_async=off ...` | Das gierige `\(.*\)` im `sed`-Muster verschluckte das schließende Zeichen nicht. Es wird jetzt getrennt entfernt. Gegenprobe: alt `[quiet splash"]`, neu `[quiet splash]`. |

Beide Fehler sind im Quelltext behoben. **Die Korrekturen sind noch nicht
in einem vollständigen Lauf nachgeprüft.**

## 10. Befund 7: Das installierte System startete nicht

Dies ist der schwerste Fund dieser Prüfläufe. Er wäre ohne den Neustarttest
unentdeckt geblieben.

**Messung.** Nach der vollständigen Installation wurde die Testplatte **ohne
Installationsmedium** gestartet. Die serielle Schnittstelle zeigte:

```
GNU GRUB  version 2.12

grub>
```

Das System landete in der Eingabeaufforderung, nicht im Startmenü.

**Ursache.** `grub-install` legt nur den Starter in der EFI-Partition ab.
Die Datei `/boot/grub/grub.cfg` entsteht erst durch `update-grub`.
Gemessen vor der Korrektur:

```
grep -c 'update-grub' install-direct.sh  ->  0
grep -c 'update-grub' postinstall.sh     ->  0
```

Beide Skripte riefen `update-grub` **nie** auf. Die Meldung
`[  OK  ] GRUB in die EFI-Partition geschrieben` war richtig und trotzdem
irreführend: Der Starter lag da, seine Konfiguration nicht.

**Das ist genau der Fall, vor dem der Auftrag warnt:** Ein erfolgreich
beendeter Schreibbefehl allein genügt nicht als Nachweis der Startfähigkeit.

**Korrektur.** Zwei Teile:

1. `install-direct.sh` ruft nach `grub-install` jetzt `update-grub` auf.
   `postinstall.sh` wiederholt es, nachdem es die Startparameter geändert
   hat. Ohne diese Wiederholung stünden die neuen Parameter zwar in
   `/etc/default/grub`, aber nicht im Menü.
2. Ein neuer Schritt **9b "Startfähigkeit nachweisen"** prüft drei Dinge und
   bricht sonst mit Code 18 ab:
   - `/boot/grub/grub.cfg` ist vorhanden und hat mindestens einen Eintrag,
   - in `/boot` liegen Kernel **und** Initialramdisk,
   - `EFI/BOOT/BOOTX64.EFI` ist vorhanden.

Gemessen nach der Korrektur:

```
grep -c 'update-grub' install-direct.sh  ->  3
grep -c 'update-grub' postinstall.sh     ->  3
```

## 11. Gegenproben zu den Korrekturen 5 und 6

Geprüft ohne virtuelle Maschine mit `tests/pruefe-nachbereitung.sh`:

```
=== Korrektur 5: Medienpfad zur Laufzeit ===
notiert war:  /root/cdrom
gefunden:     <vorhandener Pfad>
BESTANDEN: der vorhandene Pfad gewinnt, die tote Notiz nicht.
Gegenprobe ohne Treffer: /cdrom
BESTANDEN: Rueckfall auf /cdrom.

=== Korrektur 6: Startparameter ohne stehendes Anfuehrungszeichen ===
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"  -> [quiet splash pm_async=off ...]
GRUB_CMDLINE_LINUX_DEFAULT='quiet splash'  -> [quiet splash pm_async=off ...]
GRUB_CMDLINE_LINUX_DEFAULT=quiet           -> [quiet pm_async=off ...]
GRUB_CMDLINE_LINUX_DEFAULT=""              -> [pm_async=off ...]
Gegenprobe doppelt: [quiet splash pm_async=off intel_iommu=on]
BESTANDEN: kein doppelter Parameter.

Fehler gesamt: 0
```

Vier Schreibweisen und eine Gegenprobe gegen doppelte Parameter.

## 12. Noch nicht geprüft

| Punkt | Grund |
| --- | --- |
| Schreiben auf die Samsung T7 | kein Zugriff auf Datenträger in dieser Umgebung |
| Start am echten Mac | kein Zugriff auf das Zielgerät |
| Jede Hardwarefunktion des MacBookPro16,1 | kein Zugriff auf das Zielgerät |
| Verhalten des Mac-Startmanagers | nur am Gerät prüfbar |
| Ursache der früher gemessenen 98 °C | nur am Gerät prüfbar |

**Eine virtuelle Maschine beweist keine funktionierende T2-Hardware.**
