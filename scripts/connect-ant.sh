#!/usr/bin/env bash
#
# Verbindet die Claude Platform CLI (`ant`) mit diesem Rechner, damit Agent OS
# im Dashboard (http://localhost:3737) den Bereich "Agenten" aktivieren kann.
#
# Nimmt alles ab, was automatisierbar ist:
#   - Installation (Homebrew auf macOS, Tarball/Go auf Linux)
#   - der Gatekeeper-Fix, den macOS braucht und der im Dashboard-Hinweis fehlt
#   - Vorabpruefung auf ANTHROPIC_API_KEY, das jedes OAuth-Profil still ueberschreibt
#   - Warnung vor dem Login-Konflikt mit Claude Code
#   - Verifikation mit einem echten API-Aufruf nach dem Login
#
# Einen Schritt kann es nicht abnehmen: `ant auth login` oeffnet den Browser und
# verlangt die Zustimmung des Kontoinhabers. Das ist eine Einwilligung, keine
# Konfiguration — sie muss von Hand erfolgen.
#
# Aufruf:
#   ./scripts/connect-ant.sh              # interaktiv, mit Rueckfragen
#   ./scripts/connect-ant.sh --yes        # ohne Rueckfragen
#   ./scripts/connect-ant.sh --check      # nur pruefen, nichts aendern
#
# Quelle der Installations- und Auth-Details: der mitgelieferte `claude-api`-Skill
# (shared/anthropic-cli.md). Nicht aus dem Gedaechtnis geschrieben.

set -uo pipefail

ASSUME_YES=0
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    --check)  CHECK_ONLY=1 ;;
    --help|-h) sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unbekannte Option: $arg" >&2; exit 1 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
warn() { printf '   ! %s\n' "$*" >&2; }
ok()   { printf '   + %s\n' "$*"; }

ask() {
  # ask "Frage" -> 0 = ja. Ohne TTY oder mit --yes: ja.
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ -t 0 ] || return 0
  printf '   ? %s [j/N] ' "$1"
  read -r answer
  case "$answer" in j|J|y|Y|ja|Ja|yes) return 0 ;; *) return 1 ;; esac
}

# `ant` ohne die Variablen aufrufen, die Profil bzw. Endpunkt ueberschreiben.
# ANTHROPIC_BASE_URL ist der gefaehrlichste: zeigt er auf einen lokalen Server
# (z. B. LM Studio auf Port 1234), gehen ALLE Anfragen dorthin statt an die API —
# bei perfekt gueltigem OAuth-Token.
ant_run() {
  env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL ant "$@"
}

say "Claude Platform CLI (ant) <-> Agent OS"
say "Dashboard: http://localhost:3737"

# ---------------------------------------------------------------- Schritt 1
step "Schritt 1 — Umgebung pruefen"

# Ein gesetztes ANTHROPIC_API_KEY ueberschreibt JEDES OAuth-Profil, auch ein
# leerer Wert gewinnt noch seinen Vorrang. Das ist die haeufigste Fehlerquelle.
key_problem=0
if [ -n "${ANTHROPIC_API_KEY+x}" ]; then
  if [ -z "${ANTHROPIC_API_KEY}" ]; then
    warn 'ANTHROPIC_API_KEY ist LEER gesetzt — gewinnt trotzdem gegen jedes Profil'
  else
    warn 'ANTHROPIC_API_KEY ist gesetzt — ueberschreibt jedes OAuth-Profil still'
  fi
  warn 'Dieses Skript ruft ant mit `env -u ANTHROPIC_API_KEY` auf, um das zu umgehen.'
  warn 'Dauerhaft loesen: die Zeile aus ~/.zshrc bzw. ~/.bashrc entfernen, dann `unset ANTHROPIC_API_KEY`.'
  key_problem=1
else
  ok 'kein ANTHROPIC_API_KEY gesetzt'
fi

# ANTHROPIC_AUTH_TOKEN steht in der Rangfolge UEBER dem OAuth-Profil.
# Ein kurzer Platzhalterwert wird dann anstelle des gueltigen Tokens gesendet.
if [ -n "${ANTHROPIC_AUTH_TOKEN+x}" ]; then
  n=${#ANTHROPIC_AUTH_TOKEN}
  warn "ANTHROPIC_AUTH_TOKEN ist gesetzt ($n Zeichen) — steht in der Rangfolge UEBER dem Profil."
  [ "$n" -lt 40 ] && warn 'So kurz ist das kein echtes Token, sondern ein Platzhalter. Entfernen.'
  warn 'Dauerhaft loesen: Zeile aus der Shell-Konfiguration entfernen, dann `unset ANTHROPIC_AUTH_TOKEN`.'
  key_problem=1
fi

# Der haeufigste stille Totalausfall: ein umgebogener Endpunkt.
if [ -n "${ANTHROPIC_BASE_URL:-}" ]; then
  warn "ANTHROPIC_BASE_URL zeigt auf: $ANTHROPIC_BASE_URL"
  case "$ANTHROPIC_BASE_URL" in
    *127.0.0.1*|*localhost*)
      warn 'Das ist ein LOKALER Server, nicht die Claude API. Jede Anfrage geht dorthin —'
      warn 'auch mit gueltigem OAuth-Token. Typisch fuer LM Studio (Port 1234) oder einen Proxy.'
      warn 'Gehoert das zu einem Local-LLM-Setup, lass es dort und nutze fuer die Platform'
      warn 'ein eigenes Profil: ant auth login --profile platform'
      ;;
  esac
  warn 'Dieses Skript umgeht die Variable; dauerhaft: aus der Shell-Konfiguration entfernen.'
  key_problem=1
fi

# Auch das Profil selbst kann einen base_url festhalten — Variable allein zu
# entfernen reicht dann nicht.
cfg="${ANTHROPIC_CONFIG_DIR:-$HOME/.config/anthropic}/configs/default.json"
if [ -f "$cfg" ] && grep -q '"base_url"' "$cfg" 2>/dev/null; then
  pburl="$(sed -n 's/.*"base_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -1)"
  if [ -n "$pburl" ]; then
    warn "Das Profil 'default' speichert base_url: $pburl"
    case "$pburl" in
      *anthropic.com*) : ;;
      *)
        warn 'Auch ohne Umgebungsvariable gehen Anfragen dorthin.'
        if [ "$CHECK_ONLY" -eq 0 ] && ask 'base_url im Profil auf https://api.anthropic.com zuruecksetzen?'; then
          if ant profile set base_url https://api.anthropic.com --profile default 2>/dev/null; then
            ok 'Profil-base_url zurueckgesetzt'
          else
            warn "Automatisch fehlgeschlagen. Von Hand: $cfg bearbeiten und die base_url-Zeile entfernen."
          fi
        fi
        ;;
    esac
  fi
fi

if [ "$key_problem" -eq 1 ]; then
  say ''
  say '   Woher die Variablen kommen, findest du so:'
  say '     grep -rn ANTHROPIC_ ~/.zshrc ~/.zprofile ~/.bashrc ~/.bash_profile ~/.profile 2>/dev/null'
fi

os="$(uname -s)"
ok "System: $os $(uname -m)"

# ---------------------------------------------------------------- Schritt 2
step "Schritt 2 — ant installieren"

if command -v ant >/dev/null 2>&1; then
  ok "ant ist vorhanden: $(command -v ant)"
  ok "Version: $(ant --version 2>/dev/null | head -1 || echo unbekannt)"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  warn 'ant fehlt. Mit --check wird nichts installiert.'
  exit 1
elif [ "$os" = "Darwin" ]; then
  if ! command -v brew >/dev/null 2>&1; then
    warn 'Homebrew fehlt. Entweder von https://brew.sh installieren, oder:'
    warn '  go install github.com/anthropics/anthropic-cli/cmd/ant@latest   (Go 1.25+)'
    exit 1
  fi
  if ask 'ant per Homebrew installieren?'; then
    brew install anthropics/tap/ant || { warn 'brew install fehlgeschlagen'; exit 1; }
    # Ohne diesen Schritt blockt Gatekeeper die Binary. Fehlt im Dashboard-Hinweis.
    if xattr -d com.apple.quarantine "$(brew --prefix)/bin/ant" 2>/dev/null; then
      ok 'Gatekeeper-Quarantaene entfernt'
    else
      ok 'keine Quarantaene gesetzt (nichts zu tun)'
    fi
  else
    say '   Abgebrochen.'; exit 1
  fi
else
  warn "Automatische Installation ist hier nur fuer macOS vorgesehen ($os erkannt)."
  warn 'Linux/WSL — eines von beiden:'
  warn '  go install github.com/anthropics/anthropic-cli/cmd/ant@latest   (Go 1.25+)'
  warn '  Release-Tarball von github.com/anthropics/anthropic-cli/releases nach /usr/local/bin'
  exit 1
fi

# ---------------------------------------------------------------- Schritt 3
step "Schritt 3 — Anmeldestatus"

status_out="$(ant_run auth status 2>&1)"
printf '%s\n' "$status_out" | sed 's/^/   /'

need_login=1
if printf '%s' "$status_out" | grep -qiE 'profile|workspace|oauth|logged in|active'; then
  if printf '%s' "$status_out" | grep -qiE 'not logged in|no active|no credential'; then
    need_login=1
  else
    need_login=0
  fi
fi

if [ "$need_login" -eq 0 ]; then
  ok 'Es ist bereits eine Credential-Quelle aktiv.'
elif [ "$CHECK_ONLY" -eq 1 ]; then
  warn 'Keine Anmeldung aktiv. Mit --check wird nicht angemeldet.'
  exit 1
else
  say ''
  say '   Jetzt kommt der Schritt, den nur der Kontoinhaber ausfuehren kann:'
  say '   `ant auth login` oeffnet den Browser und fragt nach Zustimmung fuer'
  say '   einen Workspace. Das Token wird an GENAU EINEN Workspace gebunden.'
  say ''
  warn 'Danach kann Claude Code einen Auth-Konflikt melden: sein eigener /login'
  warn 'und das neue ant-Profil konkurrieren. Nur eines darf gelten —'
  warn 'entweder in Claude Code /logout, oder spaeter `ant auth logout`.'
  say ''
  if ask 'Login jetzt starten?'; then
    ant_run auth login || { warn 'Login fehlgeschlagen oder abgebrochen'; exit 1; }
  else
    say '   Uebersprungen. Spaeter manuell: ant auth login'
    say '   (Auf einem Rechner ohne Browser: ant auth login --no-browser)'
    exit 1
  fi
fi

# ---------------------------------------------------------------- Schritt 4
step "Schritt 4 — Verbindung verifizieren"

# Echter API-Aufruf. `ant auth status` sagt nur, welche Quelle gewinnt,
# nicht ob sie funktioniert.
if model="$(ant_run models list --max-items 1 --transform id -r 2>/dev/null)" && [ -n "$model" ]; then
  ok "API antwortet. Erreichbares Modell: $model"
  connected=1
else
  warn 'Die API antwortet nicht. Haeufigste Ursachen:'
  warn '  - ANTHROPIC_BASE_URL oder ein Profil-base_url zeigt auf einen lokalen Server'
  warn '  - ANTHROPIC_API_KEY oder ANTHROPIC_AUTH_TOKEN ueberschreibt das Profil (Schritt 1)'
  warn '  - Refresh-Token abgelaufen -> ant auth login erneut'
  warn '  - Token auf einen anderen Workspace gebunden -> ant auth status'
  warn 'Diagnose: ant auth status  und  ant --debug models list'
  connected=0
fi

# ---------------------------------------------------------------- Schritt 5
step "Schritt 5 — Agent OS neu starten"

aos=""
for candidate in "$HOME/Projects/Maximus_OS" "$HOME/Projects/maximus-agent-os"; do
  [ -d "$candidate" ] && { aos="$candidate"; break; }
done

if [ -n "$aos" ]; then
  ok "Agent OS gefunden: $aos"
  say '   Dashboard neu starten, damit der Bereich "Agenten" aktiv wird:'
  if [ -x "$aos/start-maximus-os.sh" ]; then
    say "     $aos/start-maximus-os.sh"
  else
    say "     open \"$aos/Start Agent OS.command\""
  fi
  say '   Danach http://localhost:3737 oeffnen und unter "Agenten" nachsehen.'
  say '   Health-Check von Agent OS selbst:'
  say "     open \"$aos/Check My Setup.command\""
else
  warn 'Agent OS nicht unter ~/Projects/ gefunden — Dashboard von Hand neu starten.'
fi

say ''
if [ "${connected:-0}" -eq 1 ]; then
  say 'Fertig: ant ist verbunden. Bleibt der Leitstand nach dem Neustart leer,'
  say 'ist das ein Fehler in Agent OS, nicht in der Anmeldung — dann die Ausgabe'
  say 'von `ant auth status` und die Dashboard-Logs ansehen.'
else
  say 'Nicht fertig: ant ist installiert, aber die API antwortet nicht.'
  say 'Erst Schritt 4 loesen, dann das Dashboard neu starten.'
  exit 1
fi
