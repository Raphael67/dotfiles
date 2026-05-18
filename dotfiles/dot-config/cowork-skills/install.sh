#!/usr/bin/env bash
# One-time installer for the claude-code-skills-bridge Cowork plugin.
#
# What this does:
#   1. Copies the plugin from the dotfiles tree into Cowork's rpm/ directory.
#   2. Registers it in rpm/manifest.json (Cowork's plugin registry).
#   3. Runs sync.py to populate the plugin's skills/ from ~/.claude/skills/.
#   4. Prints the post-install instruction (restart Claude Desktop).
#
# Idempotent: safe to re-run. Use `cowork-skills` for routine re-syncs;
# only re-run install.sh if the plugin's manifest/structure has changed.

set -euo pipefail

# --- Resolve paths -----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$HOME/.claude/cowork-plugins/claude-code-skills-bridge" ]]; then
    PLUGIN_SRC="$HOME/.claude/cowork-plugins/claude-code-skills-bridge"
elif [[ -d "$SCRIPT_DIR/../../dot-claude/cowork-plugins/claude-code-skills-bridge" ]]; then
    PLUGIN_SRC="$(cd "$SCRIPT_DIR/../../dot-claude/cowork-plugins/claude-code-skills-bridge" && pwd)"
else
    echo "ERROR: cannot locate claude-code-skills-bridge plugin source." >&2
    exit 1
fi

COWORK_ROOT="$HOME/Library/Application Support/Claude/local-agent-mode-sessions"

# --- Sanity checks -----------------------------------------------------------

if [[ ! -d "$COWORK_ROOT" ]]; then
    echo "ERROR: Cowork app data not found at $COWORK_ROOT" >&2
    echo "Open Claude Desktop and launch a Cowork session at least once first." >&2
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: 'jq' not in PATH. brew install jq" >&2
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: 'python3' not in PATH." >&2
    exit 1
fi

# --- Find the rpm/ directory --------------------------------------------------

RPM_DIR="$(find "$COWORK_ROOT" -maxdepth 3 -type d -name "rpm" 2>/dev/null | head -1)"
if [[ -z "$RPM_DIR" ]]; then
    echo "ERROR: no rpm/ directory found under $COWORK_ROOT." >&2
    echo "Install any plugin via Cowork's UI once, then re-run." >&2
    exit 1
fi
PLUGIN_DEST="$RPM_DIR/plugin_claude-code-skills-bridge"

echo "==> Installing plugin"
echo "    source: $PLUGIN_SRC"
echo "    target: $PLUGIN_DEST"

# --- Copy the plugin (real files, no symlinks; VM can't follow them) ---------

if [[ -d "$PLUGIN_DEST" ]]; then
    rm -rf "$PLUGIN_DEST"
fi
mkdir -p "$PLUGIN_DEST"
cp -RL "$PLUGIN_SRC"/. "$PLUGIN_DEST"/

# Ensure skills/ exists even before the first sync
mkdir -p "$PLUGIN_DEST/skills"

echo "    plugin files:"
find "$PLUGIN_DEST" -maxdepth 3 -type f | sed "s|$PLUGIN_DEST/|      |"
echo

# --- Register in rpm/manifest.json -------------------------------------------

REG_MANIFEST="$RPM_DIR/manifest.json"
echo "==> Registering plugin in rpm/manifest.json"
if [[ -f "$REG_MANIFEST" ]]; then
    cp "$REG_MANIFEST" "$REG_MANIFEST.bak.$(date +%Y%m%d-%H%M%S)"
else
    echo '{"lastUpdated":0,"plugins":[]}' > "$REG_MANIFEST"
fi
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%S.000000Z")"
NOW_MS="$(($(date +%s) * 1000))"
TMP="$(mktemp)"
jq --arg id "plugin_claude-code-skills-bridge" \
   --arg name "claude-code-skills-bridge" \
   --arg ts "$NOW_ISO" \
   --argjson ms "$NOW_MS" \
   '
   .plugins = ((.plugins // []) | map(select(.id != $id))) +
              [{
                "id": $id,
                "name": $name,
                "updatedAt": $ts,
                "marketplaceId": "marketplace_local",
                "marketplaceName": "My Uploads",
                "installedBy": "user",
                "installationPreference": "available"
              }]
   | .lastUpdated = $ms
   ' "$REG_MANIFEST" > "$TMP" && mv "$TMP" "$REG_MANIFEST"
echo "    registered."
echo

# --- Sync skills from ~/.claude/skills/ --------------------------------------

echo "==> Initial sync from ~/.claude/skills/"
python3 "$SCRIPT_DIR/sync.py"

# --- Done --------------------------------------------------------------------

cat <<'MSG'
==> Done.

Daily workflow:
  Whenever you add or edit a skill in ~/.claude/skills/, run:
      cowork-skills
  Then restart Claude Desktop. New Cowork sessions will see the updated set.

Inside Cowork your skills appear namespaced as:
      claude-code-skills-bridge:<skill-name>

No daemon, no port, no MCP server. Pure file copy.
MSG
