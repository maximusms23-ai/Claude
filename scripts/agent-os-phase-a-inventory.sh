#!/usr/bin/env bash
#
# Phase A: rein lesende Bestandsaufnahme fuer die Agent-OS-Migration (Stand 27.10.2026).
# Auszufuehren auf dem Intel-Mac als maxim_mac. Nutzt die vorbereiteten SSH-Aliase
# rtx4080, macmini, asusserver. Aendert nichts, startet nichts, laedt nichts herunter.
# Gibt KEINE Secrets, Umgebungsvariablen oder Auth-Dateien aus.
#
# Aufruf:
#   bash agent-os-phase-a-inventory.sh > ~/phase-a-$(date +%Y%m%d-%H%M).txt 2>&1
#
# macOS bash 3.2 kompatibel.

ROOT="/Users/maxim_mac/Projects/Maximus_OS"
UID_NUM="$(id -u)"

h() { printf '\n########## %s\n' "$*"; }
s() { printf '\n--- %s\n' "$*"; }
run() { printf '$ %s\n' "$*"; "$@" 2>&1; }
ssh_ro() { # ssh_ro <alias> <befehl>
  local a="$1"; shift
  printf '$ ssh %s %s\n' "$a" "$*"
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$a" "$@" 2>&1 || printf '[ssh %s fehlgeschlagen]\n' "$a"
}

h "1. INTEL-MAC: Identitaet und Ressourcen"
run hostname
run sw_vers
run date
run id -un
run sysctl -n hw.memsize
run sysctl -n machdep.cpu.brand_string
s "Speicher"; run vm_stat | head -8
s "Swap"; run sysctl vm.swapusage
s "Platte"; run df -h / "$ROOT"
s "Uptime/Last"; run uptime

h "2. INTEL-MAC: launchd-Dienste (gui/$UID_NUM)"
run launchctl print-disabled "gui/$UID_NUM" | head -5
s "Relevante Jobs mit PID/Status"
launchctl list 2>/dev/null | grep -E 'honcho|maximus|studio|gbrain|caddy|hermes|openclaw|qwen' || echo "(keine Treffer)"
s "Vorbereitete LaunchAgents (plutil -lint)"
for f in "$ROOT"/runtime/migration-launchagents/*.plist; do
  [ -f "$f" ] && { printf '%s: ' "$(basename "$f")"; plutil -lint "$f" 2>&1 | tail -1; }
done
s "Geladene LaunchAgents in ~/Library/LaunchAgents"
ls -la "$HOME/Library/LaunchAgents" 2>/dev/null | grep -E 'honcho|maximus|studio|gbrain' || echo "(keine)"

h "3. INTEL-MAC: Ports"
s "Erwartet: 54329 54330 8000 3131 3737 3740 12340 (+Caddy 443/8444?)"
lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==1 || /:(54329|54330|8000|3131|3737|3740|12340|443|8444|18081)\>/'

h "4. INTEL-MAC: Quellstand und Build"
s "source"
run git -C "$ROOT/source" rev-parse --short HEAD
run git -C "$ROOT/source" status --short | head -20
run cat "$ROOT/source/.next/BUILD_ID"
run ls -la "$ROOT/source/.next/BUILD_ID"
s "source-live"
run git -C "$ROOT/source-live" rev-parse --short HEAD
run git -C "$ROOT/source-live" status --short | head -20
run cat "$ROOT/source-live/.next/BUILD_ID"
s "Unterschiede source <-> source-live (nur Dateiliste, ohne node_modules/.next)"
diff -rq "$ROOT/source" "$ROOT/source-live" -x node_modules -x .next -x .git -x '*.log' 2>/dev/null | head -60
s "Linux-spezifische Pfade in source-live"
grep -rIl --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git -E '/home/maxim|/usr/bin/|systemctl|\.service' "$ROOT/source-live" 2>/dev/null | head -20
s "Starter"
run sed -n '1,60p' "$ROOT/runtime/start-service.sh"
s "Node/Bun"
run "$ROOT/runtime/bin/node" --version
run bun --version
s "Webfrontend-Antwort (nur Statuscode und BUILD_ID-Header, kein Login)"
curl -s -o /dev/null -w 'http://127.0.0.1:3737 -> %{http_code}\n' --max-time 5 http://127.0.0.1:3737/ 2>&1
curl -s --max-time 5 http://127.0.0.1:8000/health 2>&1 | head -c 300; echo
curl -s -o /dev/null -w 'http://127.0.0.1:3740 -> %{http_code}\n' --max-time 5 http://127.0.0.1:3740/ 2>&1

h "5. INTEL-MAC: CLI-Anmeldungen (nur Status, keine Tokens)"
run codex --version
codex login status 2>&1 | head -3
run claude --version
claude auth status 2>&1 | head -5
run caddy version

h "6. RTX (ssh rtx4080)"
ssh_ro rtx4080 'hostname; whoami; date; uptime; free -g | head -2'
ssh_ro rtx4080 'nvidia-smi --query-gpu=name,driver_version,memory.used,memory.total --format=csv'
ssh_ro rtx4080 'systemctl --user list-units --type=service --all 2>/dev/null | grep -iE "strata|qwen|agent|hermes" ; systemctl list-units --type=service --all 2>/dev/null | grep -iE "strata|qwen|agent|hermes"'
ssh_ro rtx4080 'for u in $(systemctl --user list-units --type=service --all --no-legend 2>/dev/null | grep -iE "strata|qwen" | awk "{print \$1}"); do echo "== $u"; systemctl --user show "$u" -p ActiveState,SubState,MainPID,MemoryMax,MemorySwapMax; done'
ssh_ro rtx4080 'ss -ltnp 2>/dev/null | grep -E ":(18081|18085|3737|22) " || echo "Port 18081/18085 nicht offen"'
ssh_ro rtx4080 'M=/home/maxim/maximus/agent-os-staging/runtime/intel-migration-20261026; ls -la $M/bin $M/models 2>&1 | head -30; du -sh $M/models 2>/dev/null'
ssh_ro rtx4080 'M=/home/maxim/maximus/agent-os-staging/runtime/intel-migration-20261026; $M/bin/strata --version 2>&1 | head -3; $M/bin/strata launch --help 2>&1 | head -40'
ssh_ro rtx4080 'ls -la /home/maxim/maximus/agent-os-staging/vault-staging/"Agentic OS"/ 2>&1 | head; ls /home/maxim/maximus/agent-os-staging/vault-staging 2>&1 | head -30'
ssh_ro rtx4080 'ls -la ~/.agentic-os/graphify/ 2>&1 | head'
ssh_ro rtx4080 'cd /home/maxim/maximus/agent-os-staging && git rev-parse --short HEAD 2>/dev/null; cat .next/BUILD_ID 2>/dev/null; cat source/.next/BUILD_ID 2>/dev/null'

h "7. MAC MINI (ssh macmini)"
ssh_ro macmini 'hostname; whoami; date; sysctl -n hw.memsize; sysctl vm.swapusage; vm_stat | head -6'
ssh_ro macmini 'launchctl list 2>/dev/null | grep -E "qwen|maximus|honcho|caddy|hermes" || echo "(keine)"'
ssh_ro macmini 'lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk "NR==1 || /:(12340|12344|18085|3737|8444|443)\\>/"'
ssh_ro macmini 'ps -axo pid,rss,command 2>/dev/null | grep -iE "llama|qwen|colibri|strata" | grep -v grep || echo "(kein Modellprozess)"'
ssh_ro macmini 'ls -la /Users/maxim/Projects/Maximus_OS/runtime/ 2>&1 | head -30'
ssh_ro macmini 'ls -la "/Users/maxim/Documents/ChatGPT/Agent OS/runtime/intel-orchestrator-migration-20261026/" 2>&1'
ssh_ro macmini 'cat "/Users/maxim/Documents/ChatGPT/Agent OS/runtime/intel-orchestrator-migration-20261026/STATUS.md" 2>&1 | head -120'
ssh_ro macmini 'cat "/Users/maxim/Documents/ChatGPT/Agent OS/runtime/intel-orchestrator-migration-20261026/RTX-BENCHMARK.md" 2>&1 | head -80'
ssh_ro macmini 'cat "/Users/maxim/Documents/ChatGPT/Agent OS/runtime/intel-orchestrator-migration-20261026/source-comparison.json" 2>&1 | head -80'

h "8. ASUS (ssh asusserver) – nur Identitaet"
ssh_ro asusserver 'hostname; whoami; uptime; ip -br -4 addr 2>/dev/null | grep -v lo'

h "ENDE Phase A. Keine Aenderungen vorgenommen."
