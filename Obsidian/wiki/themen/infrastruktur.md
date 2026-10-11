---
title: "Infrastruktur"
created: 2026-10-10
type: thema
tags:
  - infrastruktur
  - hardware
  - claude-code
  - gpu
aliases:
  - Infrastruktur
  - Infrastruktur-Einrichtung
---

# Infrastruktur

Uebersicht der Rechenumgebungen, in denen Claude Code fuer dieses Wiki arbeitet, und wie sie sich unterscheiden. Hintergrund: Bei einer Einrichtungsrunde am 2026-10-10 stellte sich heraus, dass die Cloud-Session *nicht* auf dem lokalen RTX-4080-Rechner laeuft.

## Geraete im Heimnetz (192.168.178.0/24)

Stand der Uebergabe vom 2026-10-11. Nur die RTX-PC-Zeile ist durch eigene Messung belegt.

| Geraet | Adresse | Rolle | Status |
|--------|---------|-------|--------|
| Mac mini | _offen_ | Zentraler Orchestrator: Agent OS unter `/Users/maxim/Projects/maximus-agent-os/source`, Codex | NICHT GEPRUEFT |
| ASUS-Linux-Server `asusserver` | `192.168.178.183`, Benutzer `maxim` | Bestehende Infrastruktur, nicht veraendern | NICHT GEPRUEFT |
| RTX-PC `maxim-B650-EAGLE-AX` | `192.168.178.127` (WLAN, DHCP) | GPU-Worker | BESTAETIGT |
| Mac-Skriptserver | `192.168.178.48:8765` | Einmalige Bereitstellung `bootstrap-rtx-ssh.sh` | NICHT GEPRUEFT, aus Cloud nicht erreichbar |

Zugriffsweg Mac mini → RTX-PC: SSH mit Schluessel `maximus-mac-mini-4080-2026-10-11` (ed25519, oeffentlicher Teil liegt beim Mac, privater Schluessel bleibt dort). SSH-Port, Hostschluessel-Fingerprint und Alias: _offen_.

## Umgebungen im Ueberblick

| Umgebung | Wo | GPU | Zugriff auf lokale Dateien | Typischer Einsatz |
|----------|----|-----|----------------------------|-------------------|
| Claude Code Cloud-Sandbox | Isolierter Container (claude.ai/code) | keine | nein, nur Git-Checkout | Wiki pflegen, Recherche, Textarbeit |
| Lokaler 4080-Rechner | Eigene Hardware | NVIDIA RTX 4080 (16 GB VRAM) | ja | [[Ollama]]-Inferenz, [[Gemme Training]], [[GGUF-Quantisierung]] |
| Mac Mini M4 | Eigene Hardware | Apple Silicon, 16 GB unified memory | ja | Kleinere [[Gemma 4]]-Modelle (siehe [[Gemme Training]]) |

## Cloud-Sandbox (claude.ai/code)

Stand 2026-10-10 meldet die Sandbox:

| Eigenschaft | Wert |
|-------------|------|
| Hostname | `vm` |
| IP (intern) | `192.0.2.2` |
| GPU | keine (`nvidia-smi` fehlt, nichts via `lspci`) |
| CPU / RAM | 4 Kerne, 15 GiB |

Eigenschaften:

- Kurzlebig: Der Container wird nach Inaktivitaet verworfen. Nur Commits und Pushes bleiben erhalten.
- Keine Verbindung zu lokaler Hardware. Die IP liegt im Dokumentationsbereich `192.0.2.0/24` und ist von aussen nicht erreichbar.
- Ausgehender Netzzugriff laeuft ueber die Netzwerk-Policy der Umgebung.
- Geeignet fuer alles, was keine GPU braucht: Wiki-Pflege, Quellen einlesen, Reports, Slides.

## Lokaler 4080-Rechner (RTX-PC)

Bestaetigt am 2026-10-11 durch Ausgabe im lokalen Terminal des Rechners:

| Eigenschaft | Wert | Status |
|-------------|------|--------|
| Hostname | `maxim-B650-EAGLE-AX` | BESTAETIGT |
| Benutzer / Home | `maxim`, `/home/maxim` | BESTAETIGT |
| Betriebssystem | Ubuntu 24.04.5 LTS | BESTAETIGT |
| Mainboard | Gigabyte B650 EAGLE AX (aus Hostname abgeleitet) | NICHT GEPRUEFT |
| Netzwerkschnittstelle | `wlp7s0` (WLAN), kein aktives Kabel-Interface | BESTAETIGT |
| LAN-IP | `192.168.178.127/24`, per DHCP von der FRITZ!Box | BESTAETIGT, nicht fest |
| GPU | NVIDIA RTX 4080 (16 GB VRAM) | NICHT GEPRUEFT, `nvidia-smi` scheitert |
| NVIDIA-Treiber | NVML-Bibliothek 595.99, Fehler „Driver/library version mismatch" | BEFUND, Ursache offen |
| SSH-Server | `openssh-server` | NICHT GEPRUEFT |
| Claude Code | 2.1.296 unter `~/.local/bin/claude`, Login erfolgt | BESTAETIGT |

Werte erneut auslesen:

```bash
hostname; . /etc/os-release; echo "$PRETTY_NAME"; ip -br -4 addr
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
```

### NVIDIA-Befund (2026-10-11)

`nvidia-smi` meldet „Failed to initialize NVML: Driver/library version mismatch, NVML library version: 595.99". Das Fehlerbild bedeutet typischerweise, dass die Userspace-Bibliothek nach einem Paket-Update neuer ist als das noch geladene Kernelmodul. Belegte Ursache steht noch aus. Diagnose vor jeder Aenderung, nur lesend, auf dem RTX-PC:

```bash
uname -r
lspci -nnk | grep -iA3 'nvidia\|vga\|3d'
lsmod | grep -iE 'nvidia|nouveau'
cat /proc/driver/nvidia/version 2>/dev/null
dpkg -l | grep -iE 'nvidia-(driver|dkms|kernel|utils)|libnvidia-compute'
dkms status 2>/dev/null
mokutil --sb-state 2>/dev/null
sudo dmesg | grep -iE 'nvidia|nvrm' | tail -20
```

Kleinste Reparatur, falls geladenes Modul und Bibliothek verschiedene Versionen zeigen: Neustart des Rechners, keine Paketaenderung. Erst danach `nvidia-smi` erneut pruefen.

### Was mit 16 GB VRAM realistisch ist

Siehe die Speichertabelle in [[Gemma 4]]:

- E4B-Varianten (q4_K_M bis bf16) laufen komfortabel.
- 26B-MoE braucht 16 GB+ VRAM und ist damit grenzwertig, KV-Cache kommt noch dazu.
- 31B braucht 20 GB+ und passt nicht ohne starke Quantisierung oder CPU-Offload.
- [[TurboQuant]] koennte den KV-Cache deutlich verkleinern, ist in [[Ollama]] aber noch nicht integriert.

## Claude Code auf dem 4080-Rechner nutzen

Damit Claude direkt auf der lokalen Hardware arbeitet (GPU-Jobs, Ollama, lokale Dateien), gibt es zwei Wege:

1. **Lokale CLI**: Claude Code im Terminal auf dem Rechner starten, im Ordner des Vaults. Alle Befehle laufen dann dort.
2. **Remote Control**: Auf dem Rechner `claude remote-control` im Vault-Ordner starten oder die Claude Desktop App nutzen. Die Session erscheint dann in der Claude Code App und laesst sich von Web oder Handy aus steuern, waehrend die Befehle lokal ausgefuehrt werden.

Eine reine Cloud-Session kann diesen Schritt nicht ersetzen. Sie kann nur den Git-Stand bearbeiten und pushen.

## Arbeitsteilung

| Aufgabe | Umgebung |
|---------|----------|
| Wiki schreiben, Indizes pflegen, Quellen einlesen | Cloud-Sandbox oder lokal |
| Modelle mit [[Ollama]] laden und testen | 4080-Rechner |
| Fine-Tuning und Embeddings fuer [[Gemme Training]] | 4080-Rechner (oder Mac Mini fuer kleine Modelle) |
| MkDocs-Build und Website | beides, Deployment via Git |

## Offene Punkte

- [x] Hostname, LAN-IP und Betriebssystem des RTX-PCs eintragen (2026-10-11)
- [ ] SSH-Bootstrap lokal am RTX-PC pruefen (Pruefsumme `e84041750f0a4cd12f38b3cd43faf52cfb59a8135bd3eb9e3635ea5cad1ddd1a`, Inhalt lesen) und erst dann ausfuehren
- [ ] SSH-Hostschluessel-Fingerprint erfassen, neue Schluesselanmeldung vom Mac mini testen
- [ ] NVIDIA-Diagnose durchfuehren, Ursache belegen, kleinste Reparatur (vermutlich Neustart)
- [ ] Feste DHCP-Zuordnung in der FRITZ!Box fuer die tatsaechlich genutzte Schnittstelle (`wlp7s0` oder spaeter Kabel-MAC)
- [ ] Pruefen, ob Ollama auf dem RTX-PC laeuft und welche Modelle installiert sind
- [ ] GPU-Provider in Agent OS anbinden und einen echten Auftrag Mac → RTX → Mac nachweisen
- [ ] Temporaeren Skriptserver auf dem Mac nach Abschluss beenden

## Verwandte Seiten

- [[Ollama]] — Lokale LLM-Laufzeitumgebung
- [[Gemma 4]] — Modellvarianten und VRAM-Bedarf
- [[Gemme Training]] — Projekt, das lokale GPU-Leistung braucht
- [[GGUF-Quantisierung]] — Wie Modelle auf 16 GB VRAM passen
- [[Werkzeuge und Ressourcen]]
