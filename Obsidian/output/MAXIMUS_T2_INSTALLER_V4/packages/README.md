---
title: Paketverzeichnis
created: 2026-10-10
type: referenz
---

# Paketverzeichnis

## Ergebnis zuerst

Dieses Verzeichnis trägt die Paketdateien (`.deb`).
Im Git-Repositorium liegen sie **nicht**.
Grund: Eine einzelne Kerneldatei ist 112 MB groß. Git und GitHub sind für
solche Nutzlasten nicht geeignet.

Stelle die Nutzlast auf dem Baurechner her:

```bash
bash scripts/fetch-packages.sh
```

## Aufbau

| Pfad | Inhalt | Umfang |
| --- | --- | --- |
| `t2linux/` | T2-Kernel, Touch-Bar-Dienst, Audio- und Lüfterpakete | 14 Pakete, 236 MB |
| `ubuntu/` | die unmittelbar angeforderten Ubuntu-Pakete | 24 Pakete, 9,2 MB |
| `dependencies/` | alle mittelbaren Abhängigkeiten | 447 Pakete, 227 MB |
| `t2linux.sources` | gepinnte Quellen der T2-Pakete mit SHA-256 | im Git enthalten |
| `SHA256SUMS.debs` | Prüfsummen aller 485 Paketdateien | im Git enthalten |
| `Packages`, `Packages.gz`, `Release` | der APT-Index der Offline-Quelle | durch das Bauskript erzeugt |

## Prüfung

```bash
cd packages
sha256sum -c SHA256SUMS.debs
```

Erwartung: 485 Zeilen mit `OK`.

## Hinweis zur Abweichung

Ubuntu veröffentlicht Sicherheitsaktualisierungen.
Dann weicht der neu gebaute Bestand von `SHA256SUMS.debs` ab.
Das Bauskript meldet die Abweichung und erneuert die Liste.
Die alte Liste bleibt als `SHA256SUMS.debs.previous` erhalten.
