---
title: Optionale Kernelparameter
created: 2026-10-10
type: referenz
---

# Optionale Kernelparameter

Diese Parameter setzt das Installationsskript **nicht** automatisch.
Setze sie nur, wenn der zugehoerige Fehler auftritt.

## FRAGESTELLUNG

Welche Parameter helfen gegen bekannte Fehler, ohne neue Risiken zu erzeugen?

## UMSETZUNG

| Parameter | Hilft gegen | Nebenwirkung | Empfehlung |
| --- | --- | --- | --- |
| `amdgpu.dpm=0` | Abstuerze der Radeon Pro 5500M beim Wechsel der Auflösung | Die Leistungsverwaltung der dedizierten Grafik entfällt. Die Abwärme steigt. | Erst nach bestandener thermischer Abnahme setzen. |
| `pcie_ports=compat` | Geisterbildschirme über die dedizierte Grafik | Thunderbolt kann ausfallen. | Nur als Gegenprobe zu `pcie_ports=native`. |
| `mem_sleep_default=deep` | `s2idle` lässt die Radeon-Grafik hängen | Tiefschlaf ist auf diesem Modell noch fehlerhaft. | Nur im Rahmen eines Standby-Versuchs. |
| `modprobe.blacklist=t2bce_audio` | Unerwartete Neustarts aus dem Audio-Pfad (Fehlerbericht 179) | Internes Audio entfällt. Tastatur und Touch Bar bleiben nutzbar. | Nur als Notmaßnahme bei wiederholten Neustarts. |

Ein weicherer Weg gegen Grafikabstürze ohne Parameter:

```bash
echo high | sudo tee /sys/bus/pci/drivers/amdgpu/0000:01:00.0/power_dpm_force_performance_level
```

Ersetze die PCI-Adresse durch den Wert aus `lspci -nn | grep -i amd`.

## MEHRWERT

Du änderst nur das, was ein nachgewiesener Fehler erfordert.
Jede Änderung bleibt einzeln umkehrbar.
