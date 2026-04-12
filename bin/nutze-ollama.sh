#!/usr/bin/env bash
# nutze-ollama.sh — Shell-Library für lokalen Ollama-Modus in Claude Code
#
# Zweck: Maxim schaltet per `nutze-ollama` die aktuelle Shell so, dass
#   jeder folgende `claude`-Aufruf gegen den lokalen Claude Code Router
#   läuft, der wiederum Ollama bedient. Mit `nutze-claude` zurück zu Cloud.
#
# Source-Pfad: Diese Datei wird via ~/.zshrc gesourced:
#   [[ -f "$HOME/Claude/bin/nutze-ollama.sh" ]] && source "$HOME/Claude/bin/nutze-ollama.sh"
#
# Commands (nach Sourcing):
#   nutze-ollama     → ANTHROPIC_*-env auf lokales CCR setzen, Warning ausgeben
#   nutze-claude     → env-vars wieder entfernen, Cloud-Modus
#   ollama-status    → Aktueller Modus, Ollama-Health, CCR-Daemon, Modell-Liste
#
# Design-Notes:
#   - Kein `set -e` in sourced Lib, sonst killt Fehler die Parent-Shell
#   - Preflight ist idempotent: CCR-Daemon wird auto-gestartet wenn tot
#   - Model-Aliasing passiert im CCR-Config (Opus/Haiku→qwen2.5:3b)
#   - ADR: siehe /Users/maxim/Claude/.planning/phases/36-ollama-switch/36-01-PLAN.md

# --- Konstanten ---
# shellcheck disable=SC2034
_TOM_OLLAMA_CCR_PORT=3456
_TOM_OLLAMA_LOG="$HOME/Library/Logs/nutze-ollama.log"

# --- Hilfs-Funktionen ---

_tom_ollama_log() {
  mkdir -p "$(dirname "$_TOM_OLLAMA_LOG")"
  local ts
  ts=$(date "+%Y-%m-%d %H:%M:%S %z")
  printf '%s | %s\n' "$ts" "$*" >> "$_TOM_OLLAMA_LOG"
}

_tom_ollama_preflight() {
  # Returns 0 on success, non-zero on failure. Prints errors to stderr.
  if ! command -v ollama >/dev/null 2>&1; then
    echo "✗ ollama binary nicht im PATH" >&2
    return 1
  fi
  if ! ollama list >/dev/null 2>&1; then
    echo "✗ ollama server nicht erreichbar — 'ollama serve' starten?" >&2
    return 2
  fi
  if ! command -v ccr >/dev/null 2>&1; then
    echo "✗ ccr binary nicht im PATH — 'npm install -g @musistudio/claude-code-router'?" >&2
    return 3
  fi
  # CCR-Daemon-Check + idempotenter Start
  if ! ccr status 2>&1 | grep -q "Running"; then
    echo "… CCR-Daemon nicht aktiv, starte …" >&2
    ccr start >/dev/null 2>&1 &
    disown 2>/dev/null || true
    local tries=0
    while [ $tries -lt 10 ]; do
      sleep 0.5
      if ccr status 2>&1 | grep -q "Running"; then
        echo "✓ CCR-Daemon gestartet" >&2
        break
      fi
      tries=$((tries + 1))
    done
    if [ $tries -eq 10 ]; then
      echo "✗ CCR-Daemon konnte nicht gestartet werden" >&2
      return 4
    fi
  fi
  # Modelle vorhanden?
  local models
  models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')
  if ! echo "$models" | grep -q "^qwen2.5:3b"; then
    echo "⚠ qwen2.5:3b nicht gefunden — lokaler Qwen-Stack wird brechen" >&2
    echo "  Fix: ollama pull qwen2.5:3b" >&2
  fi
  return 0
}

# --- Haupt-Funktionen ---

nutze-ollama() {
  if ! _tom_ollama_preflight; then
    echo "✗ Preflight fehlgeschlagen — Modus bleibt Cloud" >&2
    _tom_ollama_log "FAIL preflight"
    return 1
  fi

  # CCR liefert die env-vars — wir eval'en den Output direkt in current shell
  local ccr_env
  ccr_env=$(ccr activate 2>/dev/null)
  if [ -z "$ccr_env" ]; then
    echo "✗ 'ccr activate' lieferte keine Ausgabe — Config fehlerhaft?" >&2
    _tom_ollama_log "FAIL ccr activate empty"
    return 2
  fi
  eval "$ccr_env"

  cat >&2 <<EOF
⚠  Lokaler Ollama-Modus aktiv
   ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-?}
   Modell-Aliasing (CCR-Router):
     /model opus   →  qwen2.5:3b  (Chat, Wiki, Research)
     /model haiku  →  qwen2.5:3b  (Chat, Wiki, Research)
   GSD-Workflows/Superpowers/Multi-Step bleiben im lokalen Modus eingeschraenkt.
   Rückkehr zu Cloud: nutze-claude
EOF
  _tom_ollama_log "OK nutze-ollama activated"
}

nutze-claude() {
  unset ANTHROPIC_AUTH_TOKEN
  unset ANTHROPIC_API_KEY
  unset ANTHROPIC_BASE_URL
  unset NO_PROXY
  unset DISABLE_TELEMETRY
  unset DISABLE_COST_WARNINGS
  unset API_TIMEOUT_MS
  echo "✓ Cloud-Modus wiederhergestellt — claude läuft wieder gegen Anthropic" >&2
  _tom_ollama_log "OK nutze-claude deactivated"
}

ollama-status() {
  local mode ollama_ok ccr_ok models
  if [ -n "${ANTHROPIC_BASE_URL:-}" ]; then
    mode="🦙 LOKAL (Ollama via CCR)"
  else
    mode="☁️  CLOUD (echte Anthropic)"
  fi

  if command -v ollama >/dev/null 2>&1 && ollama list >/dev/null 2>&1; then
    ollama_ok="✓"
  else
    ollama_ok="✗"
  fi

  if command -v ccr >/dev/null 2>&1 && ccr status 2>&1 | grep -q "Running"; then
    ccr_ok="✓ running (PID $(ccr status 2>&1 | grep -oE 'Process ID: [0-9]+' | awk '{print $3}'))"
  else
    ccr_ok="✗ gestoppt"
  fi

  models=$(ollama list 2>/dev/null | awk 'NR>1 {printf "     • %s (%s)\n", $1, $3}')

  cat <<EOF
=== Tom Ollama-Switch Status ===

Aktueller Modus: $mode
Ollama-Daemon:   $ollama_ok
CCR-Daemon:      $ccr_ok
ANTHROPIC_BASE_URL: ${ANTHROPIC_BASE_URL:-<leer>}

Installierte Ollama-Modelle:
$models

Aliasing (im Lokal-Modus):
  /model opus   →  qwen2.5:3b  (Chat/Research)
  /model haiku  →  qwen2.5:3b  (Chat/Research)

Kommandos:
  nutze-ollama   → in Lokal-Modus wechseln
  nutze-claude   → zurück in Cloud-Modus
  tom-local      → Subshell im Lokal-Modus spawnen
  tom-local <cmd>→ Ein-Shot Kommando im Lokal-Modus
EOF
}
