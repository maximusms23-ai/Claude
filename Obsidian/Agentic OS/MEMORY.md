---
title: "MEMORY"
created: 2026-10-10
type: memory
tags:
  - agentic-os
  - memory
---

# MEMORY — Claude Wiki Vault

> Gepflegt nach [[AI Memory Protocol]]. Zustand, kein Logbuch.

## Projekt-Fakten

- **Dieses Repo ist auf GitHub oeffentlich** (`maximusms23-ai/Claude`, visibility public). Alles in `MEMORY.md` und im Wiki ist fuer jeden lesbar — keine Keys, Tokens, Telefonnummern, Konto-IDs mit Missbrauchspotenzial. Geheimnis-Scan 2026-10-14: aktueller Stand und gesamte Historie sauber.
- Repo `maximusms23-ai/claude` enthaelt einen Obsidian-Vault unter `Obsidian/`, der als LLM-gepflegte Wissensbasis dient. Der User editiert Wiki-Dateien selten selbst.
- Schreibbereich ist `Obsidian/wiki/`, Einstieg `Obsidian/wiki/index.md`. `Obsidian/raw/` und `Obsidian/Clippings/` sind read-only Quellmaterial.
- Inhaltssprache Deutsch, technische Bezeichner Englisch. Jede `.md`-Seite braucht Frontmatter `title`, `created`, `type`.
- Website-Build: MkDocs Material mit `roamlinks`-Plugin, `docs_dir: wiki` — alles ausserhalb von `wiki/` ist nicht oeffentlich. Deploy via `.github/workflows/deploy.yml`.
- `Obsidian/TODOS.md` und `Obsidian/PROJEKTE.md` sind gitignored und existieren nur lokal beim User. In Cloud-Sessions sind sie nicht vorhanden.
- Agent-OS-Ebene liegt in `.claude/` (Agenten, Commands, Hooks, Settings), `scripts/` (Pruefskript, Bootstrap) und `Obsidian/Agentic OS/` (Protokoll, Gedaechtnis).
- **„Agent OS" des Users ist ein fertiges Produkt**, nicht dieses Repo: ein Desktop-Paket unter `/Users/maxim/Projects/Maximus_OS`, Version 2026-10-10, bezogen aus dem „AI Profit Boardroom". Dashboard („Leitstand") auf `http://localhost:3737`, Start via `Start Agent OS.command` bzw. `start-maximus-os.sh`. Struktur: `install/` (nummerierte Anleitungen), `source/`, `runtime/`, `config.example.json`, `SETUP-WITH-AI.md`.
- **Nicht verwechseln:** das GitHub-Repo `maximusms23-ai/Maximus_OS` ist **nicht** Agent OS. Es ist ein aelteres, eigenes Projekt (19 Dateien, `dokument-pipeline/`, letzter Commit 2026-03-28), ohne `source/`, ohne Design OS. Der Agent-OS-Quellcode (`/Users/maxim/Projects/Maximus_OS/source`) liegt nur auf dem Mac und ist von keiner Cloud-Session erreichbar. **`source/` hat kein `.git`** (Codex, 2026-10-13) — es gibt dort keine Versionsverwaltung.
- **Design OS** = Bereich in Agent OS unter `http://127.0.0.1:3737/design-os` (Designbibliothek, Website-Generator, Meine Websites, 3D-Welten). Codex-Uebergabe dazu: `source/docs/architecture/design-os-claude-handover.md`. Laut Codex fehlen 7 von 8 erwarteten Skills. Vollstaendiger Implementierungsauftrag vom User am 2026-10-13 formuliert — muss in Claude Code **auf dem Mac** in `source/` laufen, der Auftrag verbietet selbst die Arbeit in einer Cloud-VM ohne Projektzugriff.
  - Stand laut Codex (2026-10-13): Design OS antwortet auf 3737, Claude am Mac angemeldet, harmlose Schreibtests auf Mac und RTX bestanden. **CLAUDE READY: TEILWEISE** — Designreferenzen und 7 Skills fehlen.
  - **Updater-Verhalten bestaetigt:** `Update Agent OS.command` sichert `source/` und ersetzt es dann per `rsync --delete`. Alles, was nur in `source/` liegt, ist nach einem Update weg (die Sicherung bleibt). Codex hat eine SHA-256-gepruefte Kopie der Uebergabe ausserhalb abgelegt: `~/Projects/Maximus_OS/local-handover/design-os-claude-2026-10-13/`. **`.git` ist vom `rsync --delete` ausdruecklich ausgenommen** (Updater Zeile 86, von Codex geprueft). Ein Git-Repo in `source/` ueberlebt Updates also. Die Quelldateien selbst werden weiterhin ersetzt, und Dateien, die nur lokal existieren (z. B. neue Design-OS-Dateien), loescht der rsync — mit Git bleiben sie aber aus der Historie wiederherstellbar, und `git status` zeigt nach einem Update genau, was ueberschrieben wurde. Empfohlenes Muster: Vendor-Branch (unveraenderte Agent-OS-Staende) plus eigener Branch mit den lokalen Aenderungen.
  - ~~Vermutung, Apollos frueherer Weg sei durch ein Update verloren gegangen~~ — **widerlegt** durch den Agent-OS-CHANGELOG (2026-10-10): der alte Weg ist als Schalter erhalten, siehe Apollo.
- **Agent OS hat einen eigenen Obsidian-Connector**: `install/11-MEMORY-OBSIDIAN.md` („Memory Galaxy", „Jarvis's memory"). Vorgesehener Weg laut dessen README: Terminal-Agenten IN jenem Ordner starten und sagen „connect my Obsidian vault to the Agent OS". Der User soll dabei keine Dateien selbst editieren.
- **Obsidian-Vault-ID des Arbeits-Vaults: `53213b4610731fc1`** (vom User genannt). Pfad aufloesbar ueber `~/Library/Application Support/obsidian/obsidian.json` (macOS). Damit ist geklaert, welcher Vault gemeint ist — auf `/Volumes/Daten_Bank/Obsidian/` liegen mehrere Vaults und Backups, die NICHT der Arbeits-Vault sind.
- **Konfiguration von Agent OS (aus `config.example.json` + CHANGELOG, 2026-10-14 eingesehen):** Eigene Einstellungen gehoeren nach `~/.agentic-os/config.json` — liegt ausserhalb des App-Ordners und wird von Updates nie angefasst. Herstelleraussage (CHANGELOG 2026-06-21): „Hand-edited source files get replaced each update by design." Relevante Schluessel: `vaultRoot` (Pfad zum Obsidian-Vault = die eigentliche Obsidian-Anbindung), `userName`, `roomAgents` (pro Mastermind-Agent `provider: openai` + `baseUrl` + `apiKeyEnv` → beliebiger OpenAI-kompatibler Endpunkt, also auch RTX-llama-server ueber Tunnel `127.0.0.1:8080/v1` oder LM Studio `127.0.0.1:1234/v1`). Hermes-Keys gehoeren nach `~/.hermes/.env` (CHANGELOG 2026-08-17), nicht `~/.hermes/profiles/*/.env`.
- **Design-OS-Herkunft (CHANGELOG):** 2026-09-11 Design OS mit „optional local design library" und eigener Setup-Anleitung · 2026-09-18 World Studio / 3D Worlds — detaillierte 3D-Umgebungen und Blender-Dateien sind ein **separates optionales Add-on**, nicht im Hauptpaket · 2026-09-20 Website-Generator (lokale Dienstleistung + Stadt → Entwurfs-Website, ueber Codex-Konto, optional Higgsfield). Die als fehlend gemeldeten Designreferenzen koennten in genau diesen optionalen Teilen liegen — in Phase 1 pruefen, bevor nachgebaut wird.
- **`Claude_Agent_OS_Full.command`** im Agent-OS-Ordner startet `claude --permission-mode bypassPermissions` in `source/` — saemtliche Rueckfragen aus. Herkunft unbekannt (vermutlich Codex). Steht im Widerspruch zur noch offenen Freigabeentscheidung; ueber den passwortlosen SSH-Schluessel reicht diese Sitzung auch auf die RTX.
- **`Check My Setup.command` hat einen Fehler:** sucht Keys in `~/.hermes/profiles/*/.env` (alter, falscher Ort) statt `~/.hermes/.env` → meldet vorhandene OpenRouter-/ElevenLabs-Keys faelschlich als fehlend, und sperrt die echte Keydatei nicht auf 600. Die Zeile „dashboard only answers localhost" wird ungeprueft immer mit ✅ ausgegeben.
- Laufzeitdaten von Agent OS liegen in `~/.agentic-os/` — eigenes Verzeichnis pro Modul (`project-memory/`, `todos/`, `bots/`, `radar/`, `app-lab/`, `ultracode-runs/` u. a.). `~/.agentic-os/claude-projects/` enthaelt `claude-default/`, `ultracode-plan/`, `verbindungstest/` — alle drei leer.
- Offene `[[Wikilinks]]` sind in diesem Vault **keine Fehler**, sondern Themenvorschlaege fuer noch nicht existierende Seiten. `wiki/themen/Mannheim.md` haelt allein 36 davon.

- **Apollo** = Sprachagent in Agent OS (Hermes-Umfeld). Gespraechsverlauf in `~/.agentic-os/apollo-conversations.jsonl` auf dem Mac. Stand 2026-10-12 laut User: komplett auf **Codex** als Backend umgestellt; frueher gab es einen Weg ueber „normales ChatGPT", der zurueckgestellt wurde. **Wunsch des Users:** Fallback wieder integrieren, sodass Apollo auch funktioniert, wenn Codex ausfaellt. Code liegt in Agent OS (`~/Projects/Maximus_OS/source/`), aus der Cloud-Session nicht erreichbar.
  - **Geklaert durch CHANGELOG 2026-10-10:** Apollo spricht und hoert seit diesem Update ueber die **Codex-CLI mit ChatGPT-Login** (kostenlos, `codex login` noetig). Der alte Weg ist **nicht entfernt**: oben in der Apollo-Konsole gibt es einen Schalter **Codex ↔ API**; „API" nutzt wie frueher den eigenen OpenAI-API-Key (kostenpflichtig). Anleitung: `install/3-JARVIS-VOICE.md`. Es ist ein **manueller** Schalter, kein automatischer Fallback — automatisches Umschalten bei Codex-Ausfall waere eine Eigenentwicklung in `source/` (wird von Updates ueberschrieben).
  - Technischer Haken: Das ChatGPT-Abo hat keine eigene API. Programmatisch erreichbar ist es nur ueber Codex mit ChatGPT-Login. Ein Fallback, der *unabhaengig* von Codex funktionieren soll, braucht deshalb einen eigenen Zugang: OpenAI-API-Key (separat abgerechnet), OpenRouter, oder lokal (RTX `127.0.0.1:8080` / LM Studio `127.0.0.1:1234`).

- **GPU-Worker (Quelle: vom User eingefuegtes Uebergabeprotokoll einer anderen Session, 2026-10-11 — von mir nicht verifiziert):** physischer Rechner `maxim-B650-EAGLE-AX`, Ubuntu 24.04.5, RTX 4080, LAN-IP `192.168.178.127` (DHCP, Lease bis 21.10., noch keine feste Adresse). Laufzeit: llama.cpp mit Qwen3.5-9B (Q6_K) als OpenAI-kompatibler Server auf `127.0.0.1:8080`, Modellname `maximus-qwen35`, Start/Stop-Skripte unter `~/maximus/`. GPU-Nutzung nachgewiesen (337 tok/s Prompt, 77 tok/s Generierung). Projektordner dort: `maximus-gpu-worker`, Doku `docs/21-ssh-nvidia-*.md`, Pruefskript `~/maximus/bin/nvidia-check.sh`.
  - NVIDIA: Kernelmodul 595.91.07 geladen, Bibliotheken 595.99.02 → „Driver/library version mismatch". Ursache: Paketupgrade nach dem Systemstart. Reparatur = Neustart, keine Paketaenderung. NVML (VRAM-Anzeige) bis dahin defekt, CUDA-Inferenz laeuft trotzdem.
  - **SSH auf dem RTX-Rechner: BESTAETIGT (2026-10-11, Bootstrap-Ausgabe vom User eingefuegt).** `ssh.socket` active, ufw inaktiv, Mac-Schluessel (Kommentar `maximus-mac-mini-4080-2026-10-11`) in `authorized_keys`. ED25519-Hostschluessel-Fingerabdruck: `SHA256:EMKrX8CNJoAphW6ZpCIy5VlC/B3cngzknNSo5eKYEXo` — am Mac vor der ersten Verbindung vergleichen. Port 22 am Mac bleibt geschlossen (Richtung ist Mac → RTX).
  - Bootstrap-Falle 1: das Skript akzeptiert nur das volle Wort `ja`, nicht `j`. Falle 2: es prueft mit `sshd -t` vor dem ersten Dienststart; auf Ubuntu 24.04 fehlt dann `/run/sshd` (legt `ssh.service` erst beim Start an) → falsches „STOPP: sshd-Konfiguration ungueltig". Abhilfe: `sudo install -d -m 0755 /run/sshd`, dann erneut laufen lassen.
  - Geplanter Weg fuer den Agent-OS-Auftrag: nach SSH vom Mac aus `ssh -N -L 8080:127.0.0.1:8080 maxim@192.168.178.127`, dann Endpunkt `http://127.0.0.1:8080/v1`. SSH steht seit 2026-10-11. llama-server laeuft wieder (bestaetigt von der Codex-Session am Mac: Qwen3.5-9B-Q6_K als `maximus-qwen35`, nur `127.0.0.1:8080`, Prozess haelt `/dev/nvidia0`). Die Codex-Session richtet SSH-Alias und Tunnel ein. **Offen:** der zeitlich zugeordnete GPU-Nachweis fuer einen echten Agent-OS-Auftrag — solange NVML wegen des Treiber-Mismatches ausfaellt, muss er ueber Prozessdaten (`/proc/<pid>/maps`, `/dev/nvidia*`-Handles) und llama-server-Logs mit Zeitstempeln gefuehrt werden; nach dem Neustart genuegt `nvidia-smi --query-compute-apps`.

- **Ziel des Users (2026-10-11): den RTX-Rechner vollstaendig fernsteuern — ein- und ausschalten, auch bei dunklem Bildschirm.** Drei getrennte Probleme: (1) Bildschirm aus ist fuer SSH irrelevant; was SSH killt, ist automatischer Ruhezustand → abschalten. (2) Ausschalten/Neustart: enge sudoers-Regel nur fuer `systemctl poweroff|reboot|suspend`, Datei `/etc/sudoers.d/power`. (3) Einschalten: WLAN-Treiber meldet WoWLAN „wake up on magic packet" (`iw phy`, 2026-10-11 bestaetigt) — funktioniert nur aus **Suspend**, nie aus S5. Daher Modell A: Suspend als „Aus"-Zustand + Magic Packet ueber WLAN (`nmcli ... 802-11-wireless.wake-on-wlan magic`). Modell B: Ethernet-Kabel + BIOS-WoL (weckt aus S5). Modell C: smarte Steckdose + BIOS „AC BACK: Always On" (robustester Weg). Ethernet-Port ist laut Uebergabe unverkabelt.
  - **Nicht** `suspend.target` maskieren, wenn Modell A gewaehlt wird — das verhindert auch das gewollte Suspend. Nur den *automatischen* Idle-Suspend abschalten (gsettings `sleep-inactive-ac-type nothing`, logind `IdleAction=ignore`).

## Aktueller Stand

Agent-OS-Ebene ist repo-seitig vollstaendig ausgebaut und in Cloud-Sessions nachweislich aktiv: SessionStart-Hook feuert, die fuenf Agenten laden. Dazu sieben Slash-Commands, drei Hooks (Gedaechtnis laden, Quellmaterial schuetzen, Pflicht-Updates erzwingen), `scripts/wiki_check.py` und dieselbe Pruefung in CI (`.github/workflows/wiki-check.yml`). Branch `claude/agent-os-integration-context-gobmre`.

Aktueller Pruefstand der Wissensbasis: 0 Fehler, 6 Warnungen, 40 offene Links (Stand 2026-10-10).

Im Leitstand von Agent OS ist diese Ebene **nicht sichtbar, und kann es auch nicht sein**: sie besteht aus Konfigurationsdateien, die Claude Code beim Start selbst liest. Nichts davon registriert sich bei Agent OS, meldet einen Heartbeat oder spricht dessen API. Konnektivitaet im Dashboard entsteht ueber Agent OS' eigenen Connector (`install/11-MEMORY-OBSIDIAN.md`), nicht hierueber.

Offen: diesen Connector laufen lassen. Erfordert einen Terminal-Agenten in `/Users/maxim/Projects/Maximus_OS` — aus einer Cloud-Session nicht erreichbar (`/Users/...` existiert dort nicht, `127.0.0.1:3737` ist die Loopback-Adresse des Containers).

- **Fernsteuerung am Mac laeuft (2026-10-14):** `claude remote-control` in `~/Projects/Maximus_OS/source`. Diese Mac-Sitzung hat Dateien und Shell in `source/`, Lese-/Schreibzugriff auf den Vault und erreicht die RTX ueber den SSH-Alias. Sie ist ab jetzt die ausfuehrende Sitzung fuer Agent OS; diese Cloud-Sitzung bleibt Gedaechtnis und Pruefinstanz.
- **Sicherheitsvorfall, offen:** In einer Vault-Notiz vom 2026-10-12 (Vault auf dem Mac, nicht in diesem Repo) steht ein Telegram-Bot-Token im Klartext — laut Mac-Sitzung der Token des OpenClaw-Bots. Risiko: Agenten, die den Vault lesen (Memory Galaxy, Hermes, Jarvis, OpenClaw), koennen den Token als Kontext an Cloud-Modelle schicken; zusaetzlich liegt er in iCloud/Backups, falls der Vault dort synchronisiert ist. Reihenfolge der Behebung: (1) User widerruft den Token bei @BotFather, (2) neuen Token nur in die Konfigurationsdatei des Bots, nie in Notizen, (3) Zeile in der Notiz schwaerzen — die Mac-Sitzung tut das nur auf ausdrueckliche Anweisung. Erst schwaerzen ohne zu widerrufen laesst den alten Token gueltig.
- **Offene Stoerungen laut Mac-Sitzung (2026-10-14):** OpenClaw-Telegram-Bot antwortet nicht · OpenClaw-Heartbeat still seit 2026-10-13 21:15 · Hermes-Operator-Sitzungen scheitern an Tool-Policy-Fehlern (Terminal- und Telegram-Werkzeuge fehlen) · RTX/ASUS-Migration bleibt auf Staging, Produktion = Mac-Port 3737 · Autonomous Loop wartet auf Entscheidung ueber eigene SQLite-Datei unter `~/.agentic-os/autonomous-loop/` · Codex hat am 2026-10-13 jcode, einen Autonomous-Loop-Controller und lokale KI-Adapter in `source/` integriert (Berichte unter `source/docs/`).

- **SEO Content Pipeline Pack (AIPB, 2026-10-14 vom User erhalten):** `blog-post.md` (Claude-Skill), `seoPipeline.ts.template`, `example-transcript.txt`, `README.md`. Ziel des Packs: pro Keyword 5 verschiedene Artikel auf 5 eigenen Websites (Eleventy → Netlify), Querverlinkung, Einreichung bei Omega Indexer. Einbau laut README durch Ersetzen der `SITES` in `source/src/lib/seoPipeline.ts` → **wird bei jedem Agent-OS-Update ueberschrieben**, braucht Git/Patch-Sicherung.
  - **Im Pack steckt ein fremder, aktiver Omega-Indexer-API-Key** (der des Pack-Autors, Step 8 in `blog-post.md`). Nicht verwenden, nirgends speichern, nicht in dieses oeffentliche Repo. Nur ein eigener Key oder Schritt weglassen.
  - Ueber die 4 `{{TODO}}`-Stellen hinaus ist der Skill fest auf den Autor zugeschnitten: Autorenstimme und Bio, Schema-Autor mit dessen Social-Links, Skool-/Mastermind-CTAs, Footer, 5 fremde Domains, Pfade `/Users/juliangoldie/...`, Google-Sheet. Unveraendert wuerde er Artikel unter fremdem Namen auf den Seiten des Users veroeffentlichen.
  - Risiko: 5 Artikel pro Keyword plus Netzwerk-Querverlinkung zum Ranking faellt unter Googles Spam-Richtlinien („scaled content abuse", „link schemes") — Abstrafung aller verbundenen Seiten moeglich. Entscheidung des Users.
  - RTX bringt hier keinen Vorteil (Claude laeuft ueber API/CLI, Eleventy/Netlify sind leicht). Sinnvoll nur als Staging-Test (RTX 3738 → Mac 3739) vor dem Einbau in die Produktion auf dem Mac.
  - Lizenz des Packs: nutzen und anpassen erlaubt, das Pack selbst nicht wiederveroeffentlichen → keine Kopie in dieses oeffentliche Repo.

## Entscheidungen

- 2026-10-11 — Der Mac betreibt **zwei getrennte Inferenz-Wege**, die nicht vermischt werden duerfen: (a) Claude Platform ueber `ant` → `api.anthropic.com`, fuer den Bereich „Claude Platform" in Agent OS; (b) lokale Modelle (LM Studio auf `127.0.0.1:1234`, GPU-Worker ueber Tunnel auf `127.0.0.1:8080`), OpenAI-kompatibel. Der `ANTHROPIC_BASE_URL=127.0.0.1:1234` ist damit kein Versehen, sondern Teil von (b) — die Reparatur ist **Trennung** (eigenes `ant`-Profil, Endpunkte pro Werkzeug), nicht Loeschen.

- 2026-10-10 — `scripts/agentic-os-bootstrap.sh` laeuft nur noch mit `--confirm` und verweist zuerst auf Agent OS' eigenen Connector. Sein Verzeichnis-Layout war geraten; unbesehen ausgefuehrt haette es Verzeichnisse angelegt, die Agent OS so vielleicht nicht erwartet.
- 2026-10-10 — Die hier gebaute Ebene bleibt bestehen, aber sie ist **nicht** der Anschluss an Agent OS. Sie regelt, wie Claude Code in diesem Repo arbeitet. Was Agent OS schon selbst macht (Memory Galaxy, Obsidian-Connector), soll nicht doppelt gefuehrt werden — vor dem Anschluss ist zu pruefen, welche Teile dann entfallen.
- 2026-10-10 — Gedaechtnis als versionierte Datei im Repo (`Obsidian/Agentic OS/MEMORY.md`) statt als lokaler Zustand — Cloud-Container sind ephemer, nur git ueberlebt den Session-Wechsel.
- 2026-10-10 — `Agentic OS/` liegt ausserhalb von `wiki/`, damit `mkdocs build` das Gedaechtnis nicht auf die oeffentliche Website stellt.
- 2026-10-10 — Agenten-Zuschnitt entlang der bestehenden Workflows aus `CLAUDE.md`/`AGENTS.md` (Ingest, Health, Index, Output) plus `memory-keeper`, statt generischer Rollen.
- 2026-10-10 — Der SessionStart-Hook laedt Kontext und bricht nie ab (`exit 0` in jedem Fall), damit ein Fehler im Hook keine Session blockiert. Dasselbe Prinzip gilt fuer alle drei Hooks: im Fehlerfall fallen sie offen aus.
- 2026-10-10 — Offene Wikilinks gelten als Warnung, nicht als Fehler. Ein erster Entwurf von `wiki_check.py` meldete 42 "tote Links" und haette CI dauerhaft rot gehalten, obwohl 40 davon normale Obsidian-Stubs sind.
- 2026-10-10 — Die Index-Pflicht im Stop-Hook greift nur bei strukturellen Aenderungen (anlegen, umbenennen, entfernen), nicht bei reinen Textaenderungen — so steht es in CLAUDE.md ("when adding/removing pages"). Der erste Entwurf war strenger als die Regel und hat sich selbst blockiert.

## Offene Punkte

- **Reihenfolge vom User vorgegeben: zuerst Claude in Agent OS unter „Agenten" konfigurieren, erst danach den Obsidian-Vault anschliessen.** Nicht umdrehen.
- Claude ist in Agent OS nicht als Agent konfiguriert — deshalb ist im Leitstand nichts zu sehen. **Agent OS erwartet dort die Claude Platform CLI (`ant`)**: installieren, `ant auth login`, Dashboard neu starten. Rein lokale Konfiguration; im Vault-Repo gibt es dafuer nichts zu bauen.
  - macOS-Installation braucht ZWEI Schritte, der zweite fehlt im Dashboard-Hinweis: `brew install anthropics/tap/ant`, dann `xattr -d com.apple.quarantine "$(brew --prefix)/bin/ant"` (Gatekeeper blockt sonst).
  - **Konflikt mit Claude Code:** Nach `ant auth login` kann Claude Code einen Auth-Konflikt zwischen dem `ant`-Profil und seinem eigenen `/login` melden. Es darf nur eines gelten — entweder das Profil nutzen und in Claude Code `/logout`, oder `ant auth logout` und Claude Codes eigenen Login behalten.
  - **Haeufigste Fehlerquelle:** ein exportiertes `ANTHROPIC_API_KEY` ueberschreibt jedes OAuth-Profil stillschweigend. Auch ein leeres `ANTHROPIC_API_KEY=""` gewinnt noch. Muss echt `unset` sein. `ant auth status` zeigt, welche Quelle gewonnen hat.
  - Ein Login-Token ist an **ein** Org+Workspace gebunden. Ressourcen aus einem anderen Workspace sind dann unsichtbar — bei „verschwundenen" Objekten zuerst `ant auth status` pruefen.
  - Quelle: der mitgelieferte `claude-api`-Skill, Datei `shared/anthropic-cli.md`. Nicht aus dem Gedaechtnis beantworten, der Skill ist maßgeblich.
  - **Befund vom 2026-10-10 (`ant auth status` des Users):** Login erfolgreich — Profil `default`, Org „Maxim", Workspace „Claude Code" (`wrkspc_01WPXdDDeZADRH6NKroLNQTG`), Scopes `user:developer user:inference user:profile`. Trotzdem keine Verbindung, aus zwei Gruenden: (1) `ANTHROPIC_BASE_URL=http://127.0.0.1:1234` — gesetzt als Umgebungsvariable UND im Profil (`configs/default.json`). Port 1234 ist LM Studio; alle Anfragen gehen an den lokalen Server statt an die API. (2) `ANTHROPIC_AUTH_TOKEN` mit 8 Zeichen gesetzt — ein Platzhalter, der in der Rangfolge ueber dem OAuth-Profil steht. Beides stammt vermutlich aus einem Local-LLM-Setup (Agent OS `install/5-FREE-CLAUDE-CODE.md` o. ae.); vor dem Entfernen klaeren, ob das Setup gebraucht wird — dann getrennte Profile statt globale Variablen.

- Lokales Bootstrap auf dem Mac des Users ist offen. Aus einer Cloud-Session nicht machbar: keine Computer-Use-/Remote-Device-Tools vorhanden, keine Remote-Control-Verbindung, keine Peer-Session auf seiner Maschine. Erfordert eine Session, die auf seinem Rechner laeuft (Claude Desktop oder `claude remote-control`).
- `Obsidian/raw/` existiert laut Dokumentation, ist im Repo aber nicht vorhanden — nur `Clippings/`, `Ideen/`, `Projekte/`. Ob `raw/` lokal existiert und nur nicht committet ist, ist ungeklaert.
- Ungeklaert, welche Teile der hier gebauten Ebene nach dem Anschluss ueberfluessig werden: Agent OS fuehrt mit `project-memory/` und der „Memory Galaxy" ein eigenes Gedaechtnis. Doppelte Quellen der Wahrheit sind zu vermeiden.
- `install/11-MEMORY-OBSIDIAN.md` aus Agent OS ist ungelesen — der Inhalt entscheidet, wie der Anschluss konkret aussieht.
- `Obsidian/wiki/Unbenannt.base` und `Obsidian/Unbenannt.canvas` sind unbenannte Platzhalter ohne Inhalt — Zweck unklar.
- `Obsidian/wiki/2026-04-09.md` ist eine vollstaendig leere Seite. Nicht geloescht, weil das eine inhaltliche Entscheidung des Users ist.
- `Obsidian/.github/workflows/deploy.yml` ist eine Dublette des Workflows im Repo-Wurzel-`.github/`. Nur der im Wurzelverzeichnis ist aktiv; die Kopie im Vault ist wirkungslos und stiftet Verwirrung.

- **Freigabe ausstehend (2026-10-13):** Codex am Mac will Agent-OS-Cloud-Agenten auf Mac und RTX Schreib- und Ausfuehrungsrechte geben und braucht dafuer `approvals.single_query_mode: approve` auf der RTX-Stage — unbeaufsichtigte Python- und Shell-Aufrufe. Die automatische Freigabepruefung hat das bereits einmal abgelehnt; ein allgemeines Vollzugriffs-Okay reicht dafuer ausdruecklich nicht. Empfehlung dieser Session: **keine globale Freigabe**, sondern eigener Linux-Benutzer ohne sudo bzw. festes Arbeitsverzeichnis als Sandbox, Agenten einzeln freischalten (Hermes mit Telegram-Gateway zuletzt), Negativtest an der Sandbox-Grenze. Codex-Doku dazu auf dem Mac unter `~/Documents/ChatGPT/Agent OS/rtx-migration/deployment/` (MIGRATION-ABNAHME.md, MAC-OPERATOR-STAGE-PREPARED.md, OPERATOR-BUILTINS-STAGE-PREPARED.md), von hier nicht eingesehen.

## Gelernte Konventionen

- Der User fragt auf Deutsch und erwartet Antworten auf Deutsch.
- Vor Aussagen ueber Vorhandensein oder Fehlen von Dateien tatsaechlich im Repo nachsehen. In einer frueheren Session wurde ein fehlender Vault-Pfad als Rechteproblem gedeutet, obwohl die Datei einfach nicht existierte.
- Der User arbeitet parallel mit mehreren Agenten-Sessions (Codex am Mac, Claude Code am RTX-Rechner, diese Cloud-Session) und fuegt Ausgaben zwischen ihnen ein. Diese Session ist dabei Gedaechtnis und Pruefinstanz, nicht Ausfuehrende — keine Befehle doppelt anweisen, die eine andere Session gerade ausfuehrt.
- Cloud-Session laeuft in einem Linux-Container, nicht auf dem Mac des Users: `/Users/maxim/...` ist dort grundsaetzlich nicht erreichbar. Das explizit sagen statt es als Zugriffsfehler zu melden.
- Index-Pflege nach jeder Inhaltsaenderung ist Pflicht, nicht Kuer (`*-Index.md` plus `wiki/index.md`).

## Session-Log

- 2026-10-14 — SEO-Pipeline-Pack geprueft: fremder API-Key, fest verdrahtete Fremd-Identitaet, Spam-Richtlinien-Risiko. Nichts installiert; Vorbedingungen und Mac-Auftrag formuliert.

- 2026-10-14 — Remote Control am Mac bestaetigt. Geleakter Telegram-Token in Mac-Vault gemeldet; dieses oeffentliche Repo darauf gescannt — sauber. `~/.hermes/.env` hat bereits Rechte 600.

- 2026-10-14 — Fuenf Agent-OS-Dateien vom User erhalten (Roadmap, CHANGELOG, Check My Setup, Claude-Launcher, config.example). Apollo-Frage geklaert (Schalter existiert), Konfigurationsort und Design-OS-Herkunft festgehalten, zwei Probleme gefunden (bypassPermissions-Launcher, Key-Pfad-Fehler im Setup-Check).

- 2026-10-13 — Updater schont `.git` (Codex). Versionierung in `source/` damit tragfaehig; Empfehlung Vendor-Branch.

- 2026-10-13 — Codex hat die Design-OS-Antwort gegengeprueft: kein `.git` in `source/` (Gedaechtnis korrigiert), Updater nutzt `rsync --delete` (bestaetigt). GitHub-Frage von hier beantwortet: das Repo ist ein anderes Projekt.

- 2026-10-13 — Design-OS-Auftrag erhalten. GitHub-Repo `Maximus_OS` geprueft: anderes Projekt, nicht Agent OS. Auftrag deshalb nicht hier ausgefuehrt, sondern fuer die Mac-Session ergaenzt.

- 2026-10-12 — Apollo-Fallback (Codex → zweiter Weg) als Wunsch aufgenommen; Diagnose und Uebergabe-Auftrag fuer eine Mac-Session formuliert.

- 2026-10-11 — Fernsteuerungsziel aufgenommen; WoWLAN-Faehigkeit per `iw phy` bestaetigt; Architektur A/B/C festgehalten.
- 2026-10-11 — SSH-Bootstrap am RTX-Rechner vom User durchgefuehrt, Fingerabdruck verifiziert. Zwei Skript-Fallen dabei dokumentiert (`ja` statt `j`; fehlendes `/run/sshd` vor dem ersten Start).

- 2026-10-11 — Uebergabeprotokoll des RTX-Rechners vom User erhalten. GPU-Worker als Fakten aufgenommen (unverifiziert, als solche markiert). Erklaert den lokalen `ANTHROPIC_BASE_URL`: Local-LLM-Architektur, kein Fehler.

- 2026-10-10 — Geprueft, ob Agent OS integriert war: war es nicht (leerer Branch, keine Agenten, kein Protokoll). Anschliessend die repo-seitige Integration gebaut und committet.
- 2026-10-10 — Integration im Cloud-Resume verifiziert: Hook feuert, Agenten laden. Zugriff auf den Mac geprueft und ausgeschlossen (siehe "Offene Punkte").
- 2026-10-10 — `ant auth status` des Users ausgewertet: Login ok, aber Endpunkt auf `127.0.0.1:1234` umgebogen und Platzhalter-`ANTHROPIC_AUTH_TOKEN`. `scripts/connect-ant.sh` erkennt und umgeht jetzt beides.
- 2026-10-10 — Agent OS verlangt fuer Claude die `ant`-CLI (Claude Platform CLI). Installations- und Auth-Details aus dem `claude-api`-Skill geholt, nicht geraten.
- 2026-10-10 — User will Claude zuerst unter „Agenten" in Agent OS konfiguriert sehen, Obsidian danach. Aufgabenkarte entsprechend umgestellt.
- 2026-10-10 — Vault-ID `53213b4610731fc1` vom User erhalten; die Frage "welcher Vault" ist damit beantwortet.
- 2026-10-10 — Agent OS erstmals eingesehen (Verzeichnislisting und README vom User eingefuegt). Befund: eigenes Produkt mit eigenem Obsidian-Connector; die hier gebaute Ebene ist nicht der gesuchte Anschluss. Bootstrap daraufhin hinter `--confirm` gelegt.
- 2026-10-10 — Ebene voll ausgebaut: Commands, Guard-Hook, Stop-Gate, Pruefskript, Hook-Tests, CI. Drei eigene Entwurfsfehler dabei gefunden und behoben — zwei davon, weil die Hooks diese Session selbst blockiert haben (siehe "Entscheidungen").
