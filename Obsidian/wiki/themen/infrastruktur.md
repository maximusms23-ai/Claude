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

## Lokaler 4080-Rechner

Noch zu ergaenzen (vom Rechner selbst auslesen, siehe unten):

| Eigenschaft | Wert |
|-------------|------|
| Hostname | _offen_ |
| IP (LAN) | _offen_ |
| GPU | NVIDIA GeForce RTX 4080, 16 GB VRAM |
| Betriebssystem | _offen_ |

Werte auslesen:

```bash
# Linux
hostname && hostname -I && nvidia-smi --query-gpu=name,memory.total --format=csv

# Windows (PowerShell)
hostname; ipconfig | findstr IPv4; nvidia-smi --query-gpu=name,memory.total --format=csv
```

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

- [ ] Hostname, LAN-IP und Betriebssystem des 4080-Rechners eintragen
- [ ] Pruefen, ob Ollama auf dem 4080-Rechner laeuft und welche Modelle installiert sind
- [ ] Entscheiden, ob Remote Control dauerhaft eingerichtet wird

## Verwandte Seiten

- [[Ollama]] — Lokale LLM-Laufzeitumgebung
- [[Gemma 4]] — Modellvarianten und VRAM-Bedarf
- [[Gemme Training]] — Projekt, das lokale GPU-Leistung braucht
- [[GGUF-Quantisierung]] — Wie Modelle auf 16 GB VRAM passen
- [[Werkzeuge und Ressourcen]]
