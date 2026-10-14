---
title: "Kimi Code"
created: 2026-10-14
type: projekt
tags:
  - kimi
  - moonshot
  - agent-os
  - cli
aliases:
  - Kimi Code
  - Kimi 3
  - Kimi K3
---

# Kimi Code

Kimi Code ist der Terminal-Coding-Agent von Moonshot AI. In Agent OS auf dem Mac mini ist er als Agent „Kimi Code" (K3 + K2.7 Code, OAuth) eingetragen. Agent OS startet pro Nachricht den Befehl `kimi -p … --output-format stream-json`, erstellte Dateien erscheinen im Arbeitsbereich.

## Was „Kimi 3" ist und was nicht

- **Kimi K3** ist ein Mixture-of-Experts-Modell mit rund 2,8 Billionen Parametern. Das kleinste 1-Bit-Quant braucht ca. 600 GB RAM+VRAM, FP16 ueber 1,6 TB. Es laeuft auf keinem einzelnen Consumer-Rechner, auch nicht auf der RTX 4080 mit 16 GB VRAM.
- **Kimi Code CLI** laedt daher keine Gewichte herunter. Das Modell laeuft in der Moonshot-Cloud, die CLI schickt Prompt und Werkzeugaufrufe dorthin. Das Konto laeuft ueber Kimi-Code-OAuth oder einen API-Schluessel der Kimi-Plattform.
- Die RTX 4080 bringt fuer Kimi Code deshalb nichts. Sie bleibt fuer [[Ollama]] und lokale [[Gemma 4]]-Modelle relevant ([[Infrastruktur]]).

## Installation (Linux und macOS)

Offizieller Weg, ohne Node.js:

```bash
curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
kimi --version
```

Alternative ueber npm (Node 22.19 oder neuer): `npm install -g @moonshot-ai/kimi-code`. Vorsicht: Das PyPI-Paket `kimi-code` ist die alte Python-CLI, nicht das aktuelle Produkt.

Im Repo liegt `scripts/install-kimi-code.sh`. Es laedt das Installationsskript erst in eine Datei, zeigt Pruefsumme und Anfang an und fuehrt es nur nach Bestaetigung aus. Danach PATH, Login, `kimi doctor` und ein Headless-Rauchtest.

```bash
cd ~/Claude && bash scripts/install-kimi-code.sh          # installieren
cd ~/Claude && bash scripts/install-kimi-code.sh --check  # nur Status
```

## Login

`kimi login` startet einen Device-Code-Flow: URL und Code erscheinen im Terminal, die Anmeldung passiert im Browser auf einem beliebigen Geraet. Das Token liegt danach unter `~/.kimi-code` (oder `KIMI_CODE_HOME`). Alternativ in der TUI `/login` und API-Schluessel von platform.kimi.com. `kimi doctor` prueft die Konfiguration (`config.toml`).

## Headless-Aufruf, wie Agent OS ihn nutzt

```bash
kimi -p "Antworte nur mit dem Wort OK." --output-format stream-json
```

- `--output-format stream-json` geht nur zusammen mit `-p`. Jede stdout-Zeile ist ein JSON-Objekt.
- Im `-p`-Modus fragt kimi nicht nach Freigaben, Werkzeugaufrufe laufen nach der Auto-Policy, statische Deny-Regeln gelten weiter.
- `-p` laesst sich nicht mit `--yolo`, `--auto` oder `--plan` kombinieren.
- `-m kimi-code/kimi-for-coding` waehlt ein Modell-Alias fuer einen Lauf, sonst gilt `default_model` aus der Config. Die Aliase fuer K3 und K2.7 sind in der oeffentlichen Doku nicht aufgelistet; `kimi doctor` bzw. die TUI zeigen die verfuegbaren Modelle.

## Wo kimi installiert sein muss

| Variante | Wo laeuft `kimi` | Voraussetzung | Status |
|----------|------------------|---------------|--------|
| A: Agent OS ruft lokal auf | Mac mini | Installation + Login auf dem Mac | NICHT GEPRUEFT |
| B: Agent OS schickt an RTX-PC | RTX-PC via SSH-Wrapper | SSH vom Mac zum RTX-PC ([[Infrastruktur]]), Installation + Login auf dem RTX-PC | BLOCKIERT, SSH offen |

Agent OS startet `kimi` als lokalen Prozess auf dem Rechner, auf dem Agent OS laeuft. Fuer Variante B braucht Agent OS einen Wrapper, der statt `kimi` den Befehl `ssh maxim@192.168.178.127 kimi -p … --output-format stream-json` ausfuehrt. Weil das Modell in der Cloud laeuft, bringt Variante B keinen Leistungsvorteil, nur einen anderen Arbeitsbereich.

## Offene Punkte

- [ ] `scripts/install-kimi-code.sh` auf dem RTX-PC ausfuehren, Login abschliessen, Rauchtest bestehen
- [ ] Entscheiden: Variante A (Mac) oder B (RTX-PC per SSH). Fuer den Agenten im Screenshot ist A der direkte Weg.
- [ ] Modell-Aliase fuer K3 und K2.7 aus `kimi doctor` erfassen und hier eintragen
- [ ] Ersten echten Auftrag aus Agent OS ueber Kimi Code nachweisen

## Verwandte Seiten

- [[Infrastruktur]] — Geraete, SSH, GPU
- [[Ollama]] — lokale Modelle, fuer die die RTX 4080 tatsaechlich gebraucht wird
- [[PaperclipAI]] — weitere Agenten-Orchestrierung

## Quellen

- [MoonshotAI/kimi-code auf GitHub](https://github.com/MoonshotAI/kimi-code)
- [Getting started](https://www.kimi.com/code/docs/en/kimi-code-cli/guides/getting-started.html)
- [kimi Command Reference](https://moonshotai.github.io/kimi-code/en/reference/kimi-command.html)
- [Unsloth: Kimi K3 lokal](https://unsloth.ai/docs/models/kimi-k3)
