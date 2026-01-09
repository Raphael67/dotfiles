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
CLAUDE_MONTHLY_USAGE_FILE="${CLAUDE_MONTHLY_USAGE_FILE:-$HOME/.claude/monthly_usage.json}"
CLAUDE_MONTHLY_TARGET="${CLAUDE_MONTHLY_TARGET:-11000000}"
LOCK_FILE="/tmp/claude_usage.lock"
MONTHLY_LOCK_FILE="/tmp/claude_monthly_usage.lock"
STATE_FILE="${CLAUDE_STATE_FILE:-$HOME/.claude/statusline_state.json}"

# Read input from stdin
input=$(cat)

# Extract data from status line context (using actual Claude Code JSON structure)
SESSION_ID=$(echo "$input" | jq -r '.session_id // "unknown"')
TOKENS_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOKENS_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
MODEL=$(echo "$input" | jq -r '(.model.display_name // .model.id // "Claude") | if . == "" or . == null then "Claude" else . end')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Detect context clear: significant drop in tokens for same session or very low tokens
PREV_TOKENS=0
PREV_SESSION=""
if [ -f "$STATE_FILE" ]; then
    PREV_TOKENS=$(jq -r '.tokens // 0' "$STATE_FILE" 2>/dev/null || echo 0)
    PREV_SESSION=$(jq -r '.session_id // ""' "$STATE_FILE" 2>/dev/null || echo "")
fi

# Session was cleared if: same session with >50% token drop, or new session with <1% context usage
CONTEXT_CLEARED=false
if [ "$SESSION_ID" = "$PREV_SESSION" ] && [ "$PREV_TOKENS" -gt 10000 ] && [ "$TOKENS_USED" -lt $((PREV_TOKENS / 2)) ]; then
    CONTEXT_CLEARED=true
elif [ "$SESSION_ID" != "$PREV_SESSION" ] && [ "$TOKENS_USED" -lt $((TOKENS_MAX / 100)) ]; then
    CONTEXT_CLEARED=true
fi

# Save current state for next invocation
echo "{\"session_id\":\"$SESSION_ID\",\"tokens\":$TOKENS_USED,\"timestamp\":$(date +%s)}" > "$STATE_FILE"

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

    # If context was cleared and session changed, remove the old session from 5h tracking
    # This prevents stale session data from inflating the 5h window after /clear
    if [ "$CONTEXT_CLEARED" = true ] && [ "$SESSION_ID" != "$PREV_SESSION" ] && [ -n "$PREV_SESSION" ]; then
        LOG=$(echo "$LOG" | jq --arg old_sid "$PREV_SESSION" \
            '.sessions = [.sessions[] | select(.session_id != $old_sid)]')
    fi

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

# Monthly usage tracking
CURRENT_MONTH=$(date +"%B")
CURRENT_MONTH_NUM=$(date +"%Y-%m")

# Ensure monthly usage file exists
mkdir -p "$(dirname "$CLAUDE_MONTHLY_USAGE_FILE")"
if [ ! -f "$CLAUDE_MONTHLY_USAGE_FILE" ]; then
    echo "{\"month\":\"$CURRENT_MONTH\",\"month_num\":\"$CURRENT_MONTH_NUM\",\"tokens\":0,\"sessions\":{}}" > "$CLAUDE_MONTHLY_USAGE_FILE"
fi

# Acquire lock for monthly file
acquire_monthly_lock() {
    local max_attempts=10
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if mkdir "$MONTHLY_LOCK_FILE" 2>/dev/null; then
            trap 'rm -rf "$LOCK_FILE" "$MONTHLY_LOCK_FILE"' EXIT
            return 0
        fi
        if [ -d "$MONTHLY_LOCK_FILE" ]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                local lock_mtime=$(stat -f %m "$MONTHLY_LOCK_FILE" 2>/dev/null || echo $NOW)
            else
                local lock_mtime=$(stat -c %Y "$MONTHLY_LOCK_FILE" 2>/dev/null || echo $NOW)
            fi
            local lock_age=$((NOW - lock_mtime))
            if [ $lock_age -gt 5 ]; then
                rm -rf "$MONTHLY_LOCK_FILE"
                continue
            fi
        fi
        sleep 0.1
        attempt=$((attempt + 1))
    done
    return 1
}

if acquire_monthly_lock; then
    MONTHLY_LOG=$(cat "$CLAUDE_MONTHLY_USAGE_FILE" 2>/dev/null || echo "{\"month\":\"$CURRENT_MONTH\",\"month_num\":\"$CURRENT_MONTH_NUM\",\"tokens\":0,\"sessions\":{}}")

    STORED_MONTH_NUM=$(echo "$MONTHLY_LOG" | jq -r '.month_num // ""')

    # Reset if new month
    if [ "$STORED_MONTH_NUM" != "$CURRENT_MONTH_NUM" ]; then
        MONTHLY_LOG="{\"month\":\"$CURRENT_MONTH\",\"month_num\":\"$CURRENT_MONTH_NUM\",\"tokens\":0,\"sessions\":{}}"
    fi

    # Get previous token count for this session (to calculate delta)
    PREV_SESSION_TOKENS=$(echo "$MONTHLY_LOG" | jq -r --arg sid "$SESSION_ID" '.sessions[$sid] // 0')

    # Calculate token delta (only add new tokens, not total)
    if [ "$TOKENS_USED" -gt "$PREV_SESSION_TOKENS" ]; then
        TOKEN_DELTA=$((TOKENS_USED - PREV_SESSION_TOKENS))
    else
        # Session was cleared or new session, use current tokens
        TOKEN_DELTA=$TOKENS_USED
    fi

    # Update monthly total and session tracking
    UPDATED_MONTHLY_LOG=$(echo "$MONTHLY_LOG" | jq \
        --arg month "$CURRENT_MONTH" \
        --arg month_num "$CURRENT_MONTH_NUM" \
        --arg sid "$SESSION_ID" \
        --argjson tokens "$TOKENS_USED" \
        --argjson delta "$TOKEN_DELTA" \
        '
        .month = $month |
        .month_num = $month_num |
        .tokens = (.tokens + $delta) |
        .sessions[$sid] = $tokens
        ')

    echo "$UPDATED_MONTHLY_LOG" > "$CLAUDE_MONTHLY_USAGE_FILE"
    rm -rf "$MONTHLY_LOCK_FILE"
fi

# Read monthly totals for display
MONTHLY_LOG=$(cat "$CLAUDE_MONTHLY_USAGE_FILE" 2>/dev/null || echo "{\"month\":\"$CURRENT_MONTH\",\"tokens\":0}")
MONTHLY_TOKENS=$(echo "$MONTHLY_LOG" | jq -r '.tokens // 0')
MONTHLY_NAME=$(echo "$MONTHLY_LOG" | jq -r '.month // "Unknown"')

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

if [ "$CLAUDE_MONTHLY_TARGET" -gt 0 ]; then
    MONTHLY_PCT=$((MONTHLY_TOKENS * 100 / CLAUDE_MONTHLY_TARGET))
else
    MONTHLY_PCT=0
fi

# Cap percentages at 100
[ "$CTX_PCT" -gt 100 ] && CTX_PCT=100
[ "$WINDOW_PCT" -gt 100 ] && WINDOW_PCT=100
[ "$MONTHLY_PCT" -gt 100 ] && MONTHLY_PCT=100

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
MONTHLY_BAR=$(build_bar $MONTHLY_PCT)

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

# Monthly color is inverted (higher = better, reaching break-even target)
get_monthly_color() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then
        echo "\033[32m"  # Green - on track
    elif [ "$pct" -ge 50 ]; then
        echo "\033[33m"  # Yellow - moderate
    else
        echo "\033[31m"  # Red - low usage
    fi
}
MONTHLY_COLOR=$(get_monthly_color $MONTHLY_PCT)

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
MONTHLY_TOKENS_FMT=$(format_tokens $MONTHLY_TOKENS)
MONTHLY_TARGET_FMT=$(format_tokens $CLAUDE_MONTHLY_TARGET)

# Build status line
BOLD="\033[1m"
CYAN="\033[36m"
MAGENTA="\033[35m"

# Show "fresh" indicator when context is very low (likely just cleared or new session)
FRESH_INDICATOR=""
if [ "$TOKENS_USED" -lt 5000 ]; then
    FRESH_INDICATOR=" ${MAGENTA}✦${RESET}"
fi

echo -e "${BOLD}${CYAN}${MODEL}${RESET}${FRESH_INDICATOR} ${DIM}│${RESET} ${DIM}ctx${RESET} ${CTX_COLOR}${CTX_BAR}${RESET} ${CTX_TOKENS_FMT}/${CTX_MAX_FMT} ${DIM}│${RESET} ${DIM}5h${RESET} ${WINDOW_COLOR}${WINDOW_BAR}${RESET} ${WINDOW_TOKENS_FMT}/${WINDOW_MAX_FMT} ${DIM}│${RESET} ${MONTHLY_COLOR}${MONTHLY_NAME} ${MONTHLY_TOKENS_FMT}/${MONTHLY_TARGET_FMT}${RESET}"
