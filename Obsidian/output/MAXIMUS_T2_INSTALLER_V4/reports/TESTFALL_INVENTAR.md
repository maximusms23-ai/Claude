---
title: Testfall-Inventar
created: 2026-10-10
type: bericht
tags: [maximus, t2linux, tests]
---

# Testfall-Inventar

Erzeugt aus `scripts/regression.sh` von `scripts/make-inventory.sh`.
Diese Datei wird nicht von Hand gepflegt.

Faelle: **213**. Gruppen: **17**.

Die Gruppe R17 fuehrt die Schlussrechnung. Sie zaehlt nicht mit.
Jeder Lauf vergleicht dieses Verzeichnis mit den Rohdaten.
Ein Fall ohne Ergebnis laesst den Lauf fehlschlagen.

## Faelle je Gruppe

| Gruppe | Faelle |
| --- | --- |
| R1 - GRUB-Syntaxpruefung (Fehler 1) | 8 |
| R2 - Gepinnte Offline-Paketquelle (Fehler 2) | 13 |
| R3 - Pfade mit Sonderzeichen (Fehler 2b) | 9 |
| R4 - Pruefsummenverwaltung (Fehler 4) | 8 |
| R5 - Sicherung und Rueckfall (Fehler 3) | 9 |
| R6 - Rueckfall gegen vorhandene Systemkonfiguration | 17 |
| R7 - Unterbrochene Installation | 4 |
| R8 - Dateisystem ohne Unix-Rechte (Fehler 5) | 11 |
| R9 - Samsung T7 fehlt | 4 |
| R10 - Sperren des Installationsskripts | 6 |
| R11 - Fehlerklassen aus dem Code-Review | 7 |
| R12 - Befunde des unabhaengigen Code-Reviews | 28 |
| R13 - Temperaturueberwachung (Sicherheitsbefund 1) | 36 |
| R14 - Schreibfreiheit von Pruefung und Dry-Run (Sicherheitsbefund 2) | 21 |
| R15 - Vollstaendige Sicherungen (Sicherheitsbefund 3) | 15 |
| R16 - Git-Anleitung (Sicherheitsbefund 4) | 7 |
| R18 - Echte Wiederherstellung (Nachweis statt Ankuendigung) | 10 |

## Vollstaendige Liste

| Kennung | Bezeichnung | Quelle |
| --- | --- | --- |
| `R1.1` | gueltige grub.cfg wird akzeptiert | `scripts/regression.sh:229` |
| `R1.2` | nicht geschlossener menuentry wird erkannt | `scripts/regression.sh:230` |
| `R1.3` | fehlerhaftes if wird erkannt | `scripts/regression.sh:231` |
| `R1.4` | fehlende Datei wird gemeldet | `scripts/regression.sh:232` |
| `R1.5` | Gegenprobe: 'bash -n' meldet Fehlalarm | `scripts/regression.sh:234` |
| `R1.6` | Gegenprobe: 'bash -n' uebersieht den Fehler | `scripts/regression.sh:235` |
| `R1.7` | kein Skript prueft grub.cfg mit 'bash -n' | `scripts/regression.sh:248` |
| `R1.8` | install, preflight und rollback nutzen grub-script-check | `scripts/regression.sh:254` |
| `R2.1` | gepinnte Konfiguration wird angelegt | `scripts/regression.sh:271` |
| `R2.1b` | die Pfadvariablen sind gesetzt | `scripts/regression.sh:272` |
| `R2.1c` | ohne zweites Argument gilt der feste Pfad | `scripts/regression.sh:274` |
| `R2.2` | Quellenliste nennt nur file:// | `scripts/regression.sh:275` |
| `R2.3` | Konfiguration schaltet sourceparts ab | `scripts/regression.sh:277` |
| `R2.4` | Konfiguration nutzt eigene Listen | `scripts/regression.sh:279` |
| `R2.5` | Index wird gelesen | `scripts/regression.sh:281` |
| `R2.6` | nur die lokale Quelle ist sichtbar | `scripts/regression.sh:282` |
| `R2.7` | Gegenprobe: Netzquelle wird erkannt | `scripts/regression.sh:285` |
| `R2.8` | Aufloesung gelingt ohne Netzzugang | `scripts/regression.sh:291` |
| `R2.9` | Simulation nennt keine Netzadresse | `scripts/regression.sh:296` |
| `R2.10` | Simulation entfernt kein Paket | `scripts/regression.sh:298` |
| `R2.11` | Systemlisten bleiben unberuehrt | `scripts/regression.sh:300` |
| `R3.1` | Leerzeichen wird kodiert | `scripts/regression.sh:307` |
| `R3.2` | Prozentzeichen wird kodiert | `scripts/regression.sh:308` |
| `R3.3` | Pfad ohne Sonderzeichen bleibt gleich | `scripts/regression.sh:309` |
| `R3.4` | Quelle mit Leerzeichen im Pfad wird gelesen | `scripts/regression.sh:315` |
| `R3.5` | Gegenprobe: ohne Kodierung scheitert die Quelle | `scripts/regression.sh:320` |
| `R3.6` | keine Kommandosubstitution in einem case-Muster | `scripts/regression.sh:338` |
| `R3.7` | Gegenprobe: die alte Form trifft jeden Pfad | `scripts/regression.sh:349` |
| `R3.8` | die ANSI-C-Form trifft nur echte Umbrueche | `scripts/regression.sh:354` |
| `R3.9` | die ANSI-C-Form erkennt einen echten Umbruch | `scripts/regression.sh:359` |
| `R4.1` | fetch-packages kennt die Freigabeoption | `scripts/regression.sh:367` |
| `R4.2` | Abweichung fuehrt zum Abbruch | `scripts/regression.sh:374` |
| `R4.3` | kein unbedingtes Ueberschreiben der Liste | `scripts/regression.sh:381` |
| `R4.3b` | Uebernahme wird mit Herkunftsvermerk belegt | `scripts/regression.sh:386` |
| `R4.4` | unverfaelschter Bestand wird bestaetigt | `scripts/regression.sh:394` |
| `R4.5` | beschaedigte Paketdatei wird erkannt | `scripts/regression.sh:396` |
| `R4.6` | fehlende Paketdatei wird erkannt | `scripts/regression.sh:398` |
| `R4.7` | fehlende Pruefsummenliste wird erkannt | `scripts/regression.sh:399` |
| `R5.1` | rollback nutzt kein apt-get autoremove | `scripts/regression.sh:407` |
| `R5.2` | rollback nutzt kein Paketnamensmuster | `scripts/regression.sh:413` |
| `R5.3` | rollback prueft die Sicherung | `scripts/regression.sh:420` |
| `R5.4` | jede Dateiaenderung wird aufgezeichnet | `scripts/regression.sh:425` |
| `R5.5` | jede Paketaenderung wird aufgezeichnet | `scripts/regression.sh:430` |
| `R5.6` | Sicherung wird versiegelt | `scripts/regression.sh:439` |
| `R5.7` | unveraenderte Sicherung wird bestaetigt | `scripts/regression.sh:440` |
| `R5.8` | veraenderte Sicherung wird erkannt | `scripts/regression.sh:442` |
| `R5.9` | Sicherung ohne Siegel wird erkannt | `scripts/regression.sh:444` |
| `R6.1` | Simulation mit gueltiger Sicherung | `scripts/regression.sh:477` |
| `R6.2` | Simulation aendert nichts | `scripts/regression.sh:478` |
| `R6.3` | Sicherung wird als unverfaelscht gemeldet | `scripts/regression.sh:480` |
| `R6.4` | veraenderte Sicherung bricht ab | `scripts/regression.sh:485` |
| `R6.5` | veraenderte Sicherung nur mit Freigabe nutzbar | `scripts/regression.sh:487` |
| `R6.6` | vorher vorhandenes Paket wird geschont | `scripts/regression.sh:496` |
| `R6.7` | Ubuntu-Kernel in der Aufzeichnung bricht ab | `scripts/regression.sh:501` |
| `R6.8` | ohne Aufzeichnung wird kein Paket entfernt | `scripts/regression.sh:507` |
| `R6.10` | fehlende Pflichtdatei bricht ab | `scripts/regression.sh:515` |
| `R6.11` | fehlende Pflichtdatei nur mit Freigabe | `scripts/regression.sh:517` |
| `R6.12` | der Bericht nennt die fehlende Datei | `scripts/regression.sh:520` |
| `R6.13` | leere Pflichtdatei bricht ab | `scripts/regression.sh:525` |
| `R6.14` | ein gemeldeter Ausfall im MANIFEST bricht ab | `scripts/regression.sh:531` |
| `R6.15` | Altbestand ohne MANIFEST laeuft bei zwei Dateien | `scripts/regression.sh:536` |
| `R6.16` | der Bericht weist auf den Altbestand hin | `scripts/regression.sh:539` |
| `R6.17` | Altbestand ohne grub.cfg bricht ab | `scripts/regression.sh:543` |
| `R6.18` | fehlende Sicherung bricht ab | `scripts/regression.sh:549` |
| `R7.1` | install.sh haelt den Fortschritt fest | `scripts/regression.sh:561` |
| `R7.2` | mindestens acht Phasen sind erfasst | `scripts/regression.sh:566` |
| `R7.3` | Unterbrechung wird erkannt und benannt | `scripts/regression.sh:581` |
| `R7.4` | Rueckfall nach Unterbrechung laeuft | `scripts/regression.sh:583` |
| `R8.1` | exfat speichert keine Rechte | `scripts/regression.sh:591` |
| `R8.2` | vfat speichert keine Rechte | `scripts/regression.sh:592` |
| `R8.3` | ntfs speichert keine Rechte | `scripts/regression.sh:593` |
| `R8.4` | ext4 speichert Rechte | `scripts/regression.sh:594` |
| `R8.5` | btrfs speichert Rechte | `scripts/regression.sh:595` |
| `R8.6` | Dateisystem der Paketwurzel ist bestimmbar | `scripts/regression.sh:597` |
| `R8.7` | deploy-to-t7 prueft die Rechtefrage | `scripts/regression.sh:599` |
| `R8.8` | deploy-to-t7 prueft symbolische Verknuepfungen | `scripts/regression.sh:601` |
| `R8.9` | Paket enthaelt keine symbolische Verknuepfung | `scripts/regression.sh:603` |
| `R8.10` | jedes Skript ist ueber bash startbar | `scripts/regression.sh:610` |
| `R8.11` | Anleitungen nennen den Aufruf ueber bash | `scripts/regression.sh:611` |
| `R9.1` | fehlende Samsung T7 bricht ab | `scripts/regression.sh:622` |
| `R9.2` | Auflistung allein schreibt nichts | `scripts/regression.sh:624` |
| `R9.3` | deploy-to-t7 formatiert nicht | `scripts/regression.sh:627` |
| `R9.4` | deploy-to-t7 nutzt kein rsync --delete | `scripts/regression.sh:629` |
| `R10.1` | falsches Modell bricht ab | `scripts/regression.sh:645` |
| `R10.1b` | Modellsperre greift auch mit Vorpruefung | `scripts/regression.sh:647` |
| `R10.2` | unbekannte Option bricht ab | `scripts/regression.sh:650` |
| `R10.3` | Konfliktpaket in der Liste wird erkannt | `scripts/regression.sh:653` |
| `R10.4` | install.sh fordert grub-script-check | `scripts/regression.sh:656` |
| `R10.5` | install.sh schreibt nicht nach /etc/apt/sources.list.d | `scripts/regression.sh:658` |
| `R11.1` | kein 'case \$?' direkt nach einem Funktionsaufruf | `scripts/regression.sh:678` |
| `R11.2` | Gegenprobe: 'set -e' bricht vor dem case ab | `scripts/regression.sh:681` |
| `R11.3` | die aufgefangene Form erreicht den Zweig | `scripts/regression.sh:683` |
| `R11.4` | Zaehlfunktion liefert 0 bei fehlendem Verzeichnis | `scripts/regression.sh:687` |
| `R11.5` | Zaehlfunktion zaehlt vorhandene Dateien | `scripts/regression.sh:689` |
| `R11.6` | Sandkastenbetrieb wird bestimmt | `scripts/regression.sh:694` |
| `R11.7` | Pin-Pruefung liest auch die Quellenliste | `scripts/regression.sh:696` |
| `R12.1` | einfache Anfuehrungszeichen werden entfernt | `scripts/regression.sh:706` |
| `R12.2` | doppelte Anfuehrungszeichen werden entfernt | `scripts/regression.sh:709` |
| `R12.3` | kaufmaennisches Und wird maskiert | `scripts/regression.sh:713` |
| `R12.4` | Wert mit Und landet unveraendert in der Datei | `scripts/regression.sh:717` |
| `R12.5` | Wert mit Trennzeichen landet unveraendert in der Datei | `scripts/regression.sh:722` |
| `R12.6` | Kodieren und Dekodieren ist umkehrbar | `scripts/regression.sh:730` |
| `R12.7` | Dekodierung kennt mehr als nur das Leerzeichen | `scripts/regression.sh:731` |
| `R12.8` | Dateipruefung nutzt die Dekodierung | `scripts/regression.sh:734` |
| `R12.9` | rollback --backup ohne Wert meldet Code 2 | `scripts/regression.sh:739` |
| `R12.10` | die Meldung nennt die Option | `scripts/regression.sh:742` |
| `R12.11` | deploy --target ohne Wert meldet Code 2 | `scripts/regression.sh:744` |
| `R12.12` | fetch --out ohne Wert meldet Code 2 | `scripts/regression.sh:746` |
| `R12.13` | verify --out ohne Wert meldet Code 2 | `scripts/regression.sh:748` |
| `R12.14` | Kernelschutz liegt nach der Freigabe | `scripts/regression.sh:754` |
| `R12.15` | install.sh faengt einen zweiten Lauf ab | `scripts/regression.sh:758` |
| `R12.16` | install.sh setzt den Vorgabeeintrag | `scripts/regression.sh:762` |
| `R12.17` | rollback.sh setzt den Vorgabeeintrag | `scripts/regression.sh:764` |
| `R12.18` | rollback.sh hebt einen offenen Teststart auf | `scripts/regression.sh:766` |
| `R12.19` | verify.sh schreibt nicht auf die Vorlage | `scripts/regression.sh:771` |
| `R12.20` | verify.sh prueft das Modell vor der Kopie | `scripts/regression.sh:773` |
| `R12.21` | Tabellenzellen werden maskiert | `scripts/regression.sh:775` |
| `R12.22` | Maskierung ersetzt das Trennzeichen | `scripts/regression.sh:777` |
| `R12.23` | ACPI-BIOS-Meldungen sind ausgenommen | `scripts/regression.sh:781` |
| `R12.24` | Gegenprobe: ACPI-Meldung zaehlt nicht | `scripts/regression.sh:786` |
| `R12.25` | Gegenprobe: echter Fehler zaehlt | `scripts/regression.sh:790` |
| `R12.26` | selftest ruft grub-entry.sh ueber bash auf | `scripts/regression.sh:794` |
| `R12.27` | fetch-packages kodiert den Baupfad | `scripts/regression.sh:799` |
| `R12.28` | preflight nennt seine Schreibziele im Kopf | `scripts/regression.sh:803` |
| `R13.1` | ohne Sensor liefert Rueckgabe 1 | `scripts/regression.sh:819` |
| `R13.2` | ohne Sensor wird NICHTS ausgegeben | `scripts/regression.sh:820` |
| `R13.3` | ohne Sensor sind 0 Quellen lesbar | `scripts/regression.sh:821` |
| `R13.4` | ein Sensor mit 45 Grad wird gelesen | `scripts/regression.sh:826` |
| `R13.5` | ein Sensor wird gezaehlt | `scripts/regression.sh:827` |
| `R13.6` | Rueckgabe 0 bei gueltiger Messung | `scripts/regression.sh:828` |
| `R13.7` | der hoechste von drei Sensoren gewinnt | `scripts/regression.sh:831` |
| `R13.8` | drei Sensoren werden gezaehlt | `scripts/regression.sh:832` |
| `R13.9` | unglaubwuerdige Werte werden verworfen | `scripts/regression.sh:837` |
| `R13.10` | sie werden nicht mitgezaehlt | `scripts/regression.sh:838` |
| `R13.11` | nur unglaubwuerdige Werte: Rueckgabe 1 | `scripts/regression.sh:841` |
| `R13.12` | nur unglaubwuerdige Werte: keine Ausgabe | `scripts/regression.sh:842` |
| `R13.13` | Testnaht ohne MT2_SELFTEST unwirksam | `scripts/regression.sh:847` |
| `R13.14` | Testnaht mit MT2_SELFTEST wirksam | `scripts/regression.sh:850` |
| `R13.15` | 60 Grad unter der Grenze: weiter | `scripts/regression.sh:855` |
| `R13.16` | Spitze bleibt erhalten | `scripts/regression.sh:856` |
| `R13.17` | Grenze erreicht: Abbruch | `scripts/regression.sh:857` |
| `R13.18` | 98 Grad: Abbruch | `scripts/regression.sh:858` |
| `R13.19` | 84 Grad knapp darunter: weiter | `scripts/regression.sh:859` |
| `R13.20` | erster Messausfall: weiter | `scripts/regression.sh:860` |
| `R13.21` | zweiter Messausfall: Abbruch | `scripts/regression.sh:861` |
| `R13.22` | unsinniger Wert: Abbruch | `scripts/regression.sh:862` |
| `R13.23` | max_temp_c kommt nicht mehr vor | `scripts/regression.sh:865` |
| `R13.24` | verify.sh nutzt mt2_cpu_temp | `scripts/regression.sh:867` |
| `R13.25` | Abbruchgrenze liegt bei 85 Grad | `scripts/regression.sh:869` |
| `R13.26` | Option --thermal-test vorhanden | `scripts/regression.sh:871` |
| `R13.27` | Lasttest verlangt den Dienst t2fanrd | `scripts/regression.sh:873` |
| `R13.28` | Lasttest verlangt eine gesonderte Freigabe | `scripts/regression.sh:875` |
| `R13.29` | Ruhetemperaturgrenze ist gesetzt | `scripts/regression.sh:877` |
| `R13.30` | Standardabnahme: CPU bleibt NOT_TESTED | `scripts/regression.sh:886` |
| `R13.31` | Standardabnahme startet keinen Lasttest | `scripts/regression.sh:888` |
| `R13.32` | ohne Messung ist der Lasttest gesperrt | `scripts/regression.sh:891` |
| `R13.33` | Sensor vorhanden, Luefter fehlt: gesperrt | `scripts/regression.sh:896` |
| `R13.34` | Sensor wird als PASS gemeldet | `scripts/regression.sh:898` |
| `R13.35` | --thermal-seconds oberhalb der Grenze: Code 2 | `scripts/regression.sh:901` |
| `R13.36` | --thermal-seconds unterhalb der Grenze: Code 2 | `scripts/regression.sh:903` |
| `R14.1` | unveraenderter Baum: gleich | `scripts/regression.sh:913` |
| `R14.2` | unveraenderter Baum: keine Aenderungsliste | `scripts/regression.sh:914` |
| `R14.3` | neue Datei wird erkannt | `scripts/regression.sh:918` |
| `R14.4` | die neue Datei steht in der Liste | `scripts/regression.sh:919` |
| `R14.5` | geaenderte Groesse wird erkannt | `scripts/regression.sh:923` |
| `R14.6` | fluechtiger Pfad zaehlt nicht als Aenderung | `scripts/regression.sh:927` |
| `R14.7` | fluechtiger Pfad wird gezaehlt | `scripts/regression.sh:929` |
| `R14.8` | echte Aenderung wird nicht gefiltert | `scripts/regression.sh:933` |
| `R14.9` | mt2_apt_pin_create nimmt ein Basisverzeichnis | `scripts/regression.sh:937` |
| `R14.10` | install.sh nimmt eine Momentaufnahme vor dem Dry-Run | `scripts/regression.sh:939` |
| `R14.11` | install.sh vergleicht nach dem Dry-Run | `scripts/regression.sh:941` |
| `R14.12` | install.sh pinnt im Dry-Run in das Arbeitsverzeichnis | `scripts/regression.sh:944` |
| `R14.13` | preflight.sh pinnt in das Arbeitsverzeichnis | `scripts/regression.sh:947` |
| `R14.14` | rollback.sh raeumt die festen Pfade | `scripts/regression.sh:949` |
| `R14.16` | der Pin liegt im uebergebenen Verzeichnis | `scripts/regression.sh:958` |
| `R14.15` | der feste Pfad bleibt unberuehrt | `scripts/regression.sh:961` |
| `R14.17` | auch die Paketlisten liegen dort | `scripts/regression.sh:963` |
| `R14.18` | mt2_apt ohne Pin bricht laut ab | `scripts/regression.sh:970` |
| `R14.19` | die Fehlermeldung nennt mt2_apt_pin_create | `scripts/regression.sh:976` |
| `R14.20` | rollback.sh raeumt auch das Protokollverzeichnis | `scripts/regression.sh:978` |
| `R14.21` | rollback.sh entfernt das Verzeichnis nur wenn es leer ist | `scripts/regression.sh:981` |
| `R15.1` | vollstaendige Sicherung wird bestaetigt | `scripts/regression.sh:992` |
| `R15.2` | fehlende Pflichtdatei wird erkannt | `scripts/regression.sh:995` |
| `R15.3` | leere Pflichtdatei wird erkannt | `scripts/regression.sh:998` |
| `R15.4` | abweichende Kopie wird erkannt | `scripts/regression.sh:1001` |
| `R15.5` | nach der Korrektur wieder bestaetigt | `scripts/regression.sh:1004` |
| `R15.6` | Gegenprobe: Siegel gilt trotz fehlender Pflichtdatei | `scripts/regression.sh:1009` |
| `R15.7` | die Vollstaendigkeitspruefung schlaegt dennoch an | `scripts/regression.sh:1011` |
| `R15.8` | kein ignorierter Kopierfehler im Sicherungsschritt | `scripts/regression.sh:1014` |
| `R15.9` | install.sh kennt Pflichtdateien | `scripts/regression.sh:1016` |
| `R15.10` | install.sh kennt Wahldateien | `scripts/regression.sh:1018` |
| `R15.11` | eine fehlende Pflichtquelle stoppt die Installation | `scripts/regression.sh:1021` |
| `R15.12` | ein Kopierfehler stoppt die Installation | `scripts/regression.sh:1024` |
| `R15.13` | MANIFEST wird geschrieben | `scripts/regression.sh:1027` |
| `R15.14` | Vollstaendigkeit wird VOR dem Siegeln geprueft | `scripts/regression.sh:1029` |
| `R15.15` | rollback.sh liest das MANIFEST | `scripts/regression.sh:1031` |
| `R16.1` | README nennt den Zweig beim Klonen | `scripts/regression.sh:1037` |
| `R16.2` | README warnt vor der falschen Reihenfolge | `scripts/regression.sh:1039` |
| `R16.3` | BUILD_REPORT nennt den Zweig beim Klonen | `scripts/regression.sh:1041` |
| `R16.4` | kein 'git checkout' nach einem 'cd' in einem Codeblock | `scripts/regression.sh:1056` |
| `R16.5` | der genannte Zweig stimmt | `scripts/regression.sh:1057` |
| `R16.6` | die flache Variante ist dokumentiert | `scripts/regression.sh:1059` |
| `R16.7` | das Gegenbeispiel steht in einem text-Block | `scripts/regression.sh:1061` |
| `R18.1` | der Mount-Namensraum ist aktiv | `scripts/regression.sh:1094` |
| `R18.2` | die Installation hat die Datei wirklich geaendert | `scripts/regression.sh:1095` |
| `R18.3` | der echte Rueckfall endet mit 0 | `scripts/regression.sh:1096` |
| `R18.4` | /etc/default/grub stimmt Byte fuer Byte | `scripts/regression.sh:1097` |
| `R18.5` | /boot/grub/grub.cfg stimmt Byte fuer Byte | `scripts/regression.sh:1098` |
| `R18.6` | die neu angelegte Datei ist entfernt | `scripts/regression.sh:1099` |
| `R18.7` | beschaedigte Sicherung bricht mit 13 ab | `scripts/regression.sh:1102` |
| `R18.8` | beschaedigte Sicherung laesst die Konfiguration unberuehrt | `scripts/regression.sh:1103` |
| `R18.9` | beschaedigte Sicherung laesst die neue Datei liegen | `scripts/regression.sh:1104` |
| `R18.10` | das Wirtsystem bleibt unveraendert | `scripts/regression.sh:1109` |
