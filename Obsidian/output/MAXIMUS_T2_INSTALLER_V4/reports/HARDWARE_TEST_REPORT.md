---
title: Hardware-Abnahme (Vorlage)
created: 2026-10-10
type: vorlage
tags: [maximus, t2linux, hardware-abnahme]
---

# Hardware-Abnahme

**Dies ist eine Vorlage. Sie enthält kein Testergebnis.**

Das Skript `scripts/verify.sh` überschreibt diese Datei mit echten Werten.
Bis dahin gilt für jedes Prüffeld: **NOT_TESTED**.

Ein nicht getestetes Gerät erhält niemals PASS.

## Bewertungsstufen

| Stufe | Bedeutung |
| --- | --- |
| PASS | Erfolgreich getestet. |
| PARTIAL | Funktioniert eingeschränkt. |
| FAIL | Test fehlgeschlagen. |
| BLOCKED | Prüfung nicht möglich. |
| NOT_TESTED | Noch nicht geprüft. |

## Prüffelder

| Prüffeld | Akzeptanzkriterium | Ergebnis |
| --- | --- | --- |
| Systemstart | Ubuntu startet mit 6.18.54-1-t2-noble | NOT_TESTED |
| Kernelparameter | `intel_iommu=on iommu=pt pm_async=off` aktiv | NOT_TESTED |
| T2-Treiberstapel | mindestens ein `t2bce`-Modul geladen | NOT_TESTED |
| Tastatur | interne Tasten erzeugen Eingaben | NOT_TESTED |
| Trackpad | Zeiger, Klicks und unterstützte Gesten | NOT_TESTED |
| Touch Bar | unterstützte Funktionstasten reagieren | NOT_TESTED |
| WLAN | Verbindung zum Netzwerk erfolgreich | NOT_TESTED |
| Bluetooth | Gerät lässt sich koppeln und verwenden | NOT_TESTED |
| Kamera | Videoaufnahme gelingt | NOT_TESTED |
| Audiokarte | Kennung `AppleT2xN` mit Zahl | NOT_TESTED |
| Mikrofon | Audioaufnahme enthält Signal | NOT_TESTED |
| Lautsprecher | Audiowiedergabe hörbar und unverzerrt | NOT_TESTED |
| Lüfter | Drehzahlen lesbar, Dienst läuft | NOT_TESTED |
| Lüfterregelung | Drehzahl steigt unter Last | NOT_TESTED |
| CPU | Spitzentemperatur und Drosselung dokumentiert | NOT_TESTED |
| GPU | Treiber geladen, Beschleunigung geprüft | NOT_TESTED |
| Standby | Ruhezustand und Aufwachen funktionieren | NOT_TESTED |
| USB-C | Datenübertragung erfolgreich | NOT_TESTED |
| Akku | Laden und Statusanzeige funktionieren | NOT_TESTED |
| Kernelmeldungen | keine auffälligen Meldungen | NOT_TESTED |
| Dauerbetrieb | mehrere Stunden ohne unerwarteten Neustart | NOT_TESTED |

## Aufruf

```bash
sudo bash scripts/verify.sh
```

Nur selbsttätige Tests, ohne Mitwirkung:

```bash
sudo bash scripts/verify.sh --non-interactive
```

Mit Standby-Test (nur nach bestandener thermischer Abnahme):

```bash
sudo bash scripts/verify.sh --allow-suspend
```

## Reihenfolge der Abnahme

```
[Systemstart pruefen]
        |
        v
[Eingabe pruefen: Tastatur, Trackpad, Touch Bar]
        |
        v
[Luefter pruefen]  <-- Sperre fuer den Lasttest
        |
   bestanden?
   /        \
 Nein        Ja
  |           |
  v           v
[CPU =     [Lasttest, Abbruch bei 90 Grad Celsius]
 BLOCKED]        |
                 v
        [Audio, Kamera, Funk, Grafik, USB-C, Akku]
                 |
                 v
        [Dauerbetrieb ueber Stunden]
                 |
                 v
        [HARDWARE_READY bewerten]
```

Der Lasttest läuft erst nach bestandener Lüfterprüfung.
Das letzte Audit meldete 98 Grad Celsius.
Ohne arbeitende Lüftersteuerung ist ein Lasttest ein Hardwarerisiko.

## Statusbewertung

HARDWARE_READY: **nicht erteilt**.
Begründung: Es liegt kein Test vor.

MAXIMUS_WORKER_READY: **nicht erteilt**.
Begründung: Es liegt kein Dauerbetriebsnachweis vor.
