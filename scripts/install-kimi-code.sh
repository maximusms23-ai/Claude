#!/usr/bin/env bash
#
# Installiert Kimi Code CLI (Moonshot AI) auf dem RTX-PC (Ubuntu) oder dem Mac mini
# und prueft, ob der Headless-Aufruf funktioniert, den Agent OS verwendet:
#   kimi -p "..." --output-format stream-json
#
# Was das Skript tut:
#   1. Zielrechner anzeigen (Hostname, OS, Benutzer) und bestaetigen lassen
#   2. Offizielles Installationsskript herunterladen, Pruefsumme anzeigen, NICHT blind ausfuehren
#   3. Nach Bestaetigung installieren, PATH ergaenzen, Version pruefen
#   4. Login per Kimi-Code-OAuth (Device-Code, Browser auf beliebigem Geraet)
#   5. kimi doctor und ein Headless-Rauchtest mit stream-json
#
# Was es NICHT tut:
#   - keine Modellgewichte laden. Kimi K3 (2,8 Billionen Parameter) laeuft in der
#     Moonshot-Cloud, nicht lokal. Die RTX 4080 wird dafuer nicht gebraucht.
#   - keine Agent-OS-Konfiguration aendern. Agent OS ruft `kimi` auf dem Rechner auf,
#     auf dem Agent OS selbst laeuft.
#   - keine Schluessel oder Tokens ausgeben oder speichern (das macht `kimi login` selbst
#     unter ~/.kimi-code).
#
# Aufruf:
#   bash scripts/install-kimi-code.sh          # interaktiv
#   bash scripts/install-kimi-code.sh --check  # nur Status pruefen, nichts aendern
#
# Quellen: https://github.com/MoonshotAI/kimi-code
#          https://www.kimi.com/code/docs/en/kimi-code-cli/guides/getting-started.html
#          https://moonshotai.github.io/kimi-code/en/reference/kimi-command.html

set -uo pipefail

INSTALL_URL="https://code.kimi.com/kimi-code/install.sh"
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

say()  { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
ask()  { local a; read -r -p "$1 [ja/nein] " a; [ "$a" = "ja" ]; }

step "1. Zielrechner"
OS="$(uname -s)"
say "Hostname:  $(hostname)"
say "System:    $OS $( [ -r /etc/os-release ] && . /etc/os-release && echo "$PRETTY_NAME" || sw_vers -productVersion 2>/dev/null )"
say "Benutzer:  $(whoami)  Home: $HOME"
case "$(hostname)" in
  maxim-B650-EAGLE-AX) say "Erkannt:   RTX-PC (GPU-Worker)";;
  *)                   say "Erkannt:   anderer Rechner (vermutlich Mac mini oder Testsystem)";;
esac

step "2. Vorhandene Installation"
if command -v kimi >/dev/null 2>&1; then
  say "kimi gefunden: $(command -v kimi)"
  say "Version:       $(kimi --version 2>/dev/null || echo unbekannt)"
  HAVE_KIMI=1
else
  say "kimi nicht im PATH."
  [ -x "$HOME/.local/bin/kimi" ] && say "Hinweis: $HOME/.local/bin/kimi existiert, PATH fehlt."
  HAVE_KIMI=0
fi
[ -d "$HOME/.kimi-code" ] && say "Konfigurationsordner vorhanden: $HOME/.kimi-code" || say "Kein ~/.kimi-code (noch kein Login)."

if [ "$CHECK_ONLY" = 1 ]; then
  step "Nur Pruefung, keine Aenderung."
  exit 0
fi

if [ "$HAVE_KIMI" = 0 ]; then
  step "3. Installationsskript laden und anzeigen"
  TMP="$(mktemp -d)"
  if ! curl -fsSL --max-time 60 -o "$TMP/install.sh" "$INSTALL_URL"; then
    say "Download von $INSTALL_URL fehlgeschlagen. Abbruch."; exit 1
  fi
  say "Gespeichert: $TMP/install.sh"
  say "SHA-256:     $(sha256sum "$TMP/install.sh" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$TMP/install.sh" | cut -d' ' -f1)"
  say "Groesse:     $(wc -c < "$TMP/install.sh") Bytes"
  say "--- erste 40 Zeilen ---"
  sed -n '1,40p' "$TMP/install.sh"
  say "--- Ende Auszug (ganz lesen: less $TMP/install.sh) ---"
  ask "Installationsskript jetzt ausfuehren?" || { say "Abgebrochen, nichts geaendert."; exit 0; }
  bash "$TMP/install.sh" || { say "Installation fehlgeschlagen."; exit 1; }
  rm -rf "$TMP"
fi

step "4. PATH"
if ! command -v kimi >/dev/null 2>&1; then
  for d in "$HOME/.local/bin" "$HOME/.kimi-code/bin" "/usr/local/bin"; do
    [ -x "$d/kimi" ] && export PATH="$d:$PATH" && break
  done
fi
if ! command -v kimi >/dev/null 2>&1; then
  say "kimi weiterhin nicht gefunden. Pruefe die Ausgabe des Installers und oeffne ein neues Terminal."; exit 1
fi
KIMI_DIR="$(dirname "$(command -v kimi)")"
RC="$HOME/.bashrc"; [ "$OS" = "Darwin" ] && RC="$HOME/.zshrc"
if ! grep -qs "$KIMI_DIR" "$RC"; then
  if ask "PATH-Eintrag fuer $KIMI_DIR in $RC ergaenzen?"; then
    cp "$RC" "$RC.bak-kimi-$(date +%Y%m%d%H%M%S)" 2>/dev/null
    printf '\nexport PATH="%s:$PATH"\n' "$KIMI_DIR" >> "$RC"
    say "Ergaenzt. Rueckweg: Sicherung $RC.bak-kimi-* zurueckkopieren."
  fi
fi
say "kimi $(kimi --version 2>/dev/null)"

step "5. Login (Kimi Code OAuth, Device-Code)"
say "Es erscheint eine URL und ein Code. URL auf einem beliebigen Geraet oeffnen, Code eingeben."
say "Das Token wird von kimi selbst unter ~/.kimi-code abgelegt. Nichts davon in den Chat kopieren."
if ask "kimi login jetzt starten?"; then
  kimi login || say "Login nicht abgeschlossen. Spaeter mit 'kimi login' nachholen."
fi

step "6. Pruefung"
kimi doctor 2>&1 | tail -20 || true
say ""
say "Headless-Rauchtest (so ruft Agent OS auf):"
if kimi -p 'Antworte nur mit dem Wort OK.' --output-format stream-json 2>&1 | tail -5; then
  say ""
  say "Wenn oben JSON-Zeilen mit 'OK' stehen, ist Kimi Code einsatzbereit."
else
  say "Rauchtest fehlgeschlagen. Haeufigste Ursache: Login fehlt (kimi login)."
fi

step "Fertig"
say "Naechster Schritt: In Agent OS den Agenten 'Kimi Code' testen. Agent OS muss auf demselben"
say "Rechner laufen wie dieses 'kimi', oder ueber SSH auf diesen Rechner zeigen."
