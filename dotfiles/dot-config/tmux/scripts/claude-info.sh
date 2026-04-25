#!/usr/bin/env bash
# Output Claude model + agent info for tmux status bar.
# Reads ~/.claude/tmux-model-info (written by the SessionStart hook).
# Format of info file: "model_name:agent_name" (either can be empty)
# Returns empty string if Claude is not running / no info available.

INFO_FILE="${HOME}/.claude/tmux-model-info"

[[ -f "$INFO_FILE" ]] || exit 0

content=$(< "$INFO_FILE")
model="${content%%:*}"
agent="${content#*:}"

parts=()
[[ -n "$model" ]] && parts+=("$model")
[[ -n "$agent" && "$agent" != "$model" ]] && parts+=("($agent)")

if [[ ${#parts[@]} -gt 0 ]]; then
    printf ' %s' "${parts[*]}"
fi
