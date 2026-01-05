#!/bin/bash
# Claude Code Status Line - Token Usage Tracker
# Shows current context + 5-hour rolling window usage

# Load configuration from .env if it exists
ENV_FILE="$HOME/.claude/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Default usage file path (can be overridden via .env)
CLAUDE_USAGE_FILE="${CLAUDE_USAGE_FILE:-$HOME/.claude/usage_log.json}"
LOCK_FILE="/tmp/claude_usage.lock"

# Read input from stdin
input=$(cat)

# Extract data from status line context (using actual Claude Code JSON structure)
SESSION_ID=$(echo "$input" | jq -r '.session_id // "unknown"')
TOKENS_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOKENS_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
MODEL=$(echo "$input" | jq -r '(.model.display_name // .model.id // "Claude") | if . == "" or . == null then "Claude" else . end')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

NOW=$(date +%s)
FIVE_HOURS=18000
FIVE_HOURS_AGO=$((NOW - FIVE_HOURS))

# Ensure usage file exists
mkdir -p "$(dirname "$CLAUDE_USAGE_FILE")"
if [ ! -f "$CLAUDE_USAGE_FILE" ]; then
    echo '{"sessions":[]}' > "$CLAUDE_USAGE_FILE"
fi

# Use mkdir-based lock (portable for macOS)
acquire_lock() {
    local max_attempts=10
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if mkdir "$LOCK_FILE" 2>/dev/null; then
            trap 'rm -rf "$LOCK_FILE"' EXIT
            return 0
        fi
        # Check if lock is stale (older than 5 seconds)
        if [ -d "$LOCK_FILE" ]; then
            # Cross-platform stat: macOS uses -f %m, Linux uses -c %Y
            if [[ "$OSTYPE" == "darwin"* ]]; then
                local lock_mtime=$(stat -f %m "$LOCK_FILE" 2>/dev/null || echo $NOW)
            else
                local lock_mtime=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo $NOW)
            fi
            local lock_age=$((NOW - lock_mtime))
            if [ $lock_age -gt 5 ]; then
                rm -rf "$LOCK_FILE"
                continue
            fi
        fi
        sleep 0.1
        attempt=$((attempt + 1))
    done
    return 1
}

if acquire_lock; then
    # Read current log
    LOG=$(cat "$CLAUDE_USAGE_FILE" 2>/dev/null || echo '{"sessions":[]}')

    # Remove entries older than 5 hours and update current session
    UPDATED_LOG=$(echo "$LOG" | jq --arg sid "$SESSION_ID" \
        --argjson now "$NOW" \
        --argjson cutoff "$FIVE_HOURS_AGO" \
        --argjson tokens "$TOKENS_USED" \
        --argjson cost "$COST" \
        '
        .sessions = [.sessions[] | select(.timestamp > $cutoff and .session_id != $sid)]
        | .sessions += [{"session_id": $sid, "tokens": $tokens, "cost": $cost, "timestamp": $now}]
        ')

    echo "$UPDATED_LOG" > "$CLAUDE_USAGE_FILE"
    rm -rf "$LOCK_FILE"
fi

# Calculate 5-hour totals
LOG=$(cat "$CLAUDE_USAGE_FILE" 2>/dev/null || echo '{"sessions":[]}')
TOTAL_5H_TOKENS=$(echo "$LOG" | jq --argjson cutoff "$FIVE_HOURS_AGO" \
    '[.sessions[] | select(.timestamp > $cutoff) | .tokens] | add // 0')
TOTAL_5H_COST=$(echo "$LOG" | jq --argjson cutoff "$FIVE_HOURS_AGO" \
    '[.sessions[] | select(.timestamp > $cutoff) | .cost] | add // 0')
SESSION_COUNT=$(echo "$LOG" | jq --argjson cutoff "$FIVE_HOURS_AGO" \
    '[.sessions[] | select(.timestamp > $cutoff)] | length')

# Claude Max limits (approximate - adjust based on your tier)
# These are estimates; actual limits may vary
MAX_5H_TOKENS=5000000  # ~5M tokens per 5h window (adjust as needed)

# Calculate percentages
if [ "$TOKENS_MAX" -gt 0 ]; then
    CTX_PCT=$((TOKENS_USED * 100 / TOKENS_MAX))
else
    CTX_PCT=0
fi

if [ "$MAX_5H_TOKENS" -gt 0 ]; then
    WINDOW_PCT=$((TOTAL_5H_TOKENS * 100 / MAX_5H_TOKENS))
else
    WINDOW_PCT=0
fi

# Cap percentages at 100
[ "$CTX_PCT" -gt 100 ] && CTX_PCT=100
[ "$WINDOW_PCT" -gt 100 ] && WINDOW_PCT=100

# Build progress bars (10 chars each)
build_bar() {
    local pct=$1
    local width=10
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    local bar=""

    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo "$bar"
}

CTX_BAR=$(build_bar $CTX_PCT)
WINDOW_BAR=$(build_bar $WINDOW_PCT)

# Colors based on usage
get_color() {
    local pct=$1
    if [ "$pct" -lt 50 ]; then
        echo "\033[32m"  # Green
    elif [ "$pct" -lt 80 ]; then
        echo "\033[33m"  # Yellow
    else
        echo "\033[31m"  # Red
    fi
}

CTX_COLOR=$(get_color $CTX_PCT)
WINDOW_COLOR=$(get_color $WINDOW_PCT)
RESET="\033[0m"
DIM="\033[2m"

# Format numbers
format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fM\", $tokens/1000000}"
    elif [ "$tokens" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fK\", $tokens/1000}"
    else
        echo "$tokens"
    fi
}

CTX_TOKENS_FMT=$(format_tokens $TOKENS_USED)
CTX_MAX_FMT=$(format_tokens $TOKENS_MAX)
WINDOW_TOKENS_FMT=$(format_tokens $TOTAL_5H_TOKENS)
WINDOW_MAX_FMT=$(format_tokens $MAX_5H_TOKENS)

# Build status line
BOLD="\033[1m"
CYAN="\033[36m"
echo -e "${BOLD}${CYAN}${MODEL}${RESET} ${DIM}│${RESET} ${DIM}ctx${RESET} ${CTX_COLOR}${CTX_BAR}${RESET} ${CTX_TOKENS_FMT}/${CTX_MAX_FMT} ${DIM}│${RESET} ${DIM}5h${RESET} ${WINDOW_COLOR}${WINDOW_BAR}${RESET} ${WINDOW_TOKENS_FMT}/${WINDOW_MAX_FMT} ${DIM}(${SESSION_COUNT} sessions)${RESET}"
