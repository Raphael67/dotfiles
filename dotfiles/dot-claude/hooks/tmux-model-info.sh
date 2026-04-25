#!/usr/bin/env bash
# Hook: write Claude model info to a temp file for tmux to display
# Triggered on SessionStart / SubagentStart
# Receives JSON on stdin with shape: { "model": { "id": "...", "display_name": "..." }, ... }

INFO_FILE="${HOME}/.claude/tmux-model-info"

input=$(cat)

# Extract model display_name and id (fallback chain)
# Prefer the model id (e.g. "claude-sonnet-4-6") over display_name ("Claude Sonnet 4.6")
# since ids are more compact and machine-readable.
model_name=$(printf '%s' "$input" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    m = d.get('model', {}) or {}
    # Prefer id (compact), fall back to display_name
    name = m.get('id') or m.get('display_name') or ''
    # Shorten: 'claude-sonnet-4-6' -> 'sonnet-4-6'
    name = name.removeprefix('claude-')
    print(name)
except Exception:
    print('')
" 2>/dev/null)

# Extract agent name from env (CLAUDE_CODE_AGENT) if set
agent="${CLAUDE_CODE_AGENT:-}"

# Write to temp file: "model:agent" (either can be empty)
if [[ -n "$model_name" || -n "$agent" ]]; then
    printf '%s:%s\n' "$model_name" "$agent" > "$INFO_FILE"
fi
