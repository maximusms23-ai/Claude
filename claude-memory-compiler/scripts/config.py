"""Path constants and configuration for the personal knowledge base.

TOM-PATCHED: Paths point to $TOM_VAULT/95_Gehirn/ instead of the tool repo.
This makes the tool write into Maxim's iCloud Obsidian vault while keeping
the tool itself (scripts, hooks, state.json) git-tracked under /Users/maxim/Claude/.
See TOM-PATCHES.md in the repo root for details.
"""

import os
from pathlib import Path
from datetime import datetime, timezone

# ── Paths ──────────────────────────────────────────────────────────────
# Tool repo root (scripts, hooks, AGENTS.md, state.json live here — git-tracked)
SCRIPTS_DIR = Path(__file__).resolve().parent
TOOL_ROOT = SCRIPTS_DIR.parent
HOOKS_DIR = TOOL_ROOT / "hooks"
AGENTS_FILE = TOOL_ROOT / "AGENTS.md"
STATE_FILE = SCRIPTS_DIR / "state.json"

# Vault root (iCloud, NOT git-tracked — Tom's private brain)
_default_vault = (
    "/Users/maxim/Library/Mobile Documents/com~apple~CloudDocs/"
    "Obsidian_Valuet/Obsidian_Zentralw"
)
TOM_VAULT = Path(os.environ.get("TOM_VAULT", _default_vault))
VAULT_ROOT = TOM_VAULT / "95_Gehirn"

# Brain-Struktur lives inside $TOM_VAULT/95_Gehirn/
DAILY_DIR = VAULT_ROOT / "daily"
KNOWLEDGE_DIR = VAULT_ROOT / "knowledge"
CONCEPTS_DIR = KNOWLEDGE_DIR / "concepts"
CONNECTIONS_DIR = KNOWLEDGE_DIR / "connections"
QA_DIR = KNOWLEDGE_DIR / "qa"
REPORTS_DIR = VAULT_ROOT / "reports"

# Karpathy retrieval index + build log at Brain root (not under knowledge/)
INDEX_FILE = VAULT_ROOT / "index.md"
LOG_FILE = VAULT_ROOT / "log.md"

# Kept for backwards compatibility with upstream scripts that still
# reference ROOT_DIR — point it at the vault root so any stray usages
# land in the Brain, not the tool repo.
ROOT_DIR = VAULT_ROOT

# ── Timezone ───────────────────────────────────────────────────────────
TIMEZONE = "Europe/Berlin"


def now_iso() -> str:
    """Current time in ISO 8601 format."""
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def today_iso() -> str:
    """Current date in ISO 8601 format."""
    return datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d")
