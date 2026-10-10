#!/usr/bin/env bash
# MAXIMUS T2 Neuinstallation V1 - Fehlerfall
#
# Ergebnis: Das Skript kennzeichnet eine unvollstaendige Installation und
# nennt den naechsten Schritt. Es aendert keine Datenbereiche.
set -uo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SELF_DIR/lib/common.sh"
MX_LOG=/var/log/maximus-t2-neuinstall.log

log_step "Die Installation ist fehlgeschlagen"
MARK=/var/log/maximus-installation-unvollstaendig
{
	printf 'zustand=unvollstaendig\n'
	printf 'zeitpunkt=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
	printf 'ubiquity_protokoll=/var/log/installer/debug\n'
	printf 'assistent_protokoll=%s\n' "$MX_LOG"
} > "$MARK"
log_err "Die Installation ist UNVOLLSTAENDIG."
log "Kennzeichen liegt in: $MARK"
log ""
log "Naechster Schritt:"
log "  1. Lies /var/log/installer/debug und $MX_LOG."
log "  2. Das Zielsystem ist nicht startfaehig. Starte es nicht."
log "  3. Die Anleitung recovery/WIEDERHERSTELLUNG.md liegt auf dem Medium."
log ""
log_warn "Es wird nichts selbsttaetig wiederholt."
log_warn "Eine Wiederholung veraendert sonst weitere Datenbereiche."
exit 0
