---
title: Audiokonfiguration MacBookPro16,1
created: 2026-10-10
type: referenz
---

# Audiokonfiguration

## FRAGESTELLUNG

Welche Konfiguration passt genau zum MacBookPro16,1?

## UMSETZUNG

Drei Pakete liefern die Konfiguration. Sie ersetzen den früheren Weg über ein
fremdes Installationsskript.

| Paket | Inhalt | Begründung |
| --- | --- | --- |
| `apple-t2-audio-config` 0.5.1 | ALSA-UCM-Profile `AppleT2x2`, `AppleT2x4`, `AppleT2x6` | Grundlage für Lautsprecher, Kopfhörer und Mikrofon |
| `t2-apple-audio-dsp-speakers161` 0.2.0-1 | PipeWire-Filterkette, Impulsantworten `macbook_pro_t2_16_1_*` | Genau für das 16-Zoll-Modell 2019 gebaut |
| `t2-apple-audio-dsp-mic` 0.4.0-1 | Mikrofonkette | Hebt die sehr geringe Eingangslautstärke an |

DSP bedeutet digitale Signalverarbeitung.

### Reihenfolge der Prüfung

1. Starte den T2-Kernel.
2. Prüfe die Kartenkennung:

   ```bash
   sed -n "s/.*\(AppleT2.*\) -.*/\1/p" /proc/asound/cards
   ```

3. Erwartet wird `AppleT2x4` oder `AppleT2x6`.
   - Bei `AppleT2` ohne Zahl fehlt die modellbezogene Lautsprecheraufteilung.
     Installiere die DSP-Pakete dann **nicht**.
4. Prüfe die Kernelparameter:

   ```bash
   grep -o 'intel_iommu=on\|iommu=pt\|pm_async=off' /proc/cmdline
   ```

5. Setze die Lautstärke auf 20 Prozent.
6. Spiele erst dann einen Testton ab.

### Warnung

Die Filterkette treibt die Hochtöner direkt an.
Eine zu hohe Lautstärke bei falschem Profil kann die Lautsprecher schädigen.
Teste deshalb immer zuerst leise.

## MEHRWERT

Du nutzt ausschließlich geprüfte Pakete.
Die Konfiguration passt zum Modell und nicht zu einer anderen Baureihe.
