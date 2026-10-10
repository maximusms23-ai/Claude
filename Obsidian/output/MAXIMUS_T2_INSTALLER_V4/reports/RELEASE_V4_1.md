---
title: Release-Bericht V4.1
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, release, reparatur]
---

# Release-Bericht V4.1

Ausgangsstand: Commit `d50803c`, Fassung V4.0.
Neue Fassung: V4.1.0.
Grundsatz: dieselbe Architektur, kein zweiter Installer.

## 1. Ergebnis zuerst

| Status | Wert | Nachweis |
| --- | --- | --- |
| **SOURCE_READY** | **erteilt** | Abschnitt 2 |
| **PACKAGE_READY** | **erteilt** | Abschnitt 6 und 7 |
| INSTALLATION_READY | nicht erteilt | Die Vorprüfung am MacBook ist nicht gelaufen |
| HARDWARE_READY | nicht erteilt | Es liegt kein Hardwaretest vor |
| MAXIMUS_WORKER_READY | nicht erteilt | Es liegt kein Dauerbetriebsnachweis vor |

Offline-Fähigkeit: **PARTIAL**. Die Apple-Firmware ist nicht weitergebbar.

Nicht ausgeführt, wie beauftragt:

1. Es wurde nichts auf die Samsung T7 übertragen.
2. Es wurde nichts auf dem MacBook installiert.

## 2. SOURCE_READY: erneute Quellenprüfung

Die Quellen wurden am 2026-10-10 erneut abgerufen und verglichen.

| Quelle | Stand | Vergleich zum 2026-10-10 | Ergebnis |
| --- | --- | --- | --- |
| T2-Repositorium noble, `Release` | 2026-10-05 23:29:56 UTC | unverändert | BESTÄTIGT |
| T2-Repositorium noble, GPG-Signatur | Fingerabdruck `9F98…BFD4` | gültig | BESTÄTIGT |
| T2-Repositorium noble, `Packages` | SHA-256 `f324dc12…fd9378` | unverändert, Soll aus `Release` erfüllt | BESTÄTIGT |
| T2Linux-Zustandsseite | `docs/state.md` | unverändert | BESTÄTIGT |
| T2Linux-Grundeinrichtung | `docs/guides/postinstall.md` | unverändert | BESTÄTIGT |
| Höchste LTS-Fassung | `linux-t2-lts` 6.18.54-1-noble | unverändert | BESTÄTIGT |

Die Kernelentscheidung aus V4.0 bleibt damit gültig.

### Neue Befunde zu bekannten Problemen

Diese Befunde stammen aus Fehlerverfolgungen anderer Distributionen.
Sie sind mittelbare Nachweise. Sie sind als solche gekennzeichnet.

| Befund | Quellenart | Bedeutung für dieses Paket |
| --- | --- | --- |
| Tastatur, Trackpad und Touch Bar brachen auf Kernel 7.1.2 ab und arbeiteten auf LTS 6.18.37 wieder | CachyOS-Fehlerbericht | **stützt die Wahl der LTS-Reihe unabhängig** |
| Ein Distributionsinstallateur schreibt weiter `apple-bce` und bricht damit jede T2-Installation | Omarchy-Fehlerbericht | stützt den Ausschluss von `apple-bce` |
| Der interne Bildschirm kann über `gmux` an der AMD-Grafik hängen. Folge ist ein Hänger beim Sitzungsstart | Omarchy-Fehlerbericht zu MacBookPro16,1 | **neu aufgenommen**: `verify.sh` prüft jetzt, welcher Treiber den internen Bildschirm führt |
| `s2idle` weckt die Radeon-Grafik nicht auf. Empfehlung ist `deep` | Omarchy-Fehlerbericht zu MacBookPro16,1 | **neu aufgenommen**: `verify.sh` liest `/sys/power/mem_sleep` und warnt |
| Der Bildschirm bleibt nach dem Aufwachen dunkel, wenn `apple-set-os` fehlt | CachyOS-Fehlerbericht | als Risiko dokumentiert |

### WLAN-Chip

Auftragsabschnitt 3 fordert: Der Chip wird erst durch Hardwareerkennung
bestätigt. Das ist umgesetzt.

`verify.sh` hat ein eigenes Prüffeld **WLAN-Chip**. Es liest drei Quellen:

1. den PCI-Eintrag über `lspci -nn` samt Kennung,
2. die Chipmeldung des Treibers aus dem Kernelprotokoll,
3. die vorhandenen Firmwaredateien in `/lib/firmware/brcm`.

Nur Quelle 2 führt zu PASS. Ohne Nachweis gibt es PARTIAL oder FAIL.
Eine Annahme aus einem früheren Bericht gilt nicht als Nachweis.

## 3. Die fünf beauftragten Korrekturen

### 3.1 GRUB-Syntaxprüfung

**Befund in V4.0.** `install.sh`, `preflight.sh` und `rollback.sh` prüften
`/boot/grub/grub.cfg` mit `bash -n`. Das ist der falsche Interpreter.

**Messung.** Gemessen an drei Dateien:

| Datei | `bash -n` | `grub-script-check` |
| --- | --- | --- |
| gültige `grub.cfg` (Auszug einer echten Ubuntu-Datei) | **rc=2, Syntaxfehler gemeldet** | rc=0, gültig |
| `menuentry`-Klammer nicht geschlossen | **rc=0, kein Fehler gemeldet** | rc=1, Fehler erkannt |
| fehlerhaftes `if` | rc=2 | rc=1 |

`bash -n` war also in beide Richtungen falsch.

Die Folge in V4.0 war schwerwiegend: Nach einem erfolgreichen `update-grub`
hätte `install.sh` auf dem Zielgerät mit Code 16 abgebrochen und zum
Zurückschreiben der Sicherung aufgefordert, obwohl die Datei gültig war.
Ein echter Fehler wäre dagegen durchgelassen worden.

**Korrektur.** Neue Funktionen `mt2_grub_check_tool` und
`mt2_grub_check_cfg` in `scripts/lib/common.sh`. Sie nutzen
`grub-script-check`, ersatzweise `grub2-script-check`.
Fehlt das Programm, bricht `install.sh` mit Code 6 ab und nennt
`sudo apt install grub-common`. `bash -n` prüft nur noch Shell-Skripte.

**Regressionstests.** R1.1 bis R1.8, acht Fälle, einschließlich der
Gegenprobe auf das alte Fehlverhalten.

### 3.2 Offline-Installation

**Befund in V4.0.** Nur `apt-get update` war auf die lokale Quelle
ausgerichtet. `apt-get install -s` und `apt-get install` liefen danach
gegen die Systemquellen des Zielgeräts, also auch gegen das Internet.

Drei Folgen:

1. Die Simulation beschrieb nicht, was die Installation tat.
2. Die Installation konnte Pakete aus dem Netz laden.
3. `apt-get update` lief mit `List-Cleanup=0` auf die Systemlisten.

**Korrektur.** Eine gepinnte Paketverwaltung in `mt2_apt_pin_create`:

```
Dir::Etc::sourcelist   -> /var/lib/maximus-t2/apt/offline.list
Dir::Etc::sourceparts  -> /dev/null
Dir::State::lists      -> /var/lib/maximus-t2/apt/lists
```

Jeder apt-Aufruf läuft über `mt2_apt`. Die Simulation und die Installation
nutzen damit nachweislich denselben Bestand. Die Systemlisten bleiben
unberührt. `mt2_apt_pin_verify` prüft dreistufig:

1. die Quellenliste selbst, sie darf nur `file://` tragen,
2. die Konfiguration, `sourceparts` muss abgeschaltet sein,
3. den geladenen Zustand über `apt-cache policy`.

Stufe 1 ist nötig, weil Stufe 3 eine neu eingetragene Netzquelle erst nach
`apt-get update` zeigt.

**Weitere Korrektur.** V4.0 legte die Quelle in
`/etc/apt/sources.list.d/` ab. Nach dem Abziehen der Samsung T7 wäre jedes
spätere `apt update` des Systems gescheitert. Die Quelle liegt jetzt unter
`/var/lib/maximus-t2/apt/`. Das System bleibt unverändert.
`rollback.sh` entfernt auch den Alteintrag der Fassung V4.0.

**Abhängigkeiten des Zielsystems.** `install.sh` und `preflight.sh` lesen
den echten `dpkg`-Bestand. Sie melden, wie viele Pakete der Liste schon
vorhanden und wie viele fehlen. `preflight.sh` prüft zusätzlich, ob ein
Konfliktpaket (`apple-bce` und weitere) auf dem Zielgerät installiert ist.

**Gegenprobe auf Dateien.** `install.sh` fragt `--print-uris` ab und prüft,
dass jede benötigte Paketdatei wirklich lokal liegt.

**Regressionstests.** R2.1 bis R2.11, elf Fälle. R2.8 löst die
Abhängigkeiten mit einem unerreichbaren Vermittlungsrechner auf. Gelingt
das, ist kein Netzzugang beteiligt.

### 3.3 Rückfallskript

**Befunde in V4.0.** Drei Fehler:

1. `apt-get autoremove -y` entschied selbst, welche Pakete es entfernt.
2. Die Entfernungsliste entstand aus Paketnamensmustern wie `linux-t2*`.
   Ein Paket, das schon vor der Installation vorhanden war, wäre entfernt
   worden.
3. Die Sicherung wurde ohne Prüfung zurückgeschrieben.

**Korrektur.**

| Punkt | Umsetzung |
| --- | --- |
| kein `autoremove` | Der Befehl kommt nicht mehr vor. `rollback.sh` nennt stattdessen `apt-get --dry-run autoremove` als Hinweis. |
| Aufzeichnung statt Muster | `install.sh` schreibt `files-written.txt` mit Art und Pfad jeder Dateiänderung sowie `packages-added.txt`, `packages-changed.txt` und `packages-removed.txt` aus einem Bestandsvergleich. |
| nur eigene Änderungen | `rollback.sh` arbeitet ausschließlich diese Aufzeichnungen ab. Ohne Aufzeichnung entfernt es **kein** Paket. |
| Gegenprobe | Ein Paket, das in `pkg-before.txt` steht, wird nie entfernt. Ein Ubuntu-Kernel oder ein Systemkernpaket in der Liste führt zum Abbruch. |
| geprüfte Sicherung | `install.sh` versiegelt die Sicherung mit `SHA256SUMS`. `rollback.sh` prüft das Siegel und bricht bei Abweichung mit Code 13 ab. `--force-unverified` ist die bewusste Ausnahme. |
| genauer Blockabbau | Der eigene Block in `/etc/initramfs-tools/modules` wird gezielt entfernt, nicht mehr bis zum Dateiende. |
| Paketaufstufungen | Aufgestufte Pakete werden genannt, aber nicht selbsttätig zurückgestuft. |

Das Standardverhalten entfernt **kein** Paket. Es setzt nur die
Konfiguration zurück. Der T2-Kernel bleibt installiert und wird nur nicht
mehr gestartet. Das ist der sicherste Weg, weil kein Startpfad entfällt.

**Regressionstests.** R5.1 bis R5.9 und R6.1 bis R6.9, achtzehn Fälle.
R6.6 prüft den Schutz eines vorher vorhandenen Pakets. R6.4 prüft den
Abbruch bei veränderter Sicherung.

### 3.4 Prüfsummenverwaltung

**Befund in V4.0.** `fetch-packages.sh` schrieb nach einer Warnung
`cp "$NEWLIST" "$EXPECTED"`. Ein veränderter Bestand wurde damit
stillschweigend zum neuen Sollstand.

**Korrektur.** Bei Abweichung bricht das Skript mit Code 13 ab.
Es nennt die Zahl der Einträge nur im alten und nur im neuen Stand und legt
den neuen Stand als `SHA256SUMS.debs.new` daneben. Eine Übernahme verlangt
`--accept-new-checksums` und erzeugt dann `SHA256SUMS.debs.provenance` mit
Zeitpunkt, Umfang und Freigabevermerk.

**Regressionstests.** R4.1 bis R4.7, acht Fälle einschließlich R4.3b.

### 3.5 Behandlung von exFAT

**Befund in V4.0.** Die Fassung warnte nur. Sie prüfte nicht, ob die
Skripte auf dem Ziel startbar sind.

**Korrektur.**

| Punkt | Umsetzung |
| --- | --- |
| Erkennung | `mt2_fs_info` liest Dateisystem und `noexec`. `mt2_fs_keeps_modes` bewertet exfat, vfat, msdos, ntfs, ntfs3, fuseblk, iso9660 und udf als ohne Unix-Rechte. |
| Prüfung am Ziel | `deploy-to-t7.sh` prüft nach der Übertragung mit `bash -n`, ob `install.sh` lesbar und gültig ist, und startet `selftest.sh` von der SSD. |
| Startblatt | `deploy-to-t7.sh` schreibt `START-HIER.txt` auf die SSD. Es nennt jeden Aufruf mit dem passenden Vorsatz, also mit `bash` auf exFAT. |
| Verknüpfungen | exFAT kennt keine symbolischen Verknüpfungen. Das Paket enthält keine. Das wird geprüft. |
| Anleitungen | Alle Aufrufe in allen Dokumenten lauten jetzt `sudo bash scripts/…`. |

**Regressionstests.** R8.1 bis R8.11, elf Fälle.

## 4. Zwei zusätzliche Befunde aus der Prüfung

Diese Fehler standen nicht im Auftrag. Sie wurden bei der Arbeit gefunden.

### 4.1 Pfade mit Sonderzeichen brachen die Paketquelle

Der Paketpfad wandert in eine `file://`-Quelle. Ein Leerzeichen zerlegt
diese Quelle. Gemessen:

```
deb [...] file:///…/My T7 Disk/packages ./
E: Failed to fetch file:/…/My/dists/T7/Disk/packages/binary-amd64/Packages
```

Das ist kein Randfall. Der Dienst `udisks2` hängt Wechselmedien unter
`/media/<benutzer>/<bezeichnung>` ein. Eine Bezeichnung mit Leerzeichen ist
dort der Normalfall.

**Korrektur.** `mt2_url_encode_path` kodiert Leerzeichen, Prozentzeichen,
Raute, Fragezeichen und eckige Klammern. Geprüft in R3.1 bis R3.5.

### 4.2 apt konnte das Paketverzeichnis nicht lesen

apt lässt beim Holen die Rechte auf den Benutzer `_apt` fallen.
`udisks2` setzt `/media/<benutzer>` auf Modus 0700. `_apt` kann das
Verzeichnis deshalb nicht durchlaufen. Gemessen: `apt-get update` bricht mit
Rückgabe 100 ab.

**Korrektur.** `mt2_apt_pin_create` prüft mit `runuser` oder `setpriv`, ob
`_apt` den Paketindex lesen kann. Ist das nicht so, setzt es
`APT::Sandbox::User "root"` und schreibt den Grund ins Protokoll.
Das ist hier vertretbar: Die Quelle ist ein lokales Verzeichnis, und jede
Paketdatei wurde vorher gegen `packages/SHA256SUMS.debs` geprüft.

## 5. Drei Befunde aus dem Code-Review der eigenen Korrekturen

Der unabhängige Review-Durchgang prüfte die neuen Korrekturen selbst.
Er fand drei Fehler. Alle sind behoben und durch Tests abgesichert.

### 5.1 `set -e` übersprang jeden Fehlerzweig

Die neuen Prüffunktionen wurden so aufgerufen:

```bash
mt2_grub_check_cfg /boot/grub/grub.cfg
case "$?" in …
```

Unter `set -euo pipefail` beendet ein Rückgabewert ungleich 0 das Skript,
bevor `case` läuft. Gemessen: Der Zweig wurde nie erreicht, das Skript
endete mit Code 1 ohne Meldung.

Betroffen waren `install.sh`, `preflight.sh` und `rollback.sh`.
Eine fehlerhafte `grub.cfg` und eine veränderte Sicherung hätten damit
keine verständliche Meldung erzeugt.

**Korrektur.** Der Rückgabewert wird aufgefangen:

```bash
GRUB_RC=0
mt2_grub_check_cfg /boot/grub/grub.cfg || GRUB_RC=$?
case "$GRUB_RC" in …
```

Geprüft in R11.1 bis R11.3, mit Messung des `set -e`-Verhaltens.

### 5.2 Eine Kommandosubstitution im `case`-Muster war unwirksam

```bash
case "$PKG_DIR" in
	*"$(printf '\n')"*) …
```

Eine Kommandosubstitution entfernt abschließende Zeilenumbrüche.
`$(printf '\n')` ergibt eine leere Zeichenkette. Das Muster wird zu `**`
und trifft jeden Pfad. Gemessen: `preflight.sh` meldete bei jedem normalen
Pfad einen Zeilenumbruch.

**Korrektur.** Die ANSI-C-Form `*$'\n'*`. Geprüft in R3.6 bis R3.9.

### 5.3 Toter Code und eine ShellCheck-Warnung

Die Funktion `run()` war nach dem Umbau unbenutzt. Sie ist entfernt.

ShellCheck meldete zu `set_phase done` die Warnung SC1010.
**Richtigstellung:** Eine Messung zeigt, dass bash `done` als Argument
annimmt. `f done` übergibt die Zeichenkette korrekt. Die Warnung war
vorsorglich, nicht ein Fehler. Die Phasennamen sind trotzdem in
Anführungszeichen gesetzt, damit der Code eindeutig lesbar bleibt.

### 5.4 Befunde des unabhängigen Code-Reviews

Nach den Korrekturen lief ein unabhängiger Review-Durchgang über die
gesamte Änderung. Er meldete 17 Befunde. Die Prüfung ergab:

| Nr. | Befund | Prüfung | Maßnahme |
| --- | --- | --- | --- |
| 1 | Der einmalige Teststart ist nicht einmalig: `GRUB_DEFAULT=saved` ohne gesetztes `saved_entry` | **teils bestätigt.** Die Begründung des Reviews war falsch: Eintrag 0 ist nach Versionssortierung der Ubuntu-Kernel 7.0.0-38, nicht der T2-Kernel 6.18.54. Die unbestimmte Vorgabe bleibt aber ein Risiko. | `install.sh` setzt den Vorgabeeintrag jetzt mit `grub-set-default` ausdrücklich auf den bisherigen Kernel. |
| 2 | Der Rückfall richtet den Vorgabeeintrag nicht neu aus | **bestätigt** | `rollback.sh` setzt den Vorgabeeintrag, hebt einen offenen Teststart mit `grub-editenv unset next_entry` auf und warnt, wenn das zurückgesetzte Menü unsichtbar bleibt. |
| 3 | Die Abnahmevorlage wurde durch einen Testlauf der Bauumgebung überschrieben | **bestätigt, eigener Fehler** | Die Vorlage ist aus dem Commit wiederhergestellt. |
| 4 | `verify.sh` kopiert den Bericht ohne Prüfung in das Paket | **bestätigt** | Die Kopie entsteht nur auf `MacBookPro16,1`, trägt einen Zeitstempel und überschreibt die Vorlage nie. |
| 5 | Die Dateiprüfung dekodierte nur `%20` | **bestätigt** | Neue Funktionen `mt2_url_decode_path` und `mt2_apt_wanted_files`. Sie dekodieren alle sechs Kodierungen und melden eine Netzadresse getrennt. |
| 6 | Ein zweiter Installationslauf überschreibt die Aufzeichnungen des ersten | **bestätigt** | `install.sh` bricht ab und verlangt zuerst einen Rückfall. `--force-reinstall` ist die bewusste Ausnahme; die alte Aufzeichnung bleibt erhalten. |
| 7 | Die Rohdaten sind in einer anderen Umgebung nicht reproduzierbar | **bestätigt** | Die Rohdatentabelle trägt jetzt einen Kopf mit Zeitpunkt, Rootrechten, Pfad von `grub-script-check`, Paketquelle und Zahl der Paketdateien, dazu die Liste der Tests, die ohne diese Voraussetzungen übersprungen werden. |
| 8 | `verify.sh` schreibt `\|` unmaskiert in eine Markdown-Tabelle | **bestätigt** | Neue Funktion `md_cell` maskiert jede Tabellenzelle. |
| 9 | `mt2_grub_read_cmdline` entfernt nur doppelte Anführungszeichen | **bestätigt, nachgestellt** | Beide Arten werden entfernt. Gemessen vorher: `['quiet splash']`. |
| 10 | Eine Option ohne Wert lässt `shift` scheitern: stiller Abbruch mit Code 1 | **bestätigt, nachgestellt** | Neue Funktion `mt2_opt_needs_value`. Betroffen waren `rollback.sh`, `fetch-packages.sh`, `deploy-to-t7.sh`, `regression.sh` und `verify.sh`. |
| 11 | `apt-mark hold` lief vor der Freigabe | **bestätigt** | Der Schritt liegt jetzt nach der Freigabe. |
| 12 | `selftest.sh` ruft `grub-entry.sh` direkt auf | **bestätigt** | Der Aufruf läuft über `bash`. Sonst scheitert Test 8 auf exFAT. |
| 13 | `preflight.sh` verspricht im Kopf, nichts zu ändern, legt aber eigene Verzeichnisse an | **bestätigt** | Der Kopf benennt die beiden eigenen Arbeitsbereiche. |
| 14 | `BUG:` ohne Beachtung der Schreibweise trifft auch `ACPI BIOS Bug:` | **bestätigt** | Die Suche achtet auf die Schreibweise und nimmt ACPI-BIOS-Meldungen aus. Diese Meldungen kommen auf Apple-Firmware regelmäßig vor. |
| 15 | Eine sed-Ersetzung mit `&` verfälscht die Zeile | **bestätigt, nachgestellt** | Gemessen vorher: `GRUB_TEST=a&b` wurde zu `GRUB_TEST=aGRUB_TEST=altb`; ein `\|` brach sed ganz ab. Neue Funktion `mt2_sed_escape_replacement`. |
| 16 | `fetch-packages.sh` schreibt den Baupfad ohne Kodierung | **bestätigt** | Der Pfad wird kodiert. |
| 17 | Die Aussage zu `set_phase done` im Bericht ist falsch | **bestätigt** | Siehe Abschnitt 5.3. Der Bericht ist richtiggestellt. |

Alle 17 Befunde sind abgearbeitet. Die Gruppe R12 der Regressionstests
deckt sie mit 28 Fällen ab.

## 6. Testergebnisse aus Rohdaten

Die Rohdaten liegen in `reports/REGRESSION_RESULTS.tsv`.
Spalten: Gruppe, Test, erwartet, gemessen, Ergebnis.

### 6.1 Regressionstests

| Gruppe | Inhalt | Tests | Bestanden |
| --- | --- | --- | --- |
| R1 | GRUB-Syntaxprüfung | 8 | 8 |
| R2 | gepinnte Offline-Paketquelle | 11 | 11 |
| R3 | Pfade mit Sonderzeichen | 9 | 9 |
| R4 | Prüfsummenverwaltung | 8 | 8 |
| R5 | Sicherung und Rückfall | 9 | 9 |
| R6 | Rückfall gegen vorhandene Konfiguration | 9 | 9 |
| R7 | unterbrochene Installation | 4 | 4 |
| R8 | Dateisystem ohne Unix-Rechte | 11 | 11 |
| R9 | Samsung T7 fehlt | 4 | 4 |
| R10 | Sperren des Installationsskripts | 6 | 6 |
| R11 | Fehlerklassen aus dem Code-Review | 7 | 7 |
| R12 | Befunde des unabhängigen Code-Reviews | 28 | 28 |
| **Summe** | | **114** | **114** |

Erfolgsquote, berechnet aus bestanden geteilt durch bewertet:
**100,0 Prozent** (114 von 114). Übersprungen: 0.

### Verlauf der Erfolgsquote

Die Quote wurde in jedem Durchgang aus den Rohdaten berechnet.

| Durchgang | Tests | Bestanden | Quote | Anlass |
| --- | --- | --- | --- | --- |
| 1 | 73 | 61 | 83,6 % | erster Lauf nach den fünf beauftragten Korrekturen |
| 2 | 75 | 69 | 92,0 % | nach Behebung von fünf Fehlalarmen der Testsuite |
| 3 | 75 | 74 | 98,7 % | nach Behebung des `set -e`-Fehlers und des apt-Rechtefehlers |
| 4 | 86 | 86 | 100,0 % | nach Verstärkung der Pin-Prüfung, mit neuen Testfällen |
| 5 | 114 | 114 | 100,0 % | nach Abarbeitung der 17 Review-Befunde |

Die zwölf Fehler des ersten Durchgangs teilten sich auf in sieben
Fehlalarme der Testsuite und fünf echte Fehler der eigenen Korrekturen.

### Voraussetzungen der Rohdaten

Die Zahl 114 gilt für einen Lauf mit allen Voraussetzungen.
Der Kopf von `reports/REGRESSION_RESULTS.tsv` nennt sie:

| Voraussetzung | Ohne sie |
| --- | --- |
| Rootrechte | R2, R3.4, R6, R7, R9.1, R9.2 und R10.1 werden übersprungen |
| `grub-script-check` | R1.1 bis R1.4 werden übersprungen |
| Paketindex in `packages/` | R2 und R3.4 bis R3.5 werden übersprungen |
| `shellcheck` | Testgruppe 3 der Eigenprüfung wird übersprungen |

Ein Lauf ohne diese Voraussetzungen liefert deshalb weniger bewertete
Tests. Das ist kein Fehler. Es ist im Kopf der Rohdaten nachlesbar.

### 6.2 Eigenprüfung des Pakets

| Prüfung | Ergebnis |
| --- | --- |
| `selftest.sh` mit Paketnutzlast, 14 Testgruppen | 118 bestanden, 0 fehlgeschlagen, 0 übersprungen |
| `selftest.sh` ohne Paketnutzlast | 117 bestanden, 0 fehlgeschlagen, 1 übersprungen |
| ShellCheck 0.9.0, `-x -s bash` | 11 von 11 Skripten ohne Befund |
| `bash -n`, alle Skripte | 11 von 11 ohne Fehler |

Neu in `selftest.sh` ist die Gruppe 12b. Sie hält die V4.1-Korrekturen fest
und schlägt an, wenn eine davon verloren geht.

### 6.3 Integrationstests

| Aufruf | Erwarteter Code | Gemessen |
| --- | --- | --- |
| `selftest.sh` | 0 | 0 |
| `preflight.sh --quick` auf falscher Hardware | 12 | 12 |
| `install.sh --dry-run` auf falscher Hardware | 10 | 10 |
| `verify.sh --non-interactive` | 19 | 19 |
| `deploy-to-t7.sh --dry-run` ohne SSD | 4 | 4 |
| `regression.sh` | 0 | 0 |
| `fetch-packages.sh` bei abweichendem Sollstand | 13 | 13 |
| `fetch-packages.sh --accept-new-checksums` | 0 | 0 |
| `rollback.sh --backup` ohne Wert | 2 | 2 |

Der Abbruch bei abweichendem Sollstand wurde echt ausgelöst: Eine
Prüfsumme in `SHA256SUMS.debs` wurde verändert, danach lief
`fetch-packages.sh`. Ergebnis: Code 13, der Sollstand blieb unverändert,
der neue Bestand lag als `SHA256SUMS.debs.new` daneben. Mit
`--accept-new-checksums` entstand zusätzlich
`SHA256SUMS.debs.provenance` mit Zeitpunkt, Umfang und Freigabevermerk.

## 7. Qualitätsvergleich mit V4.0

Jeder Punkt wurde gegen die beste bisher gültige Fassung geprüft.

| Bereich | V4.0 | V4.1 | Bewertung |
| --- | --- | --- | --- |
| GRUB-Prüfung | `bash -n`, in beide Richtungen falsch | `grub-script-check` | VERBESSERUNG |
| Offline-Installation | Simulation und Installation gegen Systemquellen | eine gepinnte Quelle für beides | VERBESSERUNG |
| Systemquellen | Eintrag in `/etc/apt/sources.list.d` | eigener Pfad unter `/var/lib` | VERBESSERUNG |
| Rückfall, Pakete | Namensmuster und `autoremove` | aufgezeichnete Pakete, kein `autoremove` | VERBESSERUNG |
| Rückfall, Sicherung | ohne Prüfung | mit Siegelprüfung, Abbruch bei Abweichung | VERBESSERUNG |
| Prüfsummen | stilles Überschreiben | Abbruch, Übernahme nur mit Freigabe | VERBESSERUNG |
| exFAT | nur Warnung | Erkennung, Prüfung am Ziel, Startblatt | VERBESSERUNG |
| Pfade mit Leerzeichen | brach die Paketquelle | kodiert | VERBESSERUNG |
| apt-Sandkasten | brach auf Wechselmedien ab | geprüft, Rückfall mit Begründung | VERBESSERUNG |
| Unterbrechung | nicht erfasst | zehn Phasen im Zustand | VERBESSERUNG |
| WLAN-Chip | Annahme im Dokument | eigenes Prüffeld, nur mit Nachweis PASS | VERBESSERUNG |
| Interner Bildschirm | nicht geprüft | eigenes Prüffeld über `gmux` und eDP | VERBESSERUNG |
| Simulationsvorschau | endete nach der Simulation | zeigt zusätzlich alle geplanten Änderungen | VERBESSERUNG |
| Tests | 102 in 13 Gruppen | 118 in 14 Gruppen plus 114 Regressionstests in 12 Gruppen | VERBESSERUNG |
| Anführungszeichen in GRUB | nur doppelte entfernt | beide Arten entfernt | VERBESSERUNG |
| sed-Ersetzungen | `&` und `\|` verfälschten die Zeile | maskiert | VERBESSERUNG |
| Optionen ohne Wert | stiller Abbruch mit Code 1 | Code 2 mit Meldung | VERBESSERUNG |
| Kernelschutz | vor der Freigabe | nach der Freigabe | VERBESSERUNG |
| Zweiter Installationslauf | überschrieb die Aufzeichnungen | wird abgefangen | VERBESSERUNG |
| Vorgabeeintrag im Bootmenü | unbestimmt | ausdrücklich gesetzt | VERBESSERUNG |
| Offener Teststart beim Rückfall | blieb bestehen | wird aufgehoben | VERBESSERUNG |
| Abnahmebericht | überschrieb die Vorlage | Zeitstempel, nur auf dem Zielgerät | VERBESSERUNG |
| Kernelmeldungen | `ACPI BIOS Bug:` erzeugte FAIL | ausgenommen | VERBESSERUNG |

**REPAIR_REGRESSION: keine.**
Keine Funktion von V4.0 wurde durch eine schlechtere ersetzt.
Jede Entfernung war die Entfernung eines Fehlers.

Eine Verhaltensänderung ist zu beachten, sie ist beabsichtigt:
`install.sh` bricht jetzt mit Code 6 ab, wenn `grub-script-check` fehlt.
V4.0 hätte in diesem Fall mit einer unbrauchbaren Prüfung weitergearbeitet.

## 8. Hardwarekompatibilität

Die Bewertung bleibt getrennt von den Testergebnissen.
`COMPATIBILITY_MATRIX.md` führt die Erwartungen aus den Quellen.
`reports/HARDWARE_TEST_REPORT.md` führt die Messungen.

Neu bewertet in V4.1:

| Prüffeld | Erwartung | Begründung |
| --- | --- | --- |
| WLAN-Chip | OFFEN | PASS nur nach Hardwareerkennung |
| Interner Bildschirm | ERWARTET_PARTIAL | `gmux` kann ihn an die AMD-Grafik legen |
| Ruhezustand | ERWARTET_FAIL | `s2idle` weckt die AMD-Grafik nicht |

Es wird keine vollständige Funktion versprochen.
Ohne erfolgreichen Hardwaretest bleibt jedes Prüffeld NOT_TESTED.

## 9. Offene Risiken

| Nr. | Risiko | Lage |
| --- | --- | --- |
| 1 | Unerwartete Neustarts aus dem Audio-Pfad (Bericht 179) | offen, Diagnoseanleitung liegt bei |
| 2 | Ruhezustand hängt oder stürzt ab (Berichte 31, 215) | offen, Ruhezustand abgeschaltet |
| 3 | Hänger beim Sitzungsstart über `gmux` | offen, Prüffeld ergänzt |
| 4 | 98 Grad Celsius CPU-Temperatur | offen, Lüfterkurve und Lasttestsperre |
| 5 | Kein WLAN ohne Apple-Firmware | offen, Anleitung liegt bei |
| 6 | Kein Live-USB-Rettungsmedium | offen, Notstartanleitung liegt bei |
| 7 | `install.sh` ab Schritt 5 nicht in der Bauumgebung prüfbar | Die Modellsperre greift davor. Simulation auf dem MacBook. |
| 8 | `deploy-to-t7.sh` ab Schritt 3 nicht prüfbar | Die SSD ist im Container nicht sichtbar. |

## 10. Erforderliche Freigaben

Vor jeder dauerhaften Systemänderung ist eine gesonderte Freigabe nötig.

| Freigabe | Wofür | Wo |
| --- | --- | --- |
| Ausführung auf dem RTX-Rechner | `fetch-packages.sh` lädt 472 MB | Baurechner |
| Eingabe `JA` | Schreiben auf die Samsung T7 | `deploy-to-t7.sh` |
| Eingabe `JA` | dauerhafte Änderungen am MacBook | `install.sh` |
| Eingabe `JA` | Rückfall ausführen | `rollback.sh` |
| `--remove-added` | Pakete entfernen | `rollback.sh` |
| `--accept-new-checksums` | neuen Prüfsummenstand übernehmen | `fetch-packages.sh` |
| `--force-unverified` | veränderte Sicherung nutzen | `rollback.sh` |
| `--allow-suspend` | Standby-Test | `verify.sh` |
| gesonderte Freigabe | EFI, NVRAM, Partitionen | kein Skript tut das |

## 11. Geänderte Dateien

| Datei | Art der Änderung |
| --- | --- |
| `scripts/lib/common.sh` | neu: GRUB-Prüfung, Pfadkodierung, gepinnte Paketverwaltung, Bestandsvergleich, Sicherungssiegel, Dateisystembewertung |
| `scripts/install.sh` | neu geschrieben: Sperren zuerst, gepinnte Quelle, Aufzeichnung, Phasen, Vorschau |
| `scripts/preflight.sh` | GRUB-Prüfung, Pfad- und Dateisystemprüfung, Bestandsauswertung, gleiche Technik wie `install.sh` |
| `scripts/rollback.sh` | neu geschrieben: Siegelprüfung, Aufzeichnungen, kein `autoremove` |
| `scripts/fetch-packages.sh` | Prüfsummen schließen bei Abweichung, Herkunftsvermerk |
| `scripts/deploy-to-t7.sh` | exFAT-Behandlung, Verknüpfungsprüfung, Startblatt, Startbarkeitsprüfung |
| `scripts/verify.sh` | Prüffeld WLAN-Chip, Prüffeld interner Bildschirm, Hinweis zu `mem_sleep` |
| `scripts/selftest.sh` | Gruppe 12b gegen einen Rückfall in die V4.0-Fehler |
| `scripts/regression.sh` | **neu**: 86 Regressionstests mit Rohdatentabelle |
| `reports/RELEASE_V4_1.md` | **neu**: dieser Bericht |
| `reports/REGRESSION_RESULTS.tsv` | **neu**: Rohdaten des Testlaufs mit Umgebungskopf |
| `scripts/lib/grub-config.sh` | beide Anführungsarten, Maskierung der sed-Ersetzung |
