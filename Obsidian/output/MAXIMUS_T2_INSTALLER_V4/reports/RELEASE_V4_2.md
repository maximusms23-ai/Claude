---
title: Release-Bericht V4.2
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, release, sicherheit, reparatur]
---

# Release-Bericht V4.2

Ausgangsstand: Commit `7d23e48`, Fassung V4.1.0.
Neue Fassung: V4.2.1.
Grundsatz: dieselbe Architektur. Es gibt keinen zweiten Installer.

**Die Fassung 4.2.1 schliesst drei Lücken, die eine Prüfung dieses Berichts
gemeldet hat.** Abschnitt 11 nennt sie einzeln.
Die Abschnitte 1 bis 10 sind auf den neuen Stand gebracht.

## 1. Ergebnis zuerst

Alle vier gemeldeten Sicherheitsbefunde sind bestätigt und behoben.
Das unabhängige Code-Review der Korrekturen fand vier weitere Fehler im
Code und einen Fehlalarm in einer neuen Prüfung.
Alle fünf sind behoben.

Die Regressionstests laufen mit 215 von 215 Fällen durch.
Das sind 100,0 Prozent.

**Zur Formulierung `REPAIR_REGRESSION`:** In den beschriebenen Tests wurde
keine unbeabsichtigte Verschlechterung festgestellt.
Die Installation auf dem MacBook und das Hardwareverhalten sind nicht
geprüft. Für diese Bereiche gilt die Aussage nicht.

| Status | Wert | Begründung |
| --- | --- | --- |
| `SOURCE_READY` | **JA** | Alle Quellen sind erneut geprüft. Die Prüfsummen stimmen. |
| `PACKAGE_READY` | **JA** | Das Paket ist vollständig. 215 Regressionstests sind bestanden. |
| `INSTALLATION_READY` | **NEIN** | Es gab keine Installation auf dem MacBook. |
| `HARDWARE_READY` | **NEIN** | Es gab keinen Hardwaretest auf dem MacBook. |
| `MAXIMUS_WORKER_READY` | **NEIN** | Die Hardware-Abnahme entscheidet darüber. |

Nichts liegt auf der Samsung T7.
Nichts ist auf dem MacBook installiert.
Qwen3.5 und die MAXIMUS-Bestandteile sind unverändert.

## 2. Bestätigte Fehler

### 2.1 Temperaturüberwachung (KRITISCH, bestätigt)

**Befund:** Die Funktion `max_temp_c` in `scripts/verify.sh` gab bei fehlendem
Sensor den Wert 0 aus. Der Rückgabewert war 0, also Erfolg.

**Messung.** Die alte Funktion lief gegen ein leeres Sensorverzeichnis:

```text
alt: ausgabe='0' rc=0
neu: ausgabe=""  rc=1
```

**Wirkung.** Die Folgen waren vier:

1. Die Ruhetemperatur wurde als 0 Grad Celsius gemeldet.
2. Die Sperre `TEMP_IDLE -ge 80` griff nie.
3. Die Abbruchsicherung im Lauf verglich 0 mit 90 und brach nie ab.
4. Der Lasttest lief ohne jede Temperaturaufsicht bis zum Ende.

Die zweite Sperre war ebenso schwach.
Die Variable `FAN_OK` wurde schon wahr, wenn ein Lüfter irgendeinen Wert
über 0 lieferte.
Der Dienst `t2fanrd` musste nicht laufen.

**Korrektur.** Fünf Vorbedingungen sperren den Lasttest jetzt einzeln:

1. Die Option `--thermal-test` muss gesetzt sein.
2. `mt2_cpu_temp` muss einen glaubwürdigen Wert liefern.
3. `FAN_STRICT_OK` muss 1 sein. Das verlangt einen drehenden Lüfter **und**
   den aktiven Dienst `t2fanrd`.
4. Die Ruhetemperatur muss unter 70 Grad Celsius liegen.
5. Der Benutzer muss gesondert freigeben.

Im Lauf entscheidet `mt2_thermal_step` über jeden Messschritt.
Diese Funktion ist einzeln geprüft.
Sie bricht bei 85 Grad Celsius ab.
Sie bricht nach dem zweiten Messausfall ab.
Sie bricht bei einem unsinnigen Wert sofort ab.

Die Standardabnahme führt keinen Lasttest aus.
Das Prüffeld CPU erhält dann `NOT_TESTED`.
Ein nicht getestetes Gerät erhält niemals `PASS`.

**Gemessene Abnahme in diesem Container (ohne Sensor, ohne Lüfter):**

| Prüffeld | Standard | mit `--thermal-test` |
| --- | --- | --- |
| CPU-Temperatursensor | `FAIL` | `FAIL` |
| CPU | `NOT_TESTED` | `BLOCKED` |
| Lüfterregelung | `NOT_TESTED` | `NOT_TESTED` |

**Die früher gemessenen 98 Grad Celsius** sind berücksichtigt.
Die Abbruchgrenze sank von 90 auf 85 Grad Celsius.
Der Messabstand sank von 2 auf 1 Sekunde.
Vor der Freigabefrage warnt das Skript ausdrücklich vor den 98 Grad.
Die Bewertung `PARTIAL` beginnt bei 80 Grad Celsius Spitzenwert.

**Tests:** R13.1 bis R13.36, davon 22 Funktionstests und 14 Gegenproben.

### 2.2 Simulation war nicht schreibfrei (HOCH, bestätigt)

**Befund:** `mt2_apt_pin_create` schrieb immer nach `/var/lib/maximus-t2/apt`.
Die Vorprüfung und die Simulation riefen die Funktion auf.
Beide liefen vor jeder Freigabe.

**Messung.** Die alte Vorprüfung lief in diesem Container:

```text
/var/lib/maximus-t2 vor dem Lauf:   0 Pfade
/var/lib/maximus-t2 nach dem Lauf: 12 Pfade (6 Dateien, 6 Verzeichnisse)
```

Angelegt wurden unter anderem `apt.conf`, `offline.list`, `lists/lock`,
`lists/auxfiles` und `log/eipp.log.xz`.

**Korrektur.** Die Funktion nimmt jetzt ein zweites Argument.
Es benennt das Basisverzeichnis.

| Aufrufer | Ablage |
| --- | --- |
| `preflight.sh` | `$TMPDIR_MT2/apt` (wird automatisch gelöscht) |
| `install.sh --dry-run` | `$TMP_WORK/apt` (wird automatisch gelöscht) |
| `install.sh` (echte Installation) | `/var/lib/maximus-t2/apt` |
| `rollback.sh` | räumt nur den festen Pfad |

Beide Skripte weisen die Schreibfreiheit selbst nach.
`preflight.sh` zählt am Ende die Dateien unter `/var/lib/maximus-t2/apt`.
`install.sh --dry-run` nimmt vor und nach dem Lauf einen Fingerabdruck von
`/etc`, `/boot`, `/var/lib/maximus-t2` und `/var/backups/maximus-t2`.
Der Fingerabdruck erfasst Typ, Pfad, Größe und Änderungszeit.

**Messung nach der Korrektur:**

```text
=== Schritt 12: Schreibfreiheit nachweisen ===
[  OK  ] Unter /var/lib/maximus-t2/apt liegt keine Datei.
         Die Vorpruefung war schreibfrei.
/var/lib/maximus-t2 nach dem Lauf: 0 Pfade
```

**Grenze dieses Nachweises.** Der Fingerabdruck überwacht vier Pfade:
`/etc`, `/boot`, `/var/lib/maximus-t2` und `/var/backups/maximus-t2`.
Er belegt damit **keine** vollständige Schreibfreiheit im gesamten System.
Ein Schreibzugriff außerhalb dieser Pfade fällt nicht auf.
Die vier Pfade decken jeden Pfad ab, den `install.sh` nachweislich anfasst.
Mehr sagt die Messung nicht.

Flüchtige Systempfade zählen nicht als Änderung.
Die Liste `MT2_FS_VOLATILE` nennt neun Pfade, darunter `/etc/resolv.conf`
und `/etc/ld.so.cache`.
Das System schreibt diese Dateien von selbst.
Ohne diese Ausnahme gäbe es einen Fehlalarm.
Der Bericht nennt die Zahl der flüchtigen Änderungen trotzdem.

**Tests:** R14.1 bis R14.21.

### 2.3 Unvollständige Sicherungen (HOCH, bestätigt)

**Befund:** Im Sicherungsschritt von `scripts/install.sh` endeten 16 Befehle
auf `|| true`.
Davon waren 12 Kopierbefehle.
Eine fehlgeschlagene Kopie von `/etc/default/grub` blieb unbemerkt.

**Messung:**

```text
alt: 16 ignorierte Fehler im Sicherungsschritt, davon 12 'cp'
neu:  0 ignorierte Fehler im Sicherungsschritt
```

Das Siegel schloss die Lücke nicht.
`mt2_backup_seal` bildet die Prüfsummen über die **vorhandenen** Dateien.
`mt2_backup_verify` bestätigt danach die Selbstkonsistenz.
Eine fehlende Datei fällt dabei nicht auf.

**Gegenprobe (Test R15.6 und R15.7).** Eine Pflichtdatei wurde entfernt.
Danach wurde neu versiegelt:

```text
mt2_backup_verify         -> 0  (die Sicherung gilt als unverfälscht)
mt2_backup_check_complete -> 1  (die Sicherung ist unvollständig)
```

**Korrektur.** Die Sicherung unterscheidet jetzt zwei Dateiarten.

| Art | Dateien | Regel bei einem Fehler |
| --- | --- | --- |
| Pflicht | `/etc/default/grub`, `/boot/grub/grub.cfg` | Abbruch mit Code 17 |
| Pflicht (erzeugt) | `pkg-before.txt`, `dpkg-selections.txt`, `running-kernel.txt`, `installer-version.txt`, `stamp.txt` | Abbruch mit Code 17 |
| Wahl | 10 weitere Konfigurationspfade | Vermerk im `MANIFEST`, Lauf geht weiter |

Eine **vorhandene** Quelle muss erfolgreich kopiert werden.
Nur eine **fehlende** Quelle darf übersprungen werden, und nur bei `wahl`.

Die Reihenfolge ist jetzt:

1. Pflichtdateien kopieren.
2. Wahldateien kopieren.
3. Erzeugte Nachweise schreiben.
4. Vollständigkeit prüfen (`mt2_backup_check_complete`).
5. Versiegeln (`mt2_backup_seal`).
6. Siegel nachprüfen (`mt2_backup_verify`).

Die Prüfung in Schritt 4 vergleicht jede Pflichtdatei Byte für Byte mit dem
Original.
Das Verzeichnis trägt ein `MANIFEST` mit einer Zeile je Datei.
`rollback.sh` liest dieses `MANIFEST`.
Es bricht mit Code 13 ab, wenn eine Pflichtdatei fehlt.
Mit `--force-unverified` läuft es auf ausdrückliche Anweisung dennoch.

**Fehler-Injektionstests:** R6.10 bis R6.17 und R15.1 bis R15.15.
Geprüft werden: fehlende Pflichtdatei, leere Pflichtdatei, abweichende Kopie,
ein im `MANIFEST` gemeldeter Ausfall und ein Altbestand ohne `MANIFEST`.

### 2.4 Git-Anleitung (bestätigt, mit einer Berichtigung)

**Befund:** Die Anleitung zum Klonen zeigte diese Reihenfolge:

```text
git clone <repo-url> maximus-claude
cd maximus-claude/Obsidian/output/MAXIMUS_T2_INSTALLER_V4
```

Der erste Befehl landet auf `main`.
Dort gibt es `Obsidian/output/` nicht.
Der zweite Befehl scheitert deshalb.

**Messung in einem völlig leeren Arbeitsverzeichnis:**

```text
falsche Reihenfolge: cd scheitert, rc=1
  Inhalt von Obsidian/ auf main: CLAUDE.md, Clippings, Ideen, Projekte,
  Unbenannt.canvas, mkdocs.yml, wiki   (kein output)

richtige Reihenfolge: cd gelingt
  git branch --show-current -> claude/maximus-strata-validation-c44vzz
  ls scripts/install.sh    -> scripts/install.sh
```

**Korrektur.** Der Zweig wird beim Klonen aktiv:

```text
git clone --branch claude/maximus-strata-validation-c44vzz \
  https://github.com/maximusms23-ai/Claude maximus-claude
```

Die README trägt den Abschnitt 5.0 mit beiden richtigen Varianten
und einer Gegenprobe aus zwei Zeilen.
Die falsche Reihenfolge steht als Gegenbeispiel in einem `text`-Block.
Sie ist damit kein Arbeitsschritt.

**Tests:** R16.1 bis R16.7.

**Berichtigung zur Fehlermeldung.** Der Fehler lag nicht in `README.md`.
Die `README.md` der Fassung V4.1 enthielt überhaupt keinen Git-Befehl.
Der fehlerhafte Block stand in `reports/BUILD_REPORT.md`, Zeile 220.
Der Befund selbst ist richtig.
Nur die Dateiangabe war falsch.
Beide Dateien sind jetzt berichtigt.

## 3. Fünf Befunde aus dem Code-Review der eigenen Korrekturen

### 3.1 `pipefail` verfälschte die Zählung flüchtiger Pfade

`mt2_fs_fingerprint_volatile_count` nutzte `diff` in einer Pipeline.
`diff` liefert 1, wenn es einen Unterschied findet.
Mit `set -o pipefail` schlug die ganze Pipeline fehl.
Der Ersatzwert sprang ein.
Die Funktion gab dann zwei Zeilen aus: `1` und `0`.

Korrektur: `{ diff ... || true; }` und `|| n=0`.

### 3.2 `mt2_apt` hätte stillschweigend die Systemquellen genutzt

Die Pfadvariablen `MT2_APT_CONF`, `MT2_APT_LIST` und `MT2_APT_LISTS` sind
nicht mehr `readonly`.
`mt2_apt_pin_create` setzt sie.
Ein Aufruf von `mt2_apt` **vor** dieser Funktion hätte `APT_CONFIG=''`
gesetzt.
`apt-get` hätte dann die Systemquellen gelesen.
Genau das war der Fehler 2 der Fassung V4.0.

Korrektur: `mt2_apt` prüft die Konfiguration und bricht mit Code 14 ab.

**Messung:**

```text
[FEHLER] Die gepinnte apt-Konfiguration fehlt.
         Rufe zuerst mt2_apt_pin_create auf.
rc=14
```

**Tests:** R14.18 und R14.19.

### 3.3 Zwei Sensoraufrufe konnten zwei verschiedene Werte liefern

`verify.sh` rief `mt2_cpu_temp` zweimal auf: einmal zur Probe, einmal für den
Wert.
Zwischen beiden Aufrufen kann sich die Temperatur ändern.
Die geprüfte Messung war dann nicht die verwendete Messung.

Korrektur: ein einziger Aufruf mit `TEMP_IDLE="$(mt2_cpu_temp)" || TEMP_IDLE=''`.

### 3.4 Der Rückfall ließ das Protokollverzeichnis liegen

`rollback.sh` kündigte an, die Paketquelle unter `/var/lib/maximus-t2/apt`
zu entfernen.
Es entfernte `offline.list`, `apt.conf` und `lists/`.
Das Verzeichnis `log/` blieb liegen.
Der Bericht war damit zu großzügig.

Korrektur: `log/` wird mit entfernt.
Danach entfernt `rmdir` das Verzeichnis selbst, aber nur wenn es leer ist.
Fremde Dateien bleiben unangetastet und werden benannt.

**Tests:** R14.20 und R14.21.

### 3.5 Eine neue Prüfung schlug auf ihren eigenen Kommentar an

Die neue Gruppe "Test 12c" in `scripts/selftest.sh` suchte nach dem Namen
`max_temp_c` in `scripts/verify.sh`.
Der Name steht dort noch in einem Kommentar.
Der Kommentar erklärt, warum die Funktion entfallen ist.
Die Prüfung meldete deshalb einen Fehler, den es nicht gab.

Korrektur: Die Prüfung überspringt Kommentarzeilen.
Der gleichartige Test R13.23 in `regression.sh` war von Anfang an richtig.
Er sucht nur nach einer Definition oder einem Aufruf.

## 4. Falsche Fehlerbehauptungen

Es gab eine falsche Angabe in der Fehlermeldung.
Sie betrifft Abschnitt 2.4: die Datei `README.md` statt
`reports/BUILD_REPORT.md`.
Der Befund selbst war richtig.

Ich habe zusätzlich 13 Fehlalarme in meinen eigenen neuen Tests gefunden
und behoben (Abschnitt 5.4 und 3.5).
Alle 13 lagen in den Tests, nicht im Installationspaket.

Alle anderen drei Befunde waren in jeder Einzelheit richtig.
Die genannten Dateien, Funktionen und Zeilen stimmten.

## 5. Testergebnisse aus Rohdaten

Die Rohdaten liegen in `reports/REGRESSION_RESULTS.tsv`.
Die Datei trägt einen Kopf mit Zeitpunkt, Kernel, Rechten und Werkzeugpfaden.
Jede Erfolgsquote unten ist aus dieser Datei gerechnet.

### 5.1 Regressionstests mit allen Voraussetzungen

Voraussetzungen: Rootrechte, `grub-script-check`, `shellcheck`, Paketindex
mit 485 Dateien.

| Gruppe | Thema | Fälle |
| --- | --- | --- |
| R1 | GRUB-Syntaxprüfung | 8 |
| R2 | Gepinnte Offline-Paketquelle | 13 |
| R3 | Pfade mit Sonderzeichen | 9 |
| R4 | Prüfsummenverwaltung | 8 |
| R5 | Aufzeichnung der Änderungen | 9 |
| R6 | Rückfall gegen vorhandene Konfiguration | 17 |
| R7 | Unterbrochene Installation | 4 |
| R8 | Dateisystem ohne Unix-Rechte | 11 |
| R9 | Kernel- und Modellsperren | 4 |
| R10 | GRUB-Schutz | 6 |
| R11 | Fehlerzweige und Sandkasten | 7 |
| R12 | Befunde des Code-Reviews V4.1 | 28 |
| **R13** | **Temperaturüberwachung (neu)** | **36** |
| **R14** | **Schreibfreiheit (neu)** | **21** |
| **R15** | **Vollständige Sicherungen (neu)** | **15** |
| **R16** | **Git-Anleitung (neu)** | **7** |
| **R18** | **Echte Wiederherstellung (neu in 4.2.1)** | **10** |
| | **Summe der Fälle** | **213** |
| R17 | Schlussrechnung (zählt nicht mit) | 2 |
| | **Summe der Zeilen** | **215** |

```text
Tests:         215
Bestanden:     215
Fehler:          0
Übersprungen:    0
Bewertet:      215
Erfolgsquote:  215 / 215 = 100,0 Prozent

Schlussrechnung:
  Faelle im Verzeichnis: 213
  Faelle im Lauf:        213
  Bestanden 213 + Fehler 0 + Uebersprungen 0 = 213
```

Die vollständige Fallliste steht in `reports/TESTFALL_INVENTAR.md`.
Jede Zeile nennt Kennung, Gruppe, Bezeichnung und die Quellzeile in
`scripts/regression.sh`.

### 5.2 Die 114 Tests der Fassung V4.1

Alle 114 Fälle der Fassung V4.1 sind erhalten.
Alle 114 sind bestanden.
Die Gruppen R1 bis R12 wuchsen auf 124 Fälle.
Die 10 neuen Fälle prüfen die Korrekturen dieser Fassung:

| Neue Fälle | Thema |
| --- | --- |
| R2.1b, R2.1c | Die Pfadvariablen des Pins sind gesetzt. |
| R6.10 bis R6.17 | Fehler-Injektion in die Vollständigkeit der Sicherung. |

### 5.3 Regressionstests ohne Voraussetzungen

Derselbe Lauf ohne Rootrechte und ohne die beiden Prüfwerkzeuge:

```text
Tests:         214
Bestanden:     150
Fehler:          0
Übersprungen:   64
Bewertet:      150
Erfolgsquote:  150 / 150 = 100,0 Prozent

Schlussrechnung:
  Faelle im Verzeichnis: 213
  Faelle im Lauf:        213
  Bestanden 149 + Fehler 0 + Uebersprungen 64 = 213
```

**149 + 64 = 213.** Die Rechnung geht auf.
Jeder übersprungene Fall trägt eine eigene Zeile in den Rohdaten.
Ein übersprungener Fall gilt nie als bestanden.
Der Kopf der Rohdaten nennt jede Voraussetzung.

Abschnitt 11.1 beschreibt, warum diese Rechnung vorher nicht aufging.

### 5.4 Verlauf der Erfolgsquote

| Lauf | Fassung | Fälle | Bestanden | Quote |
| --- | --- | --- | --- | --- |
| 1 | V4.1 | 73 | 61 | 83,6 % |
| 2 | V4.1 | 75 | 69 | 92,0 % |
| 3 | V4.1 | 75 | 74 | 98,7 % |
| 4 | V4.1 | 86 | 86 | 100,0 % |
| 5 | V4.1 | 114 | 114 | 100,0 % |
| 6 | V4.2 | 188 | 177 | 94,1 % |
| 7 | V4.2 | 199 | 199 | 100,0 % |
| 8 | V4.2 | 203 | 202 | 99,5 % |
| 9 | V4.2 | 203 | 203 | 100,0 % |
| 10 | V4.2.1 | 203 | 202 | 99,5 % |
| 11 | V4.2.1 | 215 | 215 | 100,0 % |

Lauf 6 fand 11 Fehler.
Vier betrafen die Gruppe R2: der Aufruf lief in einer Befehlsersetzung,
die gesetzten Pfadvariablen gingen verloren.
Sechs betrafen die Gruppen R6 und R7: die Testdaten stammten aus V4.1 und
trugen kein `MANIFEST`.
Einer betraf die Gruppe R16: der Test erkannte das Gegenbeispiel der README
als Arbeitsschritt.
Alle 11 Fehler lagen in den Tests, nicht im Installationspaket.
Lauf 8 fand einen Fehler derselben Art (`pipefail` in einem neuen Test).
Lauf 10 fand einen Fehler durch die neue Schlussrechnung: Der Fall `R10.1b`
fiel aus dem Auswahlmuster `^R10\.[1-3]$`.
Das Muster war zu eng. Der Fehler lag in der Buchhaltung, nicht im Paket.
Lauf 11 enthält die Gruppe R18 und die beiden Fälle der Schlussrechnung.

### 5.5 Eigenprüfung des Pakets

`scripts/selftest.sh` prüft die Vollständigkeit und die Prüfsummen.
Die Gruppe "Test 12c" ist neu.
Sie sichert die vier Korrekturen dieser Fassung mit 18 Prüfungen ab.

Die Gruppe "Test 12d" prüft die Nachvollziehbarkeit der Tests (10 Fälle).

| Lauf | Fälle | Bestanden | Übersprungen |
| --- | --- | --- | --- |
| mit Paketnutzlast (485 Dateien) | 155 | 155 | 0 |
| ohne Paketnutzlast | 143 | 141 | 2 |

Die übersprungenen Fälle prüfen die Prüfsummen der `.deb`-Dateien.
Ohne Nutzlast gibt es diese Dateien nicht.

### 5.6 ShellCheck

Alle 13 Skripte sind ohne Befund.

```text
shellcheck 0.9.0, 13 Skripte, 0 Befunde
```

23 Stellen tragen `# shellcheck disable=SC2016` mit Begründung.
Sie suchen absichtlich nach wörtlichen `$`-Mustern im Quelltext.

## 6. Qualitätsvergleich mit V4.1

| Merkmal | V4.1 | V4.2 |
| --- | --- | --- |
| Lasttest in der Standardabnahme | läuft selbsttätig | läuft nicht |
| Lasttest ohne Temperaturmessung | möglich | gesperrt |
| Lasttest ohne `t2fanrd` | möglich | gesperrt |
| Abbruchgrenze | 90 Grad Celsius | 85 Grad Celsius |
| Messabstand im Lauf | 2 Sekunden | 1 Sekunde |
| Abbruch bei Sensorausfall | nein | nach zwei Ausfällen |
| Schreibzugriffe der Vorprüfung | 6 Dateien | 0 Dateien |
| Nachweis der Schreibfreiheit | keiner | Fingerabdruck vor und nach dem Lauf |
| Ignorierte Kopierfehler | 16 | 0 |
| Prüfung der Vollständigkeit | keine | Byte für Byte, vor dem Siegeln |
| Verzeichnis der Sicherung | ohne `MANIFEST` | mit `MANIFEST` |
| Git-Anleitung | ohne Zweig | mit Zweig beim Klonen |
| Regressionstests | 114 | 203 |
| ShellCheck-Befunde | 0 | 0 |

**REPAIR_REGRESSION: in den beschriebenen Tests keine.**

Diese Aussage gilt genau für den Prüfumfang dieses Berichts:
215 Regressionstests, 155 Fälle der Eigenprüfung, ShellCheck über
13 Skripte und die Wiederherstellungsprobe im Mount-Namensraum.
Kein Prüffeld dieser Läufe ist schlechter als in V4.1.
Keine Funktion ist entfallen.

**Nicht abgedeckt:** die Installation auf dem MacBook, das Verhalten der
Temperatursensoren und der Lüfterregelung am Gerät sowie der Dauerbetrieb.
Für diese Bereiche liegt kein Messwert vor.
Eine Verschlechterung ist dort weder festgestellt noch ausgeschlossen.

Zwei Änderungen sind Absicht und keine Verschlechterung:

1. Die Standardabnahme testet die CPU nicht mehr unter Last.
   Das Prüffeld CPU erhält `NOT_TESTED` statt `PASS` oder `PARTIAL`.
   Grund: Ein Lasttest ohne Aufsicht ist bei 98 Grad Celsius gefährlich.
   Die Abnahme bleibt damit ehrlich: ungetestet heißt ungetestet.
2. Die Lüfterregelung erhält ohne Lasttest `NOT_TESTED`.
   Grund: Die Regelung ist nur unter Last prüfbar.

## 7. Geänderte Dateien

| Datei | Änderung |
| --- | --- |
| `scripts/lib/common.sh` | +232 Zeilen: Temperaturfunktionen, Fingerabdruck, Vollständigkeitsprüfung, Pin mit Basisverzeichnis, Schutz in `mt2_apt` |
| `scripts/verify.sh` | Lasttest hinter `--thermal-test`, fünf Sperren, `max_temp_c` entfällt |
| `scripts/install.sh` | Arbeitsverzeichnis zuerst, Fingerabdruck im Dry-Run, Sicherung ohne `\|\| true`, `MANIFEST` |
| `scripts/preflight.sh` | Pin im temporären Verzeichnis, Nachweis der Schreibfreiheit |
| `scripts/rollback.sh` | liest das `MANIFEST`, räumt den festen Pfad vollständig |
| `scripts/regression.sh` | +89 Testfälle, Gruppen R13 bis R16 |
| `scripts/selftest.sh` | neue Gruppe "Test 12c" |
| `README.md` | neuer Abschnitt 5.0 zum Beschaffen des Pakets |
| `reports/BUILD_REPORT.md` | Klonbefehl mit `--branch` |
| `manifest.json` | Fassung 4.2.0, Liste der Korrekturen, Testzahlen |
| `reports/REGRESSION_RESULTS.tsv` | Rohdaten von 203 Fällen |
| `scripts/deploy-to-t7.sh` | nur die Fassungsangabe im Kopf |
| `scripts/fetch-packages.sh` | nur die Fassungsangabe im Kopf |
| `reports/RELEASE_V4_2.md` | neu, dieser Bericht |
| `scripts/regression.sh` (4.2.1) | Fallverzeichnis, Schlussrechnung R17, Gruppe R18 |
| `scripts/tests/restore-probe.sh` | neu, echte Wiederherstellung im Mount-Namensraum |
| `scripts/make-inventory.sh` | neu, erzeugt die Fallliste aus dem Quelltext |
| `reports/TESTFALL_INVENTAR.md` | neu, 213 Fälle mit Quellzeile |
| `SHA256SUMS` | neu gebildet, 49 Dateien |

Der Gesamtumfang: 14 Dateien, 1443 eingefügte und 160 entfernte Zeilen.

## 8. Offene Risiken

1. **Kein Hardwaretest.** Die Bauumgebung ist ein Container.
   Es gibt kein MacBookPro16,1 und keinen Temperatursensor.
   Alle Temperaturtests laufen über die Testnaht `MT2_TEMP_SOURCES`.
   Diese Naht wirkt nur mit `MT2_SELFTEST=1`.
   Sie ist durch R13.13 und R13.14 abgesichert.
   **Die Funktion auf echter Hardware ist damit nicht bewiesen.**
2. **98 Grad Celsius bleiben ein Risiko.**
   Die Ursache ist nicht geklärt.
   Der Lasttest ist jetzt gesperrt, aber die Wärme bleibt.
   Prüfe die Lüfterregelung zuerst, bevor MAXIMUS Last erzeugt.
3. **Der Fingerabdruck erfasst nur vier Pfade.**
   Geprüft werden `/etc`, `/boot`, `/var/lib/maximus-t2` und
   `/var/backups/maximus-t2`.
   Ein Schreibzugriff außerhalb dieser Pfade fällt nicht auf.
   Die Aussage „schreibfrei" gilt deshalb nur für diese vier Pfade.
4. **Die Liste der flüchtigen Pfade ist eine Annahme.**
   Sie nennt neun Pfade.
   Ein weiterer flüchtiger Pfad würde einen Fehlalarm erzeugen.
   Der Fehlalarm wäre sichtbar und sperrt nur die Simulation.
5. **Die Prüfung der Sicherung deckt nur Dateien ab.**
   `cmp` vergleicht keine Verzeichnisse.
   Die Pflichtliste nennt deshalb nur Dateien.
6. **Keine Prüfung gegen echte Paketinstallation.**
   Die Auflösung ist offline bewiesen.
   Die Installation selbst ist nicht ausgeführt.
7. **Die Wiederherstellungsprobe deckt nicht alles ab.**
   Gruppe R18 weist das Zurückschreiben von Konfigurationsdateien nach.
   Sie prüft `update-grub`, `update-initramfs` und das Bootverhalten nicht.
   Diese Programme fehlen in der Bauumgebung.

## 9. Erforderliche Freigaben

Diese Schritte brauchen eine gesonderte Freigabe:

1. Übertragung des Pakets auf die Samsung T7.
2. Installation auf dem MacBookPro16,1.
3. Der einmalige Teststart in den T2-Kernel.
4. Der CPU-Lasttest in `verify.sh`.
5. Jede Änderung an EFI, NVRAM oder Partitionen. Diese ist nicht vorgesehen.

Keiner dieser Schritte ist ausgeführt.

## 10. Empfohlene Reihenfolge am Gerät

1. `sudo bash scripts/preflight.sh`
2. `sudo bash scripts/install.sh --dry-run`
3. Freigabe einholen.
4. `sudo bash scripts/install.sh`
5. Neustart in den T2-Kernel.
6. `sudo bash scripts/verify.sh` (ohne Lasttest)
7. Die Lüfterregelung bewerten.
8. Erst danach: `sudo bash scripts/verify.sh --thermal-test`
9. Erst nach `HARDWARE_READY`: MAXIMUS-Arbeiter einrichten.

## 11. Nachtrag 4.2.1: drei gemeldete Lücken

Eine Prüfung des Berichts V4.2.0 nannte drei Lücken.
Alle drei sind bestätigt. Alle drei sind geschlossen.

### 11.1 Die Testzahlen waren nicht nachvollziehbar (bestätigt)

**Befund.** Der eingeschränkte Lauf meldete 158 Fälle.
Der vollständige Lauf meldete 203 Fälle.
Die Darstellung erklärte die Differenz von 45 Fällen nicht.

**Ursache.** Die Funktion `skip` zählte **einen** Eintrag je Bereich, nicht
einen je Fall. Ein Eintrag wie `R6.1-R6.18 Rueckfallverhalten` stand für
17 Fälle und wurde als ein übersprungener Test gezählt.
Die Bereichsangaben waren zusätzlich veraltet: `R2.1-R2.8` nannte 8 Fälle,
die Gruppe R2 führte aber 13.

**Korrektur.** Das Fallverzeichnis entsteht jetzt aus dem eigenen Quelltext.
`skip` wählt die betroffenen Kennungen daraus aus.
Jeder übersprungene Fall erhält eine eigene Zeile in den Rohdaten.
Am Ende jedes Laufs vergleicht die neue Gruppe R17 das Verzeichnis mit dem
Lauf: Fall für Fall, ohne Ausnahme.

```text
vorher (eingeschraenkt): Tests 158, Bestanden 149, Uebersprungen  9
                         149 + 9 = 158, aber 203 Faelle gibt es
nachher (eingeschraenkt): Tests 214, Bestanden 150, Uebersprungen 64
                         149 + 64 = 213 Faelle, Rechnung geht auf
```

Die Rechnung fand sofort einen echten Fehler: Der Fall `R10.1b` lag
außerhalb des Auswahlmusters und war in keinem Lauf nachlesbar.

**Neu:** `reports/TESTFALL_INVENTAR.md` nennt alle 213 Fälle mit Kennung,
Gruppe, Bezeichnung und Quellzeile.
`scripts/make-inventory.sh` erzeugt die Datei aus `scripts/regression.sh`.
Der Fall `R17.2` prüft bei jedem Lauf, ob die Datei zum Quelltext passt.
Gegenprobe: Nach dem Entfernen einer Zeile schlug `R17.2` an und nannte
`R18.10`.

### 11.2 `REPAIR_REGRESSION` war zu weit formuliert (bestätigt)

**Befund.** Die Aussage „keine Qualitätsverschlechterung" galt dem ganzen
Vorhaben. Belegt war sie nur für die beschriebenen Tests.

**Korrektur.** Abschnitt 1 und Abschnitt 6 tragen die Aussage jetzt mit
ihrem Prüfumfang. Nicht abgedeckt sind die Installation, das Verhalten der
Sensoren und der Lüfterregelung am Gerät sowie der Dauerbetrieb.

### 11.3 Die Sicherheitsnachweise hatten Grenzen (bestätigt, teils geschlossen)

**Befund A: Schreibfreiheit.** Der Fingerabdruck überwacht vier Pfade.
Er belegt keine Schreibfreiheit im gesamten System.
**Stand:** Die Grenze steht jetzt in Abschnitt 2.2 und in Abschnitt 8.
Der Nachweis selbst bleibt auf diese vier Pfade beschränkt.

**Befund B: Wiederherstellung.** Die Sicherungsprüfung erkannte fehlende und
abweichende Dateien. Ein erfolgreich **durchgeführter** Rückfall war damit
nicht bewiesen.
**Stand:** geschlossen. Die neue Gruppe R18 führt einen echten Rückfall aus.

Der Ablauf von `scripts/tests/restore-probe.sh`:

1. Die Probe öffnet einen eigenen Mount-Namensraum.
2. Sie hängt temporäre Verzeichnisse über `/etc/default`, `/boot`,
   `/etc/modules-load.d` und die eigenen Zustandspfade.
3. Sie legt einen Urzustand an und sichert ihn wie `install.sh`.
4. Sie ändert die Dateien, wie eine Installation es tut.
5. Sie ruft `rollback.sh --yes` auf. Das ist **keine** Simulation.
6. Sie vergleicht die Dateien Byte für Byte mit dem Urzustand.

**Gemessen, gültige Sicherung:**

```text
vorher_geaendert=ja
rueckfall_rc=0
grub_zurueck=ja
grubcfg_zurueck=ja
neue_datei_entfernt=ja
```

**Gemessen, Pflichtdatei aus der Sicherung entfernt:**

```text
rueckfall_rc=13
grub_zurueck=nein
grubcfg_zurueck=nein
neue_datei_entfernt=nein
```

Der zweite Fall ist die Gegenprobe. Eine beschädigte Sicherung bricht ab.
Sie fasst keine Datei an. Das Protokoll nennt die fehlende Pflichtdatei.

Der Fall `R18.10` weist nach, dass das Wirtsystem unverändert bleibt.
Er vergleicht einen Fingerabdruck von `/etc/default`, `/boot` und
`/etc/modules-load.d` vor und nach beiden Proben.

**Was R18 nicht beweist.** Die Probe läuft auf dem Baurechner, nicht auf dem
MacBook. Sie prüft das Zurückschreiben von Konfigurationsdateien.
Sie prüft **nicht** `update-grub`, `update-initramfs` oder das Bootverhalten.
Diese Programme fehlen in der Bauumgebung.
Der Rückfall nutzte deshalb den dokumentierten Ersatzweg: Er schrieb die
gesicherte `grub.cfg` unmittelbar zurück.

### 11.4 Was weiterhin offen bleibt

| Punkt | Stand |
| --- | --- |
| Testfallliste nachvollziehbar | geschlossen, `reports/TESTFALL_INVENTAR.md` |
| Abgleich mit dem Quellcode | geschlossen, `R17.1` und `R17.2` bei jedem Lauf |
| Wiederherstellung geprüft | für Konfigurationsdateien geschlossen, `R18` |
| `update-grub` und Bootpfad | offen, braucht das Zielgerät |
| Temperatursensoren am Gerät | offen, braucht das Zielgerät |
| Lüfterregelung am Gerät | offen, braucht das Zielgerät |
| Ursache der 98 Grad Celsius | offen |
| Schreibfreiheit über vier Pfade hinaus | offen, bewusst nicht abgedeckt |

Die **98 Grad Celsius** bleiben bis zur Ursachenklärung ein offener Befund.

