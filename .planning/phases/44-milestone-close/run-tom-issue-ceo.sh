#!/usr/bin/env bash
# Run when PaperclipAI / Maximus_OS API is reachable (default http://localhost:3100).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
exec "$ROOT/bin/tom-issue" \
  --title "Milestone v1.5 geschlossen — Lifecycle + Integration (Phase 44)" \
  --description "Tom v1.5 Milestone-Close abgeschlossen.

CEO-Briefing: .planning/briefings/v1.5-CEO-Briefing.md
Phase-44 Commit: siehe git log -1 --oneline (Branch main)

63 Requirements, 57 erfuellt, 6 HYG Known Gaps (Maxim-Handoff) dokumentiert in .planning/MILESTONES.md" \
  --priority high \
  --agent ceo
